import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:game_tracker/data/game_data.dart';

Future<dynamic> getGameListJson() async {
  final String appDataDir  = (await getApplicationSupportDirectory()).path;
  final File   file        = File('$appDataDir\\game_list.json');
  return jsonDecode(file.readAsStringSync());
}

void saveNewGameListJson(dynamic gameList) async {
  File file = File('${(await getApplicationSupportDirectory()).path}\\game_list.json');
  file.writeAsStringSync(jsonEncode(gameList));
}

Future<int?> getGameAppIDFromSteamDB(String gameName) async {

  // Read the appid list 
  final String  appDataDir  = (await getApplicationSupportDirectory()).path;
  final String  currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final File    file        = File('$appDataDir\\steamapplist-$currentDate.json');
  final dynamic jsonData    = jsonDecode(file.readAsStringSync());

  // Parse the appid list and compare with the game list
  for ( Map<String, dynamic> app in jsonData['applist']['apps'] ) {
    String name = app["name"];
    if (name.toLowerCase() == gameName.toLowerCase()) {
      return app["appid"];
    }
  }

  return null;
}

Future<String> getDefaultHeaderPath() async {
  return '${(await getApplicationSupportDirectory()).path}\\game_headers\\default_game_header.jpg';
}

Future<Image?> getGameHeader(int appId) async {
  final String appDataDir  = (await getApplicationSupportDirectory()).path;
  final File   file         = File('$appDataDir\\game_headers\\$appId.jpg');

  if(file.existsSync()) {
    return Image.file(file);
  }
  return null;
}

void cacheCustomImage(String imgPath, int appId) async {
  // Read the file from the given path
  File sourceFile = File(imgPath);

  // Check if a file exists at the target location and delete it if that's the case
  final String appDataDir  = (await getApplicationSupportDirectory()).path;
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
  gameList['games'][changeIdx]['name']    = game.name;
  gameList['games'][changeIdx]['hype']    = game.hype;
  gameList['games'][changeIdx]['appid']   = game.appId;
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
    'guid'    : game.guid,
    'name'    : game.name,
    'hype'    : game.hype,
    'appid'   : game.appId,
    'release' : game.releaseDate.toString(),
    'playing' : game.playing
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