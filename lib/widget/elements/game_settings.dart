import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:game_tracker/core/game_data.dart';
import 'package:game_tracker/core/game_list_provider.dart';
import 'package:game_tracker/utils/localio.dart';
import 'package:game_tracker/widget/atoms/game_control_buttons.dart';
import 'package:game_tracker/widget/atoms/star_rating.dart';
import 'package:provider/provider.dart';

class GameSettingsPane extends StatelessWidget {
  final Game game;
  final Game _tempChangeGame;
  final Function() transitionCallback; // Callback to be called when settings view is exited
  
  const GameSettingsPane({super.key, required this.game, required this.transitionCallback}) : 
    _tempChangeGame = game;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: game.releaseDate,  // Default date to show
      firstDate: DateTime(1980),    // Earliest date that can be selected
      lastDate: DateTime(2100),     // Latest date that can be selected
    );

    if (picked != null && picked != game.releaseDate) {
      _tempChangeGame.releaseDate = picked;
    }
  }

  void filePickerButton() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select a new image',
      initialDirectory: 'C:/',
      type: FileType.image
    );
    if (result != null) {
      cacheCustomImage(result.files.single.path!, game.appId);
    }
  }
  
  Widget buildSettingsMain(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 500.0, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              minLines: 1,
              maxLines: 2,
              initialValue: game.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32
              ),
              textAlign: TextAlign.center,
              onChanged: (value) {
                _tempChangeGame.name = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              }
            ),
            SizedBox.fromSize(size: const Size(0.0, 30.0)),
            StarRatingFormField(
              initialValue: _tempChangeGame.hype,
              onChanged: (value) {
                _tempChangeGame.hype = value;
              },
              validator: (value) {
                if (value == null || value == 0) {
                  return "Please select a rating";
                }
                return null;
              },
            ),
            SizedBox.fromSize(size: const Size(0.0, 20.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GameControlButton(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_month),
                ),
                if ( game.guid != 0 )
                  ...[
                    SizedBox.fromSize(size: const Size(30.0, 0.0)),
                    GameControlButton(
                      onPressed: filePickerButton,
                      icon: const Icon(Icons.image),
                    )
                  ]
              ]
            )
          ]
        )
      )
    );
  }

  Widget buildSettingsControl(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GameControlButton(
            onPressed: transitionCallback,
            icon: const Icon(Icons.cancel),
          ),
          SizedBox.fromSize(size: const Size(10.0, 0.0)),
          GameControlButton(
            onPressed: () async {
              await Provider.of<GameListData>(context, listen: false).update(_tempChangeGame);
              transitionCallback();
            },
            icon: const Icon(Icons.check_circle),
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        buildSettingsMain(context),
        buildSettingsControl(context)
      ]
    );
  }
}