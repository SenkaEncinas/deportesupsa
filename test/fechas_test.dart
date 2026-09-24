// Los formatos de fecha salen de un solo lugar. Estos tests fijan que
// den exactamente lo mismo que la fórmula que tenía copiada cada
// pantalla, para que unificarlos no cambie nada de lo que se ve.

import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/utils/fechas.dart';

/// La fórmula vieja, tal cual estaba en cada pantalla.
String _viejaDiaYHora(DateTime f) {
  final dia = f.day.toString().padLeft(2, '0');
  final mes = f.month.toString().padLeft(2, '0');
  final hora = f.hour.toString().padLeft(2, '0');
  final minuto = f.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${f.year} $hora:$minuto';
}

void main() {
  // Casos borde: un dígito, dos dígitos, medianoche, fin de año.
  final fechas = [
    DateTime(2026, 1, 5, 7, 3),
    DateTime(2026, 10, 12, 18, 30),
    DateTime(2026, 12, 31, 23, 59),
    DateTime(2027, 2, 1, 0, 0),
  ];

  test('dia y hora da lo mismo que la fórmula vieja', () {
    for (final f in fechas) {
      expect(Fechas.diaYHora(f), _viejaDiaYHora(f));
    }
  });

  test('formatos concretos', () {
    final f = DateTime(2026, 1, 5, 7, 3);

    expect(Fechas.dia(f), '05/01/2026');
    expect(Fechas.diaCorto(f), '05/01');
    expect(Fechas.hora(f), '07:03');
    expect(Fechas.diaYHora(f), '05/01/2026 07:03');
    expect(Fechas.diaYHora(f, separador: ' · '), '05/01/2026 · 07:03');
    expect(Fechas.clave(f), '2026-01-05');
  });

  test('la clave ordena bien como texto', () {
    final claves = fechas.reversed.map(Fechas.clave).toList()..sort();

    expect(claves, fechas.map(Fechas.clave).toList());
  });
}
