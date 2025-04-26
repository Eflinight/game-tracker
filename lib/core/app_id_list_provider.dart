import 'dart:collection';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

// This function must be a top-level function for compute()
List<SteamGameNameInfo> _performSearch(Map<String, dynamic> args) {
  String query = args['query'];
  int limit = args['limit'];
  List<SteamGameNameInfo> choices = args['choices'];

  return extractTop(
    query: query,
    choices: choices,
    limit: limit,
    getter: (steamGame) => steamGame.name,
  ).map((result) => result.choice).toList();
}

class SteamGameNameInfo {
  String name;
  int appid;
  SteamGameNameInfo(this.name, this.appid);
}

class AppIDListData extends ChangeNotifier {
  final List<SteamGameNameInfo> _appids = [];
  List<SteamGameNameInfo> _results = []; 
  CancelableOperation<void>? _currentSearch;
  bool _loaded = false;
  int _searchCounter = 0;
 
  UnmodifiableListView<SteamGameNameInfo> get appids  => UnmodifiableListView(_appids);
  UnmodifiableListView<SteamGameNameInfo> get results  => UnmodifiableListView(_results);

  AppIDListData.fromJson() {
    load();
  }

  Future<void> load() async {
    // Read the appid list 
    final String  appDataDir  = (await getApplicationSupportDirectory()).path;
    final String  currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final File    file        = File('$appDataDir\\steamapplist-$currentDate.json');
    final dynamic jsonData    = jsonDecode(file.readAsStringSync());

    // Parse the appid list and compare with the game list
    for ( Map<String, dynamic> app in jsonData['applist']['apps'] ) {
      final String name = app["name"];
      if (name != "") {
        _appids.add(SteamGameNameInfo(name, app["appid"]));
      }
    }

    _loaded = true;
  }

  void startSearch(String query, int limit) {
    _currentSearch?.cancel();

    if (_loaded) {
      _results.clear();
      _searchCounter++;
      _currentSearch = CancelableOperation.fromFuture(_searchN(query, limit, _searchCounter));
    }
  }

  Future<void> _searchN(String query, int limit, int searchId) async {
    try {
      final results = await compute(_performSearch, {
        'query': query,
        'limit': limit,
        'choices': _appids,
      });

      if (_searchCounter == searchId) {
        _results = results;
      }
    } catch (e, stacktrace) {
      print("Search failed or cancelled: $e");
      print(stacktrace);
      // Optional: handle or ignore specific known issues here
    } finally {
      if (_searchCounter == searchId) {
        notifyListeners();
      }
    }
  }
}
