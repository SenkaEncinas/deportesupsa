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

    expect(find.text('Llaves eliminatorias'), findsWidgets);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Tabla de posiciones'), findsOneWidget);
    expect(find.text('Tabla por grupos'), findsOneWidget);
    expect(find.text('Clasificados a la fase final'), findsOneWidget);
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
}
