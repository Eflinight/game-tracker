import 'package:flutter/material.dart';
import 'package:game_tracker/core/app_id_list_provider.dart';
import 'package:game_tracker/core/game_list_provider.dart';
import 'package:game_tracker/widget/game_list.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(alignment: Alignment.bottomCenter, children: [
          const GameList(),
          Consumer<GameListData>(builder: (context, data, child) {
            return data.loading != 1.0
                ? LinearProgressIndicator(
                    value: data.loading,
                    color: Colors.blue,
                  )
                : const SizedBox
                    .shrink(); // Widget disappears when loading == 1.0
          })
        ]));
  }
}
