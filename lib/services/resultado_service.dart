import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/gol_model.dart';
import '../models/jugador_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tarjeta_model.dart';
import '../utils/llaves.dart';
import '../utils/tabla_calculo.dart';
import 'auditoria_service.dart';

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
    : _db = firestore ?? FirebaseFirestore.instance,
      _auditoriaService = AuditoriaService(firestore: firestore);

  final FirebaseFirestore _db;
  final AuditoriaService _auditoriaService;

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

  /// Todas las tarjetas/sanciones a jugadores del campeonato (fútbol:
  /// amarillas/rojas; vóley/básquet: sanción por mesa/forzada), para el
  /// módulo de "Jugadores sancionados".
  Stream<List<TarjetaModel>> streamTarjetas(String campeonatoId) {
    return _tarjetas(
      campeonatoId,
    ).orderBy('fechaRegistro', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) {
        return TarjetaModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Goles por jugador ya registrados de un partido puntual, para
  /// precargar el formulario cuando se edita un resultado existente.
  Future<List<GolModel>> getGolesPartido({
    required String campeonatoId,
    required String partidoId,
  }) async {
    final snap = await _goles(
      campeonatoId,
    ).where('partidoId', isEqualTo: partidoId).get();

    return snap.docs
        .map((doc) => GolModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Tarjetas/sanciones ya registradas de un partido puntual, para
  /// precargar el formulario cuando se edita un resultado existente.
  Future<List<TarjetaModel>> getTarjetasPartido({
    required String campeonatoId,
    required String partidoId,
  }) async {
    final snap = await _tarjetas(
      campeonatoId,
    ).where('partidoId', isEqualTo: partidoId).get();

    return snap.docs
        .map((doc) => TarjetaModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Registra el resultado de un partido según el deporte del campeonato.
  ///
  /// - Fútbol/futsal: [golesLocal]/[golesVisitante] son goles. Si el
  ///   formato no permite empate y el marcador queda igualado, se exigen
  ///   [penalesLocal]/[penalesVisitante] con un ganador.
  /// - Vóley: se envía [sets] con el detalle de cada set;
  ///   [golesLocal]/[golesVisitante] guardan los sets ganados.
  /// - Básquet: [golesLocal]/[golesVisitante] son puntos; no se permite
  ///   empate y puede marcarse [definidoPorProrroga].
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
    required String usuarioNombre,
    int? penalesLocal,
    int? penalesVisitante,
    bool definidoPorProrroga = false,
    List<SetPartido> sets = const [],
  }) async {
    if (golesLocal < 0 || golesVisitante < 0) {
      throw Exception('El marcador no puede tener valores negativos.');
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

    // Cruces del cuadro que todavía esperan al ganador de la ronda
    // anterior, o que son un pase directo: no hay partido que jugar.
    if (partido.esDeLlave && !partido.admiteResultado) {
      throw Exception(
        partido.esBye
            ? 'Esa llave no se juega: ${partido.equipoLocalNombre.isEmpty ? partido.equipoVisitanteNombre : partido.equipoLocalNombre} pasa directo a la ronda siguiente.'
            : 'Esa llave todavía no tiene definidos a sus dos equipos: primero hay que jugar la ronda anterior.',
      );
    }

    final esAdministrativo =
        tipoResultado == TipoResultado.walkover ||
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

    final sistemaResultado = campeonato.sistemaResultadoEfectivo;
    final esFutbol = sistemaResultado == SistemaResultado.goles;

    if (!esFutbol && golesJugadores.isNotEmpty) {
      throw Exception(
        'El registro de goles por jugador solo aplica a fútbol/futsal.',
      );
    }

    if (esFutbol && tipoResultado == TipoResultado.normal) {
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
    }

    // Las tarjetas/sanciones por jugador aplican a cualquier deporte
    // (en fútbol son amarillas/rojas; en vóley/básquet, sanción por mesa
    // o forzada) y son opcionales: solo se validan si se registró alguna.
    if (tipoResultado == TipoResultado.normal) {
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

    var empate = golesLocal == golesVisitante;
    String? ganadorId;
    var tipoDefinicion = TipoDefinicion.normal;
    int? penalesLocalFinal;
    int? penalesVisitanteFinal;
    var definidoPorPenales = false;
    var prorrogaFinal = false;
    var setsFinal = <SetPartido>[];

    if (tipoResultado == TipoResultado.walkover) {
      tipoDefinicion = TipoDefinicion.walkover;
    } else if (tipoResultado == TipoResultado.sancion) {
      tipoDefinicion = TipoDefinicion.sancion;
    }

    // Walkover o sanción: el marcador lo fija el reglamento del deporte,
    // no quien lo carga, así que el resultado es siempre el mismo. En
    // vóley son 25-0 por set (50 a 0 en total) y en básquet 20-0. No es
    // una formalidad: pesa en la tabla, porque el desempate mira la
    // diferencia de puntos.
    if (tipoResultado != TipoResultado.normal) {
      if (empate) {
        throw Exception(
          'Un walkover o una sanción necesitan un ganador: marca qué equipo se presentó.',
        );
      }

      final reglamentario = TablaCalculo.marcadorPorNoPresentarse(
        campeonato: campeonato,
        ganaLocal: golesLocal > golesVisitante,
      );

      if (reglamentario != null) {
        golesLocal = reglamentario.golesLocal;
        golesVisitante = reglamentario.golesVisitante;
        setsFinal = reglamentario.sets;
      }
    }

    if (!empate) {
      ganadorId = golesLocal > golesVisitante
          ? partido.equipoLocalId
          : partido.equipoVisitanteId;
    }

    if (tipoResultado == TipoResultado.normal) {
      if (sistemaResultado == SistemaResultado.sets) {
        // ---- Vóley: resultado por sets, sin empates. ----
        if (sets.isEmpty) {
          throw Exception('Debes registrar el detalle de los sets.');
        }

        var setsGanadosLocal = 0;
        var setsGanadosVisitante = 0;

        for (final set in sets) {
          if (set.local < 0 || set.visitante < 0) {
            throw Exception('Los puntos de un set no pueden ser negativos.');
          }
          if (set.local == set.visitante) {
            throw Exception(
              'Un set no puede terminar empatado (${set.local}-${set.visitante}).',
            );
          }
          if (set.local > set.visitante) {
            setsGanadosLocal++;
          } else {
            setsGanadosVisitante++;
          }
        }

        final setsParaGanar = campeonato.configuracion.setsParaGanar;

        if (setsGanadosLocal != golesLocal ||
            setsGanadosVisitante != golesVisitante) {
          throw Exception(
            'El marcador de sets no coincide con el detalle registrado.',
          );
        }

        if (setsGanadosLocal < setsParaGanar &&
            setsGanadosVisitante < setsParaGanar) {
          throw Exception(
            'Ningún equipo alcanzó los $setsParaGanar sets necesarios para ganar.',
          );
        }

        if (setsGanadosLocal >= setsParaGanar &&
            setsGanadosVisitante >= setsParaGanar) {
          throw Exception('Ambos equipos no pueden ganar el partido.');
        }

        empate = false;
        ganadorId = setsGanadosLocal > setsGanadosVisitante
            ? partido.equipoLocalId
            : partido.equipoVisitanteId;
        setsFinal = sets;
      } else if (sistemaResultado == SistemaResultado.puntos) {
        // ---- Básquet: resultado por puntos, sin empate final. ----
        if (golesLocal == golesVisitante) {
          throw Exception(
            'El básquet no permite empate. Registra los puntos finales después de la prórroga.',
          );
        }

        empate = false;
        prorrogaFinal = definidoPorProrroga;

        if (prorrogaFinal) {
          tipoDefinicion = TipoDefinicion.prorroga;
        }
      } else {
        // ---- Fútbol/futsal: goles, con penales si no se permite empate. ----
        final requiereGanador =
            !campeonato.configuracion.permiteEmpate ||
            campeonato.tipoCampeonato == TipoCampeonato.eliminacionDirecta ||
            _esFaseFinalSinEmpate(campeonato, partido);

        if (empate && requiereGanador) {
          if (penalesLocal == null || penalesVisitante == null) {
            throw Exception(
              'Este formato no permite empates: registra los penales para definir un ganador.',
            );
          }

          if (penalesLocal < 0 || penalesVisitante < 0) {
            throw Exception('Los penales no pueden ser negativos.');
          }

          if (penalesLocal == penalesVisitante) {
            throw Exception(
              'Los penales no pueden terminar empatados. Debe haber un ganador.',
            );
          }

          empate = false;
          definidoPorPenales = true;
          tipoDefinicion = TipoDefinicion.penales;
          penalesLocalFinal = penalesLocal;
          penalesVisitanteFinal = penalesVisitante;
          ganadorId = penalesLocal > penalesVisitante
              ? partido.equipoLocalId
              : partido.equipoVisitanteId;
        }
      }
    }

    final golesAnteriores = await _goles(
      campeonatoId,
    ).where('partidoId', isEqualTo: partidoId).get();

    final tarjetasAnteriores = await _tarjetas(
      campeonatoId,
    ).where('partidoId', isEqualTo: partidoId).get();

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
      'penalesLocal': penalesLocalFinal,
      'penalesVisitante': penalesVisitanteFinal,
      'definidoPorPenales': definidoPorPenales,
      'definidoPorProrroga': prorrogaFinal,
      'tipoDefinicion': tipoDefinicion,
      'sets': setsFinal.map((set) => set.toMap()).toList(),
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

    // Si el partido era un cruce de la llave, el ganador pasa solo al
    // cruce de la ronda siguiente que le corresponde.
    if (partido.esDeLlave) {
      await avanzarGanadoresDeLlave(campeonatoId);
    }

    final esEdicion = partido.resultadoRegistrado;

    await _auditoriaService.registrar(
      campeonatoId: campeonatoId,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      accion: esEdicion ? 'Editar resultado' : 'Registrar resultado',
      modulo: 'Resultados',
      documentoAfectado: partidoId,
      detalle:
          '${esEdicion ? 'Se editó' : 'Se registró'} el resultado de '
          '${partido.equipoLocalNombre} $golesLocal - $golesVisitante '
          '${partido.equipoVisitanteNombre}.',
      observacion: observacionResultado,
    );
  }

  /// En formatos de dos fases (grupos+eliminación, liga+final,
  /// liga+playoffs) la fase de grupos/liga permite empate, pero la fase
  /// final no: de un cruce eliminatorio tiene que salir un ganador.
  ///
  /// Un cruce generado por el cuadro se reconoce por su ronda de llave.
  /// Los que se arman a mano no la tienen, y ahí sigue valiendo la
  /// señal vieja: los de la fase de grupos los genera el sistema, los
  /// de fase final los carga el admin con "cruce manual".
  bool _esFaseFinalSinEmpate(CampeonatoModel campeonato, PartidoModel partido) {
    final formatoDosFases =
        campeonato.tipoCampeonato == TipoCampeonato.gruposEliminacion ||
        campeonato.tipoCampeonato == TipoCampeonato.ligaFinal ||
        campeonato.tipoCampeonato == TipoCampeonato.ligaPlayoffs;

    if (!formatoDosFases) return false;

    return partido.esDeLlave || !partido.generadoPorSistema;
  }

  /// Lleva a los ganadores de cada ronda de la llave al cruce que les
  /// toca en la ronda siguiente, y vuelve a dejar el hueco en "Ganador
  /// llave N" si el resultado que lo definía se editó o se borró.
  ///
  /// Se dispara sola después de cargar un resultado, así que el cuadro
  /// se va completando a medida que se juega, sin que el admin tenga
  /// que copiar los nombres a mano.
  ///
  /// Vive acá y no en `PartidoService` para no tener que depender de
  /// ese servicio desde el registro de resultados (sería un círculo).
  Future<void> avanzarGanadoresDeLlave(String campeonatoId) async {
    final snap = await _partidos(campeonatoId).get();

    final partidos = snap.docs
        .map((doc) => PartidoModel.fromMap(doc.id, doc.data()))
        .where((partido) => partido.esDeLlave)
        .toList();

    if (partidos.isEmpty) return;

    // Los cruces agrupados por ronda, de la primera a la final.
    final porRonda = <int, List<PartidoModel>>{};

    for (final partido in partidos) {
      final orden = RondaLlave.orden(partido.rondaLlave!);
      porRonda.putIfAbsent(orden, () => []).add(partido);
    }

    final ordenes = porRonda.keys.toList()..sort();

    final batch = _db.batch();
    var cambios = 0;

    // Ronda por ronda: de cada una sale, por número de llave, quién
    // pasa, y eso se vuelca en los cruces de la ronda siguiente.
    for (var i = 0; i + 1 < ordenes.length; i++) {
      final pasan = <int, ({String id, String nombre})>{};

      for (final partido in porRonda[ordenes[i]]!) {
        final pasa = partido.quienPasa;
        if (pasa != null) pasan[partido.llave!] = pasa;
      }

      for (final partido in porRonda[ordenes[i + 1]]!) {
        // Un cruce que ya se jugó no se toca: para corregirlo hay que
        // rehacer su resultado primero.
        if (partido.resultadoRegistrado) continue;

        final local = _ocupanteDeSlot(pasan, partido.vieneDeLocal);
        final visitante = _ocupanteDeSlot(pasan, partido.vieneDeVisitante);

        final cambio = <String, dynamic>{};

        if (local != null && local.id != partido.equipoLocalId) {
          cambio['equipoLocalId'] = local.id;
          cambio['equipoLocalNombre'] = local.nombre;
        }

        if (visitante != null && visitante.id != partido.equipoVisitanteId) {
          cambio['equipoVisitanteId'] = visitante.id;
          cambio['equipoVisitanteNombre'] = visitante.nombre;
        }

        if (cambio.isEmpty) continue;

        cambio['fechaActualizacion'] = FieldValue.serverTimestamp();
        batch.update(_partidos(campeonatoId).doc(partido.id), cambio);
        cambios++;
      }
    }

    if (cambios > 0) await batch.commit();
  }

  /// Quién ocupa el lugar que alimenta la llave [vieneDe]: el ganador si
  /// ya está definido, o el hueco vacío con su texto provisorio si esa
  /// llave todavía no se resolvió.
  ({String id, String nombre})? _ocupanteDeSlot(
    Map<int, ({String id, String nombre})> pasan,
    int? vieneDe,
  ) {
    if (vieneDe == null) return null;

    return pasan[vieneDe] ?? (id: '', nombre: Llaves.pendiente(vieneDe));
  }

  Future<void> recalcularTablaYRanking(String campeonatoId) async {
    await _recalcularTabla(campeonatoId);
    await _recalcularRanking(campeonatoId);
  }

  /// Recalcula la tabla y la guarda.
  ///
  /// El cálculo en sí vive en [TablaCalculo], que es una función pura y
  /// la misma que usa la pantalla para mostrar la tabla en vivo. Acá
  /// solo se leen los datos, se calcula y se guarda el resultado como
  /// registro.
  Future<void> _recalcularTabla(String campeonatoId) async {
    final campeonatoDoc = await _campeonato(campeonatoId).get();

    if (!campeonatoDoc.exists || campeonatoDoc.data() == null) {
      throw Exception('El campeonato no existe.');
    }

    final campeonato = CampeonatoModel.fromMap(
      campeonatoDoc.id,
      campeonatoDoc.data()!,
    );

    final equiposSnap = await _equipos(campeonatoId).get();
    final partidosSnap = await _partidos(campeonatoId).get();

    final tabla = TablaCalculo.calcular(
      campeonato: campeonato,
      equipos: equiposSnap.docs
          .map((doc) => EquipoModel.fromMap(doc.id, doc.data()))
          .toList(),
      partidos: partidosSnap.docs
          .map((doc) => PartidoModel.fromMap(doc.id, doc.data()))
          .toList(),
    );

    final tablaAnterior = await _tabla(campeonatoId).get();

    final batch = _db.batch();

    for (final doc in tablaAnterior.docs) {
      batch.delete(doc.reference);
    }

    for (final fila in tabla) {
      batch.set(_tabla(campeonatoId).doc(fila.equipoId), fila.toMap());
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
