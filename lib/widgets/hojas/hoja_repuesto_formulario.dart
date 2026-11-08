import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';

Future<void> mostrarHojaRepuestoFormulario(
  BuildContext context, {
  Repuesto? existente,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _HojaRepuestoFormulario(existente: existente),
  );
}

class _HojaRepuestoFormulario extends StatefulWidget {
  const _HojaRepuestoFormulario({this.existente});
  final Repuesto? existente;

  @override
  State<_HojaRepuestoFormulario> createState() =>
      _HojaRepuestoFormularioState();
}

class _HojaRepuestoFormularioState extends State<_HojaRepuestoFormulario> {
  final _formKey = GlobalKey<FormState>();
  late final _codigoController = TextEditingController(
    text: widget.existente?.codigo,
  );
  late final _nombreController = TextEditingController(
    text: widget.existente?.nombre,
  );
  late final _precioController = TextEditingController(
    text: widget.existente != null
        ? (widget.existente!.precioCentavos / 100).toStringAsFixed(2)
        : null,
  );
  late final _existenciasController = TextEditingController(
    text: widget.existente?.existencias.toString() ?? '0',
  );
  late final _umbralController = TextEditingController(
    text: widget.existente?.umbralAlerta.toString() ?? '3',
  );
  bool _guardando = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _precioController.dispose();
    _existenciasController.dispose();
    _umbralController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final db = AppScope.of(context).database;
    final precioCentavos =
        (double.parse(_precioController.text.replaceAll(',', '.')) * 100)
            .round();

    final datos = RepuestosCompanion(
      codigo: Value(_codigoController.text.trim().toUpperCase()),
      nombre: Value(_nombreController.text.trim()),
      precioCentavos: Value(precioCentavos),
      existencias: Value(int.parse(_existenciasController.text)),
      umbralAlerta: Value(int.parse(_umbralController.text)),
    );

    try {
      if (widget.existente == null) {
        await db.repuestosDao.crear(
          RepuestosCompanion.insert(
            codigo: _codigoController.text.trim().toUpperCase(),
            nombre: _nombreController.text.trim(),
            precioCentavos: precioCentavos,
            existencias: Value(int.parse(_existenciasController.text)),
            umbralAlerta: Value(int.parse(_umbralController.text)),
          ),
        );
      } else {
        await db.repuestosDao.editar(widget.existente!.id, datos);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese código ya está registrado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.existente != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  esEdicion ? 'EDITAR REPUESTO' : 'NUEVO REPUESTO',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codigoController,
              decoration: const InputDecoration(labelText: 'Código'),
              textCapitalization: TextCapitalization.characters,
              validator: (valor) =>
                  (valor == null || valor.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              textCapitalization: TextCapitalization.sentences,
              validator: (valor) =>
                  (valor == null || valor.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio de venta',
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
                if (numero == null || numero <= 0) return 'Precio inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _existenciasController,
                    decoration: const InputDecoration(labelText: 'Existencias'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (valor) {
                      final numero = int.tryParse(valor ?? '');
                      if (numero == null || numero < 0) return 'Inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _umbralController,
                    decoration: const InputDecoration(
                      labelText: 'Umbral de alerta',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (valor) {
                      final numero = int.tryParse(valor ?? '');
                      if (numero == null || numero < 0) return 'Inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR REPUESTO'),
            ),
          ],
        ),
      ),
    );
  }
}
