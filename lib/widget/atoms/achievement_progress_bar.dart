import 'package:flutter/material.dart';
import 'package:game_tracker/utils/network.dart';

/// Displays the achievement completion of a game that is currently being played.
///
/// Stretches to fill the width given by its parent, so it must be laid out
/// under bounded width constraints (e.g. a `Positioned` with both `left` and
/// `right`, or a `SizedBox`).
class AchievementProgressBar extends StatelessWidget {
  final AchievementProgress progress;

  const AchievementProgressBar({super.key, required this.progress});

  /// Dark halo around glyphs, so light areas of the header art can't wash out
  /// the text or the icon.
  static const List<Shadow> _glyphShadows = [
    Shadow(color: Colors.black, blurRadius: 4.0),
    Shadow(color: Colors.black87, blurRadius: 8.0),
  ];

  @override
  Widget build(BuildContext context) {
    final bool completed = progress.unlocked == progress.total;
    final Color barColor = completed ? Colors.amber : Colors.blue.shade400;

    return DecoratedBox(
      decoration: BoxDecoration(
        // Scrim detaching the whole widget from whatever art is behind it.
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      completed ? Icons.workspace_premium : Icons.emoji_events,
                      size: 20.0,
                      color: barColor,
                      shadows: _glyphShadows,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      "${progress.unlocked}/${progress.total}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: _glyphShadows,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${progress.percent}%",
                  style: TextStyle(
                    fontSize: 16,
                    color: barColor,
                    fontWeight: FontWeight.bold,
                    shadows: _glyphShadows,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                // Opaque trough: the old translucent track let the artwork
                // show through and hid where the fill actually ended.
                color: Colors.black.withValues(alpha: 0.85),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 10.0,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
