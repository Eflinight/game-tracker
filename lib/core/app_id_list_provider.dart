import 'dart:collection';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import 'package:game_tracker/utils/network.dart';

// This function must be a top-level function for compute()
Future<List<SteamGameNameInfo>> _performSearch(Map<String, dynamic> args) {
  String query = args['query'];
  int limit = args['limit'];

  return searchSteam(query, limit);
}

class SteamGameNameInfo {
  String name;
  int appid;
  SteamGameNameInfo(this.name, this.appid);
}

class AppIDListData extends ChangeNotifier {
  List<SteamGameNameInfo> _results = [];
  CancelableOperation<void>? _currentSearch;
  int _searchCounter = 0;
  bool _searching = false;

  UnmodifiableListView<SteamGameNameInfo> get results =>
      UnmodifiableListView(_results);
  bool get searching => _searching;

  void startSearch(String query, int limit) {
    _currentSearch?.cancel();

    _searching = false;
    _results.clear();
    if (query.isNotEmpty) {
      _searching = true;
      _searchCounter++;
      _currentSearch = CancelableOperation.fromFuture(
          _searchN(query, limit, _searchCounter));
    }
    notifyListeners();
  }

  Future<void> _searchN(String query, int limit, int searchId) async {
    try {
      final results = await compute(_performSearch, {
        'query': query,
        'limit': limit,
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
        _searching = false;
        notifyListeners();
      }
    }
  }
}
