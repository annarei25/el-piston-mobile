import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';

// Devuelve el id del cliente creado o editado, o null si se canceló.
// Así quien abre la hoja puede usarlo de inmediato (por ejemplo, para
// preseleccionarlo en el formulario de orden).
Future<int?> mostrarHojaCliente(BuildContext context, {Cliente? existente}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _HojaCliente(existente: existente),
  );
}

class _HojaCliente extends StatefulWidget {
  const _HojaCliente({this.existente});
  final Cliente? existente;

  @override
  State<_HojaCliente> createState() => _HojaClienteState();
}

class _HojaClienteState extends State<_HojaCliente> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(
    text: widget.existente?.nombre,
  );
  late final _telefonoController = TextEditingController(
    text: widget.existente?.telefono,
  );
  late final _direccionController = TextEditingController(
    text: widget.existente?.direccion,
  );
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final db = AppScope.of(context).database;
    final direccion = _direccionController.text.trim();

    try {
      int id;
      if (widget.existente == null) {
        id = await db.clientesDao.crear(
          ClientesCompanion.insert(
            nombre: _nombreController.text.trim(),
            telefono: _telefonoController.text.trim(),
            direccion: Value(direccion.isEmpty ? null : direccion),
          ),
        );
      } else {
        id = widget.existente!.id;
        await db.clientesDao.editar(
          id,
          ClientesCompanion(
            nombre: Value(_nombreController.text.trim()),
            telefono: Value(_telefonoController.text.trim()),
            direccion: Value(direccion.isEmpty ? null : direccion),
          ),
        );
      }
      if (mounted) Navigator.pop(context, id);
    } catch (error) {
      // El teléfono es único; si ya existe, la base lanza una excepción.
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese teléfono ya está registrado')),
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
                  esEdicion ? 'EDITAR CLIENTE' : 'NUEVO CLIENTE',
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
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              textCapitalization: TextCapitalization.words,
              validator: (valor) {
                final largo = valor?.trim().length ?? 0;
                if (largo < 3 || largo > 60) return 'Entre 3 y 60 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (8 dígitos)',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              validator: (valor) {
                if (valor == null || !RegExp(r'^\d{8}$').hasMatch(valor)) {
                  return 'Debe tener exactamente 8 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección (opcional)',
              ),
              textCapitalization: TextCapitalization.sentences,
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
                  : Text(esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR CLIENTE'),
            ),
          ],
        ),
      ),
    );
  }
}
