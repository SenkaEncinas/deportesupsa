import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';

class PartidoService {
  PartidoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _campeonato(String campeonatoId) {
    return _db.collection('campeonatos').doc(campeonatoId);
  }

  CollectionReference<Map<String, dynamic>> _equipos(String campeonatoId) {
    return _campeonato(campeonatoId).collection('equipos');
  }

  CollectionReference<Map<String, dynamic>> _partidos(String campeonatoId) {
    return _campeonato(campeonatoId).collection('partidos');
  }

  Stream<List<PartidoModel>> streamPartidos(String campeonatoId) {
    return _partidos(campeonatoId)
        .orderBy('vuelta')
        .orderBy('jornada')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return PartidoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<PartidoModel>> streamPartidosProgramados(String campeonatoId) {
    return _partidos(campeonatoId)
        .where('estado', isEqualTo: PartidoEstado.programado)
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return PartidoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<PartidoModel>> getPartidos(String campeonatoId) async {
    final snap = await _partidos(campeonatoId)
        .orderBy('vuelta')
        .orderBy('jornada')
        .get();

    return snap.docs.map((doc) {
      return PartidoModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  /// Datos base de un partido nuevo. Incluye los campos nuevos con
  /// valores neutros para que todos los documentos queden completos.
  Map<String, dynamic> _partidoBase({
    required int jornada,
    required int vuelta,
    String? grupoId,
    required EquipoModel local,
    required EquipoModel visitante,
    required bool generadoPorSistema,
  }) {
    return {
      'jornada': jornada,
      'vuelta': vuelta,
      'grupoId': grupoId,
      'equipoLocalId': local.id,
      'equipoLocalNombre': local.nombre,
      'equipoVisitanteId': visitante.id,
      'equipoVisitanteNombre': visitante.nombre,
      'fechaHora': null,
      'estado': PartidoEstado.pendienteProgramacion,
      'golesLocal': null,
      'golesVisitante': null,
      'ganadorId': null,
      'empate': false,
      'resultadoRegistrado': false,
      'generadoPorSistema': generadoPorSistema,
      'tipoResultado': TipoResultado.normal,
      'observacionResultado': null,
      'penalesLocal': null,
      'penalesVisitante': null,
      'definidoPorPenales': false,
      'definidoPorProrroga': false,
      'tipoDefinicion': TipoDefinicion.normal,
      'sets': const [],
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _validarSinFixture(String campeonatoId) async {
    final partidosExistentes = await _partidos(campeonatoId).limit(1).get();

    if (partidosExistentes.docs.isNotEmpty) {
      throw Exception(
        'Este campeonato ya tiene partidos generados. No se puede generar otro fixture encima. Puedes agregar cruces manuales.',
      );
    }
  }

  Future<List<EquipoModel>> _equiposActivos(String campeonatoId) async {
    final equiposSnap = await _equipos(campeonatoId)
        .where('estado', isEqualTo: EquipoEstado.activo)
        .get();

    final equipos = equiposSnap.docs.map((doc) {
      return EquipoModel.fromMap(doc.id, doc.data());
    }).toList();

    if (equipos.length < 2) {
      throw Exception('Debe existir al menos 2 equipos activos.');
    }

    return equipos;
  }

  /// Genera el fixture aleatorio respetando el formato guardado en el
  /// campeonato (deporte-agnóstico: sirve para fútbol, vóley y básquet).
  ///
  /// - Liga solo ida / ida y vuelta: round-robin.
  /// - Liga + final / liga + playoffs: genera solo la fase de liga; la
  ///   fase final se crea con cruce manual cuando exista tabla final
  ///   (preparado para generación automática en una siguiente fase).
  /// - Fase de grupos / grupos + eliminación: genera la fase de grupos;
  ///   la eliminatoria se crea después con los clasificados.
  /// - Eliminación directa: genera la primera ronda con cruces aleatorios.
  Future<void> generarFixtureSegunFormato({
    required CampeonatoModel campeonato,
  }) async {
    await _validarSinFixture(campeonato.id);

    final equipos = await _equiposActivos(campeonato.id);
    final config = campeonato.configuracion;

    switch (campeonato.tipoCampeonato) {
      case TipoCampeonato.soloIda:
        await _generarRoundRobin(
          campeonatoId: campeonato.id,
          equipos: equipos,
          vueltas: 1,
        );
        return;

      case TipoCampeonato.idaVuelta:
        await _generarRoundRobin(
          campeonatoId: campeonato.id,
          equipos: equipos,
          vueltas: 2,
        );
        return;

      case TipoCampeonato.ligaFinal:
      case TipoCampeonato.ligaPlayoffs:
        // Se genera solo la liga. La final/playoffs se agregan luego con
        // cruce manual usando la tabla final (no se inventan clasificados).
        await _generarRoundRobin(
          campeonatoId: campeonato.id,
          equipos: equipos,
          vueltas: config.cantidadVueltas < 1 ? 1 : config.cantidadVueltas,
        );
        return;

      case TipoCampeonato.faseGrupos:
      case TipoCampeonato.gruposEliminacion:
        await _generarFaseGrupos(
          campeonatoId: campeonato.id,
          equipos: equipos,
          cantidadGrupos: config.cantidadGrupos < 2 ? 2 : config.cantidadGrupos,
          idaYVuelta: config.idaYVueltaEnGrupos,
          aleatorio: config.generaGruposAleatorios,
        );
        return;

      case TipoCampeonato.eliminacionDirecta:
        await _generarEliminacionDirecta(
          campeonatoId: campeonato.id,
          equipos: equipos,
          aleatorio: config.generaCrucesAleatorios,
        );
        return;

      default:
        // Tipo desconocido (documento antiguo o editado a mano):
        // se mantiene el comportamiento histórico de ida y vuelta.
        await _generarRoundRobin(
          campeonatoId: campeonato.id,
          equipos: equipos,
          vueltas: 2,
        );
    }
  }

  /// Round-robin clásico (todos contra todos) con 1 o más vueltas.
  Future<void> _generarRoundRobin({
    required String campeonatoId,
    required List<EquipoModel> equipos,
    required int vueltas,
    String? grupoId,
    WriteBatch? batchExterno,
  }) async {
    final random = Random();
    final equiposAleatorios = [...equipos]..shuffle(random);

    List<EquipoModel?> lista = [...equiposAleatorios];

    if (lista.length.isOdd) {
      lista.add(null); // descanso
    }

    final cantidadEquipos = lista.length;
    final cantidadJornadas = cantidadEquipos - 1;
    final partidosPorJornada = cantidadEquipos ~/ 2;

    final batch = batchExterno ?? _db.batch();

    final cruces = <({EquipoModel local, EquipoModel visitante, int jornada})>[];

    for (int jornada = 1; jornada <= cantidadJornadas; jornada++) {
      for (int i = 0; i < partidosPorJornada; i++) {
        final equipoA = lista[i];
        final equipoB = lista[cantidadEquipos - 1 - i];

        if (equipoA == null || equipoB == null) continue;

        final alternarLocalia = (jornada + i).isOdd;

        cruces.add((
          local: alternarLocalia ? equipoB : equipoA,
          visitante: alternarLocalia ? equipoA : equipoB,
          jornada: jornada,
        ));
      }

      final fijo = lista.first;
      final resto = lista.sublist(1);
      final ultimo = resto.removeLast();

      lista = [fijo, ultimo, ...resto];
    }

    for (int vuelta = 1; vuelta <= vueltas; vuelta++) {
      final invertir = vuelta.isEven;

      for (final cruce in cruces) {
        final doc = _partidos(campeonatoId).doc();

        batch.set(
          doc,
          _partidoBase(
            jornada: cruce.jornada,
            vuelta: vuelta,
            grupoId: grupoId,
            local: invertir ? cruce.visitante : cruce.local,
            visitante: invertir ? cruce.local : cruce.visitante,
            generadoPorSistema: true,
          ),
        );
      }
    }

    if (batchExterno == null) {
      await batch.commit();
    }
  }

  /// Fase de grupos: reparte los equipos en grupos "Grupo A", "Grupo B",
  /// etc. y genera round-robin dentro de cada grupo.
  Future<void> _generarFaseGrupos({
    required String campeonatoId,
    required List<EquipoModel> equipos,
    required int cantidadGrupos,
    required bool idaYVuelta,
    required bool aleatorio,
  }) async {
    if (cantidadGrupos < 2) {
      throw Exception('La cantidad de grupos debe ser al menos 2.');
    }

    if (equipos.length < cantidadGrupos * 2) {
      throw Exception(
        'Se necesitan al menos ${cantidadGrupos * 2} equipos activos para formar $cantidadGrupos grupos de mínimo 2 equipos.',
      );
    }

    final listaEquipos = [...equipos];

    if (aleatorio) {
      listaEquipos.shuffle(Random());
    }

    // Distribución tipo serpiente para que los grupos queden parejos.
    final grupos = List.generate(cantidadGrupos, (_) => <EquipoModel>[]);

    for (int i = 0; i < listaEquipos.length; i++) {
      grupos[i % cantidadGrupos].add(listaEquipos[i]);
    }

    final batch = _db.batch();

    for (int g = 0; g < grupos.length; g++) {
      final nombreGrupo = 'Grupo ${String.fromCharCode(65 + g)}';

      await _generarRoundRobin(
        campeonatoId: campeonatoId,
        equipos: grupos[g],
        vueltas: idaYVuelta ? 2 : 1,
        grupoId: nombreGrupo,
        batchExterno: batch,
      );
    }

    await batch.commit();
  }

  /// Eliminación directa: primera ronda con cruces aleatorios.
  /// Las rondas siguientes se agregan con cruce manual cuando existan
  /// ganadores (preparado para generación automática en una fase futura).
  Future<void> _generarEliminacionDirecta({
    required String campeonatoId,
    required List<EquipoModel> equipos,
    required bool aleatorio,
  }) async {
    if (equipos.length.isOdd) {
      throw Exception(
        'La eliminación directa necesita una cantidad par de equipos (hay ${equipos.length}). Ajusta los equipos activos o crea los cruces manualmente.',
      );
    }

    final lista = [...equipos];

    if (aleatorio) {
      lista.shuffle(Random());
    }

    final batch = _db.batch();

    for (int i = 0; i < lista.length; i += 2) {
      final doc = _partidos(campeonatoId).doc();

      batch.set(
        doc,
        _partidoBase(
          jornada: 1,
          vuelta: 1,
          grupoId: null,
          local: lista[i],
          visitante: lista[i + 1],
          generadoPorSistema: true,
        ),
      );
    }

    await batch.commit();
  }

  /// Generador histórico (ida y vuelta). Se mantiene por compatibilidad;
  /// internamente usa el mismo round-robin nuevo.
  Future<void> generarFixtureIdaVueltaAleatorio({
    required String campeonatoId,
  }) async {
    await _validarSinFixture(campeonatoId);

    final equipos = await _equiposActivos(campeonatoId);

    await _generarRoundRobin(
      campeonatoId: campeonatoId,
      equipos: equipos,
      vueltas: 2,
    );
  }

  Future<void> crearCruceManual({
    required String campeonatoId,
    required EquipoModel equipoLocal,
    required EquipoModel equipoVisitante,
    required int jornada,
    required bool idaYVuelta,
    String? grupoId,
  }) async {
    if (equipoLocal.id == equipoVisitante.id) {
      throw Exception('Un equipo no puede jugar contra sí mismo.');
    }

    if (jornada <= 0) {
      throw Exception('La jornada debe ser mayor a cero.');
    }

    final existentesSnap = await _partidos(campeonatoId)
        .where('jornada', isEqualTo: jornada)
        .get();

    for (final doc in existentesSnap.docs) {
      final partido = PartidoModel.fromMap(doc.id, doc.data());

      final mismoCruce =
          (partido.equipoLocalId == equipoLocal.id &&
                  partido.equipoVisitanteId == equipoVisitante.id) ||
              (partido.equipoLocalId == equipoVisitante.id &&
                  partido.equipoVisitanteId == equipoLocal.id);

      if (mismoCruce) {
        throw Exception(
          'Ese cruce ya existe en la jornada $jornada.',
        );
      }
    }

    final batch = _db.batch();

    final idaDoc = _partidos(campeonatoId).doc();

    batch.set(
      idaDoc,
      _partidoBase(
        jornada: jornada,
        vuelta: 1,
        grupoId: grupoId,
        local: equipoLocal,
        visitante: equipoVisitante,
        generadoPorSistema: false,
      ),
    );

    if (idaYVuelta) {
      final vueltaDoc = _partidos(campeonatoId).doc();

      batch.set(
        vueltaDoc,
        _partidoBase(
          jornada: jornada,
          vuelta: 2,
          grupoId: grupoId,
          local: equipoVisitante,
          visitante: equipoLocal,
          generadoPorSistema: false,
        ),
      );
    }

    await batch.commit();
  }

  Future<void> programarPartido({
    required String campeonatoId,
    required String partidoId,
    required DateTime fechaHora,
  }) async {
    final mismaFecha = await _partidos(campeonatoId)
        .where('fechaHora', isEqualTo: Timestamp.fromDate(fechaHora))
        .get();

    for (final doc in mismaFecha.docs) {
      if (doc.id != partidoId) {
        throw Exception(
          'Ya existe otro partido programado exactamente en esa fecha y hora.',
        );
      }
    }

    await _partidos(campeonatoId).doc(partidoId).update({
      'fechaHora': Timestamp.fromDate(fechaHora),
      'estado': PartidoEstado.programado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> suspenderPartido({
    required String campeonatoId,
    required String partidoId,
    required String observacion,
  }) async {
    if (observacion.trim().isEmpty) {
      throw Exception('La observación es obligatoria para suspender un partido.');
    }

    await _partidos(campeonatoId).doc(partidoId).update({
      'estado': PartidoEstado.suspendido,
      'observacionResultado': observacion.trim(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reprogramarPartido({
    required String campeonatoId,
    required String partidoId,
    required DateTime nuevaFechaHora,
  }) async {
    await programarPartido(
      campeonatoId: campeonatoId,
      partidoId: partidoId,
      fechaHora: nuevaFechaHora,
    );
  }
}
