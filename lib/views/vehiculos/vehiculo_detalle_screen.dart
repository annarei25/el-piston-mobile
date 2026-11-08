import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_scope.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/dinero.dart';
import '../../utils/fechas.dart';
import '../../viewmodels/vehiculo_detalle_viewmodel.dart';
import '../../widgets/estado_badge.dart';

class VehiculoDetalleScreen extends StatefulWidget {
  const VehiculoDetalleScreen({super.key, required this.vehiculoId});
  final int vehiculoId;

  @override
  State<VehiculoDetalleScreen> createState() => _VehiculoDetalleScreenState();
}

class _VehiculoDetalleScreenState extends State<VehiculoDetalleScreen> {
  VehiculoDetalleViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= VehiculoDetalleViewModel(
      AppScope.of(context).database,
      widget.vehiculoId,
    );
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel!;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.cargando) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (viewModel.error != null) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
            body: Center(child: Text(viewModel.error!)),
          );
        }

        final vehiculo = viewModel.vehiculo!;
        final esquema = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.pop()),
            title: Text('${vehiculo.marca} ${vehiculo.modelo}'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: esquema.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: esquema.outline),
                        ),
                        child: Text(
                          vehiculo.matricula,
                          style: AppTextStyles.codigoGrande.copyWith(
                            color: esquema.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${vehiculo.marca} ${vehiculo.modelo} ${vehiculo.anio}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Último kilometraje: ${vehiculo.kilometraje} km',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push(
                  '/ordenes/nueva?clienteId=${vehiculo.clienteId}&vehiculoId=${vehiculo.id}',
                ),
                icon: const Icon(Icons.add),
                label: const Text('NUEVA ORDEN'),
              ),
              const SizedBox(height: 24),
              Text(
                'HISTORIAL DE SERVICIOS',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (viewModel.historial.isEmpty)
                Text(
                  'Sin servicios registrados',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...viewModel.historial.map(
                  (o) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => context.push('/ordenes/${o.orden.id}'),
                      title: Text(
                        o.orden.problema,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${formatoFecha(o.orden.fechaEntrada)} · ${formatoDinero(o.totalCentavos)}',
                      ),
                      trailing: EstadoBadge(estado: o.orden.estado),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
