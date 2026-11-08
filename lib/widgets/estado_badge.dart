import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../theme/estado_colores.dart';
import '../utils/estado_textos.dart';

class EstadoBadge extends StatelessWidget {
  const EstadoBadge({super.key, required this.estado});

  final EstadoOrden estado;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).extension<EstadoColores>()!;
    final color = colores.deEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        nombreEstado(estado),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}