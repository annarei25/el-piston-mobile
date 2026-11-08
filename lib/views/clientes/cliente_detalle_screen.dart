import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/fechas.dart';
import '../../data/app_scope.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/dinero.dart';
import '../../utils/llamadas.dart';
import '../../viewmodels/cliente_detalle_viewmodel.dart';
import '../../widgets/estado_badge.dart';
import '../../widgets/hojas/hoja_cliente.dart';
import '../../widgets/hojas/hoja_vehiculo.dart';

class ClienteDetalleScreen extends StatefulWidget {
  const ClienteDetalleScreen({super.key, required this.clienteId});
  final int clienteId;

  @override
  State<ClienteDetalleScreen> createState() => _ClienteDetalleScreenState();
}

class _ClienteDetalleScreenState extends State<ClienteDetalleScreen> {
  ClienteDetalleViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= ClienteDetalleViewModel(
      AppScope.of(context).database,
      widget.clienteId,
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

        final cliente = viewModel.cliente!;
        final esquema = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.pop()),
            title: Text(cliente.nombre),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    mostrarHojaCliente(context, existente: cliente),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(cliente.telefono),
                  subtitle: cliente.direccion != null
                      ? Text(cliente.direccion!)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.call_outlined),
                    onPressed: () => llamarA(cliente.telefono),
                  ),
                ),
              ),
              if (viewModel.saldo > 0) ...[
                const SizedBox(height: 8),
                Card(
                  color: esquema.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SALDO PENDIENTE',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          formatoDinero(viewModel.saldo),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: esquema.error),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VEHÍCULOS',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        mostrarHojaVehiculo(context, clienteId: cliente.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('AGREGAR'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (viewModel.vehiculos.isEmpty)
                Text(
                  'Sin vehículos registrados',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...viewModel.vehiculos.map(
                  (v) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => context.push('/vehiculos/${v.id}'),
                      title: Text('${v.marca} ${v.modelo} ${v.anio}'),
                      subtitle: Text(
                        v.matricula,
                        style: AppTextStyles.codigoMediano,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    context.push('/ordenes/nueva?clienteId=${cliente.id}'),
                icon: const Icon(Icons.add),
                label: const Text('NUEVA ORDEN'),
              ),
              const SizedBox(height: 24),
              Text(
                'HISTORIAL DE ÓRDENES',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (viewModel.historial.isEmpty)
                Text(
                  'Sin órdenes registradas',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...viewModel.historial.map(
                  (o) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => context.push('/ordenes/${o.orden.id}'),
                      title: Text('${o.vehiculo.marca} ${o.vehiculo.modelo}'),
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
