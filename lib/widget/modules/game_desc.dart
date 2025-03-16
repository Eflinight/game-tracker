import 'package:flutter/material.dart';
import 'package:game_tracker/core/game_data.dart';
import 'package:game_tracker/widget/elements/game_header.dart';
import 'package:game_tracker/widget/elements/game_settings.dart';

class GameDesc extends StatefulWidget {
  final Game game; // Game data

  const GameDesc({super.key, required this.game});

  @override
  State<GameDesc> createState() => _GameDescState();
}

class _GameDescState extends State<GameDesc> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation; 

  @override
  void initState() {
    super.initState();
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
                GameSettingsPane(
                  game: widget.game,
                  transitionCallback: _startSlideOut,
                ),
                SlideTransition(
                  position: _slideAnimation,
                  child: GameHeaderPane(
                    game: widget.game, 
                    transitionCallback: _startSlideOut)
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