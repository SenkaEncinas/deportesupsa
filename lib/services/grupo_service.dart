import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipo_model.dart';
import '../models/grupo_model.dart';

/// Gestiona la inscripción de equipos en grupos ("Grupo A", "Grupo B"...)
/// antes de generar el fixture. Los grupos se guardan en la subcolección
/// `grupos` de cada campeonato usando [GrupoModel], que existía en el
/// modelo pero no se persistía en ningún lado: la fase de grupos se
/// armaba "al vuelo" dentro de PartidoService y se perdía la asignación.
class GrupoService {
  GrupoService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _campeonato(String campeonatoId) {
    return _db.collection('campeonatos').doc(campeonatoId);
  }

  CollectionReference<Map<String, dynamic>> _grupos(String campeonatoId) {
    return _campeonato(campeonatoId).collection('grupos');
  }

  Stream<List<GrupoModel>> streamGrupos(String campeonatoId) {
    return _grupos(campeonatoId).orderBy('orden').snapshots().map((snap) {
      return snap.docs.map((doc) {
        return GrupoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<GrupoModel>> getGrupos(String campeonatoId) async {
    final snap = await _grupos(campeonatoId).orderBy('orden').get();

    return snap.docs.map((doc) {
      return GrupoModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  String nombreGrupo(int orden) => 'Grupo ${String.fromCharCode(65 + orden)}';

  /// Genera los grupos automáticamente repartiendo los equipos activos
  /// en distribución tipo serpiente (o aleatoria) y los persiste. Borra
  /// cualquier agrupación previa que no tenga fixture generado todavía.
  Future<void> generarGruposAutomaticos({
    required String campeonatoId,
    required List<EquipoModel> equiposActivos,
    required int cantidadGrupos,
    required bool aleatorio,
  }) async {
    if (cantidadGrupos < 2) {
      throw Exception('La cantidad de grupos debe ser al menos 2.');
    }

    if (equiposActivos.length < cantidadGrupos * 2) {
      throw Exception(
        'Se necesitan al menos ${cantidadGrupos * 2} equipos activos para formar $cantidadGrupos grupos de mínimo 2 equipos.',
      );
    }

    final listaEquipos = [...equiposActivos];

    if (aleatorio) {
      listaEquipos.shuffle(Random());
    } else {
      listaEquipos.sort((a, b) => a.nombre.compareTo(b.nombre));
    }

    final grupos = List.generate(cantidadGrupos, (_) => <String>[]);

    for (int i = 0; i < listaEquipos.length; i++) {
      grupos[i % cantidadGrupos].add(listaEquipos[i].id);
    }

    await _reemplazarGrupos(
      campeonatoId: campeonatoId,
      equipoIdsPorGrupo: grupos,
    );
  }

  Future<void> _reemplazarGrupos({
    required String campeonatoId,
    required List<List<String>> equipoIdsPorGrupo,
  }) async {
    final existentes = await _grupos(campeonatoId).get();

    final batch = _db.batch();

    for (final doc in existentes.docs) {
      batch.delete(doc.reference);
    }

    for (int g = 0; g < equipoIdsPorGrupo.length; g++) {
      final doc = _grupos(campeonatoId).doc();

      final grupo = GrupoModel(
        id: doc.id,
        nombre: nombreGrupo(g),
        orden: g,
        equipoIds: equipoIdsPorGrupo[g],
        generadoPorSistema: true,
        fechaCreacion: DateTime.now(),
      );

      batch.set(doc, grupo.toMap());
    }

    await batch.commit();
  }

  /// Crea grupos vacíos ("Grupo A"..) para armarlos a mano desde cero.
  Future<void> crearGruposVacios({
    required String campeonatoId,
    required int cantidadGrupos,
  }) async {
    if (cantidadGrupos < 2) {
      throw Exception('La cantidad de grupos debe ser al menos 2.');
    }

    await _reemplazarGrupos(
      campeonatoId: campeonatoId,
      equipoIdsPorGrupo: List.generate(cantidadGrupos, (_) => <String>[]),
    );
  }

  /// Mueve (o inscribe) un equipo a [grupoDestinoId], quitándolo de
  /// cualquier otro grupo en el que estuviera.
  Future<void> asignarEquipoAGrupo({
    required String campeonatoId,
    required String equipoId,
    required String grupoDestinoId,
  }) async {
    final grupos = await getGrupos(campeonatoId);
    GrupoModel? destino;

    for (final grupo in grupos) {
      if (grupo.id == grupoDestinoId) {
        destino = grupo;
        break;
      }
    }

    if (destino == null) {
      throw Exception('El grupo seleccionado no existe.');
    }

    final batch = _db.batch();

    for (final grupo in grupos) {
      if (!grupo.equipoIds.contains(equipoId) && grupo.id != destino.id) {
        continue;
      }

      final nuevosIds = grupo.id == destino.id
          ? [...grupo.equipoIds.where((id) => id != equipoId), equipoId]
          : grupo.equipoIds.where((id) => id != equipoId).toList();

      batch.update(_grupos(campeonatoId).doc(grupo.id), {
        'equipoIds': nuevosIds,
        'generadoPorSistema': false,
      });
    }

    await batch.commit();
  }

  Future<void> quitarEquipoDeGrupos({
    required String campeonatoId,
    required String equipoId,
  }) async {
    final grupos = await getGrupos(campeonatoId);

    final batch = _db.batch();
    var huboCambios = false;

    for (final grupo in grupos) {
      if (!grupo.equipoIds.contains(equipoId)) continue;

      huboCambios = true;
      batch.update(_grupos(campeonatoId).doc(grupo.id), {
        'equipoIds': grupo.equipoIds.where((id) => id != equipoId).toList(),
        'generadoPorSistema': false,
      });
    }

    if (huboCambios) {
      await batch.commit();
    }
  }

  Future<void> eliminarGrupos(String campeonatoId) async {
    final existentes = await _grupos(campeonatoId).get();

    final batch = _db.batch();

    for (final doc in existentes.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
