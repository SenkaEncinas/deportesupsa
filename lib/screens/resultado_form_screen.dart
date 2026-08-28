import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/jugador_model.dart';
import '../models/partido_model.dart';
import '../models/tarjeta_model.dart';
import '../services/auth_service.dart';
import '../services/campeonato_service.dart';
import '../services/jugador_service.dart';
import '../services/resultado_service.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';

class ResultadoFormScreen extends StatefulWidget {
  final String campeonatoId;
  final PartidoModel partido;

  /// Si la pantalla anterior ya tiene el campeonato cargado puede
  /// pasarlo para evitar una lectura extra; si no, se carga aquí.
  final CampeonatoModel? campeonato;

  const ResultadoFormScreen({
    super.key,
    required this.campeonatoId,
    required this.partido,
    this.campeonato,
  });

  @override
  State<ResultadoFormScreen> createState() => _ResultadoFormScreenState();
}

class _ResultadoFormScreenState extends State<ResultadoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _jugadorService = JugadorService();
  final _campeonatoService = CampeonatoService();
  final _resultadoService = ResultadoService();

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

  /// El formato exige ganador (sin empate) para fútbol/futsal. En
  /// formatos de dos fases (grupos+eliminación, liga+final,
  /// liga+playoffs), la fase de grupos/liga puede permitir empate pero
  /// la fase final no: esos cruces siempre se crean manualmente (todavía
  /// no hay generador automático de llaves), así que
  /// `generadoPorSistema == false` identifica de forma confiable un
  /// partido de fase final.
  bool _futbolRequiereGanador(CampeonatoModel? campeonato) {
    if (campeonato == null) return false;

    final formatoDosFases =
        campeonato.tipoCampeonato == TipoCampeonato.gruposEliminacion ||
        campeonato.tipoCampeonato == TipoCampeonato.ligaFinal ||
        campeonato.tipoCampeonato == TipoCampeonato.ligaPlayoffs;

    final esFaseFinal = formatoDosFases && !widget.partido.generadoPorSistema;

    return !campeonato.configuracion.permiteEmpate ||
        campeonato.tipoCampeonato == TipoCampeonato.eliminacionDirecta ||
        esFaseFinal;
  }

  bool _mostrarPenales(CampeonatoModel? campeonato) {
    if (!_esFutbol(campeonato)) return false;
    if (_tipoResultado != TipoResultado.normal) return false;
    if (!_futbolRequiereGanador(campeonato)) return false;

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

      if (_esVolley(campeonato)) {
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

        if (_mostrarPenales(campeonato)) {
          penalesLocal = _parseInt(_penalesLocalController.text);
          penalesVisitante = _parseInt(_penalesVisitanteController.text);
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

      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
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
                      if (!esVolley)
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
                      if (esVolley) ...[
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
                      _DropdownField<String>(
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
                        _InfoBox(
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

class _PenalesSection extends StatelessWidget {
  final String localNombre;
  final String visitanteNombre;
  final TextEditingController penalesLocalController;
  final TextEditingController penalesVisitanteController;

  const _PenalesSection({
    required this.localNombre,
    required this.visitanteNombre,
    required this.penalesLocalController,
    required this.penalesVisitanteController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sports, color: AppColors.warning, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Este formato no permite empate. Registra los penales para definir al ganador.',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF92600A),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Penales $localNombre',
                controller: penalesLocalController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.sports_soccer,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Valor inválido.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppTextField(
                label: 'Penales $visitanteNombre',
                controller: penalesVisitanteController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.sports_soccer,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Valor inválido.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SetsSection extends StatelessWidget {
  final List<_SetInputState> sets;
  final String localNombre;
  final String visitanteNombre;
  final ({int local, int visitante}) setsGanados;
  final int setsParaGanar;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;

  const _SetsSection({
    required this.sets,
    required this.localNombre,
    required this.visitanteNombre,
    required this.setsGanados,
    required this.setsParaGanar,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Sets del partido', style: AppTextStyles.heading3),
            ),
            AppButton.secondary(
              text: 'Agregar set',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Marcador en sets: $localNombre ${setsGanados.local} - ${setsGanados.visitante} $visitanteNombre · Gana el primero en llegar a $setsParaGanar sets.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (sets.isEmpty)
          _InfoBox(
            text:
                'Agrega cada set con los puntos de ambos equipos. Ejemplo: 25-20, 23-25, 15-12.',
          )
        else
          Column(
            children: List.generate(sets.length, (index) {
              final item = sets[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Set ${index + 1}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: item.localController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Local',
                          hintText: '25',
                        ),
                        onChanged: (_) => onChanged(),
                        validator: (value) {
                          final number = int.tryParse(value ?? '');
                          if (number == null || number < 0) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: item.visitanteController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Visitante',
                          hintText: '20',
                        ),
                        onChanged: (_) => onChanged(),
                        validator: (value) {
                          final number = int.tryParse(value ?? '');
                          if (number == null || number < 0) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _GolesSection extends StatelessWidget {
  final List<_GolInputState> goles;
  final List<JugadorModel> jugadores;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onRefresh;

  const _GolesSection({
    required this.goles,
    required this.jugadores,
    required this.onAdd,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Goles por jugador', style: AppTextStyles.heading3),
            ),
            AppButton.secondary(
              text: 'Agregar gol',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (goles.isEmpty)
          _InfoBox(
            text:
                'Agrega los goles por jugador. La suma debe coincidir con el resultado final.',
          )
        else
          Column(
            children: List.generate(goles.length, (index) {
              final item = goles[index];
              final isMobile = Responsive.isMobile(context);

              final jugadorDropdown = _DropdownField<String>(
                label: 'Jugador',
                value: item.jugadorId,
                items: jugadores.map((jugador) {
                  return DropdownMenuItem(
                    value: jugador.id,
                    child: Text(
                      '${jugador.nombreCompleto} - ${jugador.equipoNombre}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  item.jugadorId = value;
                  onRefresh();
                },
              );

              final cantidadField = _SmallNumberField(
                label: 'Goles',
                value: item.cantidad,
                onChanged: (value) {
                  item.cantidad = value;
                },
              );

              final deleteButton = IconButton(
                onPressed: () => onRemove(index),
                icon: const Icon(Icons.delete_outline),
              );

              // En móvil el dropdown va en su propia línea: compartir
              // fila con el campo numérico lo dejaba ilegible en 375 px.
              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      jugadorDropdown,
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: cantidadField),
                          const SizedBox(width: 8),
                          deleteButton,
                        ],
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: jugadorDropdown),
                    const SizedBox(width: 12),
                    Expanded(child: cantidadField),
                    const SizedBox(width: 8),
                    deleteButton,
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _TarjetasSection extends StatelessWidget {
  final List<_TarjetaInputState> tarjetas;
  final List<JugadorModel> jugadores;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onRefresh;

  const _TarjetasSection({
    required this.tarjetas,
    required this.jugadores,
    required this.onAdd,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tarjetas por jugador',
                style: AppTextStyles.heading3,
              ),
            ),
            AppButton.secondary(
              text: 'Agregar tarjeta',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tarjetas.isEmpty)
          _InfoBox(
            text:
                'Aquí puedes registrar amarillas y rojas por jugador. Si no hubo tarjetas, deja esta sección vacía.',
          )
        else
          Column(
            children: List.generate(tarjetas.length, (index) {
              final item = tarjetas[index];
              final isMobile = Responsive.isMobile(context);

              final jugadorDropdown = _DropdownField<String>(
                label: 'Jugador',
                value: item.jugadorId,
                items: jugadores.map((jugador) {
                  return DropdownMenuItem(
                    value: jugador.id,
                    child: Text(
                      '${jugador.nombreCompleto} - ${jugador.equipoNombre}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  item.jugadorId = value;
                  onRefresh();
                },
              );

              final amarillasField = _SmallNumberField(
                label: 'Amarillas',
                value: item.amarillas,
                onChanged: (value) {
                  item.amarillas = value;
                },
              );

              final rojasField = _SmallNumberField(
                label: 'Rojas',
                value: item.rojas,
                onChanged: (value) {
                  item.rojas = value;
                },
              );

              final deleteButton = IconButton(
                onPressed: () => onRemove(index),
                icon: const Icon(Icons.delete_outline),
              );

              final motivoField = TextFormField(
                controller: item.motivoController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo / detalle opcional',
                  hintText:
                      'Ejemplo: doble amarilla, conducta antideportiva...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              );

              // En móvil: jugador en su línea y los contadores debajo.
              // Los 4 elementos en una sola fila desbordaban en 375 px.
              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      jugadorDropdown,
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: amarillasField),
                          const SizedBox(width: 12),
                          Expanded(child: rojasField),
                          const SizedBox(width: 8),
                          deleteButton,
                        ],
                      ),
                      const SizedBox(height: 10),
                      motivoField,
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 3, child: jugadorDropdown),
                        const SizedBox(width: 12),
                        Expanded(child: amarillasField),
                        const SizedBox(width: 12),
                        Expanded(child: rojasField),
                        const SizedBox(width: 8),
                        deleteButton,
                      ],
                    ),
                    const SizedBox(height: 10),
                    motivoField,
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

/// Vóley y básquet no tienen tarjetas amarillas/rojas como el fútbol,
/// pero sí pueden tener una sanción a un jugador (por mesa o forzada,
/// como una descalificación). Esta sección es opcional: solo se llena
/// "si es necesario", igual que la de tarjetas en fútbol.
class _SancionesSection extends StatelessWidget {
  final List<_SancionInputState> sanciones;
  final List<JugadorModel> jugadores;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onRefresh;

  const _SancionesSection({
    required this.sanciones,
    required this.jugadores,
    required this.onAdd,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Sanciones a jugadores', style: AppTextStyles.heading3),
            ),
            AppButton.secondary(
              text: 'Agregar sanción',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sanciones.isEmpty)
          _InfoBox(
            text:
                'Solo si hubo un problema de mesa o una sanción a algún jugador. Si no pasó nada, deja esta sección vacía.',
          )
        else
          Column(
            children: List.generate(sanciones.length, (index) {
              final item = sanciones[index];
              final isMobile = Responsive.isMobile(context);

              final jugadorDropdown = _DropdownField<String>(
                label: 'Jugador',
                value: item.jugadorId,
                items: jugadores.map((jugador) {
                  return DropdownMenuItem(
                    value: jugador.id,
                    child: Text(
                      '${jugador.nombreCompleto} - ${jugador.equipoNombre}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  item.jugadorId = value;
                  onRefresh();
                },
              );

              final tipoDropdown = _DropdownField<String>(
                label: 'Tipo de sanción',
                value: item.tipo,
                items: const [
                  DropdownMenuItem(
                    value: SancionTipo.porMesa,
                    child: Text('Sanción por mesa'),
                  ),
                  DropdownMenuItem(
                    value: SancionTipo.forzada,
                    child: Text('Sanción forzada'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  item.tipo = value;
                  onRefresh();
                },
              );

              final deleteButton = IconButton(
                onPressed: () => onRemove(index),
                icon: const Icon(Icons.delete_outline),
              );

              final detalleField = TextFormField(
                controller: item.detalleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Detalle de lo ocurrido (opcional)',
                  hintText: 'Ejemplo: conducta antideportiva con el árbitro.',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              );

              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      jugadorDropdown,
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: tipoDropdown),
                          const SizedBox(width: 8),
                          deleteButton,
                        ],
                      ),
                      const SizedBox(height: 10),
                      detalleField,
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 3, child: jugadorDropdown),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: tipoDropdown),
                        const SizedBox(width: 8),
                        deleteButton,
                      ],
                    ),
                    const SizedBox(height: 10),
                    detalleField,
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GolInputState {
  String? jugadorId;
  int cantidad = 1;
}

class _TarjetaInputState {
  String? jugadorId;
  int amarillas = 1;
  int rojas = 0;
  final TextEditingController motivoController = TextEditingController();

  void dispose() {
    motivoController.dispose();
  }
}

class _SancionInputState {
  String? jugadorId;
  String tipo = SancionTipo.porMesa;
  final TextEditingController detalleController = TextEditingController();

  void dispose() {
    detalleController.dispose();
  }
}

class _SetInputState {
  final TextEditingController localController;
  final TextEditingController visitanteController;

  _SetInputState({int? local, int? visitante})
    : localController = TextEditingController(text: local?.toString() ?? ''),
      visitanteController = TextEditingController(
        text: visitante?.toString() ?? '',
      );

  void dispose() {
    localController.dispose();
    visitanteController.dispose();
  }
}

class _SmallNumberField extends StatelessWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;

  const _SmallNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(),
          onChanged: (value) {
            final parsed = int.tryParse(value) ?? 0;
            onChanged(parsed < 0 ? 0 : parsed);
          },
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 7),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(),
          style: AppTextStyles.body,
          dropdownColor: AppColors.surface,
        ),
      ],
    );
  }
}
