import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:game_tracker/data/game_data.dart';
import 'package:game_tracker/utils/localio.dart';
import 'package:game_tracker/utils/network.dart';

class GameList extends ChangeNotifier {
  List<Game> _buffer = []; // A strictly internal copy of the game list 
  List<Game> _games = [];

  UnmodifiableListView<Game> get games => UnmodifiableListView(_games);
  
  GameList.fromJson() {
    load();
  }

  void buffer() {
    _buffer = _games;
  }

  void restore() {
    _games = _buffer;
    notifyListeners();
  }


  void add(Game game) {
    _games.add(game);
    notifyListeners();
  }

  void remove(int guid) {
    _games.removeWhere((game) => game.guid == guid);
    notifyListeners();
  }

  void removeAll() {
    _games.clear();
    notifyListeners();
  }

  void sort() {
    _games.sort((Game g1, Game g2) {
      if ( g1.playing && !g2.playing ) return -1;
      if ( !g1.playing && g2.playing ) return 1;
      if ( g1.hype > g2.hype ) return -1;
      if ( g1.hype < g2.hype ) return 1;
      if ( g1.releaseDate.compareTo(g2.releaseDate) != 0 ) return g1.releaseDate.compareTo(g2.releaseDate);
      return g1.name.compareTo(g2.name);
    });
    notifyListeners();
  }

  void filter(String filter) {
    _games.retainWhere((game) => game.name.toLowerCase().contains(filter.toLowerCase()));
    notifyListeners();
  }

  Future<void> save() async {
    // Get the old json
    dynamic    gameListData = await getGameListJson();

    // Replace all game data, add new one if necessary
    for ( Game game in _games ) {
      // Get the idx in the list of the game to change 
      int changeIdx = gameListData['games'].indexWhere((jsonGame) => jsonGame['guid'] == game.guid);

      // Update the game if found
      if ( changeIdx != -1 ) {
        gameListData['games'][changeIdx]['name']    = game.name;
        gameListData['games'][changeIdx]['hype']    = game.hype;
        gameListData['games'][changeIdx]['appid']   = game.appId;
        gameListData['games'][changeIdx]['release'] = game.releaseDate.toString();
        gameListData['games'][changeIdx]['playing'] = game.playing;
      }
      // Add the new game if it's new
      else {
        gameListData['games'].add({
          'guid'    : game.guid,
          'name'    : game.name,
          'hype'    : game.hype,
          'appid'   : game.appId,
          'release' : game.releaseDate.toString(),
          'playing' : game.playing
        });
      }
    }

    // Save the new game list
    saveNewGameListJson(gameListData);
  }

  Future<void> load() async {
    bool       gameDataChanged = false;
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
      
      _games.add(newGame);
    }

    if ( gameDataChanged ) {
      saveNewGameListJson(gameListData);
    }

    // Copy in buffer from the beginning
    _buffer = _games;

    notifyListeners();
  }
}
