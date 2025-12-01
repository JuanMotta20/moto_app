import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class MotoApp extends StatelessWidget {
  const MotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoTaxi App',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
