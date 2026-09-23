import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/grupo_model.dart';
import '../models/partido_model.dart';
import '../utils/llaves.dart';
import 'grupo_service.dart';
import 'resultado_service.dart';

class PartidoService {
  PartidoService({
    FirebaseFirestore? firestore,
    GrupoService? grupoService,
    ResultadoService? resultadoService,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _grupoService = grupoService ?? GrupoService(firestore: firestore),
       _resultadoService =
           resultadoService ?? ResultadoService(firestore: firestore);

  final FirebaseFirestore _db;
  final GrupoService _grupoService;
  final ResultadoService _resultadoService;

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
    return _partidos(
      campeonatoId,
    ).orderBy('vuelta').orderBy('jornada').snapshots().map((snap) {
      return snap.docs.map((doc) {
        return PartidoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<PartidoModel>> getPartidos(String campeonatoId) async {
    final snap = await _partidos(
      campeonatoId,
    ).orderBy('vuelta').orderBy('jornada').get();

    return snap.docs.map((doc) {
      return PartidoModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  /// Datos base de un partido nuevo. Incluye los campos nuevos con
  /// valores neutros para que todos los documentos queden completos.
  ///
  /// [local] y [visitante] pueden venir en null en los cruces de la
  /// llave que todavía esperan al ganador de la ronda anterior: en ese
  /// caso el id queda vacío y el nombre guarda el texto provisorio
  /// ("Ganador llave 8"), que es lo que se ve en el cuadro.
  Map<String, dynamic> _partidoBase({
    required int jornada,
    required int vuelta,
    String? grupoId,
    required EquipoModel? local,
    required EquipoModel? visitante,
    required bool generadoPorSistema,
    bool privilegio = false,
    String? localPendienteTexto,
    String? visitantePendienteTexto,
    String? rondaLlave,
    int? llave,
    int? ordenLlave,
    int? vieneDeLocal,
    int? vieneDeVisitante,
    bool esBye = false,
  }) {
    return {
      'jornada': jornada,
      'vuelta': vuelta,
      'grupoId': grupoId,
      'equipoLocalId': local?.id ?? '',
      'equipoLocalNombre':
          local?.nombre ?? localPendienteTexto ?? 'Por definir',
      'equipoVisitanteId': visitante?.id ?? '',
      'equipoVisitanteNombre':
          visitante?.nombre ?? visitantePendienteTexto ?? 'Por definir',
      'rondaLlave': rondaLlave,
      'llave': llave,
      'ordenLlave': ordenLlave,
      'vieneDeLocal': vieneDeLocal,
      'vieneDeVisitante': vieneDeVisitante,
      'esBye': esBye,
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
      'privilegio': privilegio,
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
    final equiposSnap = await _equipos(
      campeonatoId,
    ).where('estado', isEqualTo: EquipoEstado.activo).get();

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

      case TipoCampeonato.idaVuelta:
        await _generarRoundRobin(
          campeonatoId: campeonato.id,
          equipos: equipos,
          vueltas: 2,
        );

      case TipoCampeonato.ligaFinal:
      case TipoCampeonato.ligaPlayoffs:
        // Se genera solo la liga. La final/playoffs se agregan luego con
        // cruce manual usando la tabla final (no se inventan clasificados).
        await _generarRoundRobin(
          campeonatoId: campeonato.id,
          equipos: equipos,
          vueltas: config.cantidadVueltas < 1 ? 1 : config.cantidadVueltas,
        );

      case TipoCampeonato.faseGrupos:
      case TipoCampeonato.gruposEliminacion:
        await _generarFaseGrupos(
          campeonatoId: campeonato.id,
          equipos: equipos,
          cantidadGrupos: config.cantidadGrupos < 2 ? 2 : config.cantidadGrupos,
          idaYVuelta: config.idaYVueltaEnGrupos,
          aleatorio: config.generaGruposAleatorios,
        );

      case TipoCampeonato.eliminacionDirecta:
        await _generarEliminacionDirecta(
          campeonatoId: campeonato.id,
          equipos: equipos,
          aleatorio: config.generaCrucesAleatorios,
        );

      default:
        // Tipo desconocido (documento antiguo o editado a mano):
        // se mantiene el comportamiento histórico de ida y vuelta.
        await _generarRoundRobin(
          campeonatoId: campeonato.id,
          equipos: equipos,
          vueltas: 2,
        );
    }

    // La tabla de posiciones (y el grupoId de cada equipo, para poder
    // mostrar "por grupos" en la vista pública) se recalcula apenas
    // existe fixture, sin esperar al primer resultado: si no, la tabla
    // se ve plana (sin grupos) hasta que se cargue el primer partido.
    await _resultadoService.recalcularTablaYRanking(campeonato.id);
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

    final cruces =
        <({EquipoModel local, EquipoModel visitante, int jornada})>[];

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

  /// Fase de grupos: usa la inscripción de equipos por grupo (colección
  /// `grupos`, ver [GrupoService]) y genera round-robin dentro de cada
  /// grupo. Si todavía no se inscribió a nadie manualmente, se genera
  /// automáticamente para no romper el flujo de "un clic" existente.
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

    var grupos = await _grupoService.getGrupos(campeonatoId);

    if (grupos.isEmpty) {
      await _grupoService.generarGruposAutomaticos(
        campeonatoId: campeonatoId,
        equiposActivos: equipos,
        cantidadGrupos: cantidadGrupos,
        aleatorio: aleatorio,
      );
      grupos = await _grupoService.getGrupos(campeonatoId);
    }

    _validarGruposCompletos(grupos: grupos, equipos: equipos);

    final equiposPorId = {for (final equipo in equipos) equipo.id: equipo};
    final batch = _db.batch();

    for (final grupo in grupos) {
      final equiposDelGrupo = grupo.equipoIds
          .map((id) => equiposPorId[id])
          .whereType<EquipoModel>()
          .toList();

      await _generarRoundRobin(
        campeonatoId: campeonatoId,
        equipos: equiposDelGrupo,
        vueltas: idaYVuelta ? 2 : 1,
        grupoId: grupo.nombre,
        batchExterno: batch,
      );
    }

    await batch.commit();
  }

  /// Valida que todo equipo activo esté inscrito en exactamente un grupo
  /// y que cada grupo tenga al menos 2 equipos antes de generar cruces.
  void _validarGruposCompletos({
    required List<GrupoModel> grupos,
    required List<EquipoModel> equipos,
  }) {
    for (final grupo in grupos) {
      if (grupo.equipoIds.length < 2) {
        throw Exception(
          'El grupo "${grupo.nombre}" tiene menos de 2 equipos inscritos. Completa la inscripción de grupos antes de generar el fixture.',
        );
      }
    }

    final inscritos = grupos.expand((g) => g.equipoIds).toSet();
    final sinGrupo = equipos.where((e) => !inscritos.contains(e.id)).toList();

    if (sinGrupo.isNotEmpty) {
      final nombres = sinGrupo.map((e) => e.nombre).join(', ');
      throw Exception(
        'Hay equipos activos sin grupo asignado: $nombres. Complétalo en "Grupos" antes de generar el fixture.',
      );
    }
  }

  /// Eliminación directa: primera ronda con cruces aleatorios.
  /// Las rondas siguientes se agregan con cruce manual cuando existan
  /// ganadores (preparado para generación automática en una fase futura).
  /// Eliminación directa desde el arranque: se arma el mismo cuadro
  /// completo que en grupos+eliminación, solo que la "siembra" es el
  /// orden de los equipos (sorteado si el campeonato es aleatorio) en
  /// vez de la tabla de clasificados.
  Future<void> _generarEliminacionDirecta({
    required String campeonatoId,
    required List<EquipoModel> equipos,
    required bool aleatorio,
  }) async {
    final lista = [...equipos];

    if (aleatorio) {
      lista.shuffle(Random());
    }

    await generarLlavesEliminatorias(
      campeonatoId: campeonatoId,
      clasificados: lista,
    );
  }

  /// Determina el grupoId real de un cruce manual: mientras el
  /// campeonato deba restringir los cruces al mismo grupo ("fase de
  /// grupos" pura, o "grupos + eliminación" antes de activar la fase
  /// eliminatoria), ignora lo que se haya escrito a mano y exige que
  /// ambos equipos compartan grupo. Fuera de esa restricción, respeta
  /// el grupoId que se haya pasado (o null, para la fase final).
  Future<String?> _grupoIdParaCruceManual({
    required String campeonatoId,
    required EquipoModel equipoLocal,
    required EquipoModel equipoVisitante,
    required String? grupoIdSolicitado,
    bool privilegio = false,
  }) async {
    // Partido con privilegio: queda fuera de los grupos a propósito, así
    // que no se valida que ambos equipos sean del mismo grupo y se
    // guarda sin grupoId. Al no tener grupo, no suma para la tabla de la
    // fase de grupos (ver `_recalcularTabla`), que es justamente lo que
    // se busca para un amistoso o un partido especial.
    if (privilegio) return null;

    final campeonatoDoc = await _campeonato(campeonatoId).get();

    if (!campeonatoDoc.exists || campeonatoDoc.data() == null) {
      throw Exception('El campeonato no existe.');
    }

    final campeonato = CampeonatoModel.fromMap(
      campeonatoDoc.id,
      campeonatoDoc.data()!,
    );

    if (!campeonato.debeRestringirCrucesAlGrupo) {
      return grupoIdSolicitado;
    }

    final grupos = await _grupoService.getGrupos(campeonatoId);
    final grupoLocal = _grupoDeEquipo(grupos, equipoLocal.id);
    final grupoVisitante = _grupoDeEquipo(grupos, equipoVisitante.id);

    if (grupoLocal == null || grupoVisitante == null) {
      throw Exception(
        'Todavía es la fase de grupos: ambos equipos deben estar inscritos en un grupo (ver "Grupos") antes de crear un cruce.',
      );
    }

    if (grupoLocal != grupoVisitante) {
      throw Exception(
        'Todavía es la fase de grupos: solo puedes cruzar equipos del mismo grupo. ${equipoLocal.nombre} está en $grupoLocal y ${equipoVisitante.nombre} está en $grupoVisitante. Activa la fase eliminatoria para armar cruces entre grupos distintos.',
      );
    }

    return grupoLocal;
  }

  String? _grupoDeEquipo(List<GrupoModel> grupos, String equipoId) {
    for (final grupo in grupos) {
      if (grupo.equipoIds.contains(equipoId)) return grupo.nombre;
    }

    return null;
  }

  Future<void> crearCruceManual({
    required String campeonatoId,
    required EquipoModel equipoLocal,
    required EquipoModel equipoVisitante,
    required int jornada,
    required bool idaYVuelta,
    String? grupoId,
    bool privilegio = false,
  }) async {
    if (equipoLocal.id == equipoVisitante.id) {
      throw Exception('Un equipo no puede jugar contra sí mismo.');
    }

    if (jornada <= 0) {
      throw Exception('La jornada debe ser mayor a cero.');
    }

    final existentesSnap = await _partidos(
      campeonatoId,
    ).where('jornada', isEqualTo: jornada).get();

    for (final doc in existentesSnap.docs) {
      final partido = PartidoModel.fromMap(doc.id, doc.data());

      final mismoCruce =
          (partido.equipoLocalId == equipoLocal.id &&
              partido.equipoVisitanteId == equipoVisitante.id) ||
          (partido.equipoLocalId == equipoVisitante.id &&
              partido.equipoVisitanteId == equipoLocal.id);

      if (mismoCruce) {
        throw Exception('Ese cruce ya existe en la jornada $jornada.');
      }
    }

    final grupoIdFinal = await _grupoIdParaCruceManual(
      campeonatoId: campeonatoId,
      equipoLocal: equipoLocal,
      equipoVisitante: equipoVisitante,
      grupoIdSolicitado: grupoId,
      privilegio: privilegio,
    );

    final batch = _db.batch();

    final idaDoc = _partidos(campeonatoId).doc();

    batch.set(
      idaDoc,
      _partidoBase(
        jornada: jornada,
        vuelta: 1,
        grupoId: grupoIdFinal,
        local: equipoLocal,
        visitante: equipoVisitante,
        generadoPorSistema: false,
        privilegio: privilegio,
      ),
    );

    if (idaYVuelta) {
      final vueltaDoc = _partidos(campeonatoId).doc();

      batch.set(
        vueltaDoc,
        _partidoBase(
          jornada: jornada,
          vuelta: 2,
          grupoId: grupoIdFinal,
          local: equipoVisitante,
          visitante: equipoLocal,
          generadoPorSistema: false,
        ),
      );
    }

    await batch.commit();

    // Igual que al generar el fixture completo: si el cruce trae grupoId
    // (o es el primer partido del campeonato), la tabla pública necesita
    // recalcularse para reflejarlo sin esperar al primer resultado.
    await _resultadoService.recalcularTablaYRanking(campeonatoId);
  }

  /// Partidos que forman la llave eliminatoria: los que no tienen grupo
  /// y no son partidos de privilegio (esos quedan fuera a propósito).
  List<PartidoModel> soloDeLlave(List<PartidoModel> partidos) {
    return partidos
        .where(
          (p) => (p.grupoId == null || p.grupoId!.isEmpty) && !p.privilegio,
        )
        .toList();
  }

  /// Genera el **cuadro completo** de la fase eliminatoria: la primera
  /// ronda con los clasificados sembrados y todas las rondas siguientes
  /// ya creadas, esperando al ganador de cada llave.
  ///
  /// La siembra es la del cuadro de la Copa UPSA (ver `Llaves`): la
  /// llave `i` se cruza con la llave `n + 1 - i` en **todas** las
  /// rondas. Con 16 clasificados queda:
  ///
  ///     Octavos:   1-16, 2-15, 3-14, 4-13, 5-12, 6-11, 7-10, 8-9
  ///     Cuartos:   L1-L8, L2-L7, L3-L6, L4-L5
  ///     Semis:     L1-L4, L2-L3
  ///     Final:     L1-L2
  ///
  /// [clasificados] tiene que venir ya ordenado de mejor a peor. Si no
  /// son potencia de 2, el cuadro se completa hasta la potencia
  /// siguiente y los mejores sembrados quedan libres en la primera
  /// ronda (pasan directo).
  ///
  /// Los cruces quedan sin grupo (son fase final) y el admin los puede
  /// retocar después desde la pantalla de llaves.
  /// [rondaInicial] fuerza por qué ronda arranca el cuadro en vez de
  /// deducirla de la cantidad de clasificados. Sirve para los formatos
  /// que no se pueden deducir solos (12 equipos con repechaje, por
  /// ejemplo): el admin arma a mano las primeras rondas y genera el
  /// cuadro recién desde semifinales.
  ///
  /// Con [sembrar] en false los cruces se crean vacíos, para completar
  /// los equipos a mano. Es lo que hace falta cuando quienes llegan a
  /// esa ronda no salen de la tabla (el "mejor tercero", un repechaje).
  Future<void> generarLlavesEliminatorias({
    required String campeonatoId,
    required List<EquipoModel> clasificados,
    String? rondaInicial,
    bool sembrar = true,
  }) async {
    final tamanoForzado = rondaInicial == null
        ? null
        : RondaLlave.equiposQueLaJuegan(rondaInicial);

    if (rondaInicial != null && tamanoForzado == null) {
      throw Exception('No se reconoce la ronda "$rondaInicial".');
    }

    if (sembrar && clasificados.length < 2) {
      throw Exception(
        'Hacen falta al menos 2 equipos clasificados para armar la llave.',
      );
    }

    if (!sembrar && tamanoForzado == null) {
      throw Exception(
        'Para armar el cuadro sin sembrar hay que elegir desde qué ronda arranca.',
      );
    }

    final existentesSnap = await _partidos(campeonatoId).get();
    final existentes = existentesSnap.docs
        .map((doc) => PartidoModel.fromMap(doc.id, doc.data()))
        .toList();

    final deLlave = soloDeLlave(existentes);

    // No se pisa una llave que ya se empezó a jugar.
    final conResultado = deLlave.where((p) => p.resultadoRegistrado).toList();

    if (conResultado.isNotEmpty) {
      throw Exception(
        'La llave ya tiene ${conResultado.length} partido(s) con resultado cargado. Borra esos resultados antes de volver a generarla.',
      );
    }

    final batch = _db.batch();

    // Los cruces que ya existían se reaprovechan en vez de borrarlos y
    // volverlos a crear: así no se pierde la programación (fecha, hora
    // y estado) que el admin ya hubiera cargado. Se buscan por el par
    // de equipos, que es lo que identifica al cruce más allá del
    // documento donde esté guardado.
    final porPar = <String, PartidoModel>{};
    final porLlave = <String, PartidoModel>{};

    for (final partido in deLlave) {
      porPar[_clavePar(partido.equipoLocalId, partido.equipoVisitanteId)] =
          partido;

      if (partido.esDeLlave) {
        porLlave['${partido.rondaLlave}_${partido.llave}'] = partido;
      }
    }

    final reutilizados = <String>{};

    final estructura = Llaves.estructura(
      clasificados.length,
      tamanoForzado: tamanoForzado,
    );

    // La jornada más alta entre los cruces que cargó el admin: el cuadro
    // generado empieza a contar desde ahí. Sin cruces manuales da 0 y la
    // numeración queda igual que siempre.
    final jornadaBase = deLlave
        .where((partido) => !partido.generadoPorSistema)
        .fold<int>(
          0,
          (mayor, partido) => partido.jornada > mayor ? partido.jornada : mayor,
        );

    for (final cruce in estructura) {
      // La jornada arranca después de lo que ya haya cargado el admin a
      // mano. En un cuadro normal no hay nada antes y queda 1, 2, 3...
      // como siempre; cuando las primeras rondas se armaron a mano (12
      // equipos, por ejemplo), las generadas quedan después y el fixture
      // no muestra una semifinal antes que un cuarto.
      final jornada = jornadaBase + cruce.rondaIndice + 1;

      EquipoModel? local;
      EquipoModel? visitante;
      PartidoModel? previo;

      if (cruce.esPrimeraRonda && sembrar) {
        // Las siembras van de 1 a n; la lista, de 0 a n-1. Una siembra
        // más alta que la cantidad de clasificados es un lugar vacío del
        // cuadro, o sea que el rival queda libre.
        local = _porSiembra(clasificados, cruce.siembraLocal);
        visitante = _porSiembra(clasificados, cruce.siembraVisitante);

        if (local == null && visitante == null) continue;

        previo = porPar[_clavePar(local?.id ?? '', visitante?.id ?? '')];
      }

      // Las rondas siguientes no tienen equipos con los que buscar, así
      // que se reconocen por su lugar en el cuadro.
      previo ??= porLlave['${cruce.ronda}_${cruce.llave}'];

      final datos = _partidoBase(
        jornada: jornada,
        vuelta: 1,
        grupoId: null,
        local: local,
        visitante: visitante,
        generadoPorSistema: true,
        localPendienteTexto: !cruce.esPrimeraRonda
            ? Llaves.pendiente(cruce.vieneDeLocal)
            : (sembrar ? 'Libre' : 'Por definir'),
        visitantePendienteTexto: !cruce.esPrimeraRonda
            ? Llaves.pendiente(cruce.vieneDeVisitante)
            : (sembrar ? 'Libre' : 'Por definir'),
        rondaLlave: cruce.ronda,
        llave: cruce.llave,
        ordenLlave: cruce.ordenVisual,
        vieneDeLocal: cruce.vieneDeLocal,
        vieneDeVisitante: cruce.vieneDeVisitante,
        esBye:
            cruce.esPrimeraRonda &&
            sembrar &&
            (local == null || visitante == null),
      );

      if (previo == null) {
        batch.set(_partidos(campeonatoId).doc(), datos);
        continue;
      }

      reutilizados.add(previo.id);

      // Se reescribe el cruce pero se respeta lo que ya había cargado el
      // admin: la fecha, el estado y la observación no los define el
      // cuadro.
      batch.update(_partidos(campeonatoId).doc(previo.id), {
        ...datos,
        'fechaHora': previo.fechaHora == null
            ? null
            : Timestamp.fromDate(previo.fechaHora!),
        'estado': previo.estado,
        'observacionResultado': previo.observacionResultado,
        'fechaCreacion': previo.fechaCreacion == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(previo.fechaCreacion!),
      });
    }

    // Lo que quedó de un cuadro anterior y ya no entra en el nuevo (por
    // ejemplo si cambió la cantidad de clasificados).
    //
    // Los cruces cargados a mano no se tocan: son del admin, no de este
    // generador. Hace falta para los formatos que se arman mezclando las
    // dos cosas (12 equipos: las primeras rondas a mano y el cuadro
    // desde semifinales). Si se borraran, generar el cuadro se llevaría
    // puesto el trabajo ya cargado.
    for (final partido in deLlave) {
      if (reutilizados.contains(partido.id)) continue;
      if (!partido.generadoPorSistema) continue;
      batch.delete(_partidos(campeonatoId).doc(partido.id));
    }

    await batch.commit();

    // Los "libres" ya tienen ganador desde el momento en que se arma el
    // cuadro: se propagan enseguida para que la ronda siguiente no
    // quede diciendo "Ganador llave 3" cuando esa llave no se juega.
    await _resultadoService.avanzarGanadoresDeLlave(campeonatoId);
  }

  /// Identifica un cruce por sus dos equipos, sin importar quién figura
  /// como local: es lo que permite reconocer un cruce ya cargado cuando
  /// se vuelve a generar el cuadro.
  String _clavePar(String unoId, String otroId) {
    final ids = [unoId, otroId]..sort();
    return ids.join('|');
  }

  /// Equipo que ocupa el puesto [siembra] (1 = mejor clasificado), o
  /// `null` si ese puesto no existe porque el cuadro es más grande que
  /// la cantidad de clasificados.
  EquipoModel? _porSiembra(List<EquipoModel> clasificados, int? siembra) {
    if (siembra == null || siembra < 1 || siembra > clasificados.length) {
      return null;
    }

    return clasificados[siembra - 1];
  }

  /// Cambia los equipos de un cruce ya creado (para retocar la llave a
  /// mano). No se permite si el partido ya tiene resultado: primero hay
  /// que borrar el resultado.
  Future<void> cambiarEquiposPartido({
    required String campeonatoId,
    required String partidoId,
    required EquipoModel local,
    required EquipoModel visitante,
  }) async {
    if (local.id == visitante.id) {
      throw Exception('Un equipo no puede jugar contra sí mismo.');
    }

    final doc = await _partidos(campeonatoId).doc(partidoId).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('El partido no existe.');
    }

    final partido = PartidoModel.fromMap(doc.id, doc.data()!);

    if (partido.resultadoRegistrado) {
      throw Exception(
        'Ese partido ya tiene resultado cargado. Borra el resultado antes de cambiar los equipos.',
      );
    }

    await _partidos(campeonatoId).doc(partidoId).update({
      'equipoLocalId': local.id,
      'equipoLocalNombre': local.nombre,
      'equipoVisitanteId': visitante.id,
      'equipoVisitanteNombre': visitante.nombre,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  /// Borra un partido. Pensado para sacar un cruce de la llave que ya no
  /// va; no se permite si tiene resultado cargado.
  Future<void> eliminarPartido({
    required String campeonatoId,
    required String partidoId,
  }) async {
    final doc = await _partidos(campeonatoId).doc(partidoId).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('El partido no existe.');
    }

    final partido = PartidoModel.fromMap(doc.id, doc.data()!);

    if (partido.resultadoRegistrado) {
      throw Exception(
        'Ese partido ya tiene resultado cargado. Borra el resultado antes de eliminarlo.',
      );
    }

    await _partidos(campeonatoId).doc(partidoId).delete();
  }

  Future<void> programarPartido({
    required String campeonatoId,
    required String partidoId,
    required DateTime fechaHora,
  }) async {
    final mismaFecha = await _partidos(
      campeonatoId,
    ).where('fechaHora', isEqualTo: Timestamp.fromDate(fechaHora)).get();

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
      throw Exception(
        'La observación es obligatoria para suspender un partido.',
      );
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
