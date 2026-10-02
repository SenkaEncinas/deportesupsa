// La navegación móvil no cambia al activarse la fase eliminatoria.
//
// Antes, al pasar a eliminatoria, la pantalla se reemplazaba entera y
// el sidebar desaparecía: el usuario perdía de un día para el otro la
// forma de moverse por el campeonato. Ahora la llave es una sección
// más del mismo menú.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/screens/championship_detail_screen.dart';
import 'package:futsal/services/public_home_service.dart';

CampeonatoModel _campeonato({required String fase}) {
  return CampeonatoModel.fromMap('camp-1', {
    'nombre': 'CopaUpsa Prepromo',
    'deporte': DeporteTipo.futbol,
    'tipoCampeonato': TipoCampeonato.gruposEliminacion,
    'estado': CampeonatoEstado.activo,
    'faseActual': fase,
    'temporada': '02/2026',
    'cancha': 'Cancha UPSA',
    'configuracion': {'formato': TipoCampeonato.gruposEliminacion},
  });
}

Future<void> _pumpMovil(WidgetTester tester, CampeonatoModel campeonato) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ChampionshipDetailScreen(
        campeonato: campeonato,
        service: PublicHomeService(firestore: FakeFirebaseFirestore()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('en fase de grupos hay sidebar', (tester) async {
    await _pumpMovil(tester, _campeonato(fase: FaseCampeonato.grupos));

    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
  });

  testWidgets('en fase eliminatoria el sidebar sigue estando', (tester) async {
    await _pumpMovil(tester, _campeonato(fase: FaseCampeonato.eliminatoria));

    expect(
      find.byIcon(Icons.menu_rounded),
      findsOneWidget,
      reason: 'la navegación no puede cambiar al activar la eliminatoria',
    );
  });

  testWidgets('en eliminatoria se abre en la sección de llaves', (
    tester,
  ) async {
    await _pumpMovil(tester, _campeonato(fase: FaseCampeonato.eliminatoria));

    expect(find.text('Llaves eliminatorias'), findsOneWidget);
  });

  testWidgets('el menú ofrece llaves, resumen, tabla y clasificados', (
    tester,
  ) async {
    await _pumpMovil(tester, _campeonato(fase: FaseCampeonato.eliminatoria));

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    // Se busca dentro del menú: algunos de estos títulos también
    // aparecen en la pantalla de atrás (la tabla de clasificados, por
    // ejemplo, se muestra debajo del cuadro).
    Finder enMenu(String texto) =>
        find.descendant(of: find.byType(Drawer), matching: find.text(texto));

    expect(enMenu('Llaves eliminatorias'), findsOneWidget);
    expect(enMenu('Resumen'), findsOneWidget);
    expect(enMenu('Tabla de posiciones'), findsOneWidget);
    expect(enMenu('Tabla por grupos'), findsOneWidget);
    expect(enMenu('Clasificados a la fase final'), findsOneWidget);
  });

  testWidgets('en fase de grupos el menú todavía no ofrece las llaves', (
    tester,
  ) async {
    await _pumpMovil(tester, _campeonato(fase: FaseCampeonato.grupos));

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Llaves eliminatorias'), findsNothing);
    expect(find.text('Resumen'), findsOneWidget);
  });

  testWidgets('se puede volver al resumen desde el menú', (tester) async {
    await _pumpMovil(tester, _campeonato(fase: FaseCampeonato.eliminatoria));

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resumen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CopaUpsa Prepromo'), findsWidgets);
  });

  testWidgets('en eliminatoria la pantalla principal no muestra los '
      'clasificados', (tester) async {
    await _pumpMovil(tester, _campeonato(fase: FaseCampeonato.eliminatoria));

    // Los clasificados y la tabla se abren desde el menú: en la sección
    // de llaves solo van el cuadro, los próximos partidos y los
    // resultados.
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Clasificados a la fase final'), findsNothing);
    expect(find.text('Próximos partidos'), findsOneWidget);
    expect(find.text('Últimos resultados'), findsOneWidget);
  });

  testWidgets('en escritorio la eliminatoria tiene barra lateral', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ChampionshipDetailScreen(
          campeonato: _campeonato(fase: FaseCampeonato.eliminatoria),
          service: PublicHomeService(firestore: FakeFirebaseFirestore()),
        ),
      ),
    );
    await tester.pump();

    // Arranca en las llaves, con la tabla y los clasificados en la barra.
    expect(find.text('Próximos partidos'), findsOneWidget);
    expect(find.text('Tabla por grupos'), findsOneWidget);

    await tester.tap(find.text('Clasificados a la fase final'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Próximos partidos'), findsNothing);
  });
}
