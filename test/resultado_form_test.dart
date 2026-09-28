// La pantalla de cargar resultado: que ofrezca los penales cuando hay
// empate. Es la parte que fallaba — el registro de resultados ya los
// aceptaba, pero la pantalla no los mostraba en los cruces del cuadro.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/screens/resultado_form_screen.dart';

const _avisoObligatorio =
    'Empate en un cruce eliminatorio: registrá los penales para definir quién avanza.';
const _avisoOpcional =
    'Empate. Si se definió por penales, cargalos; si no, dejalos vacíos y queda empate.';

CampeonatoModel _campeonato() {
  return CampeonatoModel.fromMap('c', {
    'nombre': 'CopaUpsa Prepromo',
    'deporte': DeporteTipo.futbol,
    'tipoCampeonato': TipoCampeonato.gruposEliminacion,
    'estado': CampeonatoEstado.activo,
    'faseActual': FaseCampeonato.eliminatoria,
    'configuracion': {
      'formato': TipoCampeonato.gruposEliminacion,
      'permiteEmpate': true,
    },
  });
}

/// Un cruce de octavos, como los que crea "Generar llaves".
PartidoModel _cruceDelCuadro() {
  return PartidoModel.fromMap('octavo-1', {
    'jornada': 1,
    'vuelta': 1,
    'equipoLocalId': 'britanico',
    'equipoLocalNombre': 'Britanico',
    'equipoVisitanteId': 'cambridge',
    'equipoVisitanteNombre': 'Cambridge',
    'estado': PartidoEstado.programado,
    'generadoPorSistema': true,
    'rondaLlave': 'octavos',
    'llave': 1,
  });
}

/// Un partido de la fase de grupos.
PartidoModel _deGrupo() {
  return PartidoModel.fromMap('grupo-1', {
    'jornada': 1,
    'vuelta': 1,
    'grupoId': 'Grupo A',
    'equipoLocalId': 'britanico',
    'equipoLocalNombre': 'Britanico',
    'equipoVisitanteId': 'cambridge',
    'equipoVisitanteNombre': 'Cambridge',
    'estado': PartidoEstado.programado,
    'generadoPorSistema': true,
  });
}

Future<void> _abrir(WidgetTester tester, PartidoModel partido) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ResultadoFormScreen(
        campeonatoId: 'c',
        partido: partido,
        campeonato: _campeonato(),
        firestore: FakeFirebaseFirestore(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Escribe el marcador. Los dos primeros campos de la pantalla son los
/// goles del local y del visitante (el nombre de cada equipo va arriba
/// del campo, no adentro, así que no sirve para ubicarlos).
Future<void> _marcador(WidgetTester tester, String local, String visita) async {
  final campos = find.byType(TextFormField);

  await tester.enterText(campos.at(0), local);
  await tester.enterText(campos.at(1), visita);
  await tester.pumpAndSettle();
}

void main() {
  group('Cruce del cuadro eliminatorio', () {
    testWidgets('con 3 a 3 aparecen los penales, obligatorios', (tester) async {
      await _abrir(tester, _cruceDelCuadro());
      await _marcador(tester, '3', '3');

      expect(find.text(_avisoObligatorio), findsOneWidget);
      expect(find.text('Penales Britanico'), findsOneWidget);
      expect(find.text('Penales Cambridge'), findsOneWidget);
    });

    testWidgets('si no es empate, no hay penales', (tester) async {
      await _abrir(tester, _cruceDelCuadro());
      await _marcador(tester, '3', '2');

      expect(find.text(_avisoObligatorio), findsNothing);
      expect(find.text('Penales Britanico'), findsNothing);
    });
  });

  group('Partido de la fase de grupos', () {
    testWidgets('con empate aparecen los penales, opcionales', (tester) async {
      await _abrir(tester, _deGrupo());
      await _marcador(tester, '3', '3');

      expect(find.text(_avisoOpcional), findsOneWidget);
      expect(find.text(_avisoObligatorio), findsNothing);
      expect(find.text('Penales Britanico'), findsOneWidget);
    });
  });
}
