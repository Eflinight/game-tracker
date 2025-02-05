import 'package:game_tracker/utils/localio.dart';
import 'package:flutter/material.dart';
import 'package:game_tracker/utils/network.dart';
import 'dart:io';

class Game {
  int      guid        = 0;
  String   name        = '';
  int      appId       = 0;
  DateTime releaseDate = DateTime.now();
  int      hype        = 1;
  bool     playing     = false; 
  Image?   header; 

  Game() :
    guid        = 0,
    name        = "N/A",
    appId       = 0,
    releaseDate = DateTime.now(),
    hype        = 1,
    playing     = false;

  Game.withData( int? newGuid, String? newName, int? newAppId, DateTime? newReleaseDate, int? newHype, bool? newPlaying, Image? newHeader ) : 
    assert( newHype == null || ( 1 <= newHype && newHype <= 5 ) ),
    guid        = newGuid        ?? 0,
    name        = newName        ?? '',
    appId       = newAppId       ?? 0,
    releaseDate = newReleaseDate ?? DateTime.now(),
    hype        = newHype        ?? 1,
    playing     = newPlaying     ?? false,
    header      = newHeader;

  Game.copy( Game otherGame ) :
    guid        = otherGame.guid,
    name        = otherGame.name,
    releaseDate = otherGame.releaseDate,
    hype        = otherGame.hype,
    appId       = otherGame.appId,
    playing     = otherGame.playing,
    header      = otherGame.header;

  Future<void> loadHeader() async {
    header = await getGameHeader(appId) ?? Image.file(File(await getDefaultHeaderPath()));
  }

  Future<void> refresh() async {
    dynamic gameListData;

    // Update the GUID if needed
    if ( guid == 0 ) {
      gameListData ??= await getGameListJson();
      guid = gameListData['guididx'];
      gameListData['guididx']++;
    }
  
    // Attribute a temporary custom app ID
    if ( appId == 0 ) {
      gameListData ??= await getGameListJson();
      appId = (( 1 << 23 ) + gameListData['appididx']) as int;
      gameListData['appididx']++;
      saveNewGameListJson(gameListData);
    }
    
    // Check steam game list to see if it has a app ID 
    if ( appId >= ( 1 << 23 ) )
    {
      int? newAppId = await getGameAppIDFromSteamDB(name);
      if ( newAppId != null ) {
        appId = newAppId;
        await downloadImageFromSteamDB(appId);
      }
    }
    
    // Refresh the header
    await loadHeader();

    // Refresh the release dat if an online one is available
    releaseDate = await fetchReleaseDateFromSteamDB(appId) ?? releaseDate;
  }
}

Future<List<Game>> parseAllGame() async {
  bool       gameDataChanged = false;
  List<Game> games           = [];
  dynamic    gameListData    = await getGameListJson();

  for ( Map<String, dynamic> game in gameListData['games'] ) {
    Game newGame = Game();

    // Game GUID
    if ( game['guid'] == null || game['guid'] == 0 ) {
      game['guid'] = gameListData['guididx'];
      gameListData['guididx']++;
    }
    newGame.guid = game['guid'];

    // Game name
    newGame.name = game['name'];

    // Game app ID
    if ( game['appid'] == null || game['appid'] == 0 ) {
      int? newAppId = await getGameAppIDFromSteamDB(newGame.name);
      if ( newAppId != null ) {
        game['appid'] = newAppId;
      }
      else {
        game['appid'] = (( 1 << 23 ) + gameListData['appididx']) as int;
        gameListData['appididx']++;
      }
      gameDataChanged = true;
    }
    newGame.appId = game['appid'];

    // Game release data
    if ( game['release'] == null || game['release'] == '' ) {
      DateTime tempNewRelaseDate = await fetchReleaseDateFromSteamDB(newGame.appId) ?? DateTime.now();
      game['release'] = tempNewRelaseDate.toString();
      gameDataChanged = true;
    }
    newGame.releaseDate = DateTime.parse(game['release']);

    // Game hype
    if ( game['hype'] == null || game['hype'] == 0 ) {
      game['hype'] = 1;
      gameDataChanged = true;
    }
    newGame.hype = game['hype'];

    // Game playing
    if ( game['playing'] == null ) {
      game['playing'] = false;
      gameDataChanged = true;
    }
    newGame.playing = game['playing'];

    // Game header
    newGame.loadHeader();

    gameDataChanged = true;
    game['imgPath'] = null;

    // Refresh the game just in case
    await newGame.refresh();
    
    games.add(newGame);
  }

  if ( gameDataChanged ) {
    saveNewGameListJson(gameListData);
  }

  return games;
}

List<Game> orderGameList(List<Game> gameList) {
  List<Game> orderedGameList = List<Game>.from(gameList);

  orderedGameList.sort((Game g1, Game g2) {
    if ( g1.playing && !g2.playing ) return -1;
    if ( !g1.playing && g2.playing ) return 1;
    if ( g1.hype > g2.hype ) return -1;
    if ( g1.hype < g2.hype ) return 1;
    if ( g1.releaseDate.compareTo(g2.releaseDate) != 0 ) return g1.releaseDate.compareTo(g2.releaseDate);
    if ( g1.name.compareTo(g2.name) != 0 ) return g1.name.compareTo(g2.name);
    return 0;
  });

  return orderedGameList;
}

List<Game> filterGameList(List<Game> gameList, String filter) {
  List<Game> filteredGameList = List<Game>.from(gameList);

  filteredGameList.retainWhere((game) {
    return game.name.toLowerCase().contains(filter.toLowerCase());
  });

  return filteredGameList;
}