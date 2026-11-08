import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';
import '../../utils/dinero.dart';
import '../../viewmodels/facturacion_viewmodel.dart';

class FacturacionScreen extends StatefulWidget {
  const FacturacionScreen({super.key});

  @override
  State<FacturacionScreen> createState() => _FacturacionScreenState();
}

class _FacturacionScreenState extends State<FacturacionScreen> {
  FacturacionViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= FacturacionViewModel(AppScope.of(context).database);
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final viewModel = _viewModel!;
    final elegida = await showDatePicker(
      context: context,
      initialDate: esInicio ? viewModel.desde : viewModel.hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (elegida == null) return;
    await viewModel.cambiarPeriodo(
      esInicio ? elegida : viewModel.desde,
      esInicio ? viewModel.hasta : elegida,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel!;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.pop()),
            title: const Text('FACTURACIÓN'),
          ),
          body: viewModel.cargando
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _BotonFecha(
                            etiqueta: 'DESDE',
                            fecha: viewModel.desde,
                            onTap: () => _elegirFecha(esInicio: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BotonFecha(
                            etiqueta: 'HASTA',
                            fecha: viewModel.hasta,
                            onTap: () => _elegirFecha(esInicio: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL COBRADO',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatoDinero(viewModel.totalCobrado),
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 12),
                            _filaDesglose(
                              context,
                              'Mano de obra',
                              viewModel.totalManoDeObra,
                            ),
                            _filaDesglose(
                              context,
                              'Repuestos',
                              viewModel.totalRepuestos,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        title: Text('${viewModel.cantidadOrdenesEntregadas}'),
                        subtitle: const Text(
                          'órdenes entregadas con pagos en el período',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'PAGOS DEL PERÍODO',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (viewModel.pagos.isEmpty)
                      Text(
                        'Sin pagos en este período',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      ...viewModel.pagos.map(
                        (item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () =>
                                context.push('/ordenes/${item.orden.id}'),
                            title: Text(
                              '${item.vehiculo.marca} ${item.vehiculo.modelo} · ${item.cliente.nombre}',
                            ),
                            subtitle: Text(
                              '${item.pago.fecha.day.toString().padLeft(2, '0')}/${item.pago.fecha.month.toString().padLeft(2, '0')}/${item.pago.fecha.year}',
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatoDinero(item.pago.montoCentavos),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (item.orden.estado == EstadoOrden.cancelada)
                                  Text(
                                    'No cuenta (cancelada)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _filaDesglose(BuildContext context, String etiqueta, int centavos) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            formatoDinero(centavos),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BotonFecha extends StatelessWidget {
  const _BotonFecha({
    required this.etiqueta,
    required this.fecha,
    required this.onTap,
  });
  final String etiqueta;
  final DateTime fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: esquema.outline, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
