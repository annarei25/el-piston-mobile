import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';
import '../../utils/confirmaciones.dart';
import '../../viewmodels/mecanicos_viewmodel.dart';
import '../../widgets/hojas/hoja_mecanico.dart';

class MecanicosScreen extends StatefulWidget {
  const MecanicosScreen({super.key});

  @override
  State<MecanicosScreen> createState() => _MecanicosScreenState();
}

class _MecanicosScreenState extends State<MecanicosScreen> {
  MecanicosViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= MecanicosViewModel(AppScope.of(context).database);
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  Future<void> _eliminar(Mecanico mecanico) async {
    final confirmado = await confirmar(
      context,
      titulo: 'Eliminar mecánico',
      mensaje:
          '¿Eliminar a ${mecanico.nombre}? Solo es posible si no tiene órdenes en su historial.',
      textoConfirmar: 'ELIMINAR',
    );
    if (!confirmado) return;

    final error = await _viewModel!.eliminar(mecanico.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
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
            title: const Text('MECÁNICOS'),
          ),
          body: Column(
            children: [
              if (viewModel.mecanicos.length >= 2)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'El taller ya tiene sus 2 mecánicos. Elimina uno para poder agregar otro.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Expanded(
                child: viewModel.mecanicos.isEmpty
                    ? Center(
                        child: Text(
                          'No hay mecánicos registrados',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.mecanicos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, indice) {
                          final mecanico = viewModel.mecanicos[indice];
                          return Card(
                            child: ListTile(
                              title: Text(mecanico.nombre),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => mostrarHojaMecanico(
                                      context,
                                      existente: mecanico,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _eliminar(mecanico),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: viewModel.mecanicos.length < 2
              ? FloatingActionButton.extended(
                  onPressed: () => mostrarHojaMecanico(context),
                  icon: const Icon(Icons.add),
                  label: const Text('NUEVO MECÁNICO'),
                )
              : null,
        );
      },
    );
  }
}
