import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/jugador_model.dart';
import '../models/partido_model.dart';
import '../models/tarjeta_model.dart';
import '../services/auth_service.dart';
import '../services/campeonato_service.dart';
import '../services/jugador_service.dart';
import '../services/resultado_service.dart';
import '../utils/tabla_calculo.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';
import '../utils/mensajes.dart';
import 'reciclaje/app_info_box.dart';
import 'reciclaje/app_form_fields.dart';
import '../ayuda/ayuda_modelo.dart';
import '../ayuda/centro_ayuda.dart';

part 'resultado_form/secciones.dart';

class ResultadoFormScreen extends StatefulWidget {
  final String campeonatoId;
  final PartidoModel partido;

  /// Si la pantalla anterior ya tiene el campeonato cargado puede
  /// pasarlo para evitar una lectura extra; si no, se carga aquí.
  final CampeonatoModel? campeonato;

  /// Solo para los tests, que necesitan apuntar a un Firestore de
  /// mentira. En la app queda en null y se usa el de siempre.
  final FirebaseFirestore? firestore;

  const ResultadoFormScreen({
    super.key,
    required this.campeonatoId,
    required this.partido,
    this.campeonato,
    this.firestore,
  });

  @override
  State<ResultadoFormScreen> createState() => _ResultadoFormScreenState();
}

class _ResultadoFormScreenState extends State<ResultadoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Se crean recién cuando se usan: la sesión de Firebase, por ejemplo,
  // solo hace falta al guardar.
  late final _authService = AuthService();
  late final _jugadorService = JugadorService(firestore: widget.firestore);
  late final _campeonatoService = CampeonatoService(
    firestore: widget.firestore,
  );
  late final _resultadoService = ResultadoService(firestore: widget.firestore);

  final _golesLocalController = TextEditingController();
  final _golesVisitanteController = TextEditingController();
  final _observacionController = TextEditingController();

  final _penalesLocalController = TextEditingController();
  final _penalesVisitanteController = TextEditingController();

  String _tipoResultado = TipoResultado.normal;
  bool _definidoPorProrroga = false;
  bool _loading = false;

  late Future<_FormData> _dataFuture;

  final List<_GolInputState> _goles = [];
  final List<_TarjetaInputState> _tarjetas = [];
  final List<_SetInputState> _sets = [];

  /// Equipo que gana un walkover/sanción en vóley. Ahí no se cargan sets
  /// a mano: el resultado es siempre 25-0 en cada set para el que se
  /// presentó, así que solo hace falta saber quién fue.
  String? _ganadorAdministrativo;
  final List<_SancionInputState> _sanciones = [];

  @override
  void initState() {
    super.initState();

    _golesLocalController.text = widget.partido.golesLocal?.toString() ?? '';
    _golesVisitanteController.text =
        widget.partido.golesVisitante?.toString() ?? '';
    _tipoResultado = widget.partido.tipoResultado;
    _observacionController.text = widget.partido.observacionResultado ?? '';
    _penalesLocalController.text =
        widget.partido.penalesLocal?.toString() ?? '';
    _penalesVisitanteController.text =
        widget.partido.penalesVisitante?.toString() ?? '';
    _definidoPorProrroga = widget.partido.definidoPorProrroga;

    for (final set in widget.partido.sets) {
      _sets.add(_SetInputState(local: set.local, visitante: set.visitante));
    }

    // Al editar un walkover/sanción ya cargado, se deja marcado el equipo
    // que había ganado para no tener que elegirlo otra vez.
    if (_tipoResultado != TipoResultado.normal) {
      _ganadorAdministrativo = widget.partido.ganadorId;
    }

    // Los campos de goles disparan rebuild para mostrar/ocultar penales.
    _golesLocalController.addListener(_onMarcadorChanged);
    _golesVisitanteController.addListener(_onMarcadorChanged);

    _dataFuture = _loadData();
  }

  void _onMarcadorChanged() {
    if (mounted) setState(() {});
  }

  Future<_FormData> _loadData() async {
    final campeonato =
        widget.campeonato ??
        await _campeonatoService.getCampeonato(widget.campeonatoId);

    final local = await _jugadorService.getJugadoresPorEquipo(
      campeonatoId: widget.campeonatoId,
      equipoId: widget.partido.equipoLocalId,
    );

    final visitante = await _jugadorService.getJugadoresPorEquipo(
      campeonatoId: widget.campeonatoId,
      equipoId: widget.partido.equipoVisitanteId,
    );

    final jugadores = [
      ...local,
      ...visitante,
    ].where((jugador) => jugador.estado == JugadorEstado.activo).toList();

    // Al editar un resultado ya registrado, precargamos los goles y
    // tarjetas/sanciones por jugador (viven en colecciones aparte, no en
    // el documento del partido) para que el admin pueda corregirlos en
    // vez de ver solo el marcador final.
    if (widget.partido.resultadoRegistrado) {
      final goles = await _resultadoService.getGolesPartido(
        campeonatoId: widget.campeonatoId,
        partidoId: widget.partido.id,
      );

      final tarjetas = await _resultadoService.getTarjetasPartido(
        campeonatoId: widget.campeonatoId,
        partidoId: widget.partido.id,
      );

      for (final gol in goles) {
        _goles.add(
          _GolInputState()
            ..jugadorId = gol.jugadorId
            ..cantidad = gol.cantidad,
        );
      }

      final esFutbol = _esFutbol(campeonato);

      for (final tarjeta in tarjetas) {
        if (esFutbol) {
          _tarjetas.add(
            _TarjetaInputState()
              ..jugadorId = tarjeta.jugadorId
              ..amarillas = tarjeta.amarillas
              ..rojas = tarjeta.rojas
              ..motivoController.text = tarjeta.motivo ?? '',
          );
        } else {
          _sanciones.add(
            _SancionInputState()
              ..jugadorId = tarjeta.jugadorId
              ..tipo = tarjeta.rojas > 0
                  ? SancionTipo.forzada
                  : SancionTipo.porMesa
              ..detalleController.text = tarjeta.motivo ?? '',
          );
        }
      }
    }

    return _FormData(campeonato: campeonato, jugadores: jugadores);
  }

  @override
  void dispose() {
    _golesLocalController.dispose();
    _golesVisitanteController.dispose();
    _observacionController.dispose();
    _penalesLocalController.dispose();
    _penalesVisitanteController.dispose();

    for (final tarjeta in _tarjetas) {
      tarjeta.dispose();
    }

    for (final set in _sets) {
      set.dispose();
    }

    for (final sancion in _sanciones) {
      sancion.dispose();
    }

    super.dispose();
  }

  void _addGol() {
    setState(() {
      _goles.add(_GolInputState());
    });
  }

  void _removeGol(int index) {
    setState(() {
      _goles.removeAt(index);
    });
  }

  void _addTarjeta() {
    setState(() {
      _tarjetas.add(_TarjetaInputState());
    });
  }

  void _removeTarjeta(int index) {
    setState(() {
      final item = _tarjetas.removeAt(index);
      item.dispose();
    });
  }

  void _addSet() {
    setState(() {
      _sets.add(_SetInputState());
    });
  }

  void _removeSet(int index) {
    setState(() {
      final item = _sets.removeAt(index);
      item.dispose();
    });
  }

  void _addSancion() {
    setState(() {
      _sanciones.add(_SancionInputState());
    });
  }

  void _removeSancion(int index) {
    setState(() {
      final item = _sanciones.removeAt(index);
      item.dispose();
    });
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  bool _esFutbol(CampeonatoModel? campeonato) =>
      campeonato == null || campeonato.esFutbol;

  bool _esVolley(CampeonatoModel? campeonato) =>
      campeonato != null && campeonato.esVolley;

  bool _esBasket(CampeonatoModel? campeonato) =>
      campeonato != null && campeonato.esBasket;

  /// Si este partido tiene que terminar con ganador (la regla vive en
  /// el campeonato, ver `CampeonatoModel.requiereGanador`).
  bool _requiereGanador(CampeonatoModel? campeonato) =>
      campeonato != null && campeonato.requiereGanador(widget.partido);

  /// Los penales aparecen solo en un partido de fútbol de la fase final
  /// que va empatado: ahí alguien tiene que avanzar. En la fase de
  /// grupos o de liga el empate queda como empate y no se muestran.
  bool _mostrarPenales(CampeonatoModel? campeonato) {
    if (!_esFutbol(campeonato)) return false;
    if (_tipoResultado != TipoResultado.normal) return false;
    if (!_requiereGanador(campeonato)) return false;

    final local = _golesLocalController.text.trim();
    final visitante = _golesVisitanteController.text.trim();

    if (local.isEmpty || visitante.isEmpty) return false;

    return _parseInt(local) == _parseInt(visitante);
  }

  ({int local, int visitante}) _setsGanados() {
    var local = 0;
    var visitante = 0;

    for (final set in _sets) {
      final puntosLocal = _parseInt(set.localController.text);
      final puntosVisitante = _parseInt(set.visitanteController.text);

      if (puntosLocal > puntosVisitante) local++;
      if (puntosVisitante > puntosLocal) visitante++;
    }

    return (local: local, visitante: visitante);
  }

  Future<void> _guardar(_FormData data) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      final admin = await _authService.requireAdmin();
      final campeonato = data.campeonato;
      final jugadores = data.jugadores;

      final golesInputs = <GolJugadorInput>[];
      final tarjetasInputs = <TarjetaJugadorInput>[];
      var setsInputs = <SetPartido>[];

      int golesLocal;
      int golesVisitante;
      int? penalesLocal;
      int? penalesVisitante;

      if (_esAdministrativoConGanador(campeonato)) {
        // Walkover/sanción en vóley y básquet: no se carga marcador, solo
        // se elige al equipo que se presentó. El servicio arma el 25-0 por
        // set (vóley) o el 20-0 (básquet).
        if (_ganadorAdministrativo == null) {
          throw Exception('Elegí qué equipo gana por walkover o sanción.');
        }

        final ganaLocal =
            _ganadorAdministrativo == widget.partido.equipoLocalId;

        golesLocal = ganaLocal ? 1 : 0;
        golesVisitante = ganaLocal ? 0 : 1;
        penalesLocal = null;
        penalesVisitante = null;
      } else if (_esVolley(campeonato)) {
        // Vóley: el marcador son los sets ganados calculados del detalle.
        if (_sets.isEmpty) {
          throw Exception('Agrega al menos un set con su puntaje.');
        }

        setsInputs = _sets.map((set) {
          return SetPartido(
            local: _parseInt(set.localController.text),
            visitante: _parseInt(set.visitanteController.text),
          );
        }).toList();

        final ganados = _setsGanados();
        golesLocal = ganados.local;
        golesVisitante = ganados.visitante;
        penalesLocal = null;
        penalesVisitante = null;
      } else {
        golesLocal = _parseInt(_golesLocalController.text);
        golesVisitante = _parseInt(_golesVisitanteController.text);

        // Los campos ya se validaron (son obligatorios cuando se ven).
        if (_mostrarPenales(campeonato)) {
          penalesLocal = int.tryParse(_penalesLocalController.text.trim());
          penalesVisitante = int.tryParse(
            _penalesVisitanteController.text.trim(),
          );
        }
      }

      if (_esFutbol(campeonato) && _tipoResultado == TipoResultado.normal) {
        for (final item in _goles) {
          if (item.jugadorId == null || item.jugadorId!.isEmpty) continue;

          final jugador = jugadores.firstWhere((j) => j.id == item.jugadorId);

          golesInputs.add(
            GolJugadorInput(
              equipoId: jugador.equipoId,
              equipoNombre: jugador.equipoNombre,
              jugadorId: jugador.id,
              jugadorNombre: jugador.nombreCompleto,
              cantidad: item.cantidad,
            ),
          );
        }

        for (final item in _tarjetas) {
          final amarillas = item.amarillas;
          final rojas = item.rojas;

          if (item.jugadorId == null || item.jugadorId!.isEmpty) {
            if (amarillas > 0 || rojas > 0) {
              throw Exception(
                'Selecciona un jugador en todos los registros de tarjetas.',
              );
            }
            continue;
          }

          if (amarillas == 0 && rojas == 0) {
            continue;
          }

          final jugador = jugadores.firstWhere((j) => j.id == item.jugadorId);

          tarjetasInputs.add(
            TarjetaJugadorInput(
              equipoId: jugador.equipoId,
              equipoNombre: jugador.equipoNombre,
              jugadorId: jugador.id,
              jugadorNombre: jugador.nombreCompleto,
              amarillas: amarillas,
              rojas: rojas,
              motivo: item.motivoController.text.trim().isEmpty
                  ? null
                  : item.motivoController.text.trim(),
            ),
          );
        }
      }

      // Vóley/básquet no tienen tarjetas: una sanción "por mesa" o
      // "forzada" se guarda con el mismo modelo (amarilla/roja) para que
      // el módulo de jugadores sancionados los muestre a todos juntos.
      if (!_esFutbol(campeonato) && _tipoResultado == TipoResultado.normal) {
        for (final item in _sanciones) {
          if (item.jugadorId == null || item.jugadorId!.isEmpty) {
            throw Exception(
              'Selecciona un jugador en todas las sanciones agregadas.',
            );
          }

          final jugador = jugadores.firstWhere((j) => j.id == item.jugadorId);

          tarjetasInputs.add(
            TarjetaJugadorInput(
              equipoId: jugador.equipoId,
              equipoNombre: jugador.equipoNombre,
              jugadorId: jugador.id,
              jugadorNombre: jugador.nombreCompleto,
              amarillas: item.tipo == SancionTipo.porMesa ? 1 : 0,
              rojas: item.tipo == SancionTipo.forzada ? 1 : 0,
              motivo: item.detalleController.text.trim().isEmpty
                  ? null
                  : item.detalleController.text.trim(),
            ),
          );
        }
      }

      await _resultadoService.registrarResultado(
        campeonatoId: widget.campeonatoId,
        partidoId: widget.partido.id,
        golesLocal: golesLocal,
        golesVisitante: golesVisitante,
        golesJugadores: golesInputs,
        tarjetasJugadores: tarjetasInputs,
        tipoResultado: _tipoResultado,
        observacionResultado: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        usuarioId: admin.id,
        usuarioNombre: admin.nombre,
        penalesLocal: penalesLocal,
        penalesVisitante: penalesVisitante,
        definidoPorProrroga: _esBasket(campeonato)
            ? _definidoPorProrroga
            : false,
        sets: setsInputs,
      );

      if (!mounted) return;

      AppSnackbars.success(context, 'Resultado registrado correctamente.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      AppSnackbars.error(context, mensajeDeError(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String? _requiredNumber(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) return 'Valor inválido.';
    return null;
  }

  /// En vóley y básquet, un walkover/sanción no se carga con marcador:
  /// el resultado lo fija el reglamento y solo hace falta saber qué
  /// equipo se presentó.
  bool _esAdministrativoConGanador(CampeonatoModel? campeonato) {
    if (_tipoResultado == TipoResultado.normal) return false;
    return _esVolley(campeonato) || _esBasket(campeonato);
  }

  /// Qué marcador se va a guardar, para mostrárselo al admin antes.
  String _detalleResultadoAdministrativo(CampeonatoModel? campeonato) {
    if (_esBasket(campeonato)) {
      return 'Se va a guardar ${TablaCalculo.puntosWalkoverBasket}-0 a favor suyo '
          '(${TablaCalculo.puntosWalkoverBasket} puntos a favor y 0 en contra).';
    }

    final sets = campeonato?.configuracion.setsParaGanar ?? 2;
    final puntos = campeonato?.configuracion.puntosSetNormal ?? 25;
    final marcador = List.filled(sets, '$puntos-0').join(' · ');

    return 'Se va a guardar $marcador a favor suyo '
        '(${sets * puntos} puntos a favor y 0 en contra).';
  }

  String _marcadorLabel(CampeonatoModel? campeonato) {
    if (_esBasket(campeonato)) return 'Puntos';
    return 'Goles';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_FormData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Cargando datos del partido...');
          }

          final data =
              snapshot.data ?? const _FormData(campeonato: null, jugadores: []);
          final campeonato = data.campeonato;
          final jugadores = data.jugadores;

          final esVolley = _esVolley(campeonato);
          final esBasket = _esBasket(campeonato);
          final esFutbol = _esFutbol(campeonato);

          return SingleChildScrollView(
            child: AppPage(
              title: 'Registrar resultado',
              subtitle:
                  '${widget.partido.equipoLocalNombre} vs ${widget.partido.equipoVisitanteNombre}',
              actions: [
                AppButton.secondary(
                  text: 'Cancelar',
                  icon: Icons.close,
                  onPressed: _loading ? null : () => Navigator.pop(context),
                ),
                AyudaBoton(
                  pantalla: PantallaAyuda.resultadoForm,
                  campeonatoId: widget.campeonatoId,
                ),
                AppButton.primary(
                  text: 'Guardar resultado',
                  icon: Icons.save_outlined,
                  loading: _loading,
                  onPressed: () => _guardar(data),
                ),
              ],
              child: AppCard(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      if (!esVolley && !_esAdministrativoConGanador(campeonato))
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: widget.partido.equipoLocalNombre,
                                hint: '${_marcadorLabel(campeonato)} local',
                                controller: _golesLocalController,
                                keyboardType: TextInputType.number,
                                prefixIcon: esBasket
                                    ? Icons.sports_basketball_outlined
                                    : Icons.sports_soccer,
                                validator: _requiredNumber,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: AppTextField(
                                label: widget.partido.equipoVisitanteNombre,
                                hint: '${_marcadorLabel(campeonato)} visitante',
                                controller: _golesVisitanteController,
                                keyboardType: TextInputType.number,
                                prefixIcon: esBasket
                                    ? Icons.sports_basketball_outlined
                                    : Icons.sports_soccer,
                                validator: _requiredNumber,
                              ),
                            ),
                          ],
                        ),
                      if (_esAdministrativoConGanador(campeonato)) ...[
                        _GanadorAdministrativoSelector(
                          partido: widget.partido,
                          ganadorId: _ganadorAdministrativo,
                          detalle: _detalleResultadoAdministrativo(campeonato),
                          onChanged: (value) =>
                              setState(() => _ganadorAdministrativo = value),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (esVolley &&
                          _tipoResultado == TipoResultado.normal) ...[
                        _SetsSection(
                          sets: _sets,
                          localNombre: widget.partido.equipoLocalNombre,
                          visitanteNombre: widget.partido.equipoVisitanteNombre,
                          setsGanados: _setsGanados(),
                          setsParaGanar:
                              campeonato?.configuracion.setsParaGanar ?? 2,
                          onAdd: _addSet,
                          onRemove: _removeSet,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 6),
                      ],
                      const SizedBox(height: 18),
                      AppDropdownField<String>(
                        label: 'Tipo de resultado',
                        value: _tipoResultado,
                        items: const [
                          DropdownMenuItem(
                            value: TipoResultado.normal,
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: TipoResultado.walkover,
                            child: Text('Walkover'),
                          ),
                          DropdownMenuItem(
                            value: TipoResultado.sancion,
                            child: Text('Sanción'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _tipoResultado = value;
                            if (_tipoResultado != TipoResultado.normal) {
                              _goles.clear();

                              for (final tarjeta in _tarjetas) {
                                tarjeta.dispose();
                              }

                              _tarjetas.clear();
                            }
                          });
                        },
                      ),
                      if (_tipoResultado != TipoResultado.normal) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Observación obligatoria',
                          hint:
                              'Ejemplo: resultado administrativo por ausencia del equipo.',
                          controller: _observacionController,
                          maxLines: 4,
                          prefixIcon: Icons.notes_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La observación es obligatoria.';
                            }
                            return null;
                          },
                        ),
                      ],
                      if (_mostrarPenales(campeonato)) ...[
                        const SizedBox(height: 22),
                        _PenalesSection(
                          localNombre: widget.partido.equipoLocalNombre,
                          visitanteNombre: widget.partido.equipoVisitanteNombre,
                          penalesLocalController: _penalesLocalController,
                          penalesVisitanteController:
                              _penalesVisitanteController,
                        ),
                      ],
                      if (esBasket &&
                          _tipoResultado == TipoResultado.normal) ...[
                        const SizedBox(height: 18),
                        SwitchListTile(
                          value: _definidoPorProrroga,
                          onChanged: (value) {
                            setState(() {
                              _definidoPorProrroga = value;
                            });
                          },
                          title: const Text('Definido por prórroga'),
                          subtitle: const Text(
                            'Activa esta opción si el partido se definió en tiempo extra. El marcador debe incluir los puntos de la prórroga.',
                          ),
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                        AppInfoBox(
                          tone: AppInfoBoxTone.primary,
                          text:
                              'El básquet no permite empate: registra los puntos finales con un ganador.',
                        ),
                      ],
                      if (esFutbol &&
                          _tipoResultado == TipoResultado.normal) ...[
                        const SizedBox(height: 22),
                        _GolesSection(
                          goles: _goles,
                          jugadores: jugadores,
                          onAdd: _addGol,
                          onRemove: _removeGol,
                          onRefresh: () => setState(() {}),
                        ),
                        const SizedBox(height: 24),
                        _TarjetasSection(
                          tarjetas: _tarjetas,
                          jugadores: jugadores,
                          onAdd: _addTarjeta,
                          onRemove: _removeTarjeta,
                          onRefresh: () => setState(() {}),
                        ),
                      ],
                      if (!esFutbol &&
                          _tipoResultado == TipoResultado.normal) ...[
                        const SizedBox(height: 22),
                        _SancionesSection(
                          sanciones: _sanciones,
                          jugadores: jugadores,
                          onAdd: _addSancion,
                          onRemove: _removeSancion,
                          onRefresh: () => setState(() {}),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormData {
  final CampeonatoModel? campeonato;
  final List<JugadorModel> jugadores;

  const _FormData({required this.campeonato, required this.jugadores});
}
