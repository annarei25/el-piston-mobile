import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.ramasVisibles,
    required this.indiceActual,
    required this.onCambiar,
  });

  final List<int> ramasVisibles;
  final int indiceActual;
  final ValueChanged<int> onCambiar;

  static const _destinos =
      <int, ({IconData icono, IconData iconoActivo, String etiqueta})>{
    0: (icono: Icons.home_outlined, iconoActivo: Icons.home, etiqueta: 'INICIO'),
    1: (icono: Icons.build_outlined, iconoActivo: Icons.build, etiqueta: 'ÓRDENES'),
    2: (icono: Icons.people_outline, iconoActivo: Icons.people, etiqueta: 'CLIENTES'),
    3: (
      icono: Icons.inventory_2_outlined,
      iconoActivo: Icons.inventory_2,
      etiqueta: 'INVENTARIO'
    ),
  };

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: esquema.surface,
        border: Border(top: BorderSide(color: esquema.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final rama in ramasVisibles)
            Expanded(child: _item(context, rama, esquema)),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, int rama, ColorScheme esquema) {
    final destino = _destinos[rama]!;
    final activo = rama == indiceActual;
    final color = activo ? esquema.primary : esquema.onSurfaceVariant;

    return InkWell(
      onTap: () => onCambiar(rama),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(activo ? destino.iconoActivo : destino.icono, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            destino.etiqueta,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 24,
            color: activo ? esquema.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}