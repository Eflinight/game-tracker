import 'package:flutter/material.dart';
import 'package:game_tracker/data/game_data.dart';
import 'package:game_tracker/data/game_list_provider.dart';
import 'package:game_tracker/widget/game_list.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Game> games = provider<List<Game>>();

  @override
  Widget build(BuildContext context) {
    GameList toPlayList = GameList(games: games, title: "NEXT GAME TO PLAY");
    return Scaffold(
      backgroundColor: Colors.black,
      body: toPlayList,
    );
  }
} 
