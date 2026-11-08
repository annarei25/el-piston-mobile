import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/llamadas.dart';

import '../../utils/confirmaciones.dart';
import '../../data/app_database.dart';
import '../../data/app_scope.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/dinero.dart';
import '../../utils/estado_textos.dart';
import '../../viewmodels/orden_detalle_viewmodel.dart';
import '../../widgets/estado_badge.dart';
import '../../widgets/hojas/hoja_trabajo.dart';
import '../../widgets/hojas/hoja_repuesto_pago.dart';

class OrdenDetalleScreen extends StatefulWidget {
  const OrdenDetalleScreen({super.key, required this.ordenId});
  final int ordenId;

  @override
  State<OrdenDetalleScreen> createState() => _OrdenDetalleScreenState();
}

class _OrdenDetalleScreenState extends State<OrdenDetalleScreen> {
  OrdenDetalleViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sesion = AppScope.of(context).sesion;
    _viewModel ??= OrdenDetalleViewModel(
      AppScope.of(context).database,
      widget.ordenId,
      mecanicoRequeridoId: sesion.rol == RolUsuario.mecanico
          ? sesion.mecanicoId
          : null,
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

        // Ruta con un id que no existe: mensaje claro y botón para volver,
        // sin cerrar la app, como pide la metodología de Turco.
        if (viewModel.error != null) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('VOLVER'),
                  ),
                ],
              ),
            ),
          );
        }

        final orden = viewModel.orden!;
        final puedeGestionar = AppScope.of(context).sesion.puede({
          RolUsuario.dueno,
          RolUsuario.recepcion,
        });

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.pop()),
            title: Text('#OT-${orden.id.toString().padLeft(4, '0')}'),
            actions: [
              if (!viewModel.esSoloLectura && puedeGestionar)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/ordenes/${orden.id}/editar'),
                ),
              if (!viewModel.esSoloLectura && puedeGestionar)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: () => _confirmarCancelar(context, viewModel),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _EncabezadoVehiculo(viewModel: viewModel),
              const SizedBox(height: 16),
              _TarjetaCliente(viewModel: viewModel),
              const SizedBox(height: 16),
              _BarraFases(viewModel: viewModel),
              if (!viewModel.esSoloLectura &&
                  viewModel.siguienteEstado != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _avanzarEstado(viewModel),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'AVANZAR A ${nombreEstado(viewModel.siguienteEstado!)}',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SeccionTrabajos(viewModel: viewModel),
              const SizedBox(height: 24),
              _SeccionRepuestos(viewModel: viewModel),
              const SizedBox(height: 24),
              _ResumenSaldo(viewModel: viewModel),
              const SizedBox(height: 80),
            ],
          ),
          bottomSheet: viewModel.esSoloLectura
              ? null
              : _BarraAcciones(
                  viewModel: viewModel,
                  puedeCobrar: puedeGestionar,
                ),
        );
      },
    );
  }

  Future<void> _avanzarEstado(OrdenDetalleViewModel viewModel) async {
    final siguiente = viewModel.siguienteEstado!;
    if (siguiente == EstadoOrden.entregada && viewModel.saldo > 0) {
      final confirmado = await confirmar(
        context,
        titulo: 'Entregar con saldo pendiente',
        mensaje:
            'Esta orden tiene un saldo pendiente de ${formatoDinero(viewModel.saldo)}. '
            'El vehículo se entrega igual y el saldo queda en la cuenta del cliente. ¿Continuar?',
        textoConfirmar: 'ENTREGAR',
      );
      if (!confirmado) return;
    }
    await viewModel.avanzarEstado();
  }

  void _confirmarCancelar(
    BuildContext context,
    OrdenDetalleViewModel viewModel,
  ) {
    final pagado = viewModel.totalPagado;
    final mensaje = pagado > 0
        ? '¿Seguro que quieres cancelar esta orden? Los repuestos usados vuelven al inventario. '
              'Esta orden tiene ${formatoDinero(pagado)} pagados: recuerda devolverlos o acreditarlos '
              'al cliente, la app no lo hace de forma automática.'
        : '¿Seguro que quieres cancelar esta orden? Los repuestos usados vuelven al inventario.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar orden'),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('NO')),
          FilledButton(
            onPressed: () {
              viewModel.cancelar();
              context.pop();
            },
            child: const Text('SÍ, CANCELAR'),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoVehiculo extends StatelessWidget {
  const _EncabezadoVehiculo({required this.viewModel});
  final OrdenDetalleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final vehiculo = viewModel.vehiculo!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                EstadoBadge(estado: viewModel.orden!.estado),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${vehiculo.marca} ${vehiculo.modelo} ${vehiculo.anio}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${vehiculo.kilometraje} km (entrada: ${viewModel.orden!.kilometrajeEntrada} km)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaCliente extends StatelessWidget {
  const _TarjetaCliente({required this.viewModel});
  final OrdenDetalleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final cliente = viewModel.cliente!;
    final mecanico = viewModel.mecanico!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        cliente.telefono,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call_outlined),
                  onPressed: () => llamarA(cliente.telefono),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.engineering_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mecánico: ${mecanico.nombre}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'SÍNTOMA REPORTADO',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              viewModel.orden!.problema,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraFases extends StatelessWidget {
  const _BarraFases({required this.viewModel});
  final OrdenDetalleViewModel viewModel;

  static const _nombres = [
    'RECIBIDA',
    'DIAGNÓSTICO',
    'REPARACIÓN',
    'LISTA',
    'ENTREGADA',
  ];

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final fase = viewModel.faseActual;
    final cancelada = viewModel.orden!.estado == EstadoOrden.cancelada;

    if (cancelada) {
      return Card(
        color: esquema.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.block, color: esquema.error),
              const SizedBox(width: 8),
              Text(
                'ORDEN CANCELADA',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: esquema.error),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FASE ${fase + 1} DE ${_nombres.length}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_nombres.length, (indice) {
                final completada = indice <= fase;
                return Expanded(
                  child: Column(
                    children: [
                      Icon(
                        completada ? Icons.check_circle : Icons.circle_outlined,
                        color: completada ? esquema.tertiary : esquema.outline,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _nombres[indice],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeccionTrabajos extends StatelessWidget {
  const _SeccionTrabajos({required this.viewModel});
  final OrdenDetalleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MANO DE OBRA',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              formatoDinero(viewModel.totalTrabajos),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (viewModel.trabajos.isEmpty)
          Text(
            'Sin trabajos registrados',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ...viewModel.trabajos.map(
            (trabajo) => Card(
              child: ListTile(
                title: Text(trabajo.descripcion),
                onLongPress: viewModel.esSoloLectura
                    ? null
                    : () async {
                        final confirmado = await confirmar(
                          context,
                          titulo: 'Quitar trabajo',
                          mensaje:
                              '¿Quitar "${trabajo.descripcion}" de la orden?',
                          textoConfirmar: 'QUITAR',
                        );
                        if (confirmado) {
                          viewModel.quitarTrabajo(trabajo.id);
                        }
                      },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatoDinero(trabajo.precioCentavos)),
                    if (!viewModel.esSoloLectura)
                      IconButton(
                        tooltip: 'Quitar trabajo',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _ejecutarAccion(
                          context,
                          () => viewModel.quitarTrabajo(trabajo.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SeccionRepuestos extends StatelessWidget {
  const _SeccionRepuestos({required this.viewModel});
  final OrdenDetalleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('REPUESTOS', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              formatoDinero(viewModel.totalRepuestos),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (viewModel.repuestosUsados.isEmpty)
          Text(
            'Sin repuestos registrados',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ...viewModel.repuestosUsados.map(
            (uso) => Card(
              child: ListTile(
                title: Text(uso.repuesto.nombre),
                subtitle: Text(
                  '${uso.uso.cantidad} x ${formatoDinero(uso.uso.precioUnitarioCentavos)}',
                ),
                onLongPress: viewModel.esSoloLectura
                    ? null
                    : () async {
                        final confirmado = await confirmar(
                          context,
                          titulo: 'Quitar repuesto',
                          mensaje:
                              '¿Quitar "${uso.repuesto.nombre}" de la orden? Vuelve al inventario.',
                          textoConfirmar: 'QUITAR',
                        );
                        if (confirmado) {
                          viewModel.quitarRepuesto(uso.uso.id);
                        }
                      },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatoDinero(
                        uso.uso.cantidad * uso.uso.precioUnitarioCentavos,
                      ),
                    ),
                    if (!viewModel.esSoloLectura)
                      IconButton(
                        tooltip: 'Quitar repuesto',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _ejecutarAccion(
                          context,
                          () => viewModel.quitarRepuesto(uso.uso.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResumenSaldo extends StatelessWidget {
  const _ResumenSaldo({required this.viewModel});
  final OrdenDetalleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FilaSaldo(
              etiqueta: 'Mano de obra',
              monto: viewModel.totalTrabajos,
            ),
            const SizedBox(height: 8),
            _FilaSaldo(etiqueta: 'Repuestos', monto: viewModel.totalRepuestos),
            const Divider(height: 24),
            _FilaSaldo(
              etiqueta: 'Total',
              monto: viewModel.totalGeneral,
              estilo: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _FilaSaldo(etiqueta: 'Pagado', monto: viewModel.totalPagado),
            const SizedBox(height: 8),
            _FilaSaldo(
              etiqueta: 'Saldo pendiente',
              monto: viewModel.saldo,
              estilo: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaSaldo extends StatelessWidget {
  const _FilaSaldo({required this.etiqueta, required this.monto, this.estilo});

  final String etiqueta;
  final int monto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final textStyle = estilo ?? Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: textStyle),
        Text(formatoDinero(monto), style: textStyle),
      ],
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({
    required this.viewModel,
    required this.puedeCobrar,
  });

  final OrdenDetalleViewModel viewModel;
  final bool puedeCobrar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final ordenId = viewModel.ordenId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esquema.surface,
        border: Border(top: BorderSide(color: esquema.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => mostrarHojaTrabajo(context, ordenId),
                icon: const Icon(Icons.add),
                label: const Text('TRABAJO'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => mostrarHojaRepuestoPago(
                  context,
                  ordenId,
                  puedePagar: puedeCobrar,
                ),
                icon: const Icon(Icons.build_outlined),
                label: const Text('REPUESTO'),
              ),
            ),
            if (puedeCobrar) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => mostrarHojaRepuestoPago(
                    context,
                    ordenId,
                    mostrarPagoPrimero: true,
                  ),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('PAGO'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _ejecutarAccion(
  BuildContext context,
  Future<void> Function() accion,
) async {
  try {
    await accion();
  } catch (error) {
    if (context.mounted) _mostrarError(context, error);
  }
}

void _mostrarError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('No se pudo completar la acción: $error')),
  );
}
