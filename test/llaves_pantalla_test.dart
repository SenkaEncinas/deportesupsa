// Cómo se ve la llave según el ancho de pantalla.
//
// El árbol se dibuja siempre: es lo que deja seguir de un vistazo cómo
// va avanzando cada equipo. Lo único que cambia es que en pantallas
// anchas se encoge para entrar entero, y en celular se deja a tamaño
// normal y se recorre con el dedo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/screens/reciclaje/app_bracket_view.dart';

PartidoModel _partido({
  required int llave,
  required String ronda,
  required String local,
  required String visitante,
  bool jugado = false,
}) {
  return PartidoModel.fromMap('p-$ronda-$llave', {
    'jornada': 1,
    'vuelta': 1,
    'rondaLlave': ronda,
    'llave': llave,
    'equipoLocalId': local.isEmpty ? '' : 'id-$local',
    'equipoLocalNombre': local,
    'equipoVisitanteId': visitante.isEmpty ? '' : 'id-$visitante',
    'equipoVisitanteNombre': visitante,
    'golesLocal': jugado ? 2 : null,
    'golesVisitante': jugado ? 1 : null,
    'resultadoRegistrado': jugado,
    'ganadorId': jugado ? 'id-$local' : null,
  });
}

/// Un cuadro de 16 con los octavos cargados, como el de la Copa UPSA.
List<MapEntry<String, List<PartidoModel>>> _cuadroDe16() {
  const nombres = [
    'Britanico',
    'Santa Ana',
    'Franco Boliviano',
    'Domingo Savio',
    'Juan Pablo II (M)',
    'Saint George',
    'San Agustin',
    'La Salle',
  ];
  const rivales = [
    'Cambridge',
    'Isabel Saavedra',
    'Cristo Rey',
    'San Lorenzo',
    'Espiritu Santo',
    'Marista',
    'Don Bosco B',
    'Bautista',
  ];

  return [
    MapEntry('Octavos de final', [
      for (var i = 0; i < 8; i++)
        _partido(
          llave: i + 1,
          ronda: 'octavos',
          local: nombres[i],
          visitante: rivales[i],
        ),
    ]),
  ];
}

Future<void> _pumpEn(WidgetTester tester, Size tamano) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AppBracketView(
            rondas: _cuadroDe16(),
            deporte: DeporteTipo.futbol,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('En celular', () {
    testWidgets('se dibuja el árbol, no una lista por rondas', (tester) async {
      await _pumpEn(tester, const Size(375, 812));

      expect(tester.takeException(), isNull);

      // Todas las rondas están en pantalla a la vez, aunque haya que
      // arrastrar para verlas: es lo que permite seguir el avance.
      expect(find.text('Octavos de final'), findsOneWidget);
      expect(find.text('Cuartos de final'), findsOneWidget);
      expect(find.text('Semifinales'), findsOneWidget);
      expect(find.text('Final'), findsOneWidget);
      expect(find.text('Campeón'), findsOneWidget);
    });

    testWidgets('se ven los cruces con sus equipos', (tester) async {
      await _pumpEn(tester, const Size(375, 812));

      expect(find.text('Britanico'), findsOneWidget);
      expect(find.text('Cambridge'), findsOneWidget);
    });

    testWidgets('no desborda en la pantalla más angosta', (tester) async {
      await _pumpEn(tester, const Size(320, 640));
      expect(tester.takeException(), isNull);
    });
  });

  group('En pantallas anchas', () {
    testWidgets('están todas las rondas a la vez', (tester) async {
      await _pumpEn(tester, const Size(1440, 1200));

      expect(tester.takeException(), isNull);
      expect(find.text('Octavos de final'), findsOneWidget);
      expect(find.text('Cuartos de final'), findsOneWidget);
      expect(find.text('Semifinales'), findsOneWidget);
      expect(find.text('Final'), findsOneWidget);
      expect(find.text('Campeón'), findsOneWidget);
    });

    testWidgets('el árbol entero entra en el ancho disponible', (tester) async {
      const ancho = 1440.0;
      await _pumpEn(tester, const Size(ancho, 1400));

      // Se encoge solo hasta entrar: nada del cuadro queda fuera de la
      // pantalla obligando a scrollear de costado.
      final tamano = tester.getSize(find.byType(AppBracketView));
      expect(tamano.width, lessThanOrEqualTo(ancho));

      final campeon = tester.getTopLeft(find.text('Campeón'));
      expect(
        campeon.dx,
        lessThan(ancho),
        reason: 'la columna del campeón tiene que quedar dentro de pantalla',
      );
    });

    testWidgets('en tablet tampoco desborda', (tester) async {
      await _pumpEn(tester, const Size(1024, 1200));
      expect(tester.takeException(), isNull);
    });
  });
}
