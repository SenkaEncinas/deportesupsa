import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipo_model.dart';
import '../models/historial_cambio_model.dart';
import '../models/tabla_posicion_model.dart';
import 'auditoria_service.dart';

class EquipoService {
  EquipoService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auditoriaService = AuditoriaService(firestore: firestore);

  final FirebaseFirestore _db;
  final AuditoriaService _auditoriaService;

  CollectionReference<Map<String, dynamic>> _equipos(String campeonatoId) {
    return _db
        .collection('campeonatos')
        .doc(campeonatoId)
        .collection('equipos');
  }

  CollectionReference<Map<String, dynamic>> _tabla(String campeonatoId) {
    return _db
        .collection('campeonatos')
        .doc(campeonatoId)
        .collection('tabla_posiciones');
  }

  Stream<List<EquipoModel>> streamEquipos(String campeonatoId) {
    return _equipos(campeonatoId).orderBy('nombre').snapshots().map((snap) {
      return snap.docs.map((doc) {
        return EquipoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<EquipoModel>> getEquipos(String campeonatoId) async {
    final snap = await _equipos(campeonatoId).orderBy('nombre').get();

    return snap.docs.map((doc) {
      return EquipoModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  Future<String> crearEquipo({
    required String campeonatoId,
    required String nombre,
    required String representante,
    String? carrera,
    String? facultad,
    required String usuarioId,
  }) async {
    final equipoDoc = _equipos(campeonatoId).doc();

    final carreraLimpia = carrera?.trim();
    final facultadLimpia = facultad?.trim();

    final batch = _db.batch();

    batch.set(equipoDoc, {
      'nombre': nombre.trim(),
      'representante': representante.trim(),
      'carrera': carreraLimpia == null || carreraLimpia.isEmpty
          ? null
          : carreraLimpia,
      'facultad': facultadLimpia == null || facultadLimpia.isEmpty
          ? null
          : facultadLimpia,
      'estado': EquipoEstado.activo,
      'cantidadJugadoresRegistrados': 0,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'creadoPor': usuarioId,
      'actualizadoPor': usuarioId,
    });

    final tablaInicial = TablaPosicionModel.empty(
      equipoId: equipoDoc.id,
      equipoNombre: nombre.trim(),
    );

    batch.set(_tabla(campeonatoId).doc(equipoDoc.id), tablaInicial.toMap());

    await batch.commit();

    return equipoDoc.id;
  }

  /// Colecciones que guardan una copia del nombre del equipo, con los
  /// campos (id, nombre) de cada copia.
  static const _copiasDelNombre = <String, List<(String, String)>>{
    'partidos': [
      ('equipoLocalId', 'equipoLocalNombre'),
      ('equipoVisitanteId', 'equipoVisitanteNombre'),
    ],
    'jugadores': [('equipoId', 'equipoNombre')],
    'goles': [('equipoId', 'equipoNombre')],
    'tarjetas': [('equipoId', 'equipoNombre')],
    'ranking_goleadores': [('equipoId', 'equipoNombre')],
    'tabla_posiciones': [('equipoId', 'equipoNombre')],
  };

  /// Pone el nombre actual de cada equipo en todas las copias que lo
  /// repiten (partidos, jugadores, goles, tarjetas, ranking y tabla).
  ///
  /// Cada documento guarda el nombre del equipo al crearse, para no
  /// tener que buscarlo cada vez que se dibuja un partido o un PDF. El
  /// costo es que, al renombrar un equipo, esas copias quedaban con el
  /// nombre viejo. Solo escribe las que no coinciden, así que correrla
  /// de más no cuesta escrituras; también corrige los renombres que
  /// quedaron mal de antes.
  ///
  /// Devuelve cuántos documentos actualizó.
  Future<int> sincronizarNombresEquipos(String campeonatoId) async {
    final nombres = {
      for (final equipo in await getEquipos(campeonatoId))
        equipo.id: equipo.nombre,
    };
    final campeonato = _db.collection('campeonatos').doc(campeonatoId);

    var batch = _db.batch();
    var enLote = 0;
    var actualizados = 0;

    for (final MapEntry(key: coleccion, value: campos)
        in _copiasDelNombre.entries) {
      final snap = await campeonato.collection(coleccion).get();

      for (final doc in snap.docs) {
        final datos = doc.data();
        final cambios = <String, dynamic>{};

        for (final (campoId, campoNombre) in campos) {
          final nombre = nombres[datos[campoId]];
          if (nombre != null && datos[campoNombre] != nombre) {
            cambios[campoNombre] = nombre;
          }
        }

        if (cambios.isEmpty) continue;

        batch.update(doc.reference, cambios);
        actualizados++;

        // Firestore acepta hasta 500 escrituras por lote.
        if (++enLote == 450) {
          await batch.commit();
          batch = _db.batch();
          enLote = 0;
        }
      }
    }

    if (enLote > 0) await batch.commit();

    return actualizados;
  }

  Future<void> editarEquipo({
    required String campeonatoId,
    required String equipoId,
    required Map<String, dynamic> cambios,
    required String observacion,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    if (observacion.trim().isEmpty) {
      throw Exception('La observación es obligatoria para editar la planilla.');
    }

    final equipoRef = _equipos(campeonatoId).doc(equipoId);
    final equipoDoc = await equipoRef.get();

    if (!equipoDoc.exists || equipoDoc.data() == null) {
      throw Exception('El equipo no existe.');
    }

    final datosAnteriores = Map<String, dynamic>.from(equipoDoc.data()!);

    cambios.remove('sigla');
    cambios.remove('colorPrincipal');

    final datosNuevos = {
      ...cambios,
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': usuarioId,
    };

    await equipoRef.update(datosNuevos);

    // Los partidos, jugadores, goles, tarjetas, ranking y tabla guardan
    // una copia del nombre del equipo. Sin esto, un equipo renombrado
    // seguía saliendo con el nombre viejo en el fixture y en los PDF.
    await sincronizarNombresEquipos(campeonatoId);

    final historial = HistorialCambioModel(
      id: '',
      accion: 'editar_planilla_equipo',
      datosAnteriores: datosAnteriores,
      datosNuevos: cambios,
      observacion: observacion.trim(),
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      fecha: DateTime.now(),
    );

    await equipoRef.collection('historial_planilla').add(historial.toMap());

    final nombreEquipo = datosAnteriores['nombre'] as String? ?? equipoId;

    await _auditoriaService.registrar(
      campeonatoId: campeonatoId,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      accion: 'Editar equipo',
      modulo: 'Equipos',
      documentoAfectado: equipoId,
      detalle: 'Se editó al equipo $nombreEquipo (${cambios.keys.join(', ')}).',
      observacion: observacion,
    );
  }
}
