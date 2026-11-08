import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_scope.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/orden_formulario_viewmodel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/hojas/hoja_cliente.dart';
import '../../widgets/hojas/hoja_vehiculo.dart';

class OrdenFormularioScreen extends StatefulWidget {
  const OrdenFormularioScreen({
    super.key,
    this.ordenId,
    this.clienteInicialId,
    this.vehiculoInicialId,
  });
  final int? ordenId;
  final int? clienteInicialId;
  final int? vehiculoInicialId;

  @override
  State<OrdenFormularioScreen> createState() => _OrdenFormularioScreenState();
}

class _OrdenFormularioScreenState extends State<OrdenFormularioScreen> {
  final _formKey = GlobalKey<FormState>();
  OrdenFormularioViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= OrdenFormularioViewModel(
      AppScope.of(context).database,
      ordenId: widget.ordenId,
      clienteInicialId: widget.clienteInicialId,
      vehiculoInicialId: widget.vehiculoInicialId,
    );
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  Future<bool> _confirmarSalida() async {
    if (_viewModel == null || !_viewModel!.huboCambios) return true;
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Los cambios que hiciste se perderán.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('SEGUIR EDITANDO'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('SALIR'),
          ),
        ],
      ),
    );
    return salir ?? false;
  }

  Future<void> _guardar() async {
    final viewModel = _viewModel!;
    if (!_formKey.currentState!.validate()) return;

    final id = await viewModel.guardar();
    if (id == null || !mounted) return;

    if (viewModel.esEdicion) {
      context.pop();
    } else {
      // Se navega directo al detalle de la orden recién creada, en vez
      // de volver a una lista, porque lo normal es seguir cargando
      // trabajos y repuestos justo después de crearla.
      context.pushReplacement('/ordenes/$id');
    }
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

        return PopScope(
          canPop: !viewModel.huboCambios,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (await _confirmarSalida() && context.mounted) context.pop();
          },
          child: Scaffold(
            appBar: AppTopBar(
              titulo: viewModel.esEdicion ? 'EDITAR ORDEN' : 'NUEVA ORDEN',
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _SelectorCliente(viewModel: viewModel),
                  const SizedBox(height: 16),
                  _SelectorVehiculo(viewModel: viewModel),
                  const SizedBox(height: 16),
                  _SelectorFecha(viewModel: viewModel),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: viewModel.kilometrajeController,
                    enabled: !viewModel.esEdicion,
                    decoration: const InputDecoration(
                      labelText: 'Kilometraje de entrada',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => viewModel.marcarCambio(),
                    validator: viewModel.validarKilometraje,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: viewModel.problemaController,
                    decoration: const InputDecoration(
                      labelText: 'Problema reportado',
                    ),
                    maxLines: 4,
                    onChanged: (_) => viewModel.marcarCambio(),
                    validator: (valor) =>
                        (valor == null || valor.trim().isEmpty)
                        ? 'Describe el problema'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _SelectorMecanico(viewModel: viewModel),
                  if (viewModel.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      viewModel.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            bottomSheet: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: FilledButton(
                  onPressed: viewModel.guardando ? null : _guardar,
                  child: viewModel.guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          viewModel.esEdicion
                              ? 'GUARDAR CAMBIOS'
                              : 'CREAR ORDEN',
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectorCliente extends StatelessWidget {
  const _SelectorCliente({required this.viewModel});
  final OrdenFormularioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final cliente = viewModel.clienteSeleccionado;

    return _CampoSelector(
      etiqueta: 'CLIENTE',
      valor: cliente?.nombre,
      subvalor: cliente?.telefono,
      habilitado: !viewModel.esEdicion,
      onTap: () => _abrirSelector(context),
    );
  }

  void _abrirSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _HojaSeleccionCliente(viewModel: viewModel),
    );
  }
}

class _HojaSeleccionCliente extends StatefulWidget {
  const _HojaSeleccionCliente({required this.viewModel});
  final OrdenFormularioViewModel viewModel;

  @override
  State<_HojaSeleccionCliente> createState() => _HojaSeleccionClienteState();
}

class _HojaSeleccionClienteState extends State<_HojaSeleccionCliente> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final clientes = widget.viewModel.clientes
        .where((c) => c.nombre.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              onChanged: (texto) => setState(() => _filtro = texto),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar cliente...',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, indice) {
                final cliente = clientes[indice];
                return ListTile(
                  title: Text(cliente.nombre),
                  subtitle: Text(cliente.telefono),
                  onTap: () {
                    widget.viewModel.seleccionarCliente(cliente);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: OutlinedButton.icon(
              onPressed: () async {
                final id = await mostrarHojaCliente(context);
                if (id != null) {
                  final creado =
                      widget.viewModel.clientes
                          .where((c) => c.id == id)
                          .isNotEmpty
                      ? widget.viewModel.clientes.firstWhere((c) => c.id == id)
                      : null;
                  if (creado != null) {
                    widget.viewModel.seleccionarCliente(creado);
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('CREAR CLIENTE NUEVO'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorVehiculo extends StatelessWidget {
  const _SelectorVehiculo({required this.viewModel});
  final OrdenFormularioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vehiculo = viewModel.vehiculoSeleccionado;
    final sinCliente = viewModel.clienteSeleccionado == null;

    return _CampoSelector(
      etiqueta: 'VEHÍCULO',
      valor: vehiculo != null
          ? '${vehiculo.marca} ${vehiculo.modelo} ${vehiculo.anio}'
          : null,
      subvalor: vehiculo?.matricula,
      habilitado: !viewModel.esEdicion && !sinCliente,
      textoDeshabilitado: sinCliente ? 'Elige un cliente primero' : null,
      onTap: () => _abrirSelector(context),
    );
  }

  void _abrirSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _HojaSeleccionVehiculo(viewModel: viewModel),
    );
  }
}

class _HojaSeleccionVehiculo extends StatelessWidget {
  const _HojaSeleccionVehiculo({required this.viewModel});
  final OrdenFormularioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Expanded(
            child: viewModel.vehiculosDelCliente.isEmpty
                ? const Center(child: Text('Este cliente no tiene vehículos'))
                : ListView.builder(
                    itemCount: viewModel.vehiculosDelCliente.length,
                    itemBuilder: (context, indice) {
                      final vehiculo = viewModel.vehiculosDelCliente[indice];
                      return ListTile(
                        title: Text(
                          '${vehiculo.marca} ${vehiculo.modelo} ${vehiculo.anio}',
                        ),
                        subtitle: Text(
                          vehiculo.matricula,
                          style: AppTextStyles.codigoMediano,
                        ),
                        onTap: () {
                          viewModel.seleccionarVehiculo(vehiculo);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: OutlinedButton.icon(
              onPressed: () async {
                final id = await mostrarHojaVehiculo(
                  context,
                  clienteId: viewModel.clienteSeleccionado!.id,
                );
                if (id != null && context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('AGREGAR VEHÍCULO NUEVO'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorFecha extends StatelessWidget {
  const _SelectorFecha({required this.viewModel});
  final OrdenFormularioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final fecha = viewModel.fecha!;
    return _CampoSelector(
      etiqueta: 'FECHA DE ENTRADA',
      valor:
          '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
      habilitado: true,
      onTap: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (elegida != null) viewModel.seleccionarFecha(elegida);
      },
    );
  }
}

class _SelectorMecanico extends StatelessWidget {
  const _SelectorMecanico({required this.viewModel});
  final OrdenFormularioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MECÁNICO', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        if (viewModel.mecanicos.isEmpty)
          Text(
            'No hay mecánicos registrados. Agrega uno desde Inicio.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 8,
            children: viewModel.mecanicos.map((mecanico) {
              final seleccionado =
                  viewModel.mecanicoSeleccionado?.id == mecanico.id;
              return ChoiceChip(
                label: Text(mecanico.nombre),
                selected: seleccionado,
                onSelected: (_) => viewModel.seleccionarMecanico(mecanico),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _CampoSelector extends StatelessWidget {
  const _CampoSelector({
    required this.etiqueta,
    required this.valor,
    this.subvalor,
    required this.habilitado,
    required this.onTap,
    this.textoDeshabilitado,
  });

  final String etiqueta;
  final String? valor;
  final String? subvalor;
  final bool habilitado;
  final VoidCallback onTap;
  final String? textoDeshabilitado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return InkWell(
      onTap: habilitado ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: esquema.outline, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valor ?? textoDeshabilitado ?? 'Toca para elegir',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subvalor != null)
                    Text(
                      subvalor!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (habilitado) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
