String formatoDinero(int centavos) {
  final esNegativo = centavos < 0;
  final valorAbsoluto = centavos.abs();
  final pesos = valorAbsoluto ~/ 100;
  final centavosRestantes = valorAbsoluto % 100;
  final signo = esNegativo ? '-' : '';
  return '$signo\$${_conSeparadorDeMiles(pesos)}.${centavosRestantes.toString().padLeft(2, '0')}';
}

String _conSeparadorDeMiles(int numero) {
  final texto = numero.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    final posicionDesdeElFinal = texto.length - i;
    if (i > 0 && posicionDesdeElFinal % 3 == 0) buffer.write(',');
    buffer.write(texto[i]);
  }
  return buffer.toString();
}