// "Próximos partidos" muestra esta semana y la siguiente, sin cortes a
// mitad de semana: antes la semana terminaba el sábado a las 14:00 y los
// partidos del sábado a la tarde no aparecían.

import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/services/public_home_service.dart';

void main() {
  test('un jueves: desde hoy hasta el domingo de la semana que viene', () {
    final rango = PublicHomeService.rangoProximos(
      DateTime(2026, 10, 1, 18, 30), // jueves
    );

    expect(rango.desde, DateTime(2026, 10, 1));
    expect(rango.corteSemana, DateTime(2026, 10, 5)); // lunes
    expect(rango.hasta, DateTime(2026, 10, 12)); // lunes siguiente
  });

  test('el sábado a la tarde sigue siendo "esta semana"', () {
    final rango = PublicHomeService.rangoProximos(
      DateTime(2026, 10, 3, 15), // sábado 15:00
    );

    expect(rango.corteSemana, DateTime(2026, 10, 5));
    expect(
      DateTime(2026, 10, 3, 16).isBefore(rango.corteSemana),
      isTrue,
      reason: 'un partido del sábado 16:00 es de esta semana',
    );
  });

  test('un lunes arranca una semana nueva', () {
    final rango = PublicHomeService.rangoProximos(DateTime(2026, 10, 5, 9));

    expect(rango.desde, DateTime(2026, 10, 5));
    expect(rango.corteSemana, DateTime(2026, 10, 12));
    expect(rango.hasta, DateTime(2026, 10, 19));
  });

  test('el domingo todavía es la semana en curso', () {
    final rango = PublicHomeService.rangoProximos(DateTime(2026, 10, 4, 20));

    expect(rango.corteSemana, DateTime(2026, 10, 5));
    expect(rango.hasta, DateTime(2026, 10, 12));
  });
}
