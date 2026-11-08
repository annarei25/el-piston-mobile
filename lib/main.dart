import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'data/app_database.dart';
import 'data/app_scope.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'viewmodels/sesion_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final themeController = ThemeController();
  final sesion = SesionController(database);
  await sesion.restaurarSesion();

  final router = crearRouter(sesion);

  runApp(ElPistonApp(
    database: database,
    themeController: themeController,
    sesion: sesion,
    router: router,
  ));
}

class ElPistonApp extends StatelessWidget {
  const ElPistonApp({
    super.key,
    required this.database,
    required this.themeController,
    required this.sesion,
    required this.router,
  });

  final AppDatabase database;
  final ThemeController themeController;
  final SesionController sesion;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      database: database,
      themeController: themeController,
      sesion: sesion,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) => MaterialApp.router(
          title: 'El Pistón',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro(),
          darkTheme: AppTheme.oscuro(),
          themeMode: themeController.modo,
          routerConfig: router,
        ),
      ),
    );
  }
}