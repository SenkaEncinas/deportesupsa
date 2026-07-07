import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';

class CampeonatoService {
  CampeonatoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _campeonatos =>
      _db.collection('campeonatos');

  Stream<List<CampeonatoModel>> streamCampeonatos() {
    return _campeonatos
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map(
      (snap) {
        return snap.docs.map((doc) {
          return CampeonatoModel.fromMap(doc.id, doc.data());
        }).toList();
      },
    );
  }

  Stream<CampeonatoModel?> streamCampeonato(String campeonatoId) {
    return _campeonatos.doc(campeonatoId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CampeonatoModel.fromMap(doc.id, doc.data()!);
    });
  }

  Future<CampeonatoModel?> getCampeonato(String campeonatoId) async {
    final doc = await _campeonatos.doc(campeonatoId).get();

    if (!doc.exists || doc.data() == null) return null;

    return CampeonatoModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> crearCampeonato({
    required String nombre,
    required String descripcion,
    required String deporte,
    required String modalidad,
    required String tipoCampeonato,
    required String temporada,
    required String cancha,
    required CampeonatoConfig configuracion,
    required String creadoPor,
  }) async {
    final doc = _campeonatos.doc();

    await doc.set({
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'deporte': deporte.trim(),
      'modalidad': modalidad.trim(),
      'tipoCampeonato': tipoCampeonato,
      'estado': CampeonatoEstado.inscripcion,
      'temporada': temporada.trim(),
      'cancha': cancha.trim().isEmpty ? 'Cancha UPSA' : cancha.trim(),
      'configuracion': configuracion.toMap(),
      'reglasPuntuacion': ReglasPuntuacion.defaultRules().toMap(),
      'reglasDesempate': [
        'puntos',
        'diferencia_goles',
        'goles_favor',
        'goles_contra',
        'resultado_directo',
      ],
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'creadoPor': creadoPor,
    });

    return doc.id;
  }

  Future<void> actualizarCampeonato({
    required String campeonatoId,
    required Map<String, dynamic> data,
  }) async {
    data.remove('fechaInicio');
    data.remove('fechaFin');

    await _campeonatos.doc(campeonatoId).update({
      ...data,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> validarParaActivar(String campeonatoId) async {
    final errores = <String>[];

    final campeonato = await getCampeonato(campeonatoId);

    if (campeonato == null) {
      return ['El campeonato no existe.'];
    }

    if (campeonato.estado != CampeonatoEstado.inscripcion) {
      return [
        'Solo se puede activar un campeonato que está en estado inscripción.',
      ];
    }

    final equiposSnap = await _campeonatos
        .doc(campeonatoId)
        .collection('equipos')
        .where('estado', isEqualTo: EquipoEstado.activo)
        .get();

    final equiposActivos = equiposSnap.docs.map((doc) {
      return EquipoModel.fromMap(doc.id, doc.data());
    }).toList();

    if (equiposActivos.length < 2) {
      errores.add(
        'Debe existir al menos 2 equipos activos para activar el campeonato.',
      );
    }

    final minimo =
        campeonato.configuracion.cantidadMinimaJugadoresPorEquipo;

    final maximo =
        campeonato.configuracion.cantidadMaximaJugadoresPorEquipo;

    for (final equipo in equiposActivos) {
      if (equipo.cantidadJugadoresRegistrados < minimo) {
        errores.add(
          'El equipo ${equipo.nombre} debe tener al menos $minimo jugadores.',
        );
      }

      if (equipo.cantidadJugadoresRegistrados > maximo) {
        errores.add(
          'El equipo ${equipo.nombre} supera el máximo de $maximo jugadores.',
        );
      }
    }

    return errores;
  }

  Future<void> activarCampeonato(String campeonatoId) async {
    final errores = await validarParaActivar(campeonatoId);

    if (errores.isNotEmpty) {
      throw Exception(errores.join('\n'));
    }

    await _campeonatos.doc(campeonatoId).update({
      'estado': CampeonatoEstado.activo,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> finalizarCampeonato(String campeonatoId) async {
    final campeonato = await getCampeonato(campeonatoId);

    if (campeonato == null) {
      throw Exception('El campeonato no existe.');
    }

    if (campeonato.estado == CampeonatoEstado.finalizado) {
      throw Exception('El campeonato ya está finalizado.');
    }

    await _campeonatos.doc(campeonatoId).update({
      'estado': CampeonatoEstado.finalizado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }
}