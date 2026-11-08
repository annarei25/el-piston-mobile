import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';
import '../../utils/estado_textos.dart';
import '../../viewmodels/ordenes_viewmodel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/orden_card.dart';

class OrdenesScreen extends StatefulWidget {
  const OrdenesScreen({super.key, this.estadoInicial});

  final String? estadoInicial;

  @override
  State<OrdenesScreen> createState() => _OrdenesScreenState();
}

class _OrdenesScreenState extends State<OrdenesScreen> {
  OrdenesViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sesion = AppScope.of(context).sesion;
    _viewModel ??= OrdenesViewModel(
      AppScope.of(context).database,
      estadoInicial: _parseEstado(widget.estadoInicial),
      mecanicoFijoId: sesion.rol == RolUsuario.mecanico
          ? sesion.mecanicoId
          : null,
    );
  }

  EstadoOrden? _parseEstado(String? texto) {
    if (texto == null) return null;
    for (final estado in EstadoOrden.values) {
      if (estado.name == texto) return estado;
    }
    return null;
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
        final ordenes = viewModel.ordenesFiltradas;
        final puedeGestionar = AppScope.of(context).sesion
            .puede({RolUsuario.dueno, RolUsuario.recepcion});

        return Scaffold(
          appBar: AppTopBar(
            titulo: 'ÓRDENES DE SERVICIO',
            subtitulo: '${viewModel.todas.length} en total',
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: viewModel.buscar,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por matrícula o cliente...',
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _ChipFiltro(
                      etiqueta: 'TODOS',
                      cantidad: viewModel.conteoDeEstado(null),
                      seleccionado: viewModel.estadoSeleccionado == null,
                      onTap: () => viewModel.filtrarPorEstado(null),
                    ),
                    for (final estado in EstadoOrden.values)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _ChipFiltro(
                          etiqueta: nombreEstado(estado),
                          cantidad: viewModel.conteoDeEstado(estado),
                          seleccionado: viewModel.estadoSeleccionado == estado,
                          onTap: () => viewModel.filtrarPorEstado(estado),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (puedeGestionar)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _ChipFiltro(
                        etiqueta: 'TÉCNICO: TODOS',
                        cantidad: viewModel.conteoDeMecanico(null),
                        seleccionado: viewModel.mecanicoSeleccionadoId == null,
                        onTap: () => viewModel.filtrarPorMecanico(null),
                      ),
                      for (final mecanico in viewModel.mecanicos)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _ChipFiltro(
                            etiqueta: mecanico.nombre,
                            cantidad: viewModel.conteoDeMecanico(mecanico.id),
                            seleccionado: viewModel.mecanicoSeleccionadoId ==
                                mecanico.id,
                            onTap: () =>
                                viewModel.filtrarPorMecanico(mecanico.id),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: ordenes.isEmpty
                    ? const _ListaVacia()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ordenes.length,
                        itemBuilder: (context, indice) =>
                            OrdenCard(resumen: ordenes[indice]),
                      ),
              ),
            ],
          ),
          floatingActionButton: puedeGestionar
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/ordenes/nueva'),
                  icon: const Icon(Icons.add),
                  label: const Text('NUEVA ORDEN'),
                )
              : null,
        );
      },
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.etiqueta,
    required this.cantidad,
    required this.seleccionado,
    required this.onTap,
  });

  final String etiqueta;
  final int cantidad;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text('$etiqueta ($cantidad)'),
      selected: seleccionado,
      onSelected: (_) => onTap(),
      selectedColor: esquema.primary,
      backgroundColor: esquema.surfaceContainer,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontSize: 12,
        color: seleccionado ? esquema.onPrimary : esquema.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: esquema.outline),
      ),
    );
  }
}

class _ListaVacia extends StatelessWidget {
  const _ListaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay órdenes con estos filtros',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
