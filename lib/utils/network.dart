import 'package:game_tracker/core/app_id_list_provider.dart';
import 'package:game_tracker/utils/localio.dart';
import 'package:http/http.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

Future<List<SteamGameNameInfo>> searchSteam(String query, int limit) async {
  final encodedQuery = Uri.encodeComponent(query.replaceAll(" ", "+"));
  final url = 'https://store.steampowered.com/search/?term=$encodedQuery';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    return List.empty();
  }

  final document = parse(response.body);
  final results = document.querySelectorAll('.search_result_row');

  int counter = 0;
  List<SteamGameNameInfo> searchResults = [];
  for (var result in results) {
    final href = result.attributes['href'];
    final titleElement = result.querySelector('.title');

    if (href != null && titleElement != null) {
      final appIdMatch = RegExp(r'/app/(\d+)/').firstMatch(href);
      if (appIdMatch != null) {
        final appid = int.parse(appIdMatch.group(1) ?? "0");
        final name = titleElement.text.trim();
        if (appid != 0) {
          searchResults.add(SteamGameNameInfo(name, appid));
          counter++;
        }
        if (counter == limit) {
          break;
        }
      }
    }
  }

  return searchResults;
}

Future<String?> downloadImageFromSteamDB(int appId) async {
  // Check if there isn't already an image
  final String appDataDir = (await getApplicationSupportDirectory()).path;
  final File file = File('$appDataDir\\game_headers\\$appId.jpg');

  if (!file.existsSync()) {
    // Try to get the image from steam database, default header if not existent
    Response response = await get(
        Uri.parse('https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/library_hero.jpg'));
    if (response.statusCode == 200) {
      // Save the image
      file.writeAsBytesSync(response.bodyBytes);
    } else {
      return null;
    }
  }
  return file.path;
}

Future<dynamic> fetchDataFromSteam(int appid) async {
  final dynamic cachedData = await getCachedSteamData(appid);

  if (cachedData == null) {
    final String url = 'https://store.steampowered.com/api/appdetails?appids=$appid';
    try {
      final Response response = await get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic appData = jsonDecode(response.body)[appid.toString()];
        if (appData['success']) {
          if (appid == 2825880) {
            print("appData: $appData");
          }
          await cacheSteamData(appid, appData);
          return appData;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  } else {
    return cachedData;
  }
}

/// Returns {appid: -discountPercent} (0 when no sale / unavailable).
Future<Map<int, int>> multiFetchSaleFromSteam(
  List<int> appidList, {
  int batchSize = 100,
  int maxRetries = 3,
  Duration delayBetweenBatches = const Duration(seconds: 1),
}) async {
  final Map<int, int> saleList = {};

  for (int i = 0; i < appidList.length; i += batchSize) {
    final batch = appidList.sublist(
      i,
      i + batchSize > appidList.length ? appidList.length : i + batchSize,
    );

    final Map<String, dynamic>? json = await _fetchBatch(batch, maxRetries);

    for (final appid in batch) {
      saleList[appid] = _parseDiscount(json?[appid.toString()]);
    }

    if (i + batchSize < appidList.length) {
      await Future.delayed(delayBetweenBatches);
    }
  }

  return saleList;
}

Future<Map<String, dynamic>?> _fetchBatch(
  List<int> batch,
  int maxRetries,
) async {
  final url = Uri.parse(
    'https://store.steampowered.com/api/appdetails'
    '?appids=${batch.join(",")}&filters=price_overview',
  );

  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      final Response response = await get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Throttled requests can return 200 with a literal `null` body.
        if (decoded is Map<String, dynamic>) return decoded;
      } else if (response.statusCode != 429 && response.statusCode != 400) {
        break; // not worth retrying
      }
    } catch (e) {
      print('Batch fetch error: $e');
    }

    // Exponential backoff: 2s, 4s, 8s...
    await Future.delayed(Duration(seconds: 2 << attempt));
  }

  print('Batch failed after $maxRetries attempts (${batch.length} appids)');
  return null;
}

int _parseDiscount(dynamic appData) {
  if (appData is! Map || appData['success'] != true) return 0;

  final data = appData['data'];
  // Free / unpriced apps return an empty list instead of a map.
  if (data is! Map) return 0;

  final discount = data['price_overview']?['discount_percent'];
  return discount is int ? -discount : 0;
}

Future<DateTime?> fetchReleaseDateFromSteamDB(int appid) async {
  final dynamic appData = await fetchDataFromSteam(appid);

  if (appData == null) {
    return null;
  }

  for (dynamic genre in appData['data']['genres']) {
    if (genre["description"] == "Early Access") {
      return DateTime(9999, 12, 31);
    }
  }

  final String releaseDateStr = appData['data']['release_date']['date'];
  try {
    final DateFormat dateFormat = DateFormat("d MMM, yyyy", "en");
    return dateFormat.parse(releaseDateStr);
  } catch (_) {
    try {
      final DateFormat dateFormat = DateFormat("MMM d, yyyy", "en");
      return dateFormat.parse(releaseDateStr);
    } catch (_) {
      try {
        int year = int.parse(releaseDateStr.split(" ").last);
        return DateTime(year, 12, 31);
      } catch (_) {
        return DateTime(9999, 12, 31);
      }
    }
  }
}

Future<int> fetchSaleFromSteamDB(int appid) async {
  final dynamic appData = await fetchDataFromSteam(appid);

  if (appData == null) {
    return 0;
  }

  final List<dynamic> packageGroups = appData['data']['package_groups'];
  if (appid == 2825880) {
    print("packageGroups: $packageGroups");
  }
  if (packageGroups.isEmpty) {
    return 0;
  }

  final dynamic saleStringSubs = packageGroups[0]['subs'];
  for (dynamic sub in saleStringSubs) {
    if (!sub['is_free_license']) {
      final String saleString = sub['percent_savings_text'].trim();
      if (appid == 2825880) {
        print(saleString);
      }
      return saleString.isEmpty ? 0 : int.parse(saleString.split('%')[0]);
    }
  }

  return 0;
}
