import 'package:el_piston/data/daos/ordenes_dao.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';
import '../../theme/estado_colores.dart';
import '../../utils/dinero.dart';
import '../../utils/estado_textos.dart';
import '../../viewmodels/inicio_viewmodel.dart';
import '../../widgets/app_top_bar.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  InicioViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sesion = AppScope.of(context).sesion;
    _viewModel ??= InicioViewModel(
      AppScope.of(context).database,
      mecanicoFijoId: sesion.rol == RolUsuario.mecanico
          ? sesion.mecanicoId
          : null,
    );
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  static const _estadosActivos = [
    EstadoOrden.recibida,
    EstadoOrden.enDiagnostico,
    EstadoOrden.enReparacion,
    EstadoOrden.listaParaEntregar,
  ];

    @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel!;
    final sesion = AppScope.of(context).sesion;
    final esStaff = sesion.puede({RolUsuario.dueno, RolUsuario.recepcion});
    final esDueno = sesion.puede({RolUsuario.dueno});

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Scaffold(
        appBar: const AppTopBar(titulo: 'EL PISTÓN', subtitulo: 'Taller mecánico'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (esDueno) ...[
              _TarjetaFacturacion(centavos: viewModel.facturacionMesCentavos),
              const SizedBox(height: 16),
            ],
            if (esStaff) ...[
              FilledButton.icon(
                onPressed: () => context.push('/ordenes/nueva'),
                icon: const Icon(Icons.add),
                label: const Text('NUEVA ORDEN DE TRABAJO'),
              ),
              const SizedBox(height: 24),
            ],
            _EncabezadoSeccion(
              titulo: 'Estado de órdenes',
              accion: 'Ver todas',
              onTap: () => context.go('/ordenes'),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: _estadosActivos
                  .map((estado) => _TarjetaEstado(
                        estado: estado,
                        cantidad: viewModel.conteoPorEstado(estado),
                        onTap: () => context.go('/ordenes?estado=${estado.name}'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Carga por mecánico', style: Theme.of(context).textTheme.headlineSmall),
                if (esDueno)
                  TextButton(
                    onPressed: () => context.push('/mecanicos'),
                    child: const Text('GESTIONAR'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...viewModel.mecanicos
                .where((m) => esStaff || m.id == sesion.mecanicoId)
                .map((mecanico) => _TarjetaMecanico(
                      mecanico: mecanico,
                      ordenes: viewModel.ordenesActivasDe(mecanico.id),
                    )),
            if (esDueno) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push('/usuarios'),
                child: const Text('CUENTAS DE USUARIO'),
              ),
            ],
            if (esStaff) ...[
              const SizedBox(height: 24),
              _TarjetaCuentasPorCobrar(
                totalCentavos: viewModel.saldoTotalPendiente,
                cantidad: viewModel.cantidadConSaldo,
                onTap: () => context.go('/ordenes'),
              ),
            ],
            if (esStaff && viewModel.repuestosBajos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _TarjetaAlertaRepuestos(
                repuestos: viewModel.repuestosBajos,
                onTap: () => context.go('/inventario'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EncabezadoSeccion extends StatelessWidget {
  const _EncabezadoSeccion({
    required this.titulo,
    required this.accion,
    required this.onTap,
  });

  final String titulo;
  final String accion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
        TextButton(onPressed: onTap, child: Text(accion.toUpperCase())),
      ],
    );
  }
}

class _TarjetaFacturacion extends StatelessWidget {
  const _TarjetaFacturacion({required this.centavos});

  final int centavos;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FACTURACIÓN MENSUAL',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  formatoDinero(centavos),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
            IconButton(
              onPressed: () => context.push('/facturacion'),
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaEstado extends StatelessWidget {
  const _TarjetaEstado({
    required this.estado,
    required this.cantidad,
    required this.onTap,
  });

  final EstadoOrden estado;
  final int cantidad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).extension<EstadoColores>()!;
    final color = colores.deEstado(estado);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(width: 6, height: 36, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cantidad',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      nombreEstado(estado),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaMecanico extends StatelessWidget {
  const _TarjetaMecanico({required this.mecanico, required this.ordenes});

  final Mecanico mecanico;
  final List<OrdenResumen> ordenes;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mecanico.nombre,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${ordenes.length} órdenes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (ordenes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ordenes
                    .map(
                      (o) => ActionChip(
                        label: Text(o.vehiculo.matricula),
                        onPressed: () => context.push('/ordenes/${o.orden.id}'),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaCuentasPorCobrar extends StatelessWidget {
  const _TarjetaCuentasPorCobrar({
    required this.totalCentavos,
    required this.cantidad,
    required this.onTap,
  });

  final int totalCentavos;
  final int cantidad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CUENTAS POR COBRAR',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                '$cantidad órdenes con saldo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                formatoDinero(totalCentavos),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: esquema.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaAlertaRepuestos extends StatelessWidget {
  const _TarjetaAlertaRepuestos({required this.repuestos, required this.onTap});

  final List<Repuesto> repuestos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).extension<EstadoColores>()!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: colores.stockBajo),
                const SizedBox(width: 8),
                Text(
                  'ALERTA DE REPUESTOS',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...repuestos
                .take(3)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            r.nombre,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${r.existencias} restantes',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: r.existencias == 0
                                    ? colores.stockAgotado
                                    : colores.stockBajo,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onTap,
              child: const Text('REVISAR INVENTARIO'),
            ),
          ],
        ),
      ),
    );
  }
}
