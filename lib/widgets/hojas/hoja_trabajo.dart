import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_database.dart';
import '../../data/app_scope.dart';

Future<void> mostrarHojaTrabajo(BuildContext context, int ordenId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _HojaTrabajo(ordenId: ordenId),
  );
}

class _HojaTrabajo extends StatefulWidget {
  const _HojaTrabajo({required this.ordenId});
  final int ordenId;

  @override
  State<_HojaTrabajo> createState() => _HojaTrabajoState();
}

class _HojaTrabajoState extends State<_HojaTrabajo> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final db = AppScope.of(context).database;
    final precioCentavos =
        (double.parse(_precioController.text.replaceAll(',', '.')) * 100)
            .round();

    await db.ordenesDao.agregarTrabajo(
      TrabajosCompanion.insert(
        ordenId: widget.ordenId,
        descripcion: _descripcionController.text.trim(),
        precioCentavos: precioCentavos,
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // El teclado empuja la hoja hacia arriba en vez de taparla.
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
                  'AGREGAR TRABAJO',
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
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción del trabajo',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (valor) {
                if (valor == null || valor.trim().length < 3) {
                  return 'Escribe una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio de mano de obra',
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
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('AGREGAR TRABAJO'),
            ),
          ],
        ),
      ),
    );
  }
}
