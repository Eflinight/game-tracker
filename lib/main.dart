import 'package:flutter/material.dart';
import 'package:game_tracker/view/home.dart';
import 'package:game_tracker/core/game_list_provider.dart';
import 'package:game_tracker/utils/network.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting("en");
  await updateGameList();
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameListData.fromJson(),
      child: const MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}
