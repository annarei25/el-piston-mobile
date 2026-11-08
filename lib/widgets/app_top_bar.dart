import 'package:flutter/material.dart';
import '../data/app_scope.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.titulo, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitulo != null)
            Text(subtitulo!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(app.themeController.icono),
          tooltip: 'Cambiar tema',
          onPressed: app.themeController.alternar,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: app.sesion.cerrarSesion,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}