import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';

Future<void> mostrarHojaMecanico(BuildContext context, {Mecanico? existente}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _HojaMecanico(existente: existente),
  );
}

class _HojaMecanico extends StatefulWidget {
  const _HojaMecanico({this.existente});
  final Mecanico? existente;

  @override
  State<_HojaMecanico> createState() => _HojaMecanicoState();
}

class _HojaMecanicoState extends State<_HojaMecanico> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(
    text: widget.existente?.nombre,
  );
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final db = AppScope.of(context).database;
    try {
      if (widget.existente == null) {
        await db.mecanicosDao.crear(
          MecanicosCompanion.insert(nombre: _nombreController.text.trim()),
        );
      } else {
        await db.mecanicosDao.editar(
          widget.existente!.id,
          MecanicosCompanion(nombre: Value(_nombreController.text.trim())),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
                  esEdicion ? 'EDITAR MECÁNICO' : 'NUEVO MECÁNICO',
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
              validator: (valor) => (valor == null || valor.trim().length < 3)
                  ? 'Mínimo 3 caracteres'
                  : null,
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
                  : Text(esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR MECÁNICO'),
            ),
          ],
        ),
      ),
    );
  }
}
