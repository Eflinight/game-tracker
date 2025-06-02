import 'package:flutter/material.dart';
import 'package:game_tracker/core/app_id_list_provider.dart';
import 'package:game_tracker/core/game_data.dart';
import 'package:game_tracker/core/game_list_provider.dart';
import 'package:game_tracker/utils/network.dart';
import 'package:game_tracker/widget/atoms/game_control_buttons.dart';
import 'package:game_tracker/widget/atoms/star_rating.dart';
import 'package:provider/provider.dart';

class GameAdd extends StatelessWidget {
  final SteamGameNameInfo potentialGameSteamData;
  final Game potentialGame;

  GameAdd({super.key, required this.potentialGameSteamData})
      : potentialGame = Game.withData(
          null,
          potentialGameSteamData.name,
          potentialGameSteamData.appid,
          null,
          5,
          null,
          null,
        );

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
          height: MediaQuery.of(context).size.height * 0.1,
          width: double.infinity,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Colors.black, Color.fromARGB(255, 9, 46, 77)]),
              border: Border.all(width: 0.2, color: Colors.white),
              borderRadius: const BorderRadius.all(Radius.circular(10.0))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(potentialGame.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontStyle: FontStyle.italic)),
              ),
              Expanded(child: Container()),
              StarRatingFormField(
                initialValue: potentialGame.hype,
                onChanged: (value) {
                  potentialGame.hype = value;
                },
                validator: (value) {
                  if (value == null || value == 0) {
                    return "Please select a rating";
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GameControlButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    await downloadImageFromSteamDB(potentialGame.appId);
                    await potentialGame.refresh();
                    await Provider.of<GameListData>(context, listen: false)
                        .add(potentialGame);
                  },
                  tooltip: "Add Game",
                ),
              )
            ],
          ))
    ]);
  }
}
