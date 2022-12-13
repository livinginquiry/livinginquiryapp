import 'package:get_it/get_it.dart';

import './blocs/notes_bloc.dart';
// import './services/db_provider.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  // locator.registerLazySingleton(() => DbProvider());
  locator.registerLazySingleton(() => NotesBloc());
}
