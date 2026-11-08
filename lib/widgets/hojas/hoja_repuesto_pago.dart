import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';
import '../../utils/dinero.dart';

Future<void> mostrarHojaRepuestoPago(
  BuildContext context,
  int ordenId, {
  bool mostrarPagoPrimero = false,
  bool puedePagar = true,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _HojaRepuestoPago(
      ordenId: ordenId,
      mostrarPagoPrimero: mostrarPagoPrimero,
      puedePagar: puedePagar,
    ),
  );
}

class _HojaRepuestoPago extends StatelessWidget {
  const _HojaRepuestoPago({
    required this.ordenId,
    required this.mostrarPagoPrimero,
    required this.puedePagar,
  });

  final int ordenId;
  final bool mostrarPagoPrimero;
  final bool puedePagar;

  @override
  Widget build(BuildContext context) {
    if (!puedePagar) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(child: _FormularioRepuesto(ordenId: ordenId)),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      initialIndex: mostrarPagoPrimero ? 0 : 1,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Alto fijo, porque las dos pestañas tienen contenido de distinto
        // tamaño y la hoja no debe "saltar" al cambiar entre ellas.
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'REGISTRAR PAGO'),
                  Tab(text: 'AGREGAR REPUESTO'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _FormularioPago(ordenId: ordenId),
                    _FormularioRepuesto(ordenId: ordenId),
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

class _FormularioPago extends StatefulWidget {
  const _FormularioPago({required this.ordenId});
  final int ordenId;

  @override
  State<_FormularioPago> createState() => _FormularioPagoState();
}

class _FormularioPagoState extends State<_FormularioPago> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _guardar(int saldo) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final db = AppScope.of(context).database;
    final montoCentavos =
        (double.parse(_montoController.text.replaceAll(',', '.')) * 100)
            .round();

    try {
      await db.ordenesDao.registrarPago(
        ordenId: widget.ordenId,
        montoCentavos: montoCentavos,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      // El DAO ya valida que el monto no supere el saldo, pero si dos
      // personas pagaran a la vez el saldo pudo cambiar; este catch
      // cubre ese caso.
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = AppScope.of(context).database;

    return FutureBuilder<List<int>>(
      future: Future.wait([
        db.ordenesDao.totalOrden(widget.ordenId),
        db.ordenesDao.totalPagado(widget.ordenId),
        db.ordenesDao.saldo(widget.ordenId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final total = snapshot.data![0];
        final pagado = snapshot.data![1];
        final saldo = snapshot.data![2];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _datoResumen(context, 'TOTAL ORDEN', total),
                    ),
                    Expanded(
                      child: _datoResumen(context, 'PAGADO ANTERIOR', pagado),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SALDO PENDIENTE',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        formatoDinero(saldo),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (saldo <= 0)
                  Text(
                    'Esta orden ya está saldada.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...[
                  TextFormField(
                    controller: _montoController,
                    decoration: const InputDecoration(
                      labelText: 'Monto a pagar',
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (valor) {
                      final numero = double.tryParse(
                        (valor ?? '').replaceAll(',', '.'),
                      );
                      if (numero == null || numero <= 0) {
                        return 'Monto inválido';
                      }
                      if ((numero * 100).round() > saldo) {
                        return 'No puede superar el saldo pendiente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _guardando ? null : () => _guardar(saldo),
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('CONFIRMAR PAGO'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _datoResumen(BuildContext context, String etiqueta, int centavos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.labelMedium),
        Text(
          formatoDinero(centavos),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _FormularioRepuesto extends StatefulWidget {
  const _FormularioRepuesto({required this.ordenId});
  final int ordenId;

  @override
  State<_FormularioRepuesto> createState() => _FormularioRepuestoState();
}

class _FormularioRepuestoState extends State<_FormularioRepuesto> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();
  Repuesto? _seleccionado;
  bool _guardando = false;

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_seleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige un repuesto del catálogo')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    final db = AppScope.of(context).database;
    final cantidad = int.parse(_cantidadController.text);
    final precioCentavos =
        (double.parse(_precioController.text.replaceAll(',', '.')) * 100)
            .round();

    try {
      await db.ordenesDao.agregarRepuesto(
        ordenId: widget.ordenId,
        repuestoId: _seleccionado!.id,
        cantidad: cantidad,
        precioUnitarioCentavos: precioCentavos,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = AppScope.of(context).database;

    return StreamBuilder<List<Repuesto>>(
      stream: db.repuestosDao.watchTodos(),
      builder: (context, snapshot) {
        final catalogo = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUSCADOR DE CATÁLOGO',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Autocomplete<Repuesto>(
                  displayStringForOption: (r) => '#${r.codigo} ${r.nombre}',
                  optionsBuilder: (texto) {
                    if (texto.text.isEmpty) {
                      return const Iterable<Repuesto>.empty();
                    }
                    final filtro = texto.text.toLowerCase();
                    return catalogo.where(
                      (r) =>
                          r.nombre.toLowerCase().contains(filtro) ||
                          r.codigo.toLowerCase().contains(filtro),
                    );
                  },
                  onSelected: (repuesto) => setState(() {
                    _seleccionado = repuesto;
                    _precioController.text = (repuesto.precioCentavos / 100)
                        .toStringAsFixed(2);
                  }),
                  fieldViewBuilder:
                      (context, controller, focusNode, onSubmit) => TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Nombre o código del repuesto',
                        ),
                      ),
                ),
                if (_seleccionado != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _seleccionado!.nombre,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  '${_seleccionado!.existencias} en existencia',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatoDinero(_seleccionado!.precioCentavos),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cantidadController,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (valor) {
                            final numero = int.tryParse(valor ?? '');
                            if (numero == null || numero <= 0) {
                              return 'Inválido';
                            }
                            if (numero > _seleccionado!.existencias) {
                              return 'Solo hay ${_seleccionado!.existencias}';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _precioController,
                          decoration: const InputDecoration(
                            labelText: 'Precio unit.',
                            prefixText: '\$ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          validator: (valor) {
                            final numero = double.tryParse(
                              (valor ?? '').replaceAll(',', '.'),
                            );
                            if (numero == null || numero <= 0) {
                              return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'El precio quedará congelado en esta orden, aunque el catálogo suba después.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('AGREGAR REPUESTO'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
