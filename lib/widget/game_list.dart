import 'dart:async';
import 'package:flutter/material.dart';
import 'package:game_tracker/core/app_id_list_provider.dart';
import 'package:game_tracker/core/game_data.dart';
import 'package:game_tracker/core/game_list_provider.dart';
import 'package:game_tracker/utils/localio.dart';
import 'package:game_tracker/widget/modules/game_add.dart';
import 'package:game_tracker/widget/modules/game_desc.dart';
import 'package:provider/provider.dart';

class GameList extends StatefulWidget {
  const GameList({super.key});

  @override
  State<GameList> createState() => _GameListState();
}

class _GameListState extends State<GameList> {
  final ScrollController _scrollController = ScrollController();
  int _focusedIndex = 0;
  String filter = "";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    filter = "";
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Function to handle scroll changes
  void _onScroll() {
    // The height of each item (adjust if your item size changes)
    double itemHeight =
        MediaQuery.of(context).size.height * 0.5; // Example item height
    // Calculate the current focused index based on the scroll offset
    int newIndex = (_scrollController.offset / itemHeight).round();
    if (newIndex != _focusedIndex &&
        newIndex >= 0 &&
        newIndex <
            Provider.of<GameListData>(context, listen: false).games.length) {
      setState(() {
        _focusedIndex = newIndex;
      });
    }
  }

  Widget createSearchBar() {
    return SearchBar(
      onChanged: (String newFilter) {
        setState(() => filter = newFilter);
        _debounce?.cancel();
        _debounce = Timer(
            const Duration(milliseconds: 500),
            () => Provider.of<AppIDListData>(context, listen: false)
                .startSearch(newFilter, 5));
      },
      backgroundColor:
          MaterialStatePropertyAll<Color>(Colors.blueGrey.shade900),
      surfaceTintColor:
          const MaterialStatePropertyAll<Color>(Colors.transparent),
      overlayColor: const MaterialStatePropertyAll<Color>(Colors.transparent),
      textStyle: const MaterialStatePropertyAll<TextStyle>(
          TextStyle(color: Colors.white, fontSize: 25.0)),
    );
  }

  Widget createSortButton() {
    return IconButton(
      icon: const Icon(Icons.sort),
      color: Colors.white,
      style: const ButtonStyle(
        iconSize: MaterialStatePropertyAll<double>(40.0),
      ),
      onPressed: () => Provider.of<GameListData>(context, listen: false).sort(),
      tooltip: "Sort",
    );
  }

  Widget createAddButton() {
    return IconButton(
      icon: const Icon(Icons.add),
      color: Colors.white,
      style: const ButtonStyle(
        iconSize: MaterialStatePropertyAll<double>(40.0),
      ),
      onPressed: () {
        Game game = Game();
        game.loadHeader();
        Provider.of<GameListData>(context, listen: false).add(game);
        addNewGameData(game);
      },
      tooltip: "Add Game",
    );
  }

  Widget createBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 20.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        createSearchBar(),
        SizedBox.fromSize(size: const Size(20.0, 0.0)),
        createSortButton(),
        SizedBox.fromSize(size: const Size(20.0, 0.0)),
        createAddButton()
      ]),
    );
  }

  Widget createGameListView() {
    return Consumer2<GameListData, AppIDListData>(
        builder: (context, glData, alData, child) {
      List<Game> filteredGames = List<Game>.from(glData.games);
      filteredGames.retainWhere(
          (game) => game.name.toLowerCase().contains(filter.toLowerCase()));
      List<SteamGameNameInfo> steamSearchResults = alData.results;
      int extraIdxs = steamSearchResults.length;
      if (alData.searching) {
        extraIdxs = 1;
      }

      return ListView.builder(
          controller: _scrollController,
          itemCount: filteredGames.length +
              extraIdxs +
              (filteredGames.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < filteredGames.length) {
              return GameDesc(game: filteredGames[index]);
            } else if (filteredGames.isNotEmpty &&
                index == filteredGames.length) {
              return const Divider();
            } else if (alData.searching) {
              return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Colors.blue[800]),
                    )
                  ]);
            } else {
              return GameAdd(
                potentialGameSteamData:
                    alData.results[(index - 1 - filteredGames.length)],
              );
            }
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      createBar(),
      const Divider(),
      Expanded(child: createGameListView())
    ]);
  }
}
