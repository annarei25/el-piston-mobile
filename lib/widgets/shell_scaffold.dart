import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/app_database.dart';
import '../data/app_scope.dart';
import 'bottom_nav_bar.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final sesion = AppScope.of(context).sesion;
    // Ramas: 0 Inicio, 1 Órdenes, 2 Clientes, 3 Inventario.
    final ramas = sesion.rol == RolUsuario.mecanico
        ? const [0, 1]
        : const [0, 1, 2, 3];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        ramasVisibles: ramas,
        indiceActual: navigationShell.currentIndex,
        onCambiar: (rama) => navigationShell.goBranch(
          rama,
          initialLocation: rama == navigationShell.currentIndex,
        ),
      ),
    );
  }
}