import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'features/translator/domain/app_state.dart';
import 'features/translator/presentation/translator_screen.dart';
import 'features/profile/presentation/auth_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Asegurar inicialización de bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Forzar orientación vertical para mejorar el diseño UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicializar estado global (Hive, base de datos de perfiles y bluetooth)
  final appState = AppState();
  await appState.init();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const GuanteLSPApp(),
    ),
  );
}

class GuanteLSPApp extends StatelessWidget {
  const GuanteLSPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Maki Voice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Consumer<AppState>(
        builder: (context, state, _) {
          return state.isLoggedIn
              ? MainScreen(appState: state)
              : const AuthScreen();
        },
      ),
    );
  }
}
