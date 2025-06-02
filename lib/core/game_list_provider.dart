import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:game_tracker/core/game_data.dart';
import 'package:game_tracker/utils/localio.dart';
import 'package:game_tracker/utils/network.dart';

class GameListData extends ChangeNotifier {
  final List<Game> _games = []; // Game list
  double _loadingPercent = 0.0; // Loading percentage

  UnmodifiableListView<Game> get games => UnmodifiableListView(_games);
  double get loading => _loadingPercent;

  GameListData.fromJson() {
    load();
  }

  Future<void> add(Game game) async {
    game.guid = await getNewGuid();
    _games.add(game);
    addNewGameData(game);
    notifyListeners();
  }

  void remove(int guid) {
    _games.removeWhere((game) => game.guid == guid);
    removeGameData(guid);
    notifyListeners();
  }

  void removeAll() {
    _games.clear();
    notifyListeners();
  }

  Future<void> update(Game game) async {
    await game.refresh();
    _games[_games.indexWhere((g) => g.guid == game.guid)] = game;
    saveGameData(game);
    notifyListeners();
  }

  void sort() {
    _games.sort((Game g1, Game g2) {
      int g1Score = g1.hype * 25 - g1.sale;
      int g2Score = g2.hype * 25 - g2.sale;
      if (g1.playing && !g2.playing) return -1;
      if (!g1.playing && g2.playing) return 1;
      if (g1Score > g2Score) return -1;
      if (g1Score < g2Score) return 1;
      if (g1.releaseDate.compareTo(g2.releaseDate) != 0)
        return g1.releaseDate.compareTo(g2.releaseDate);
      return g1.name.compareTo(g2.name);
    });
    notifyListeners();
  }

  Future<void> save() async {
    // Get the old json
    dynamic gameListData = await getGameListJson();

    // Replace all game data, add new one if necessary
    for (Game game in _games) {
      // Get the idx in the list of the game to change
      int changeIdx = gameListData['games']
          .indexWhere((jsonGame) => jsonGame['guid'] == game.guid);

      // Update the game if found
      if (changeIdx != -1) {
        gameListData['games'][changeIdx]['name'] = game.name;
        gameListData['games'][changeIdx]['hype'] = game.hype;
        gameListData['games'][changeIdx]['appid'] = game.appId;
        gameListData['games'][changeIdx]['release'] =
            game.releaseDate.toString();
        gameListData['games'][changeIdx]['playing'] = game.playing;
      }
      // Add the new game if it's new
      else {
        gameListData['games'].add({
          'guid': game.guid,
          'name': game.name,
          'hype': game.hype,
          'appid': game.appId,
          'release': game.releaseDate.toString(),
          'playing': game.playing
        });
      }
    }

    // Save the new game list
    saveNewGameListJson(gameListData);
  }

  Future<void> load() async {
    bool gameDataChanged = false;
    dynamic gameListData = await getGameListJson();
    int index = 0;

    for (Map<String, dynamic> game in gameListData['games']) {
      index++;
      Game newGame = Game();

      // Game GUID
      if (game['guid'] == null || game['guid'] == 0) {
        game['guid'] = gameListData['guididx'];
        gameListData['guididx']++;
      }
      newGame.guid = game['guid'];

      // Game name
      newGame.name = game['name'];

      // Game app ID
      newGame.appId = game['appid'];

      // Game release data
      if (game['release'] == null || game['release'] == '') {
        DateTime tempNewRelaseDate =
            await fetchReleaseDateFromSteamDB(newGame.appId) ?? DateTime.now();
        game['release'] = tempNewRelaseDate.toString();
        gameDataChanged = true;
      }
      newGame.releaseDate = DateTime.parse(game['release']);

      // Game hype
      if (game['hype'] == null || game['hype'] == 0) {
        game['hype'] = 1;
        gameDataChanged = true;
      }
      newGame.hype = game['hype'];

      // Game playing
      if (game['playing'] == null) {
        game['playing'] = false;
        gameDataChanged = true;
      }
      newGame.playing = game['playing'];

      // Game sale
      newGame.sale = await fetchSaleFromSteamDB(newGame.appId);

      // Game header
      newGame.loadHeader();

      gameDataChanged = true;
      game['imgPath'] = null;

      // Refresh the game just in case
      await newGame.refresh();

      _games.add(newGame);
      sort();

      // Update the loading percentage
      _loadingPercent = index / gameListData['games'].length;

      notifyListeners();
    }

    if (gameDataChanged) {
      saveNewGameListJson(gameListData);
    }
  }
}
