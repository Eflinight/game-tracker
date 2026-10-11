import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:game_tracker/core/game_data.dart';
import 'package:game_tracker/utils/localio.dart';
import 'package:game_tracker/utils/network.dart';

class GameListData extends ChangeNotifier {
  /// How often the achievement progress of playing games is polled.
  static const Duration achievementPollInterval = Duration(minutes: 1);

  final List<Game> _games = []; // Game list
  double _loadingPercent = 0.0; // Loading percentage
  Timer? _achievementTimer;
  bool _achievementPollRunning = false;
  bool _achievementPollPaused = false;

  UnmodifiableListView<Game> get games => UnmodifiableListView(_games);
  double get loading => _loadingPercent;

  GameListData.fromJson() {
    load();
    _startAchievementPolling();
  }

  @override
  void dispose() {
    _achievementTimer?.cancel();
    super.dispose();
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

  void _startAchievementPolling() {
    _achievementTimer?.cancel();
    _achievementTimer = Timer.periodic(
      achievementPollInterval,
      (_) => refreshAchievements(forceRefresh: true),
    );
  }

  /// Suspends/resumes the periodic poll, so a window left open in the
  /// background doesn't keep hitting the Steam API all day.
  void setAchievementPollingPaused(bool paused) {
    if (_achievementPollPaused == paused) return;
    _achievementPollPaused = paused;

    if (paused) {
      _achievementTimer?.cancel();
      _achievementTimer = null;
    } else {
      // Catch up immediately on the time spent paused, then resume the cycle.
      refreshAchievements(forceRefresh: true);
      _startAchievementPolling();
    }
  }

  /// Reloads the achievement progress of every game currently being played.
  ///
  /// Notifies listeners once, and only when something actually changed, to
  /// avoid rebuilding the list every minute for nothing.
  Future<void> refreshAchievements({bool forceRefresh = false}) async {
    // A slow or retrying pass must not stack up with the next tick.
    if (_achievementPollRunning) return;
    _achievementPollRunning = true;

    try {
      bool changed = false;
      for (Game game in _games.where((game) => game.playing)) {
        if (await game.loadAchievements(forceRefresh: forceRefresh)) {
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    } finally {
      _achievementPollRunning = false;
    }
  }

  void sort() {
    _games.sort((Game g1, Game g2) {
      int g1Score = g1.hype * 25 - g1.sale;
      int g2Score = g2.hype * 25 - g2.sale;
      if (g1.playing && g2.playing) return g1.name.compareTo(g2.name);
      if (g1.releaseDate == null && g2.releaseDate != null) return 1;
      if (g1.releaseDate != null && g2.releaseDate == null) return -1;
      if (g1.releaseDate != null && g2.releaseDate != null) {
        if (g1.releaseDate!.isBefore(DateTime.now()) && g2.releaseDate!.isAfter(DateTime.now()))
          return -1;
        if (g1.releaseDate!.isAfter(DateTime.now()) && g2.releaseDate!.isBefore(DateTime.now()))
          return 1;
        if (g1.playing && !g2.playing) return -1;
        if (!g1.playing && g2.playing) return 1;
        if (g1Score > g2Score) return -1;
        if (g1Score < g2Score) return 1;
        if (g1.releaseDate!.compareTo(g2.releaseDate!) != 0) {
          return g1.releaseDate!.compareTo(g2.releaseDate!);
        }
      }
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
      int changeIdx = gameListData['games'].indexWhere((jsonGame) => jsonGame['guid'] == game.guid);

      // Update the game if found
      if (changeIdx != -1) {
        gameListData['games'][changeIdx]['name'] = game.name;
        gameListData['games'][changeIdx]['hype'] = game.hype;
        gameListData['games'][changeIdx]['appid'] = game.appId;
        gameListData['games'][changeIdx]['release'] = game.releaseDate.toString();
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
    List<int> appidList = [];

    // Get all steam appid
    for (Map<String, dynamic> game in gameListData['games']) {
      if (game['appid'] < (1 << 23)) {
        appidList.add(game['appid']);
      }
    }

    // Get sale values into a map
    final Map<int, int> saleList = await multiFetchSaleFromSteam(appidList);

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
      DateTime? newReleaseDate = DateTime.tryParse(game['release']);
      if (newReleaseDate == null || newReleaseDate.isAfter(DateTime.now())) {
        DateTime? updatedReleaseDate = await fetchReleaseDateFromSteamDB(newGame.appId);
        if (updatedReleaseDate != null && newReleaseDate != updatedReleaseDate) {
          newReleaseDate = updatedReleaseDate;
          game['release'] = newReleaseDate.toString();
          gameDataChanged = true;
        }
      }
      newGame.releaseDate = newReleaseDate;

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

      // Game header
      newGame.loadHeader();

      // Game achievement progress
      newGame.loadAchievements();

      // Game sale
      if (saleList.keys.contains(game["appid"])) {
        newGame.sale = saleList[game["appid"]]!;
      }

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
