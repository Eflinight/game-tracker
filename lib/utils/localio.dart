import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:game_tracker/core/game_data.dart';

String _steamCacheFilename(int appid) {
  final DateTime now = DateTime.now();
  final String date =
      '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
  return '${appid}_$date.json';
}

Future<void> cacheSteamData(int appid, dynamic data) async {
  final String appDataDir = (await getApplicationSupportDirectory()).path;
  final Directory cacheDir = Directory('$appDataDir\\steam_cache');
  if (!cacheDir.existsSync()) {
    cacheDir.createSync(recursive: true);
  }

  // Delete any stale cache files for this appid
  cacheDir
      .listSync()
      .whereType<File>()
      .where((f) => RegExp('^${appid}_').hasMatch(p.basename(f.path)))
      .forEach((f) => f.deleteSync());

  final File file = File('${cacheDir.path}\\${_steamCacheFilename(appid)}');
  file.writeAsStringSync(jsonEncode(data));
}

Future<dynamic> getCachedSteamData(int appid) async {
  final String appDataDir = (await getApplicationSupportDirectory()).path;
  final File file = File('$appDataDir\\steam_cache\\${_steamCacheFilename(appid)}');
  if (file.existsSync()) {
    return jsonDecode(file.readAsStringSync());
  }
  return null;
}

Future<dynamic> getGameListJson() async {
  final String appDataDir = (await getApplicationSupportDirectory()).path;
  final File file = File('$appDataDir\\game_list.json');
  return jsonDecode(file.readAsStringSync());
}

void saveNewGameListJson(dynamic gameList) async {
  File file = File('${(await getApplicationSupportDirectory()).path}\\game_list.json');
  file.writeAsStringSync(jsonEncode(gameList));
}

Future<dynamic> getAppList() async {
  final String appDataDir = (await getApplicationSupportDirectory()).path;
  final File file = File('$appDataDir\\steamapplist.json');
  return jsonDecode(file.readAsStringSync());
}

Future<void> saveAppList(dynamic appList) async {
  final String appDataDir = (await getApplicationSupportDirectory()).path;
  final File file = File('$appDataDir\\steamapplist.json');
  file.writeAsStringSync(jsonEncode(appList));
}

Future<String> getDefaultHeaderPath() async {
  return '${(await getApplicationSupportDirectory()).path}\\game_headers\\default_game_header.jpg';
}

Future<Image?> getGameHeader(int appId) async {
  final String appDataDir = (await getApplicationSupportDirectory()).path;
  final File file = File('$appDataDir\\game_headers\\$appId.jpg');

  if (file.existsSync()) {
    return Image.file(file);
  }
  return null;
}

void cacheCustomImage(String imgPath, int appId) async {
  // Read the file from the given path
  File sourceFile = File(imgPath);

  // Check if a file exists at the target location and delete it if that's the case
  final String appDataDir = (await getApplicationSupportDirectory()).path;
  String targetPath = '$appDataDir\\game_headers\\$appId.jpg';
  File targetFile = File(targetPath);
  if (targetFile.existsSync()) {
    targetFile.deleteSync();
  }

  // Copy the new file in cache
  sourceFile.copy(targetPath);
}

void saveGameData(Game game) async {
  // Search the old game reference in the game list
  dynamic gameList = await getGameListJson();

  // Get the idx in the list of the game to change
  int changeIdx = gameList['games'].indexWhere((jsonGame) => jsonGame['guid'] == game.guid);

  // Update the game
  gameList['games'][changeIdx]['name'] = game.name;
  gameList['games'][changeIdx]['hype'] = game.hype;
  gameList['games'][changeIdx]['appid'] = game.appId;
  gameList['games'][changeIdx]['release'] = game.releaseDate.toString();
  gameList['games'][changeIdx]['playing'] = game.playing;

  // Save the new json
  saveNewGameListJson(gameList);
}

void addNewGameData(Game game) async {
  // Get the the game list
  dynamic gameList = await getGameListJson();

  // Add the new game to the json list
  gameList['games'].add({
    'guid': game.guid,
    'name': game.name,
    'hype': game.hype,
    'appid': game.appId,
    'release': game.releaseDate.toString(),
    'playing': game.playing
  });

  // Save the new json
  saveNewGameListJson(gameList);
}

void removeGameData(int gameGuid) async {
  // Get the the game list
  dynamic gameList = await getGameListJson();

  // Remove the game
  gameList['games'].removeWhere((game) => game['guid'] == gameGuid);

  // Save the new json
  saveNewGameListJson(gameList);
}

Future<int> getNewGuid() async {
  // Get the the game list
  dynamic gameList = await getGameListJson();

  ++gameList['guididx'];

  // Save the new json
  saveNewGameListJson(gameList);

  return gameList['guididx'];
}
