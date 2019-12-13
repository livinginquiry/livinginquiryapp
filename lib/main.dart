import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import './blocs/notes_bloc.dart';
import './locator.dart';
import 'pages/home_page.dart';

void main() {
  setupLocator();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    super.dispose();
    locator<NotesBloc>()?.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => locator<NotesBloc>()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Living Inquiry App',
          theme: ThemeData(
            fontFamily: "Roboto",
            iconTheme: IconThemeData(color: Colors.black),
            primaryTextTheme: TextTheme(
              title: TextStyle(color: Colors.black),
            ),
            primarySwatch: Colors.blue,
          ),
          home: HomePage(),
        ));
  }
}
