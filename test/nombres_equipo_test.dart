// Al renombrar un equipo, el nombre nuevo tiene que llegar a todas las
// copias: partidos, jugadores, goles, tarjetas, ranking y tabla. Antes
// solo cambiaba en el equipo, y el fixture y los PDF seguían mostrando
// el nombre viejo.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/services/equipo_service.dart';

const _camp = 'camp-1';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    final camp = db.collection('campeonatos').doc(_camp);

    await camp.collection('equipos').doc('civil').set({
      'nombre': 'INGENIERIA CIVIL',
      'representante': 'rep',
      'estado': 'activo',
    });
    await camp.collection('equipos').doc('der').set({
      'nombre': 'DERECHO',
      'representante': 'rep',
      'estado': 'activo',
    });
    await camp.collection('partidos').doc('p1').set({
      'equipoLocalId': 'civil',
      'equipoLocalNombre': 'INGENIERIA CIVIL',
      'equipoVisitanteId': 'der',
      'equipoVisitanteNombre': 'DERECHO',
    });
    // Un cruce que todavía espera al ganador de otra llave: sin id, su
    // texto no se toca.
    await camp.collection('partidos').doc('p2').set({
      'equipoLocalId': '',
      'equipoLocalNombre': 'Ganador llave 1',
      'equipoVisitanteId': 'civil',
      'equipoVisitanteNombre': 'INGENIERIA CIVIL',
    });
    await camp.collection('jugadores').doc('j1').set({
      'equipoId': 'civil',
      'equipoNombre': 'INGENIERIA CIVIL',
    });
    await camp.collection('tabla_posiciones').doc('civil').set({
      'equipoId': 'civil',
      'equipoNombre': 'INGENIERIA CIVIL',
    });
  });

  test('el nombre nuevo llega a todas las copias', () async {
    final camp = db.collection('campeonatos').doc(_camp);
    await camp.collection('equipos').doc('civil').update({
      'nombre': 'ING. CIVIL',
    });

    final actualizados = await EquipoService(
      firestore: db,
    ).sincronizarNombresEquipos(_camp);

    expect(actualizados, 4);

    final p1 = (await camp.collection('partidos').doc('p1').get()).data()!;
    final p2 = (await camp.collection('partidos').doc('p2').get()).data()!;
    final j1 = (await camp.collection('jugadores').doc('j1').get()).data()!;
    final tabla = (await camp.collection('tabla_posiciones').doc('civil').get())
        .data()!;

    expect(p1['equipoLocalNombre'], 'ING. CIVIL');
    expect(p1['equipoVisitanteNombre'], 'DERECHO');
    expect(p2['equipoLocalNombre'], 'Ganador llave 1');
    expect(p2['equipoVisitanteNombre'], 'ING. CIVIL');
    expect(j1['equipoNombre'], 'ING. CIVIL');
    expect(tabla['equipoNombre'], 'ING. CIVIL');
  });

  test('si todo coincide no escribe nada', () async {
    final actualizados = await EquipoService(
      firestore: db,
    ).sincronizarNombresEquipos(_camp);

    expect(actualizados, 0);
  });
}
