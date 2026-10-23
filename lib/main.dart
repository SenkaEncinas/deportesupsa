import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/reciclaje/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPSA Campeonatos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      // Sin esto el calendario y el reloj (al programar un partido)
      // salían en inglés: "Select date", "Cancel", "OK".
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeScreen(),
    );
  }
}
