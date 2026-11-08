import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';

Future<int?> mostrarHojaVehiculo(
  BuildContext context, {
  required int clienteId,
  Vehiculo? existente,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _HojaVehiculo(clienteId: clienteId, existente: existente),
  );
}

class _HojaVehiculo extends StatefulWidget {
  const _HojaVehiculo({required this.clienteId, this.existente});
  final int clienteId;
  final Vehiculo? existente;

  @override
  State<_HojaVehiculo> createState() => _HojaVehiculoState();
}

class _HojaVehiculoState extends State<_HojaVehiculo> {
  final _formKey = GlobalKey<FormState>();
  late final _matriculaController = TextEditingController(
    text: widget.existente?.matricula,
  );
  late final _marcaController = TextEditingController(
    text: widget.existente?.marca,
  );
  late final _modeloController = TextEditingController(
    text: widget.existente?.modelo,
  );
  late final _anioController = TextEditingController(
    text: widget.existente?.anio.toString(),
  );
  late final _kilometrajeController = TextEditingController(
    text: widget.existente?.kilometraje.toString() ?? '0',
  );
  bool _guardando = false;

  @override
  void dispose() {
    _matriculaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _kilometrajeController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final db = AppScope.of(context).database;

    try {
      int id;
      if (widget.existente == null) {
        id = await db.vehiculosDao.crear(
          VehiculosCompanion.insert(
            clienteId: widget.clienteId,
            matricula: _matriculaController.text.trim().toUpperCase(),
            marca: _marcaController.text.trim(),
            modelo: _modeloController.text.trim(),
            anio: int.parse(_anioController.text),
            kilometraje: Value(int.parse(_kilometrajeController.text)),
          ),
        );
      } else {
        id = widget.existente!.id;
        await db.vehiculosDao.editar(
          id,
          VehiculosCompanion(
            matricula: Value(_matriculaController.text.trim().toUpperCase()),
            marca: Value(_marcaController.text.trim()),
            modelo: Value(_modeloController.text.trim()),
            anio: Value(int.parse(_anioController.text)),
          ),
        );
      }
      if (mounted) Navigator.pop(context, id);
    } catch (_) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esa matrícula ya está registrada')),
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
                  esEdicion ? 'EDITAR VEHÍCULO' : 'NUEVO VEHÍCULO',
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
              controller: _matriculaController,
              decoration: const InputDecoration(labelText: 'Matrícula'),
              textCapitalization: TextCapitalization.characters,
              validator: (valor) =>
                  (valor == null || valor.trim().isEmpty) ? 'Requerida' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _marcaController,
                    decoration: const InputDecoration(labelText: 'Marca'),
                    validator: (valor) =>
                        (valor == null || valor.trim().isEmpty)
                        ? 'Requerida'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modeloController,
                    decoration: const InputDecoration(labelText: 'Modelo'),
                    validator: (valor) =>
                        (valor == null || valor.trim().isEmpty)
                        ? 'Requerido'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anioController,
                    decoration: const InputDecoration(labelText: 'Año'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (valor) {
                      final numero = int.tryParse(valor ?? '');
                      if (numero == null ||
                          numero < 1950 ||
                          numero > DateTime.now().year + 1) {
                        return 'Año inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _kilometrajeController,
                    decoration: const InputDecoration(labelText: 'Kilometraje'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled:
                        !esEdicion, // Se actualiza solo al crear una orden.
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
                  : Text(esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR VEHÍCULO'),
            ),
          ],
        ),
      ),
    );
  }
}
