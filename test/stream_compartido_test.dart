// La vista pública comparte una sola conexión por dato entre todas sus
// secciones. Estos tests fijan las dos promesas de [StreamCompartido]:
// la fuente se abre una sola vez, y quien llega tarde recibe enseguida
// el último valor (sin volver a "cargando").

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/services/public_home_service.dart';
import 'package:futsal/utils/stream_compartido.dart';

PartidoModel _partido(
  String id, {
  required String estado,
  DateTime? fecha,
  DateTime? actualizado,
}) {
  return PartidoModel.fromMap(id, {
    'jornada': 1,
    'vuelta': 1,
    'equipoLocalId': 'a',
    'equipoLocalNombre': 'A',
    'equipoVisitanteId': 'b',
    'equipoVisitanteNombre': 'B',
    'estado': estado,
    'fechaHora': fecha,
    'fechaActualizacion': actualizado,
  });
}

void main() {
  test('la fuente se abre una sola vez aunque haya varios oyentes', () async {
    var aperturas = 0;
    final fuente = StreamController<int>.broadcast();
    final compartido = StreamCompartido<int>(() {
      aperturas++;
      return fuente.stream;
    });

    final a = <int>[];
    final b = <int>[];
    compartido.stream.listen(a.add);
    compartido.stream.listen(b.add);

    fuente.add(1);
    await Future<void>.delayed(Duration.zero);

    expect(aperturas, 1);
    expect(a, [1]);
    expect(b, [1]);

    await compartido.cerrar();
    await fuente.close();
  });

  test('quien se suma tarde recibe el último valor al instante', () async {
    final fuente = StreamController<int>.broadcast();
    final compartido = StreamCompartido<int>(() => fuente.stream);

    compartido.stream.listen((_) {});
    fuente.add(7);
    await Future<void>.delayed(Duration.zero);

    final tarde = <int>[];
    compartido.stream.listen(tarde.add);
    await Future<void>.delayed(Duration.zero);

    expect(tarde, [7]);

    await compartido.cerrar();
    await fuente.close();
  });

  test('próximos: programados de estas dos semanas, por fecha', () {
    final ahora = DateTime(2026, 10, 1, 12); // jueves
    final lista = PublicHomeService.proximos([
      _partido(
        'tarde',
        estado: PartidoEstado.programado,
        fecha: DateTime(2026, 10, 9, 18),
      ),
      _partido(
        'hoy',
        estado: PartidoEstado.programado,
        fecha: DateTime(2026, 10, 1, 8),
      ),
      _partido(
        'lejos',
        estado: PartidoEstado.programado,
        fecha: DateTime(2026, 10, 20),
      ),
      _partido(
        'ayer',
        estado: PartidoEstado.programado,
        fecha: DateTime(2026, 9, 30),
      ),
      _partido(
        'jugado',
        estado: PartidoEstado.finalizado,
        fecha: DateTime(2026, 10, 2),
      ),
    ], ahora);

    expect(lista.map((p) => p.id).toList(), ['hoy', 'tarde']);
  });

  test('últimos resultados: los 5 más recientes', () {
    final lista = PublicHomeService.ultimosResultados([
      for (var i = 1; i <= 7; i++)
        _partido(
          'p$i',
          estado: PartidoEstado.finalizado,
          actualizado: DateTime(2026, 10, i),
        ),
      _partido('sin jugar', estado: PartidoEstado.programado),
    ]);

    expect(lista.map((p) => p.id).toList(), ['p7', 'p6', 'p5', 'p4', 'p3']);
  });
}
