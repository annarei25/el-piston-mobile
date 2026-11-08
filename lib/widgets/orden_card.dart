import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/daos/ordenes_dao.dart';
import '../theme/app_text_styles.dart';
import '../theme/estado_colores.dart';
import '../utils/dinero.dart';
import 'estado_badge.dart';

class OrdenCard extends StatelessWidget {
  const OrdenCard({super.key, required this.resumen});

  final OrdenResumen resumen;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final colores = Theme.of(context).extension<EstadoColores>()!;
    final color = colores.deEstado(resumen.orden.estado);
    final saldo = resumen.saldoCentavos;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/ordenes/${resumen.orden.id}'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MatriculaChip(matricula: resumen.vehiculo.matricula),
                          EstadoBadge(estado: resumen.orden.estado),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${resumen.vehiculo.marca} ${resumen.vehiculo.modelo} ${resumen.vehiculo.anio}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${resumen.cliente.nombre} · ${resumen.cliente.telefono}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resumen.orden.problema,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(resumen.mecanico.nombre),
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            visualDensity: VisualDensity.compact,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Tot: ${formatoDinero(resumen.totalCentavos)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'SALDO: ${formatoDinero(saldo)}',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: saldo > 0 ? esquema.error : colores.listaParaEntregar,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatriculaChip extends StatelessWidget {
  const _MatriculaChip({required this.matricula});

  final String matricula;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: esquema.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: esquema.outline),
      ),
      child: Text(matricula, style: AppTextStyles.codigoMediano.copyWith(color: esquema.onSurface)),
    );
  }
}