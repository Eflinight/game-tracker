import 'package:get_it/get_it.dart';
import 'package:game_tracker/data/game_data.dart';

GetIt provider = GetIt.instance;

Future<void> setupGameListProvider() async {
  List<Game> gameList = orderGameList(await parseAllGame());
  provider.registerSingleton<List<Game>>(gameList);
}

Future<void> setupAllProviders() async {
  await setupGameListProvider();
}
