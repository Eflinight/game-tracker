import 'package:flutter/material.dart';
import 'package:game_tracker/data/game_data.dart';
import 'package:game_tracker/data/game_list_provider.dart';
import 'package:game_tracker/utils/localio.dart';
import 'package:game_tracker/widget/game_list.dart';
import 'package:game_tracker/widget/star_rating.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

class GameDesc extends StatefulWidget {
  final Game game; // Game data

  const GameDesc({super.key, required this.game});

  @override
  State<GameDesc> createState() => _GameDescState();
}

class _GameDescState extends State<GameDesc> with SingleTickerProviderStateMixin {
  late Game _tempChangeGame;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation; 

  @override
  void initState() {
    super.initState();
    _tempChangeGame = Game.copy(widget.game);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
      
    );

    // Define the slide animation: starts in place, then moves left
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0), // Slides out to the left
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _startSlideOut() {
    if (_controller.status == AnimationStatus.completed) {
      _controller.reverse(); // Reset for replay
    } else {
      _controller.forward(); // Slide out
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.game.releaseDate,  // Default date to show
      firstDate: DateTime(1990),    // Earliest date that can be selected
      lastDate: DateTime(2100),     // Latest date that can be selected
    );

    if (picked != null && picked != widget.game.releaseDate) {
      setState(() {
        _tempChangeGame.releaseDate = picked;
      });
    }
  }

  Widget createHeaderPane() {
    return Stack(
      children: [
        createHeaderView(),
        Align(
          alignment: Alignment.topRight,
          child: createGeneralHeaderButtons()
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: createSpecificHeaderButtons()
        )
      ]
    );
  }

  Widget createSettingsPane() {
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        createSettingsView(),
        createSettingsButtons()
      ]
    );
  }

  Widget createSettingsView() {
    return Center(
      child: SizedBox(
        width: 500.0, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              minLines: 1,
              maxLines: 2,
              initialValue: widget.game.name,
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
                IconButton(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_month),
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
                    shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
                    elevation: MaterialStatePropertyAll<double>(20.0),
                    fixedSize: MaterialStatePropertyAll<Size>(Size(50.0, 50.0))
                  )
                ),
                if ( widget.game.guid != 0 )
                  ...[
                    SizedBox.fromSize(size: const Size(30.0, 0.0)),
                    IconButton(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          dialogTitle: 'Select a new image',
                          initialDirectory: 'C:/',
                          type: FileType.image
                        );
                    
                        if (result != null) {
                          cacheCustomImage(result.files.single.path!, widget.game.appId);
                        }
                      },
                      icon: const Icon(Icons.image),
                      style: const ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
                        shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
                        elevation: MaterialStatePropertyAll<double>(20.0),
                        fixedSize: MaterialStatePropertyAll<Size>(Size(50.0, 50.0))
                      )
                    )
                  ]
              ]
            )
          ]
        )
      )
    );
  }

  Widget createSettingsButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {
              _startSlideOut();
            },
            icon: const Icon(Icons.cancel),
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
              shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
              elevation: MaterialStatePropertyAll<double>(20.0)
            )
          ),
          SizedBox.fromSize(size: const Size(10.0, 0.0)),
          IconButton(
            onPressed: () {
              Provider.of<GameListData>(context, listen: false).update(_tempChangeGame);
              _startSlideOut();
            },
            icon: const Icon(Icons.check_circle),
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
              shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
              elevation: MaterialStatePropertyAll<double>(20.0)
            )
          )
        ]
      )
    );
  }

  Widget createHeaderView() {
    return Container(
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60.0, bottom: 60.0),
            child: Column(
              children: [
                Text(
                  widget.game.releaseDate.toString().split(' ')[0],
                  style: const TextStyle(
                    color: Colors.white70,
                  )
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  child: Text(
                    widget.game.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white
                    ),
                  ),
                ),
                Expanded(child: Container()),
                if (widget.game.playing)
                  Icon(
                    Icons.videogame_asset,
                    size: 40.0,
                    color: Colors.blue.shade600
                  )
                else
                  Row(
                    children: List.generate(
                      widget.game.hype, 
                      (index) => Icon(
                        Icons.star,
                        color: Colors.blue.shade600,
                      ),
                    )
                  )
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
            child: widget.game.header
          ),
        ]
      ),
    );
  }

  Widget createSpecificHeaderButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.game.playing)
            ...[
              IconButton(
                onPressed: () {
                  _tempChangeGame.playing = false;
                  _tempChangeGame.hype = 1;
                  Provider.of<GameListData>(context, listen: false).update(_tempChangeGame);
                },
                icon: const Icon(Icons.workspace_premium),
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
                  shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
                  elevation: MaterialStatePropertyAll<double>(7.0)
                ),
                tooltip: "To 100%",
              ),
              SizedBox.fromSize(size: const Size(15.0, 0.0))
            ],
          IconButton(
            onPressed: () {
              _tempChangeGame.playing = !_tempChangeGame.playing;
              Provider.of<GameListData>(context, listen: false).update(_tempChangeGame);
            },
            icon: Icon(widget.game.playing ? Icons.videogame_asset_off : Icons.videogame_asset),
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
              shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
              elevation: MaterialStatePropertyAll<double>(7.0)
            ),
            tooltip: widget.game.playing ? "Stop Playing" : "Start Playing",
          ),
        ],
      ),
    );
  } 

  Widget createGeneralHeaderButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => _startSlideOut(),
            icon: const Icon(Icons.edit),
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
              shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
              elevation: MaterialStatePropertyAll<double>(7.0)
            ),
            tooltip: "Edit",
          ),
          SizedBox.fromSize(size: const Size(15.0, 0.0)),
          IconButton(
            onPressed: () => Provider.of<GameListData>(context, listen: false).remove(widget.game.guid),
            icon: const Icon(Icons.delete_forever),
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
              shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
              elevation: MaterialStatePropertyAll<double>(7.0)
            ),
            tooltip: "Delete Game",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [ 
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(width: 0.2),
            borderRadius: const BorderRadius.all( 
              Radius.circular( 10.0 )
            )
          ),
          clipBehavior: Clip.hardEdge,
          child: ClipRRect(
            borderRadius: const BorderRadius.all( 
              Radius.circular( 10.0 )
            ),
            child: Stack(
              children: [
                createSettingsPane(),
                SlideTransition(
                  position: _slideAnimation,
                  child: createHeaderPane()
                )
              ]
            )
          )
        ),
        if (widget.game.playing) 
          IgnorePointer(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber.withOpacity(0.5)), 
                borderRadius: BorderRadius.circular(10.0), // Match container's radius
              ),
            ),
          ),
      ]
    );
  }
}