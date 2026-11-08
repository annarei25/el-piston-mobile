import 'package:flutter/material.dart';
import '../../data/app_database.dart';
import '../../data/app_scope.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/estado_colores.dart';
import '../../utils/dinero.dart';
import '../../viewmodels/inventario_viewmodel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/hojas/hoja_repuesto_formulario.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  InventarioViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= InventarioViewModel(AppScope.of(context).database);
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
            titulo: 'INVENTARIO',
            subtitulo: viewModel.totalBajos > 0 ? '${viewModel.totalBajos} con stock bajo' : null,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: viewModel.buscar,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre o código...',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('SOLO BAJOS'),
                    selected: viewModel.soloBajos,
                    onSelected: (_) => viewModel.alternarSoloBajos(),
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
                              'No hay repuestos con estos filtros',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: lista.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, indice) => _TarjetaRepuesto(repuesto: lista[indice]),
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => mostrarHojaRepuestoFormulario(context),
            icon: const Icon(Icons.add),
            label: const Text('NUEVO REPUESTO'),
          ),
        );
      },
    );
  }
}

class _TarjetaRepuesto extends StatelessWidget {
  const _TarjetaRepuesto({required this.repuesto});
  final Repuesto repuesto;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).extension<EstadoColores>()!;
    final agotado = repuesto.existencias == 0;
    final bajo = repuesto.existencias <= repuesto.umbralAlerta;
    final color = agotado ? colores.stockAgotado : (bajo ? colores.stockBajo : null);

    return Card(
      child: ListTile(
        onTap: () => mostrarHojaRepuestoFormulario(context, existente: repuesto),
        title: Text(repuesto.nombre, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('#${repuesto.codigo} · ${formatoDinero(repuesto.precioCentavos)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${repuesto.existencias}',
              style: AppTextStyles.codigoGrande.copyWith(color: color),
            ),
            if (bajo)
              Text(
                agotado ? 'AGOTADO' : 'BAJO',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
              ),
          ],
        ),
      ),
    );
  }
}