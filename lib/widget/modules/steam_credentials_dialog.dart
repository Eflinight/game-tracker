import 'package:flutter/material.dart';
import 'package:game_tracker/utils/localio.dart';

/// Dialog letting the user enter the Steam Web API key and SteamID64 required
/// to read the achievement progress of their account.
class SteamCredentialsDialog extends StatefulWidget {
  const SteamCredentialsDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (_) => const SteamCredentialsDialog(),
    );
    return saved ?? false;
  }

  @override
  State<SteamCredentialsDialog> createState() => _SteamCredentialsDialogState();
}

class _SteamCredentialsDialogState extends State<SteamCredentialsDialog> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _steamIdController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final SteamCredentials credentials = await getSteamCredentials();
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = credentials.apiKey;
      _steamIdController.text = credentials.steamId;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _steamIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Steam achievements"),
      content: _loading
          ? const SizedBox(
              height: 80.0, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: "Steam Web API key",
                    helperText: "From steamcommunity.com/dev/apikey",
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _steamIdController,
                  decoration: const InputDecoration(
                    labelText: "SteamID64",
                    helperText: "Your 17 digit profile ID",
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            await saveSteamCredentials(SteamCredentials(
              _apiKeyController.text.trim(),
              _steamIdController.text.trim(),
            ));
            if (context.mounted) Navigator.of(context).pop(true);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
