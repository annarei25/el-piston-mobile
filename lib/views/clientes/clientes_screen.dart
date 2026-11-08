import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/app_scope.dart';
import '../../utils/dinero.dart';
import '../../viewmodels/clientes_viewmodel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/hojas/hoja_cliente.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  ClientesViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= ClientesViewModel(AppScope.of(context).database);
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
        final lista = viewModel.filtrados;

        return Scaffold(
          appBar: AppTopBar(
            titulo: 'CLIENTES',
            subtitulo: '${viewModel.totalClientes} en total · ${viewModel.totalConSaldo} con saldo',
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: viewModel.buscar,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre o teléfono...',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('CON SALDO'),
                    selected: viewModel.soloConSaldo,
                    onSelected: (_) => viewModel.alternarSoloConSaldo(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: viewModel.cargando
                    ? const Center(child: CircularProgressIndicator())
                    : lista.isEmpty
                        ? Center(
                            child: Text(
                              'No hay clientes con estos filtros',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: lista.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, indice) {
                              final item = lista[indice];
                              return _TarjetaCliente(item: item);
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => mostrarHojaCliente(context),
            icon: const Icon(Icons.add),
            label: const Text('NUEVO CLIENTE'),
          ),
        );
      },
    );
  }
}

class _TarjetaCliente extends StatelessWidget {
  const _TarjetaCliente({required this.item});
  final ClienteConDatos item;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        onTap: () => context.push('/clientes/${item.cliente.id}'),
        title: Text(item.cliente.nombre, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          '${item.cliente.telefono} · ${item.cantidadVehiculos} vehículo(s)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: item.saldo > 0
            ? Text(
                formatoDinero(item.saldo),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: esquema.error),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}