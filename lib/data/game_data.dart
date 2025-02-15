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
      saveNewGameListJson(gameListData);
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
