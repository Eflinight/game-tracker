import 'package:flutter/material.dart';
import 'package:game_tracker/widget/game_list.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: GameList()
    );
  }
} 
