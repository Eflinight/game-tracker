import 'package:http/http.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

Future<void> updateGameList() async {
  // Check if an update if necessary
  final String appDataDir  = (await getApplicationSupportDirectory()).path;
  final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final File file          = File('$appDataDir\\steamapplist-$currentDate.json');
  
  if(!file.existsSync()) {
    // Delete the previous files
    final Directory dir = Directory(appDataDir);
    final RegExp pattern = RegExp(r'^steamapplist.*\.json$');
    final List<FileSystemEntity> files = await dir
      .list()
      .where((file) => file is File && pattern.hasMatch(file.uri.pathSegments.last))
      .toList();
    for (FileSystemEntity fileToRemove in files) {
      if (fileToRemove.path != file.path) {
        fileToRemove.delete();
      }
    }

    // Get the list of all app IDs
    final Response response = await get(
      Uri.parse('https://api.steampowered.com/ISteamApps/GetAppList/v0002/'),
    );

    // Save the list in cache
    file.writeAsBytesSync(response.bodyBytes);
  }
}

Future<String?> downloadImageFromSteamDB(int appId) async {
  // Check if there isn't already an image
  final String appDataDir  = (await getApplicationSupportDirectory()).path;
  final File file          = File('$appDataDir\\game_headers\\$appId.jpg');

  if (!file.existsSync())
  {
    // Try to get the image from steam database, default header if not existent
    Response response = await get(
      Uri.parse('https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/library_hero.jpg')
    );
    if ( response.statusCode == 200 ) {
      // Save the image
      file.writeAsBytesSync(response.bodyBytes);
    }
    else {
      return null;
    }
  }
  return file.path;
}

Future<DateTime?> fetchReleaseDateFromSteamDB(int appid) async {
  final String url = 'https://store.steampowered.com/api/appdetails?appids=$appid';

  try {
    final Response response = await get(Uri.parse(url));

    if (response.statusCode == 200) {
      final dynamic appData = jsonDecode(response.body)[appid.toString()];

      if (appData['success']) {
        final String releaseDateStr = appData['data']['release_date']['date'];
        try {
          final DateFormat dateFormat = DateFormat("d MMM, yyyy", "en");
          return dateFormat.parse(releaseDateStr);
        } 
        catch (e) {
          try {
            final DateFormat dateFormat = DateFormat("MMM d, yyyy", "en");
            return dateFormat.parse(releaseDateStr);
          } 
          catch (e) {
            return null;
          }
        }
      } 
      else {
        return null;
      }
    } 
    else {
      return null;
    }
  } 
  catch (e) {
    return null;
  }
}

Future<int> fetchSaleFromSteamDB(int appid) async {
  final String url = 'https://store.steampowered.com/api/appdetails?appids=$appid';

  try {
    final Response response = await get(Uri.parse(url));


    if (response.statusCode == 200) {
      final dynamic appData = jsonDecode(response.body)[appid.toString()];

      if (appData['success']) {
        final dynamic saleStringSubs = appData['data']['package_groups'][0]['subs'];
        for (dynamic sub in saleStringSubs) {
          print(sub['is_free_license']);
          if (!sub['is_free_license']) {
            final String saleString = sub['percent_savings_text'].trim();
            return saleString.isEmpty ? 0 : int.parse(saleString.split('%')[0]);
          }
        }
        return 0;
      } 
      else {
        return 0;
      }
    } 
    else {
      return 0;
    }
  } 
  catch (e) {
    return 0;
  }
}