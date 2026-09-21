// Tests del armado del cuadro eliminatorio.
//
// La referencia es el cuadro de la Copa UPSA 2026 (fútbol pre promo
// varones), que con 16 clasificados tiene que quedar así:
//
//   Octavos:   1-16, 2-15, 3-14, 4-13, 5-12, 6-11, 7-10, 8-9
//   Cuartos:   L1-L8, L2-L7, L3-L6, L4-L5
//   Semifinal: L1-L4, L2-L3
//   Final:     L1-L2

import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/utils/llaves.dart';

/// Los cruces de una ronda, como pares legibles de siembras o de llaves
/// de la ronda anterior.
List<List<int>> _paresDeRonda(List<CruceLlave> cuadro, String ronda) {
  final cruces = cuadro.where((cruce) => cruce.ronda == ronda).toList()
    ..sort((a, b) => a.llave.compareTo(b.llave));

  return cruces
      .map(
        (cruce) => cruce.esPrimeraRonda
            ? [cruce.siembraLocal!, cruce.siembraVisitante!]
            : [cruce.vieneDeLocal!, cruce.vieneDeVisitante!],
      )
      .toList();
}

void main() {
  group('Cuadro de 16 clasificados', () {
    final cuadro = Llaves.estructura(16);

    test('octavos siembra 1-16, 2-15, ... 8-9', () {
      expect(_paresDeRonda(cuadro, RondaLlave.octavos), [
        [1, 16],
        [2, 15],
        [3, 14],
        [4, 13],
        [5, 12],
        [6, 11],
        [7, 10],
        [8, 9],
      ]);
    });

    test('cuartos cruza las llaves 1-8, 2-7, 3-6, 4-5', () {
      expect(_paresDeRonda(cuadro, RondaLlave.cuartos), [
        [1, 8],
        [2, 7],
        [3, 6],
        [4, 5],
      ]);
    });

    test('semifinal cruza las llaves 1-4 y 2-3', () {
      expect(_paresDeRonda(cuadro, RondaLlave.semifinal), [
        [1, 4],
        [2, 3],
      ]);
    });

    test('la final cruza las llaves 1-2', () {
      expect(_paresDeRonda(cuadro, RondaLlave.finalRonda), [
        [1, 2],
      ]);
    });

    test('el cuadro tiene 15 cruces: 8 + 4 + 2 + 1', () {
      expect(cuadro.length, 15);
    });

    test('el 1° y el 2° solo se pueden cruzar en la final', () {
      // Se simula que siempre gana el mejor sembrado y se mira en qué
      // ronda se encuentran las siembras 1 y 2.
      final ganadorPorLlave = <int, Map<int, int>>{};

      for (final cruce in cuadro.where((c) => c.esPrimeraRonda)) {
        ganadorPorLlave
            .putIfAbsent(0, () => {})[cruce.llave] = cruce.siembraLocal! <
                cruce.siembraVisitante!
            ? cruce.siembraLocal!
            : cruce.siembraVisitante!;
      }

      String? rondaDelClasico;

      for (final ronda in [
        RondaLlave.cuartos,
        RondaLlave.semifinal,
        RondaLlave.finalRonda,
      ]) {
        final indice = RondaLlave.orden(ronda) - RondaLlave.orden(
          RondaLlave.octavos,
        );

        final previos = ganadorPorLlave[indice - 1]!;
        final actuales = <int, int>{};

        for (final cruce in cuadro.where((c) => c.ronda == ronda)) {
          final local = previos[cruce.vieneDeLocal]!;
          final visitante = previos[cruce.vieneDeVisitante]!;

          if ({local, visitante}.containsAll({1, 2})) {
            rondaDelClasico ??= ronda;
          }

          actuales[cruce.llave] = local < visitante ? local : visitante;
        }

        ganadorPorLlave[indice] = actuales;
      }

      expect(rondaDelClasico, RondaLlave.finalRonda);
    });
  });

  group('Orden de dibujo', () {
    test('los cruces vecinos del dibujo alimentan la misma llave', () {
      for (final cantidad in [2, 4, 8, 16]) {
        final orden = Llaves.ordenVisual(cantidad);

        expect(orden.length, cantidad);
        expect(orden.toSet().length, cantidad, reason: 'sin repetidos');

        for (var i = 0; i + 1 < cantidad; i += 2) {
          expect(
            orden[i] + orden[i + 1],
            cantidad + 1,
            reason:
                'en un cuadro de $cantidad llaves, las llaves '
                '${orden[i]} y ${orden[i + 1]} tienen que cruzarse',
          );
        }
      }
    });
  });

  group('Cuadros que no son potencia de 2', () {
    test('12 clasificados juegan un cuadro de 16 con 4 libres', () {
      final cuadro = Llaves.estructura(12);

      expect(Llaves.tamanoCuadro(12), 16);

      final octavos = cuadro
          .where((cruce) => cruce.ronda == RondaLlave.octavos)
          .toList();

      // Los libres le tocan a los mejores sembrados: las siembras 13 a
      // 16 no existen, así que 1, 2, 3 y 4 pasan directo.
      final libres = octavos
          .where((cruce) => cruce.siembraVisitante! > 12)
          .map((cruce) => cruce.siembraLocal)
          .toList();

      expect(libres, [1, 2, 3, 4]);
    });

    test('6 clasificados juegan un cuadro de 8 con 2 libres', () {
      final cuadro = Llaves.estructura(6);

      expect(Llaves.tamanoCuadro(6), 8);
      expect(_paresDeRonda(cuadro, RondaLlave.cuartos), [
        [1, 8],
        [2, 7],
        [3, 6],
        [4, 5],
      ]);
    });
  });

  group('A dónde pasa cada ganador', () {
    test('en octavos, las llaves 1 y 8 caen en el mismo cuarto', () {
      expect(Llaves.llaveSiguiente(llave: 1, cantidadLlaves: 8), 1);
      expect(Llaves.llaveSiguiente(llave: 8, cantidadLlaves: 8), 1);
      expect(Llaves.llaveSiguiente(llave: 4, cantidadLlaves: 8), 4);
      expect(Llaves.llaveSiguiente(llave: 5, cantidadLlaves: 8), 4);
    });

    test('la final no tiene ronda siguiente', () {
      expect(Llaves.llaveSiguiente(llave: 1, cantidadLlaves: 1), isNull);
    });
  });
}
