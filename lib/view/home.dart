import 'package:flutter/material.dart';
import 'package:game_tracker/core/game_list_provider.dart';
import 'package:game_tracker/widget/game_list.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Only poll Steam while the window is actually being looked at.
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        final bool paused = state != AppLifecycleState.resumed;
        Provider.of<GameListData>(context, listen: false).setAchievementPollingPaused(paused);
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

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
                : const SizedBox.shrink(); // Widget disappears when loading == 1.0
          })
        ]));
  }
}
