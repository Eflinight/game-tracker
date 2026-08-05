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

Future<Map<int, int>> multiFetchSaleFromSteam(List<int> appidList) async {
  Map<int, int> saleList = {};

  final String url =
      'https://store.steampowered.com/api/appdetails?appids=${appidList.join(",")}&filters=price_overview';
  try {
    final Response response = await get(Uri.parse(url));
    if (response.statusCode == 200) {
      for (int appid in appidList) {
        final dynamic appData = jsonDecode(response.body)[appid.toString()];
        if (appData['success']) {
          if (appData['data'] is List) {
            saleList[appid] = 0;
            continue;
          }

          saleList[appid] = -appData['data']['price_overview']['discount_percent'];
        } else {
          saleList[appid] = 0;
        }
      }
    }
  } catch (e) {
    print(e);
  }

  return saleList;
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

  if (packageGroups.isEmpty) {
    return 0;
  }

  final dynamic saleStringSubs = packageGroups[0]['subs'];
  for (dynamic sub in saleStringSubs) {
    if (!sub['is_free_license']) {
      final String saleString = sub['percent_savings_text'].trim();
      return saleString.isEmpty ? 0 : int.parse(saleString.split('%')[0]);
    }
  }

  return 0;
}
