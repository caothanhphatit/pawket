import 'package:flutter/material.dart';
import 'package:pawket_mobile/app/routing/app_router.dart';
import 'package:pawket_mobile/app/theme/pawket_theme.dart';

class PawketApp extends StatelessWidget {
  const PawketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pawket',
      debugShowCheckedModeBanner: false,
      theme: PawketTheme.light(),
      routerConfig: appRouter,
    );
  }
}
