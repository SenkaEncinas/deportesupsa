import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../utils/fixture_grouping.dart';

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
        .map((snap) {
          return snap.docs.map((doc) {
            return CampeonatoModel.fromMap(doc.id, doc.data());
          }).toList();
        });
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
      'reglasDesempate': _reglasDesempatePorDeporte(deporte),
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'creadoPor': creadoPor,
    });

    return doc.id;
  }

  /// Reglas de desempate por deporte. Los campeonatos antiguos mantienen
  /// su lista guardada; esto solo aplica a campeonatos nuevos.
  List<String> _reglasDesempatePorDeporte(String deporte) {
    switch (deporte) {
      case DeporteTipo.volley:
        return const [
          'puntos',
          'diferencia_sets',
          'sets_favor',
          'diferencia_puntos',
          'resultado_directo',
        ];
      case DeporteTipo.basket:
        return const [
          'puntos',
          'diferencia_puntos',
          'puntos_favor',
          'resultado_directo',
        ];
      default:
        return const [
          'puntos',
          'diferencia_goles',
          'goles_favor',
          'goles_contra',
          'resultado_directo',
        ];
    }
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

  /// Pasa un campeonato de "Grupos + eliminación" de la fase de grupos a
  /// la fase eliminatoria: a partir de acá, "Agregar cruce manual" deja
  /// de limitarse a equipos del mismo grupo, para poder armar las llaves
  /// con los clasificados que decida el admin.
  Future<void> activarFaseEliminatoria(CampeonatoModel campeonato) async {
    if (!campeonato.tieneFasesSeparadas) {
      throw Exception(
        'Solo los campeonatos de "Grupos + eliminación" tienen fase eliminatoria para activar.',
      );
    }

    if (campeonato.estaEnFaseEliminatoria) {
      throw Exception('Este campeonato ya está en fase eliminatoria.');
    }

    await _campeonatos.doc(campeonato.id).update({
      'faseActual': FaseCampeonato.eliminatoria,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  /// Ajusta "clasifican por grupo" y "mejores terceros" de un campeonato
  /// que ya existe (grupos ya armados, equipos ya inscritos), sin tener
  /// que recrearlo. Solo aplica a "Grupos + eliminación": recalcula la
  /// ronda inicial (octavos, cuartos...) y exige que el total clasificado
  /// (grupos × clasificanPorGrupo + mejoresTerceros) sea potencia de 2.
  Future<void> actualizarClasificacionGrupos({
    required CampeonatoModel campeonato,
    required int clasificanPorGrupo,
    required int mejoresTerceros,
  }) async {
    if (campeonato.tipoCampeonato != TipoCampeonato.gruposEliminacion) {
      throw Exception(
        'Solo los campeonatos de "Grupos + eliminación" tienen mejores terceros.',
      );
    }

    final grupos = campeonato.configuracion.cantidadGrupos;

    if (clasificanPorGrupo <= 0) {
      throw Exception('Debe clasificar al menos 1 equipo por grupo.');
    }

    if (mejoresTerceros < 0) {
      throw Exception('La cantidad de mejores terceros no puede ser negativa.');
    }

    if (mejoresTerceros > grupos) {
      throw Exception(
        'Los mejores terceros no pueden ser más que la cantidad de grupos ($grupos).',
      );
    }

    final total = grupos * clasificanPorGrupo + mejoresTerceros;

    // Antes esto bloqueaba guardar si el total no era potencia de 2. Se
    // sacó el bloqueo a pedido explícito (mismo criterio que al crear el
    // campeonato): hay casos reales donde la llave no cuadra pareja y
    // aun así hace falta poder guardar la configuración — el ajuste de
    // la llave se resuelve aparte. `GruposScreen` avisa igual desde la
    // UI si el total no arma una llave pareja.

    await _campeonatos.doc(campeonato.id).update({
      'configuracion.clasificanPorGrupo': clasificanPorGrupo,
      'configuracion.mejoresTerceros': mejoresTerceros,
      'configuracion.rondaEliminatoriaInicial':
          FixtureGrouping.claveRondaSegunEquipos(total),
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

    final minimo = campeonato.configuracion.cantidadMinimaJugadoresPorEquipo;

    final maximo = campeonato.configuracion.cantidadMaximaJugadoresPorEquipo;

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
