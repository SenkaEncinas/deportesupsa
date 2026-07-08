import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../services/auth_service.dart';
import '../services/campeonato_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_logo_mark.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';

class CampeonatoFormScreen extends StatefulWidget {
  const CampeonatoFormScreen({super.key});

  @override
  State<CampeonatoFormScreen> createState() => _CampeonatoFormScreenState();
}

class _CampeonatoFormScreenState extends State<CampeonatoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _campeonatoService = CampeonatoService();

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _temporadaController = TextEditingController();
  final _canchaController = TextEditingController(text: 'Cancha UPSA');

  final _minJugadoresController = TextEditingController(text: '5');
  final _maxJugadoresController = TextEditingController(text: '12');
  final _jugadoresCanchaController = TextEditingController(text: '5');

  final _vueltasController = TextEditingController(text: '2');
  final _cantidadGruposController = TextEditingController(text: '2');
  final _clasificanPorGrupoController = TextEditingController(text: '2');
  final _clasificadosPlayoffsController = TextEditingController(text: '4');

  // Configuración específica por deporte.
  final _periodosController = TextEditingController(text: '4');
  final _puntosSetNormalController = TextEditingController(text: '25');
  final _puntosSetDecisivoController = TextEditingController(text: '15');

  String _deporte = DeporteTipo.futbol;
  String _modalidad = ModalidadDeporte.futsal;
  int _setsParaGanar = 2; // mejor de 3
  String _tipoCampeonato = TipoCampeonato.idaVuelta;

  bool _generaCrucesAleatorios = true;
  bool _generaGruposAleatorios = true;
  bool _permiteEmpate = true;
  bool _idaYVueltaEnGrupos = false;
  bool _incluyeTercerLugar = false;

  bool _loading = false;

  static const List<_FormatoOption> _formatos = [
    _FormatoOption(
      value: TipoCampeonato.soloIda,
      title: 'Liga solo ida',
      subtitle: 'Todos contra todos una vez.',
      icon: Icons.looks_one_outlined,
    ),
    _FormatoOption(
      value: TipoCampeonato.idaVuelta,
      title: 'Liga ida y vuelta',
      subtitle: 'Todos contra todos dos veces.',
      icon: Icons.swap_horiz_rounded,
    ),
    _FormatoOption(
      value: TipoCampeonato.ligaFinal,
      title: 'Liga + final',
      subtitle: 'Tabla general y final entre los mejores.',
      icon: Icons.emoji_events_outlined,
    ),
    _FormatoOption(
      value: TipoCampeonato.ligaPlayoffs,
      title: 'Liga + playoffs',
      subtitle: 'Tabla general y fase final.',
      icon: Icons.account_tree_outlined,
    ),
    _FormatoOption(
      value: TipoCampeonato.faseGrupos,
      title: 'Fase de grupos',
      subtitle: 'Equipos divididos en grupos.',
      icon: Icons.grid_view_rounded,
    ),
    _FormatoOption(
      value: TipoCampeonato.gruposEliminacion,
      title: 'Grupos + eliminación',
      subtitle: 'Grupos y luego llaves finales.',
      icon: Icons.hub_outlined,
    ),
    _FormatoOption(
      value: TipoCampeonato.eliminacionDirecta,
      title: 'Eliminación directa',
      subtitle: 'Llaves de partido único.',
      icon: Icons.bolt_outlined,
    ),
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _temporadaController.dispose();
    _canchaController.dispose();
    _minJugadoresController.dispose();
    _maxJugadoresController.dispose();
    _jugadoresCanchaController.dispose();
    _vueltasController.dispose();
    _cantidadGruposController.dispose();
    _clasificanPorGrupoController.dispose();
    _clasificadosPlayoffsController.dispose();
    _periodosController.dispose();
    _puntosSetNormalController.dispose();
    _puntosSetDecisivoController.dispose();
    super.dispose();
  }

  bool get _esVolley => _deporte == DeporteTipo.volley;
  bool get _esBasket => _deporte == DeporteTipo.basket;
  bool get _esFutbol => _deporte == DeporteTipo.futbol;

  void _aplicarDeporte(String deporte) {
    setState(() {
      _deporte = deporte;

      if (deporte == DeporteTipo.volley) {
        _modalidad = ModalidadDeporte.volleySala;
        _jugadoresCanchaController.text = '6';
        _minJugadoresController.text = '6';
        _maxJugadoresController.text = '14';
        _setsParaGanar = 2;
        _puntosSetNormalController.text = '25';
        _puntosSetDecisivoController.text = '15';
        _permiteEmpate = false; // el vóley nunca empata
      } else if (deporte == DeporteTipo.basket) {
        _modalidad = ModalidadDeporte.basket5;
        _jugadoresCanchaController.text = '5';
        _minJugadoresController.text = '5';
        _maxJugadoresController.text = '12';
        _periodosController.text = '4';
        _permiteEmpate = false; // el básquet no permite empate final
      } else {
        _modalidad = ModalidadDeporte.futsal;
        _jugadoresCanchaController.text = '5';
        _minJugadoresController.text = '5';
        _maxJugadoresController.text = '12';
        _permiteEmpate =
            _tipoCampeonato != TipoCampeonato.eliminacionDirecta;
      }
    });
  }

  void _aplicarModalidad(String modalidad) {
    setState(() {
      _modalidad = modalidad;

      switch (modalidad) {
        case ModalidadDeporte.futsal:
          _jugadoresCanchaController.text = '5';
          _minJugadoresController.text = '5';
          _maxJugadoresController.text = '12';
          break;
        case ModalidadDeporte.futbol11:
          _jugadoresCanchaController.text = '11';
          _minJugadoresController.text = '11';
          _maxJugadoresController.text = '25';
          break;
        case ModalidadDeporte.futbol7:
          _jugadoresCanchaController.text = '7';
          _minJugadoresController.text = '7';
          _maxJugadoresController.text = '16';
          break;
        case ModalidadDeporte.volleySala:
        case ModalidadDeporte.volleyMixto:
          _jugadoresCanchaController.text = '6';
          _minJugadoresController.text = '6';
          _maxJugadoresController.text = '14';
          break;
        case ModalidadDeporte.basket5:
          _jugadoresCanchaController.text = '5';
          _minJugadoresController.text = '5';
          _maxJugadoresController.text = '12';
          _periodosController.text = '4';
          break;
        case ModalidadDeporte.basket3x3:
          _jugadoresCanchaController.text = '3';
          _minJugadoresController.text = '3';
          _maxJugadoresController.text = '6';
          _periodosController.text = '1';
          break;
      }
    });
  }

  void _aplicarFormato(String tipo) {
    // El empate solo aplica a fútbol/futsal en formatos de liga o grupos.
    final permiteEmpateBase = _esFutbol;

    setState(() {
      _tipoCampeonato = tipo;

      switch (tipo) {
        case TipoCampeonato.soloIda:
          _vueltasController.text = '1';
          _permiteEmpate = permiteEmpateBase;
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = false;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.idaVuelta:
          _vueltasController.text = '2';
          _permiteEmpate = permiteEmpateBase;
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = false;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.ligaFinal:
          _vueltasController.text = '1';
          _clasificadosPlayoffsController.text = '2';
          _permiteEmpate = permiteEmpateBase;
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = false;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.ligaPlayoffs:
          _vueltasController.text = '1';
          _clasificadosPlayoffsController.text = '4';
          _permiteEmpate = permiteEmpateBase;
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = false;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.faseGrupos:
          _vueltasController.text = '1';
          _cantidadGruposController.text = '2';
          _clasificanPorGrupoController.text = '0';
          _permiteEmpate = permiteEmpateBase;
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = true;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.gruposEliminacion:
          _vueltasController.text = '1';
          _cantidadGruposController.text = '2';
          _clasificanPorGrupoController.text = '2';
          _permiteEmpate = permiteEmpateBase;
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = true;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.eliminacionDirecta:
          _vueltasController.text = '1';
          _permiteEmpate = false;
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = false;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;
      }
    });
  }

  int _intValue(TextEditingController controller, int fallback) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  bool get _usaGrupos {
    return _tipoCampeonato == TipoCampeonato.faseGrupos ||
        _tipoCampeonato == TipoCampeonato.gruposEliminacion;
  }

  bool get _usaEliminatoria {
    return _tipoCampeonato == TipoCampeonato.eliminacionDirecta ||
        _tipoCampeonato == TipoCampeonato.gruposEliminacion ||
        _tipoCampeonato == TipoCampeonato.ligaFinal ||
        _tipoCampeonato == TipoCampeonato.ligaPlayoffs;
  }

  bool get _usaPlayoffs {
    return _tipoCampeonato == TipoCampeonato.ligaFinal ||
        _tipoCampeonato == TipoCampeonato.ligaPlayoffs;
  }

  bool get _usaLiga {
    return _tipoCampeonato == TipoCampeonato.soloIda ||
        _tipoCampeonato == TipoCampeonato.idaVuelta ||
        _tipoCampeonato == TipoCampeonato.ligaFinal ||
        _tipoCampeonato == TipoCampeonato.ligaPlayoffs;
  }

  String _formatoBase() {
    switch (_tipoCampeonato) {
      case TipoCampeonato.soloIda:
      case TipoCampeonato.idaVuelta:
        return 'liga';

      case TipoCampeonato.ligaFinal:
        return 'liga_final';

      case TipoCampeonato.ligaPlayoffs:
        return 'liga_playoffs';

      case TipoCampeonato.faseGrupos:
        return 'grupos';

      case TipoCampeonato.gruposEliminacion:
        return 'grupos_eliminacion';

      case TipoCampeonato.eliminacionDirecta:
        return 'eliminacion_directa';

      default:
        return 'liga';
    }
  }

  bool _generaTablaPosiciones() {
    return _tipoCampeonato != TipoCampeonato.eliminacionDirecta;
  }

  String _rondaEliminatoriaInicial() {
    if (_tipoCampeonato == TipoCampeonato.ligaFinal) return 'final';
    if (_tipoCampeonato == TipoCampeonato.ligaPlayoffs) {
      final clasificados = _intValue(_clasificadosPlayoffsController, 4);

      if (clasificados <= 2) return 'final';
      if (clasificados <= 4) return 'semifinal';
      return 'cuartos';
    }

    if (_tipoCampeonato == TipoCampeonato.gruposEliminacion) {
      final grupos = _intValue(_cantidadGruposController, 2);
      final clasificados = _intValue(_clasificanPorGrupoController, 2);
      final total = grupos * clasificados;

      if (total <= 2) return 'final';
      if (total <= 4) return 'semifinal';
      return 'cuartos';
    }

    if (_tipoCampeonato == TipoCampeonato.eliminacionDirecta) {
      return 'llaves';
    }

    return 'no_aplica';
  }

  CampeonatoConfig _buildConfig() {
    final jugadoresEnCancha = _intValue(_jugadoresCanchaController, 5);
    final minJugadores = _intValue(_minJugadoresController, 5);
    final maxJugadores = _intValue(_maxJugadoresController, 12);
    final vueltas = _intValue(_vueltasController, 1);
    final cantidadGrupos = _usaGrupos ? _intValue(_cantidadGruposController, 2) : 0;
    final clasificanPorGrupo = _tipoCampeonato == TipoCampeonato.gruposEliminacion
        ? _intValue(_clasificanPorGrupoController, 2)
        : 0;
    final clasificadosPlayoffs =
        _usaPlayoffs ? _intValue(_clasificadosPlayoffsController, 4) : 0;

    // El vóley y el básquet nunca permiten empate.
    final permiteEmpateFinal = _esFutbol && _permiteEmpate;

    return CampeonatoConfig(
      formato: _formatoBase(),
      cantidadVueltas: _usaGrupos
          ? (_idaYVueltaEnGrupos ? 2 : 1)
          : vueltas,
      idaYVuelta: _usaGrupos
          ? _idaYVueltaEnGrupos
          : vueltas >= 2 || _tipoCampeonato == TipoCampeonato.idaVuelta,
      generaCrucesAleatorios: _generaCrucesAleatorios,
      generaGruposAleatorios: _usaGrupos ? _generaGruposAleatorios : false,
      permiteEmpate: permiteEmpateFinal,
      generaTablaPosiciones: _generaTablaPosiciones(),
      cantidadJugadoresEnCancha: jugadoresEnCancha,
      cantidadMinimaJugadoresPorEquipo: minJugadores,
      cantidadMaximaJugadoresPorEquipo: maxJugadores,
      cantidadGrupos: cantidadGrupos,
      clasificanPorGrupo: clasificanPorGrupo,
      clasificadosPlayoffs: clasificadosPlayoffs,
      idaYVueltaEnGrupos: _usaGrupos && _idaYVueltaEnGrupos,
      incluyeTercerLugar: _usaEliminatoria && _incluyeTercerLugar,
      generaFaseEliminatoria: _usaEliminatoria,
      fixtureManualPermitido: true,
      rondaEliminatoriaInicial: _rondaEliminatoriaInicial(),
      deporte: _deporte,
      modalidad: _modalidad,
      sistemaResultado: SistemaResultado.porDeporte(_deporte),
      setsParaGanar: _esVolley ? _setsParaGanar : 2,
      puntosSetNormal:
          _esVolley ? _intValue(_puntosSetNormalController, 25) : 25,
      puntosSetDecisivo:
          _esVolley ? _intValue(_puntosSetDecisivoController, 15) : 15,
      cantidadPeriodos: _esBasket ? _intValue(_periodosController, 4) : 0,
      // En fútbol, si el formato no permite empate se definen penales.
      permitePenales: _esFutbol && !permiteEmpateFinal,
      // El básquet define los empates con prórroga.
      permiteProrroga: _esBasket,
    );
  }

  void _validarConfiguracion() {
    final jugadoresEnCancha = _intValue(_jugadoresCanchaController, 5);
    final minJugadores = _intValue(_minJugadoresController, 5);
    final maxJugadores = _intValue(_maxJugadoresController, 12);

    if (minJugadores > maxJugadores) {
      throw Exception(
        'La cantidad mínima de jugadores no puede ser mayor a la máxima.',
      );
    }

    if (jugadoresEnCancha > maxJugadores) {
      throw Exception(
        'Los jugadores en cancha no pueden superar la cantidad máxima por equipo.',
      );
    }

    if (jugadoresEnCancha > minJugadores) {
      throw Exception(
        'El mínimo por equipo debe ser igual o mayor a los jugadores en cancha.',
      );
    }

    if (_usaLiga) {
      final vueltas = _intValue(_vueltasController, 0);
      if (vueltas <= 0) {
        throw Exception('La cantidad de vueltas debe ser mayor a cero.');
      }
    }

    if (_usaGrupos) {
      final grupos = _intValue(_cantidadGruposController, 0);

      if (grupos < 2) {
        throw Exception('La cantidad de grupos debe ser al menos 2.');
      }
    }

    if (_tipoCampeonato == TipoCampeonato.gruposEliminacion) {
      final clasifican = _intValue(_clasificanPorGrupoController, 0);

      if (clasifican <= 0) {
        throw Exception('Debe clasificar al menos 1 equipo por grupo.');
      }
    }

    if (_usaPlayoffs) {
      final clasificados = _intValue(_clasificadosPlayoffsController, 0);

      if (clasificados < 2) {
        throw Exception('Deben clasificar al menos 2 equipos a la fase final.');
      }

      if (clasificados != 2 && clasificados != 4 && clasificados != 8) {
        throw Exception(
          'Los clasificados a playoffs deben ser 2, 4 u 8 para que el fixture pueda generar llaves ordenadas.',
        );
      }
    }

    if (_esVolley) {
      final setNormal = _intValue(_puntosSetNormalController, 0);
      final setDecisivo = _intValue(_puntosSetDecisivoController, 0);

      if (setNormal <= 0 || setDecisivo <= 0) {
        throw Exception('Los puntos por set deben ser mayores a cero.');
      }

      if (_setsParaGanar != 2 && _setsParaGanar != 3) {
        throw Exception(
          'El partido de vóley debe ser al mejor de 3 o al mejor de 5 sets.',
        );
      }
    }

    if (_esBasket) {
      final periodos = _intValue(_periodosController, 0);

      if (periodos <= 0) {
        throw Exception('La cantidad de periodos debe ser mayor a cero.');
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      _validarConfiguracion();

      final admin = await _authService.requireAdmin();
      final config = _buildConfig();

      await _campeonatoService.crearCampeonato(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        deporte: _deporte,
        modalidad: _modalidad,
        tipoCampeonato: _tipoCampeonato,
        temporada: _temporadaController.text,
        cancha: _canchaController.text,
        configuracion: config,
        creadoPor: admin.id,
      );

      if (!mounted) return;

      AppSnackbars.success(context, 'Campeonato creado correctamente.');

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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF5F1),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: AppPage(
              title: 'Nuevo campeonato',
              subtitle:
                  'Configura la modalidad deportiva, el formato de competencia y las reglas base.',
              actions: [
                AppButton.secondary(
                  text: isMobile ? 'Cancelar' : 'Cancelar',
                  icon: Icons.close_rounded,
                  onPressed: _loading ? null : () => Navigator.pop(context),
                ),
                AppButton.primary(
                  text: 'Guardar',
                  icon: Icons.save_outlined,
                  loading: _loading,
                  onPressed: _guardar,
                ),
              ],
              child: Column(
                children: [
                  _HeroCard(
                    tipoCampeonato: _tipoCampeonato,
                    deporte: _deporte,
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const _SectionTitle(
                            title: 'Datos generales',
                            subtitle:
                                'Estos datos se mostrarán en la pantalla pública del campeonato.',
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            label: 'Nombre del campeonato',
                            hint: 'Ejemplo: Campeonato UPSA Futsal 2026',
                            controller: _nombreController,
                            prefixIcon: Icons.emoji_events_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es obligatorio.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Descripción',
                            hint:
                                'Ejemplo: Campeonato universitario masculino organizado por la UPSA.',
                            controller: _descripcionController,
                            maxLines: 3,
                            prefixIcon: Icons.description_outlined,
                          ),
                          const SizedBox(height: 16),
                          _ResponsiveFields(
                            children: [
                              AppTextField(
                                label: 'Temporada',
                                hint: '2026',
                                controller: _temporadaController,
                                prefixIcon: Icons.calendar_today_outlined,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'La temporada es obligatoria.';
                                  }
                                  return null;
                                },
                              ),
                              AppTextField(
                                label: 'Cancha',
                                hint: 'Cancha UPSA',
                                controller: _canchaController,
                                prefixIcon: Icons.place_outlined,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'La cancha es obligatoria.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const _SectionTitle(
                            title: 'Deporte',
                            subtitle:
                                'Elige el deporte del campeonato. La modalidad y las reglas base se ajustan automáticamente.',
                          ),
                          const SizedBox(height: 18),
                          _DeporteSelector(
                            selected: _deporte,
                            onSelected: _aplicarDeporte,
                          ),
                          const SizedBox(height: 28),
                          const _SectionTitle(
                            title: 'Configuración deportiva',
                            subtitle:
                                'Modalidad, jugadores en cancha y tamaño de plantilla por equipo.',
                          ),
                          const SizedBox(height: 18),
                          _ResponsiveFields(
                            children: [
                              _DropdownField<String>(
                                // La key fuerza a reconstruir el dropdown
                                // cuando cambia el deporte seleccionado.
                                key: ValueKey('modalidad_$_deporte'),
                                label: 'Modalidad',
                                value: _modalidad,
                                items: ModalidadDeporte.porDeporte(_deporte)
                                    .map((modalidad) {
                                  return DropdownMenuItem(
                                    value: modalidad,
                                    child: Text(_modalidadTexto(modalidad)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  _aplicarModalidad(value);
                                },
                              ),
                              AppTextField(
                                label: 'Jugadores en cancha',
                                controller: _jugadoresCanchaController,
                                keyboardType: TextInputType.number,
                                prefixIcon: _deporteIcono(_deporte),
                                validator: _numberValidator,
                              ),
                              AppTextField(
                                label: 'Mínimo por equipo',
                                controller: _minJugadoresController,
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.group_outlined,
                                validator: _numberValidator,
                              ),
                              AppTextField(
                                label: 'Máximo por equipo',
                                controller: _maxJugadoresController,
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.groups_2_outlined,
                                validator: _numberValidator,
                              ),
                            ],
                          ),
                          if (_esVolley) ...[
                            const SizedBox(height: 16),
                            _ResponsiveFields(
                              children: [
                                _DropdownField<int>(
                                  label: 'Formato del partido',
                                  value: _setsParaGanar,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text('Al mejor de 3 sets'),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text('Al mejor de 5 sets'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _setsParaGanar = value;
                                    });
                                  },
                                ),
                                AppTextField(
                                  label: 'Puntos por set normal',
                                  controller: _puntosSetNormalController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.scoreboard_outlined,
                                  validator: _numberValidator,
                                ),
                                AppTextField(
                                  label: 'Puntos set decisivo',
                                  controller: _puntosSetDecisivoController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.flag_outlined,
                                  validator: _numberValidator,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _InfoBox(
                              title: 'Vóley',
                              message:
                                  'Los sets se ganan por diferencia de 2 puntos. No existen empates: gana quien alcance los sets necesarios.',
                              secondary: true,
                            ),
                          ],
                          if (_esBasket) ...[
                            const SizedBox(height: 16),
                            _ResponsiveFields(
                              children: [
                                AppTextField(
                                  label: 'Cantidad de periodos',
                                  controller: _periodosController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.timer_outlined,
                                  validator: _numberValidator,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _InfoBox(
                              title: 'Básquet',
                              message:
                                  'No se permite empate final: si el marcador queda igualado se juega prórroga hasta definir un ganador.',
                              secondary: true,
                            ),
                          ],
                          const SizedBox(height: 28),
                          const _SectionTitle(
                            title: 'Formato del campeonato',
                            subtitle:
                                'Elige cómo se organizarán los partidos. Esta información se usará luego para generar el fixture.',
                          ),
                          const SizedBox(height: 18),
                          _FormatoSelector(
                            formatos: _formatos,
                            selected: _tipoCampeonato,
                            onSelected: _aplicarFormato,
                          ),
                          const SizedBox(height: 24),
                          _DynamicFormatSection(
                            tipoCampeonato: _tipoCampeonato,
                            esFutbol: _esFutbol,
                            vueltasController: _vueltasController,
                            cantidadGruposController: _cantidadGruposController,
                            clasificanPorGrupoController:
                                _clasificanPorGrupoController,
                            clasificadosPlayoffsController:
                                _clasificadosPlayoffsController,
                            generaCrucesAleatorios: _generaCrucesAleatorios,
                            generaGruposAleatorios: _generaGruposAleatorios,
                            permiteEmpate: _permiteEmpate,
                            idaYVueltaEnGrupos: _idaYVueltaEnGrupos,
                            incluyeTercerLugar: _incluyeTercerLugar,
                            onGeneraCrucesChanged: (value) {
                              setState(() {
                                _generaCrucesAleatorios = value;
                              });
                            },
                            onGeneraGruposChanged: (value) {
                              setState(() {
                                _generaGruposAleatorios = value;
                              });
                            },
                            onPermiteEmpateChanged: (value) {
                              setState(() {
                                _permiteEmpate = value;
                              });
                            },
                            onIdaYVueltaGruposChanged: (value) {
                              setState(() {
                                _idaYVueltaEnGrupos = value;
                              });
                            },
                            onTercerLugarChanged: (value) {
                              setState(() {
                                _incluyeTercerLugar = value;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          _InfoBox(
                            title: 'Estado inicial',
                            message:
                                'El campeonato se creará en estado inscripción. En ese estado podrás registrar equipos y jugadores antes de activarlo.',
                          ),
                          const SizedBox(height: 12),
                          _InfoBox(
                            title: 'Fixture',
                            message:
                                'Por ahora esta configuración queda guardada. En el siguiente paso ajustaremos el generador de fixture para que respete cada formato.',
                            secondary: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _numberValidator(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number <= 0) {
      return 'Valor inválido.';
    }

    return null;
  }
}

class _HeroCard extends StatelessWidget {
  final String tipoCampeonato;
  final String deporte;

  const _HeroCard({
    required this.tipoCampeonato,
    required this.deporte,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF003D2D),
              Color(0xFF005C45),
              AppColors.primary,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 22 : 30),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogoMark(),
                    const SizedBox(height: 20),
                    _HeroText(
                      tipoCampeonato: tipoCampeonato,
                      deporte: deporte,
                    ),
                  ],
                )
              : Row(
                  children: [
                    const AppLogoMark(),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _HeroText(
                        tipoCampeonato: tipoCampeonato,
                        deporte: deporte,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final String tipoCampeonato;
  final String deporte;

  const _HeroText({
    required this.tipoCampeonato,
    required this.deporte,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            const AppBadge(
              text: 'Nuevo',
              type: AppBadgeType.success,
              icon: Icons.add_circle_outline,
            ),
            AppBadge(
              text: _deporteTexto(deporte),
              type: AppBadgeType.warning,
              icon: _deporteIcono(deporte),
            ),
            AppBadge(
              text: _tipoTexto(tipoCampeonato),
              type: AppBadgeType.primary,
              icon: Icons.account_tree_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Crear campeonato UPSA',
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.white,
            fontSize: isMobile ? 26 : 34,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Define los datos generales, la modalidad deportiva y el formato de competencia para que el sistema pueda preparar el fixture correctamente.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.white.withValues(alpha: 0.88),
            fontSize: isMobile ? 14 : 15,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _DynamicFormatSection extends StatelessWidget {
  final String tipoCampeonato;
  final bool esFutbol;
  final TextEditingController vueltasController;
  final TextEditingController cantidadGruposController;
  final TextEditingController clasificanPorGrupoController;
  final TextEditingController clasificadosPlayoffsController;
  final bool generaCrucesAleatorios;
  final bool generaGruposAleatorios;
  final bool permiteEmpate;
  final bool idaYVueltaEnGrupos;
  final bool incluyeTercerLugar;
  final ValueChanged<bool> onGeneraCrucesChanged;
  final ValueChanged<bool> onGeneraGruposChanged;
  final ValueChanged<bool> onPermiteEmpateChanged;
  final ValueChanged<bool> onIdaYVueltaGruposChanged;
  final ValueChanged<bool> onTercerLugarChanged;

  const _DynamicFormatSection({
    required this.tipoCampeonato,
    required this.esFutbol,
    required this.vueltasController,
    required this.cantidadGruposController,
    required this.clasificanPorGrupoController,
    required this.clasificadosPlayoffsController,
    required this.generaCrucesAleatorios,
    required this.generaGruposAleatorios,
    required this.permiteEmpate,
    required this.idaYVueltaEnGrupos,
    required this.incluyeTercerLugar,
    required this.onGeneraCrucesChanged,
    required this.onGeneraGruposChanged,
    required this.onPermiteEmpateChanged,
    required this.onIdaYVueltaGruposChanged,
    required this.onTercerLugarChanged,
  });

  bool get _usaGrupos {
    return tipoCampeonato == TipoCampeonato.faseGrupos ||
        tipoCampeonato == TipoCampeonato.gruposEliminacion;
  }

  bool get _usaEliminatoria {
    return tipoCampeonato == TipoCampeonato.eliminacionDirecta ||
        tipoCampeonato == TipoCampeonato.gruposEliminacion ||
        tipoCampeonato == TipoCampeonato.ligaFinal ||
        tipoCampeonato == TipoCampeonato.ligaPlayoffs;
  }

  bool get _usaPlayoffs {
    return tipoCampeonato == TipoCampeonato.ligaFinal ||
        tipoCampeonato == TipoCampeonato.ligaPlayoffs;
  }

  bool get _usaLiga {
    return tipoCampeonato == TipoCampeonato.soloIda ||
        tipoCampeonato == TipoCampeonato.idaVuelta ||
        tipoCampeonato == TipoCampeonato.ligaFinal ||
        tipoCampeonato == TipoCampeonato.ligaPlayoffs;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reglas del formato seleccionado',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 6),
          Text(
            _descripcionFormato(tipoCampeonato),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          if (_usaLiga)
            _ResponsiveFields(
              children: [
                AppTextField(
                  label: 'Cantidad de vueltas',
                  hint: '1 o 2',
                  controller: vueltasController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.repeat_rounded,
                  enabled: tipoCampeonato != TipoCampeonato.soloIda &&
                      tipoCampeonato != TipoCampeonato.idaVuelta,
                  validator: _numberValidator,
                ),
                // El empate solo es configurable en fútbol/futsal:
                // vóley y básquet siempre definen un ganador.
                if (esFutbol)
                  _ConfigSwitch(
                    title: 'Permitir empate',
                    subtitle:
                        'Aplica para partidos de liga o fase de clasificación.',
                    value: permiteEmpate,
                    onChanged: onPermiteEmpateChanged,
                  )
                else
                  const _ConfigInfoTile(
                    title: 'Sin empates',
                    subtitle:
                        'Este deporte siempre define un ganador por reglamento.',
                  ),
              ],
            ),
          if (_usaGrupos) ...[
            if (_usaLiga) const SizedBox(height: 16),
            _ResponsiveFields(
              children: [
                AppTextField(
                  label: 'Cantidad de grupos',
                  hint: 'Ejemplo: 2',
                  controller: cantidadGruposController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.grid_view_rounded,
                  validator: _numberValidator,
                ),
                if (tipoCampeonato == TipoCampeonato.gruposEliminacion)
                  AppTextField(
                    label: 'Clasifican por grupo',
                    hint: 'Ejemplo: 2',
                    controller: clasificanPorGrupoController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.military_tech_outlined,
                    validator: _numberValidator,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _ResponsiveFields(
              children: [
                _ConfigSwitch(
                  title: 'Grupos aleatorios',
                  subtitle:
                      'El sistema podrá distribuir equipos aleatoriamente.',
                  value: generaGruposAleatorios,
                  onChanged: onGeneraGruposChanged,
                ),
                _ConfigSwitch(
                  title: 'Ida y vuelta en grupos',
                  subtitle:
                      'Cada equipo juega dos veces contra sus rivales de grupo.',
                  value: idaYVueltaEnGrupos,
                  onChanged: onIdaYVueltaGruposChanged,
                ),
              ],
            ),
          ],
          if (_usaPlayoffs) ...[
            if (_usaLiga || _usaGrupos) const SizedBox(height: 16),
            _ResponsiveFields(
              children: [
                AppTextField(
                  label: tipoCampeonato == TipoCampeonato.ligaFinal
                      ? 'Clasificados a final'
                      : 'Clasificados a playoffs',
                  hint: tipoCampeonato == TipoCampeonato.ligaFinal ? '2' : '4',
                  controller: clasificadosPlayoffsController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.workspace_premium_outlined,
                  enabled: tipoCampeonato != TipoCampeonato.ligaFinal,
                  validator: _numberValidator,
                ),
                _ConfigSwitch(
                  title: 'Cruces aleatorios',
                  subtitle:
                      'El sistema podrá generar los cruces automáticamente.',
                  value: generaCrucesAleatorios,
                  onChanged: onGeneraCrucesChanged,
                ),
              ],
            ),
          ],
          if (tipoCampeonato == TipoCampeonato.eliminacionDirecta) ...[
            const SizedBox(height: 16),
            _ConfigSwitch(
              title: 'Cruces aleatorios',
              subtitle:
                  'El sistema podrá sortear los cruces iniciales de eliminación.',
              value: generaCrucesAleatorios,
              onChanged: onGeneraCrucesChanged,
            ),
          ],
          if (_usaEliminatoria) ...[
            const SizedBox(height: 16),
            _ConfigSwitch(
              title: 'Incluir partido por tercer lugar',
              subtitle:
                  'Útil cuando la organización quiere definir primer, segundo y tercer puesto.',
              value: incluyeTercerLugar,
              onChanged: onTercerLugarChanged,
            ),
          ],
        ],
      ),
    );
  }

  String? _numberValidator(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number <= 0) {
      return 'Valor inválido.';
    }

    return null;
  }
}

class _FormatoSelector extends StatelessWidget {
  final List<_FormatoOption> formatos;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FormatoSelector({
    required this.formatos,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);
        final columns = isMobile
            ? 1
            : constraints.maxWidth < 950
                ? 2
                : 3;

        const spacing = 14.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: formatos.map((formato) {
            return SizedBox(
              width: width,
              child: _FormatoCard(
                option: formato,
                selected: selected == formato.value,
                onTap: () => onSelected(formato.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FormatoCard extends StatelessWidget {
  final _FormatoOption option;
  final bool selected;
  final VoidCallback onTap;

  const _FormatoCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: selected ? AppColors.primaryLight : AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Icon(
              option.icon,
              color: selected ? AppColors.white : AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    color: selected
                        ? AppColors.primaryDark.withValues(alpha: 0.75)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfigInfoTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ConfigInfoTile({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConfigSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveFields({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumn = Responsive.isMobile(context) || constraints.maxWidth < 860;

        if (useColumn) {
          return Column(
            children: List.generate(children.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < children.length - 1 ? 14 : 0,
                ),
                child: children[index],
              );
            }),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(children.length, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < children.length - 1 ? 14 : 0,
                ),
                child: children[index],
              ),
            );
          }),
        );
      },
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String message;
  final bool secondary;

  const _InfoBox({
    required this.title,
    required this.message,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondary ? AppColors.infoLight : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: secondary
              ? AppColors.info.withValues(alpha: 0.16)
              : AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            secondary ? Icons.info_outline : Icons.verified_outlined,
            color: secondary ? AppColors.info : AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.body.copyWith(
                  color: secondary ? AppColors.info : AppColors.primaryDark,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading3),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _DropdownField({
    super.key,
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
          isExpanded: true,
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

class _FormatoOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _FormatoOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _DeporteSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _DeporteSelector({
    required this.selected,
    required this.onSelected,
  });

  static const List<_FormatoOption> _deportes = [
    _FormatoOption(
      value: DeporteTipo.futbol,
      title: 'Fútbol / Futsal',
      subtitle: 'Resultado por goles, con goleadores y tarjetas.',
      icon: Icons.sports_soccer,
    ),
    _FormatoOption(
      value: DeporteTipo.volley,
      title: 'Vóley',
      subtitle: 'Resultado por sets, sin empates.',
      icon: Icons.sports_volleyball_outlined,
    ),
    _FormatoOption(
      value: DeporteTipo.basket,
      title: 'Básquet',
      subtitle: 'Resultado por puntos, con prórroga.',
      icon: Icons.sports_basketball_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);
        final columns = isMobile ? 1 : 3;

        const spacing = 14.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _deportes.map((deporte) {
            return SizedBox(
              width: width,
              child: _FormatoCard(
                option: deporte,
                selected: selected == deporte.value,
                onTap: () => onSelected(deporte.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

String _modalidadTexto(String modalidad) {
  switch (modalidad) {
    case ModalidadDeporte.futsal:
      return 'Futsal';
    case ModalidadDeporte.futbol7:
      return 'Fútbol 7';
    case ModalidadDeporte.futbol11:
      return 'Fútbol 11';
    case ModalidadDeporte.volleySala:
      return 'Vóley sala';
    case ModalidadDeporte.volleyMixto:
      return 'Vóley mixto';
    case ModalidadDeporte.basket5:
      return 'Básquet 5';
    case ModalidadDeporte.basket3x3:
      return 'Básquet 3x3';
    default:
      return modalidad.replaceAll('_', ' ');
  }
}

IconData _deporteIcono(String deporte) {
  switch (deporte) {
    case DeporteTipo.volley:
      return Icons.sports_volleyball_outlined;
    case DeporteTipo.basket:
      return Icons.sports_basketball_outlined;
    default:
      return Icons.sports_soccer;
  }
}

String _deporteTexto(String deporte) {
  switch (deporte) {
    case DeporteTipo.volley:
      return 'Vóley';
    case DeporteTipo.basket:
      return 'Básquet';
    default:
      return 'Fútbol / Futsal';
  }
}

String _tipoTexto(String tipo) {
  switch (tipo) {
    case TipoCampeonato.soloIda:
      return 'Liga solo ida';
    case TipoCampeonato.idaVuelta:
      return 'Liga ida y vuelta';
    case TipoCampeonato.eliminacionDirecta:
      return 'Eliminación directa';
    case TipoCampeonato.faseGrupos:
      return 'Fase de grupos';
    case TipoCampeonato.gruposEliminacion:
      return 'Grupos + eliminación';
    case TipoCampeonato.ligaFinal:
      return 'Liga + final';
    case TipoCampeonato.ligaPlayoffs:
      return 'Liga + playoffs';
    default:
      return tipo.replaceAll('_', ' ');
  }
}

String _descripcionFormato(String tipo) {
  switch (tipo) {
    case TipoCampeonato.soloIda:
      return 'Todos los equipos juegan entre sí una sola vez. Se genera tabla de posiciones.';
    case TipoCampeonato.idaVuelta:
      return 'Todos los equipos juegan entre sí dos veces, invirtiendo localía en la segunda vuelta.';
    case TipoCampeonato.ligaFinal:
      return 'Se juega una liga general y los dos mejores disputan una final.';
    case TipoCampeonato.ligaPlayoffs:
      return 'Se juega una liga general y luego los mejores clasifican a una fase final.';
    case TipoCampeonato.faseGrupos:
      return 'Los equipos se dividen en grupos. Cada grupo tiene su propia tabla de posiciones.';
    case TipoCampeonato.gruposEliminacion:
      return 'Primero se juega fase de grupos y luego los clasificados pasan a llaves eliminatorias.';
    case TipoCampeonato.eliminacionDirecta:
      return 'Los equipos juegan llaves de eliminación. El perdedor queda fuera.';
    default:
      return 'Formato personalizado.';
  }
}