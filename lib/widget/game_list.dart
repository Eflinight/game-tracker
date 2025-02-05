import 'package:flutter/material.dart';
import 'package:game_tracker/data/game_data.dart';
import 'package:game_tracker/utils/localio.dart';
import 'package:game_tracker/widget/game_desc.dart';

class GameList extends StatefulWidget {
  final List<Game> games;
  final String title;
  const GameList({super.key, required this.games, required this.title});

  @override
  State<GameList> createState() => _GameListState();
}

class _GameListState extends State<GameList> {
  final ScrollController _scrollController = ScrollController();
  int _focusedIndex = 0;
  String filter = "";
  List<Game> filteredGames = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    filter = "";
    filteredGames = filterGameList(widget.games, filter);
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
    if (newIndex != _focusedIndex && newIndex >= 0 && newIndex < widget.games.length) {
      setState(() {
        _focusedIndex = newIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top : 8.0, left : 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SearchBar(
                onChanged: (String newFilter) {
                  setState(() {
                    filter = newFilter;
                    filteredGames = filterGameList(widget.games, filter);
                  });
                },
                backgroundColor: MaterialStatePropertyAll<Color>(Colors.blueGrey.shade900),
                surfaceTintColor: const MaterialStatePropertyAll<Color>(Colors.transparent),
                overlayColor: const MaterialStatePropertyAll<Color>(Colors.transparent),
                textStyle: const MaterialStatePropertyAll<TextStyle>(TextStyle(
                  color: Colors.white,
                  fontSize: 25.0
                )),
              ),
              SizedBox.fromSize(size: const Size(20.0, 0.0)),
              IconButton(
                icon: const Icon( Icons.sort ),
                color: Colors.white,
                style: const ButtonStyle(
                  iconSize: MaterialStatePropertyAll<double>(40.0),
                  
                ),
                onPressed: () => setState(() {
                  filteredGames = orderGameList(filteredGames);
                }),
                tooltip: "Sort",
              ),
              SizedBox.fromSize(size: const Size(20.0, 0.0)),
              IconButton(
                icon: const Icon( Icons.add ),
                color: Colors.white,
                style: const ButtonStyle(
                  iconSize: MaterialStatePropertyAll<double>(40.0),
                  
                ),
                onPressed: () => setState(() {
                  Game game = Game();
                  game.loadHeader();
                  widget.games.insert(_focusedIndex, game);
                  addNewGameData(game);
                  filteredGames = filterGameList(widget.games, filter);
                }),
                tooltip: "Add Game",
              )
            ]
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: filteredGames.length,
            itemBuilder: (context, index) {
              Game game = filteredGames[index];
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  GameDesc(
                    key: ValueKey(game.releaseDate.millisecondsSinceEpoch),
                    game: game
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () => setState(() {
                        Game removedGame = widget.games.removeAt(index);
                        removeGameData(removedGame.guid);
                        filteredGames.removeAt(index);
                        filteredGames = filterGameList(filteredGames, filter);
                      }),
                      icon: const Icon(Icons.delete_forever),
                      style: const ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
                        shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
                        elevation: MaterialStatePropertyAll<double>(7.0)
                      ),
                      tooltip: "Delete",
                    ),
                  )
                ]
              );
            },
          ),
        ),
      ],
    );
  }
} 
