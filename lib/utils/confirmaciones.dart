import 'package:flutter/material.dart';

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'CONFIRMAR',
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(textoConfirmar)),
      ],
    ),
  );
  return resultado ?? false;
}