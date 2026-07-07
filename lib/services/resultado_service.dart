import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/gol_model.dart';
import '../models/jugador_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';

class GolJugadorInput {
  final String equipoId;
  final String equipoNombre;
  final String jugadorId;
  final String jugadorNombre;
  final int cantidad;

  const GolJugadorInput({
    required this.equipoId,
    required this.equipoNombre,
    required this.jugadorId,
    required this.jugadorNombre,
    required this.cantidad,
  });
}

class TarjetaJugadorInput {
  final String equipoId;
  final String equipoNombre;
  final String jugadorId;
  final String jugadorNombre;
  final int amarillas;
  final int rojas;
  final String? motivo;

  const TarjetaJugadorInput({
    required this.equipoId,
    required this.equipoNombre,
    required this.jugadorId,
    required this.jugadorNombre,
    required this.amarillas,
    required this.rojas,
    this.motivo,
  });
}

class ResultadoService {
  ResultadoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _campeonato(String campeonatoId) {
    return _db.collection('campeonatos').doc(campeonatoId);
  }

  CollectionReference<Map<String, dynamic>> _equipos(String campeonatoId) {
    return _campeonato(campeonatoId).collection('equipos');
  }

  CollectionReference<Map<String, dynamic>> _jugadores(String campeonatoId) {
    return _campeonato(campeonatoId).collection('jugadores');
  }

  CollectionReference<Map<String, dynamic>> _partidos(String campeonatoId) {
    return _campeonato(campeonatoId).collection('partidos');
  }

  CollectionReference<Map<String, dynamic>> _goles(String campeonatoId) {
    return _campeonato(campeonatoId).collection('goles');
  }

  CollectionReference<Map<String, dynamic>> _tarjetas(String campeonatoId) {
    return _campeonato(campeonatoId).collection('tarjetas');
  }

  CollectionReference<Map<String, dynamic>> _tabla(String campeonatoId) {
    return _campeonato(campeonatoId).collection('tabla_posiciones');
  }

  CollectionReference<Map<String, dynamic>> _ranking(String campeonatoId) {
    return _campeonato(campeonatoId).collection('ranking_goleadores');
  }

  Future<void> registrarResultado({
    required String campeonatoId,
    required String partidoId,
    required int golesLocal,
    required int golesVisitante,
    required List<GolJugadorInput> golesJugadores,
    List<TarjetaJugadorInput> tarjetasJugadores = const [],
    String tipoResultado = TipoResultado.normal,
    String? observacionResultado,
    required String usuarioId,
  }) async {
    if (golesLocal < 0 || golesVisitante < 0) {
      throw Exception('Los goles no pueden ser negativos.');
    }

    final campeonatoDoc = await _campeonato(campeonatoId).get();

    if (!campeonatoDoc.exists || campeonatoDoc.data() == null) {
      throw Exception('El campeonato no existe.');
    }

    final campeonato = CampeonatoModel.fromMap(
      campeonatoDoc.id,
      campeonatoDoc.data()!,
    );

    if (!campeonato.estaActivo) {
      throw Exception(
        'Solo se pueden registrar resultados en campeonatos activos.',
      );
    }

    final partidoDoc = await _partidos(campeonatoId).doc(partidoId).get();

    if (!partidoDoc.exists || partidoDoc.data() == null) {
      throw Exception('El partido no existe.');
    }

    final partido = PartidoModel.fromMap(partidoDoc.id, partidoDoc.data()!);

    final esAdministrativo = tipoResultado == TipoResultado.walkover ||
        tipoResultado == TipoResultado.sancion;

    if (esAdministrativo &&
        (observacionResultado == null || observacionResultado.trim().isEmpty)) {
      throw Exception(
        'La observación es obligatoria para resultados por ausencia o sanción.',
      );
    }

    if (esAdministrativo && golesJugadores.isNotEmpty) {
      throw Exception(
        'Los resultados administrativos no deben registrar goles por jugador.',
      );
    }

    if (esAdministrativo && tarjetasJugadores.isNotEmpty) {
      throw Exception(
        'Los resultados administrativos no deben registrar tarjetas por jugador.',
      );
    }

    if (tipoResultado == TipoResultado.normal) {
      final sumaLocal = golesJugadores
          .where((gol) => gol.equipoId == partido.equipoLocalId)
          .fold<int>(0, (total, gol) => total + gol.cantidad);

      final sumaVisitante = golesJugadores
          .where((gol) => gol.equipoId == partido.equipoVisitanteId)
          .fold<int>(0, (total, gol) => total + gol.cantidad);

      if (sumaLocal != golesLocal) {
        throw Exception(
          'Los goles registrados para ${partido.equipoLocalNombre} no coinciden con el resultado final.',
        );
      }

      if (sumaVisitante != golesVisitante) {
        throw Exception(
          'Los goles registrados para ${partido.equipoVisitanteNombre} no coinciden con el resultado final.',
        );
      }

      for (final gol in golesJugadores) {
        if (gol.cantidad <= 0) {
          throw Exception(
            'La cantidad de goles por jugador debe ser mayor a cero.',
          );
        }

        if (gol.equipoId != partido.equipoLocalId &&
            gol.equipoId != partido.equipoVisitanteId) {
          throw Exception(
            'Hay un gol registrado para un equipo que no juega este partido.',
          );
        }
      }

      for (final tarjeta in tarjetasJugadores) {
        if (tarjeta.amarillas < 0 || tarjeta.rojas < 0) {
          throw Exception('Las tarjetas no pueden tener valores negativos.');
        }

        if (tarjeta.amarillas == 0 && tarjeta.rojas == 0) {
          throw Exception(
            'Cada registro de tarjeta debe tener al menos una amarilla o una roja.',
          );
        }

        if (tarjeta.equipoId != partido.equipoLocalId &&
            tarjeta.equipoId != partido.equipoVisitanteId) {
          throw Exception(
            'Hay una tarjeta registrada para un equipo que no juega este partido.',
          );
        }
      }
    }

    final empate = golesLocal == golesVisitante;
    String? ganadorId;

    if (!empate) {
      ganadorId = golesLocal > golesVisitante
          ? partido.equipoLocalId
          : partido.equipoVisitanteId;
    }

    final golesAnteriores = await _goles(campeonatoId)
        .where('partidoId', isEqualTo: partidoId)
        .get();

    final tarjetasAnteriores = await _tarjetas(campeonatoId)
        .where('partidoId', isEqualTo: partidoId)
        .get();

    final batch = _db.batch();

    for (final doc in golesAnteriores.docs) {
      batch.delete(doc.reference);
    }

    for (final doc in tarjetasAnteriores.docs) {
      batch.delete(doc.reference);
    }

    batch.update(_partidos(campeonatoId).doc(partidoId), {
      'estado': PartidoEstado.finalizado,
      'golesLocal': golesLocal,
      'golesVisitante': golesVisitante,
      'ganadorId': ganadorId,
      'empate': empate,
      'resultadoRegistrado': true,
      'tipoResultado': tipoResultado,
      'observacionResultado': observacionResultado?.trim(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (tipoResultado == TipoResultado.normal) {
      for (final gol in golesJugadores) {
        final golDoc = _goles(campeonatoId).doc();

        batch.set(golDoc, {
          'partidoId': partidoId,
          'equipoId': gol.equipoId,
          'equipoNombre': gol.equipoNombre,
          'jugadorId': gol.jugadorId,
          'jugadorNombre': gol.jugadorNombre,
          'cantidad': gol.cantidad,
          'fechaRegistro': FieldValue.serverTimestamp(),
          'registradoPor': usuarioId,
        });
      }

      for (final tarjeta in tarjetasJugadores) {
        final tarjetaDoc = _tarjetas(campeonatoId).doc();

        batch.set(tarjetaDoc, {
          'partidoId': partidoId,
          'equipoId': tarjeta.equipoId,
          'equipoNombre': tarjeta.equipoNombre,
          'jugadorId': tarjeta.jugadorId,
          'jugadorNombre': tarjeta.jugadorNombre,
          'amarillas': tarjeta.amarillas,
          'rojas': tarjeta.rojas,
          'motivo': tarjeta.motivo?.trim(),
          'fechaRegistro': FieldValue.serverTimestamp(),
          'registradoPor': usuarioId,
        });
      }
    }

    await batch.commit();

    await recalcularTablaYRanking(campeonatoId);
  }

  Future<void> recalcularTablaYRanking(String campeonatoId) async {
    await _recalcularTabla(campeonatoId);
    await _recalcularRanking(campeonatoId);
  }

  Future<void> _recalcularTabla(String campeonatoId) async {
    final campeonato = await _campeonato(campeonatoId).get();

    if (!campeonato.exists || campeonato.data() == null) {
      throw Exception('El campeonato no existe.');
    }

    final campeonatoModel = CampeonatoModel.fromMap(
      campeonato.id,
      campeonato.data()!,
    );

    final equiposSnap = await _equipos(campeonatoId).get();
    final partidosSnap = await _partidos(campeonatoId)
        .where('estado', isEqualTo: PartidoEstado.finalizado)
        .where('resultadoRegistrado', isEqualTo: true)
        .get();

    final acumulados = <String, _TablaAcumulada>{};

    for (final doc in equiposSnap.docs) {
      final equipo = EquipoModel.fromMap(doc.id, doc.data());

      acumulados[equipo.id] = _TablaAcumulada(
        equipoId: equipo.id,
        equipoNombre: equipo.nombre,
      );
    }

    for (final doc in partidosSnap.docs) {
      final partido = PartidoModel.fromMap(doc.id, doc.data());

      if (partido.golesLocal == null || partido.golesVisitante == null) {
        continue;
      }

      final local = acumulados[partido.equipoLocalId];
      final visitante = acumulados[partido.equipoVisitanteId];

      if (local == null || visitante == null) continue;

      local.partidosJugados++;
      visitante.partidosJugados++;

      local.golesFavor += partido.golesLocal!;
      local.golesContra += partido.golesVisitante!;

      visitante.golesFavor += partido.golesVisitante!;
      visitante.golesContra += partido.golesLocal!;

      if (partido.golesLocal! > partido.golesVisitante!) {
        local.partidosGanados++;
        visitante.partidosPerdidos++;
        local.puntos += campeonatoModel.reglasPuntuacion.victoria;
        visitante.puntos += campeonatoModel.reglasPuntuacion.derrota;
      } else if (partido.golesLocal! < partido.golesVisitante!) {
        visitante.partidosGanados++;
        local.partidosPerdidos++;
        visitante.puntos += campeonatoModel.reglasPuntuacion.victoria;
        local.puntos += campeonatoModel.reglasPuntuacion.derrota;
      } else {
        local.partidosEmpatados++;
        visitante.partidosEmpatados++;
        local.puntos += campeonatoModel.reglasPuntuacion.empate;
        visitante.puntos += campeonatoModel.reglasPuntuacion.empate;
      }
    }

    final tablaOrdenada = acumulados.values.toList();

    for (final item in tablaOrdenada) {
      item.diferenciaGoles = item.golesFavor - item.golesContra;
    }

    tablaOrdenada.sort((a, b) {
      var compare = b.puntos.compareTo(a.puntos);
      if (compare != 0) return compare;

      compare = b.diferenciaGoles.compareTo(a.diferenciaGoles);
      if (compare != 0) return compare;

      compare = b.golesFavor.compareTo(a.golesFavor);
      if (compare != 0) return compare;

      compare = a.golesContra.compareTo(b.golesContra);
      if (compare != 0) return compare;

      return a.equipoNombre.compareTo(b.equipoNombre);
    });

    final tablaAnterior = await _tabla(campeonatoId).get();

    final batch = _db.batch();

    for (final doc in tablaAnterior.docs) {
      batch.delete(doc.reference);
    }

    for (int i = 0; i < tablaOrdenada.length; i++) {
      final item = tablaOrdenada[i];

      final tablaModel = TablaPosicionModel(
        equipoId: item.equipoId,
        equipoNombre: item.equipoNombre,
        partidosJugados: item.partidosJugados,
        partidosGanados: item.partidosGanados,
        partidosEmpatados: item.partidosEmpatados,
        partidosPerdidos: item.partidosPerdidos,
        golesFavor: item.golesFavor,
        golesContra: item.golesContra,
        diferenciaGoles: item.diferenciaGoles,
        puntos: item.puntos,
        posicion: i + 1,
        fechaActualizacion: DateTime.now(),
      );

      batch.set(
        _tabla(campeonatoId).doc(item.equipoId),
        tablaModel.toMap(),
      );
    }

    await batch.commit();
  }

  Future<void> _recalcularRanking(String campeonatoId) async {
    final golesSnap = await _goles(campeonatoId).get();
    final jugadoresSnap = await _jugadores(campeonatoId).get();

    final jugadores = <String, JugadorModel>{};

    for (final doc in jugadoresSnap.docs) {
      jugadores[doc.id] = JugadorModel.fromMap(doc.id, doc.data());
    }

    final acumulados = <String, _RankingAcumulado>{};

    for (final doc in golesSnap.docs) {
      final gol = GolModel.fromMap(doc.id, doc.data());

      final jugador = jugadores[gol.jugadorId];

      final acumulado = acumulados.putIfAbsent(
        gol.jugadorId,
        () => _RankingAcumulado(
          jugadorId: gol.jugadorId,
          jugadorNombre: jugador?.nombreCompleto ?? gol.jugadorNombre,
          jugadorEstado: jugador?.estado ?? JugadorEstado.activo,
          equipoId: gol.equipoId,
          equipoNombre: gol.equipoNombre,
        ),
      );

      acumulado.totalGoles += gol.cantidad;
      acumulado.partidos.add(gol.partidoId);
    }

    final rankingAnterior = await _ranking(campeonatoId).get();

    final batch = _db.batch();

    for (final doc in rankingAnterior.docs) {
      batch.delete(doc.reference);
    }

    final rankingOrdenado = acumulados.values.toList()
      ..sort((a, b) {
        final compare = b.totalGoles.compareTo(a.totalGoles);
        if (compare != 0) return compare;
        return a.jugadorNombre.compareTo(b.jugadorNombre);
      });

    for (final item in rankingOrdenado) {
      final rankingModel = RankingGoleadorModel(
        jugadorId: item.jugadorId,
        jugadorNombre: item.jugadorNombre,
        jugadorEstado: item.jugadorEstado,
        equipoId: item.equipoId,
        equipoNombre: item.equipoNombre,
        totalGoles: item.totalGoles,
        partidosConGol: item.partidos.length,
        fechaActualizacion: DateTime.now(),
      );

      batch.set(
        _ranking(campeonatoId).doc(item.jugadorId),
        rankingModel.toMap(),
      );
    }

    await batch.commit();
  }
}

class _TablaAcumulada {
  final String equipoId;
  final String equipoNombre;
  int partidosJugados = 0;
  int partidosGanados = 0;
  int partidosEmpatados = 0;
  int partidosPerdidos = 0;
  int golesFavor = 0;
  int golesContra = 0;
  int diferenciaGoles = 0;
  int puntos = 0;

  _TablaAcumulada({
    required this.equipoId,
    required this.equipoNombre,
  });
}

class _RankingAcumulado {
  final String jugadorId;
  final String jugadorNombre;
  final String jugadorEstado;
  final String equipoId;
  final String equipoNombre;
  int totalGoles = 0;
  final Set<String> partidos = {};

  _RankingAcumulado({
    required this.jugadorId,
    required this.jugadorNombre,
    required this.jugadorEstado,
    required this.equipoId,
    required this.equipoNombre,
  });
}