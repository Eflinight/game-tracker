import 'package:flutter/material.dart';

class GameControlButton extends IconButton {
/// Standardized buttons for game control
    const GameControlButton({
      super.key,
      required super.onPressed,
      required Icon super.icon,
      super.tooltip
    }) : super(
      style: const ButtonStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
        shadowColor: MaterialStatePropertyAll<Color>(Colors.black),
        elevation: MaterialStatePropertyAll<double>(20.0)
      )
    );
}