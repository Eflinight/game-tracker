import 'package:flutter/material.dart';
import 'package:game_tracker/core/game_data.dart';
import 'package:game_tracker/core/game_list_provider.dart';
import 'package:game_tracker/utils/localio.dart';
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
    double itemHeight = MediaQuery.of(context).size.height * 0.5; // Example item height
    // Calculate the current focused index based on the scroll offset
    int newIndex = (_scrollController.offset / itemHeight).round();
    if ( newIndex != _focusedIndex 
      && newIndex >= 0 
      && newIndex < Provider.of<GameListData>(context, listen: false).games.length
    ) {
      setState(() {
        _focusedIndex = newIndex;
      });
    }
  }

  Widget createSearchBar() {
    return SearchBar(
      onChanged: (String newFilter) => setState(() => filter = newFilter),
      backgroundColor: MaterialStatePropertyAll<Color>(Colors.blueGrey.shade900),
      surfaceTintColor: const MaterialStatePropertyAll<Color>(Colors.transparent),
      overlayColor: const MaterialStatePropertyAll<Color>(Colors.transparent),
      textStyle: const MaterialStatePropertyAll<TextStyle>(TextStyle(
        color: Colors.white,
        fontSize: 25.0
      )),
    );
  }

  Widget createSortButton() {
    return IconButton(
      icon: const Icon( Icons.sort ),
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
      icon: const Icon( Icons.add ),
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
      padding: const EdgeInsets.only(top : 8.0, left : 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          createSearchBar(),
          SizedBox.fromSize(size: const Size(20.0, 0.0)),
          createSortButton(),
          SizedBox.fromSize(size: const Size(20.0, 0.0)),
          createAddButton()
        ]
      ),
    );
  }
  
  Widget createGameListView() {
    return Consumer<GameListData>(
      builder: (context, data, child) {
        List<Game> filteredGames = List<Game>.from(data.games);
        filteredGames.retainWhere((game) => game.name.toLowerCase().contains(filter.toLowerCase()));
        return ListView.builder(
          controller: _scrollController,
          itemCount: filteredGames.length,
          itemBuilder: (context, index) {
            Game game = filteredGames[index];
            return GameDesc(game: game);
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        createBar(),
        const Divider(),
        Expanded(
          child: createGameListView()
        )
      ]
    );
  }
} 
