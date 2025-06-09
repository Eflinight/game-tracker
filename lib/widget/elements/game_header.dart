import 'package:flutter/material.dart';
import 'package:game_tracker/core/game_data.dart';
import 'package:game_tracker/core/game_list_provider.dart';
import 'package:game_tracker/widget/atoms/game_control_buttons.dart';
import 'package:provider/provider.dart';

class GameHeaderPane extends StatelessWidget {
  final Game game;
  final Function() transitionCallback; // Callback to be called when settings view is exited

  const GameHeaderPane({super.key, required this.game, required this.transitionCallback});

  Widget buildHeaderMain(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Padding(
          padding: const EdgeInsets.only(top: 60.0, bottom: 60.0),
          child: Column(
            children: [
              Text(game.releaseDate.toString().split(' ')[0],
                  style: const TextStyle(
                    color: Colors.white70,
                  )),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.1,
                child: Text(
                  game.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              if (!game.playing && game.sale != 0)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  child: Text(
                    "${game.sale.toString()}%",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              Expanded(child: Container()),
              if (game.playing)
                Icon(Icons.videogame_asset, size: 40.0, color: Colors.blue.shade600)
              else
                Row(
                    children: List.generate(
                  game.hype,
                  (index) => Icon(
                    Icons.star,
                    color: Colors.blue.shade600,
                  ),
                ))
            ],
          ),
        ),
        ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.white, // Full opacity on the left side of the image
                  Colors.transparent, // Gradual fade-out on the right side
                ],
                stops: [0.6, 1.0], // Adjust the stops for a smooth fade
              ).createShader(bounds);
            },
            child: game.header),
      ]),
    );
  }

  Widget buildSpecificHeaderButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (game.playing) ...[
            GameControlButton(
              onPressed: () {
                game.playing = false;
                game.hype = 1;
                Provider.of<GameListData>(context, listen: false).update(game);
              },
              icon: const Icon(Icons.workspace_premium),
              tooltip: "To 100%",
            ),
            SizedBox.fromSize(size: const Size(15.0, 0.0))
          ],
          GameControlButton(
            onPressed: () {
              game.playing = !game.playing;
              Provider.of<GameListData>(context, listen: false).update(game);
            },
            icon: Icon(game.playing ? Icons.videogame_asset_off : Icons.videogame_asset),
            tooltip: game.playing ? "Stop Playing" : "Start Playing",
          ),
        ],
      ),
    );
  }

  Widget buildGeneralHeaderButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GameControlButton(
            onPressed: transitionCallback,
            icon: const Icon(Icons.edit),
            tooltip: "Edit",
          ),
          SizedBox.fromSize(size: const Size(15.0, 0.0)),
          GameControlButton(
            onPressed: () => Provider.of<GameListData>(context, listen: false).remove(game.guid),
            icon: const Icon(Icons.delete_forever),
            tooltip: "Delete Game",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      buildHeaderMain(context),
      Align(alignment: Alignment.topRight, child: buildGeneralHeaderButtons(context)),
      Align(alignment: Alignment.bottomRight, child: buildSpecificHeaderButtons(context))
    ]);
  }
}
