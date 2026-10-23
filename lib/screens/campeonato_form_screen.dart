import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../services/auth_service.dart';
import '../services/campeonato_service.dart';
import '../utils/fixture_grouping.dart';
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
import '../utils/mensajes.dart';
import '../utils/etiquetas.dart';
import 'reciclaje/app_match_card.dart';
import 'reciclaje/app_info_box.dart';
import 'reciclaje/app_fondo.dart';
import 'reciclaje/app_form_fields.dart';
import '../ayuda/ayuda_modelo.dart';
import '../ayuda/centro_ayuda.dart';

part 'campeonato_form/secciones.dart';

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
  final _mejoresTercerosController = TextEditingController(text: '0');
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
    _mejoresTercerosController.dispose();
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
      } else if (deporte == DeporteTipo.basket) {
        _modalidad = ModalidadDeporte.basket5;
        _jugadoresCanchaController.text = '5';
        _minJugadoresController.text = '5';
        _maxJugadoresController.text = '12';
        _periodosController.text = '4';
      } else {
        _modalidad = ModalidadDeporte.futsal;
        _jugadoresCanchaController.text = '5';
        _minJugadoresController.text = '5';
        _maxJugadoresController.text = '12';
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
    setState(() {
      _tipoCampeonato = tipo;

      switch (tipo) {
        case TipoCampeonato.soloIda:
          _vueltasController.text = '1';
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = false;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.idaVuelta:
          _vueltasController.text = '2';
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = false;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.ligaFinal:
          _vueltasController.text = '1';
          _clasificadosPlayoffsController.text = '2';
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = false;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.ligaPlayoffs:
          _vueltasController.text = '1';
          _clasificadosPlayoffsController.text = '4';
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = false;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.faseGrupos:
          _vueltasController.text = '1';
          _cantidadGruposController.text = '2';
          _clasificanPorGrupoController.text = '0';
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = true;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.gruposEliminacion:
          _vueltasController.text = '1';
          _cantidadGruposController.text = '2';
          _clasificanPorGrupoController.text = '2';
          _mejoresTercerosController.text = '0';
          _generaCrucesAleatorios = true;
          _generaGruposAleatorios = true;
          _idaYVueltaEnGrupos = false;
          _incluyeTercerLugar = false;
          break;

        case TipoCampeonato.eliminacionDirecta:
          _vueltasController.text = '1';
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
      return FixtureGrouping.claveRondaSegunEquipos(clasificados);
    }

    if (_tipoCampeonato == TipoCampeonato.gruposEliminacion) {
      return FixtureGrouping.claveRondaSegunEquipos(_totalClasificados);
    }

    if (_tipoCampeonato == TipoCampeonato.eliminacionDirecta) {
      return 'llaves';
    }

    return 'no_aplica';
  }

  /// Total de equipos que clasifican de la fase de grupos a la fase
  /// final: los que clasifican directo por grupo, más los mejores
  /// terceros entre grupos.
  int get _totalClasificados {
    final grupos = _intValue(_cantidadGruposController, 2);
    final clasificados = _intValue(_clasificanPorGrupoController, 2);
    final terceros = _intValue(_mejoresTercerosController, 0);
    return grupos * clasificados + terceros;
  }

  CampeonatoConfig _buildConfig() {
    final jugadoresEnCancha = _intValue(_jugadoresCanchaController, 5);
    final minJugadores = _intValue(_minJugadoresController, 5);
    final maxJugadores = _intValue(_maxJugadoresController, 12);
    final vueltas = _intValue(_vueltasController, 1);
    final cantidadGrupos = _usaGrupos
        ? _intValue(_cantidadGruposController, 2)
        : 0;
    final clasificanPorGrupo =
        _tipoCampeonato == TipoCampeonato.gruposEliminacion
        ? _intValue(_clasificanPorGrupoController, 2)
        : 0;
    final mejoresTerceros = _tipoCampeonato == TipoCampeonato.gruposEliminacion
        ? _intValue(_mejoresTercerosController, 0)
        : 0;
    final clasificadosPlayoffs = _usaPlayoffs
        ? _intValue(_clasificadosPlayoffsController, 4)
        : 0;

    return CampeonatoConfig(
      formato: _formatoBase(),
      cantidadVueltas: _usaGrupos ? (_idaYVueltaEnGrupos ? 2 : 1) : vueltas,
      idaYVuelta: _usaGrupos
          ? _idaYVueltaEnGrupos
          : vueltas >= 2 || _tipoCampeonato == TipoCampeonato.idaVuelta,
      generaCrucesAleatorios: _generaCrucesAleatorios,
      generaGruposAleatorios: _usaGrupos ? _generaGruposAleatorios : false,
      generaTablaPosiciones: _generaTablaPosiciones(),
      cantidadJugadoresEnCancha: jugadoresEnCancha,
      cantidadMinimaJugadoresPorEquipo: minJugadores,
      cantidadMaximaJugadoresPorEquipo: maxJugadores,
      cantidadGrupos: cantidadGrupos,
      clasificanPorGrupo: clasificanPorGrupo,
      mejoresTerceros: mejoresTerceros,
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
      puntosSetNormal: _esVolley
          ? _intValue(_puntosSetNormalController, 25)
          : 25,
      puntosSetDecisivo: _esVolley
          ? _intValue(_puntosSetDecisivoController, 15)
          : 15,
      cantidadPeriodos: _esBasket ? _intValue(_periodosController, 4) : 0,
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
      final grupos = _intValue(_cantidadGruposController, 0);
      final clasifican = _intValue(_clasificanPorGrupoController, 0);
      final terceros = _intValue(_mejoresTercerosController, 0);

      if (clasifican <= 0) {
        throw Exception('Debe clasificar al menos 1 equipo por grupo.');
      }

      if (terceros < 0) {
        throw Exception(
          'La cantidad de mejores terceros no puede ser negativa.',
        );
      }

      if (terceros > grupos) {
        throw Exception(
          'Los mejores terceros no pueden ser más que la cantidad de grupos (solo hay un candidato a "mejor tercero" por grupo).',
        );
      }

      // Antes esto bloqueaba guardar si el total no era potencia de 2
      // (2/4/8/16/32). Se sacó el bloqueo a pedido explícito: hay
      // campeonatos reales (ej. 12 equipos) donde la llave no cuadra
      // pareja y aun así hace falta poder crear el campeonato — el
      // ajuste de la llave se resuelve aparte, a mano. El aviso sigue
      // ahí: `_RondaResumenBox` ya muestra la advertencia en naranja
      // ("esa cantidad no arma una llave pareja...") sin impedir
      // guardar.
    }

    if (_usaPlayoffs) {
      final clasificados = _intValue(_clasificadosPlayoffsController, 0);

      if (clasificados < 2) {
        throw Exception('Deben clasificar al menos 2 equipos a la fase final.');
      }

      if (!FixtureGrouping.esPotenciaDeDos(clasificados)) {
        throw Exception(
          'Los clasificados a playoffs deben ser 2, 4, 8 o 16 para que el fixture pueda generar llaves ordenadas.',
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

      AppSnackbars.error(context, mensajeDeError(e));
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

    return AppFondo(
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
            AyudaBoton(pantalla: PantallaAyuda.nuevoCampeonato),
            AppButton.primary(
              text: 'Guardar',
              icon: Icons.save_outlined,
              loading: _loading,
              onPressed: _guardar,
            ),
          ],
          child: Column(
            children: [
              _HeroCard(tipoCampeonato: _tipoCampeonato, deporte: _deporte),
              const SizedBox(height: 20),
              AppCard(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      const AppFormSectionTitle(
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
                      const AppFormSectionTitle(
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
                      const AppFormSectionTitle(
                        title: 'Configuración deportiva',
                        subtitle:
                            'Modalidad, jugadores en cancha y tamaño de plantilla por equipo.',
                      ),
                      const SizedBox(height: 18),
                      _ResponsiveFields(
                        children: [
                          AppDropdownField<String>(
                            // La key fuerza a reconstruir el dropdown
                            // cuando cambia el deporte seleccionado.
                            key: ValueKey('modalidad_$_deporte'),
                            label: 'Modalidad',
                            value: _modalidad,
                            items: ModalidadDeporte.porDeporte(_deporte).map((
                              modalidad,
                            ) {
                              return DropdownMenuItem(
                                value: modalidad,
                                child: Text(Etiquetas.modalidad(modalidad)),
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
                            prefixIcon: deporteIcono(_deporte),
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
                            AppDropdownField<int>(
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
                        AppInfoBox(
                          title: 'Vóley',
                          text:
                              'Los sets se ganan por diferencia de 2 puntos. No existen empates: gana quien alcance los sets necesarios.',
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
                        AppInfoBox(
                          title: 'Básquet',
                          text:
                              'No se permite empate final: si el marcador queda igualado se juega prórroga hasta definir un ganador.',
                        ),
                      ],
                      const SizedBox(height: 28),
                      const AppFormSectionTitle(
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
                        mejoresTercerosController: _mejoresTercerosController,
                        clasificadosPlayoffsController:
                            _clasificadosPlayoffsController,
                        generaCrucesAleatorios: _generaCrucesAleatorios,
                        generaGruposAleatorios: _generaGruposAleatorios,
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
                      AppInfoBox(
                        tone: AppInfoBoxTone.primary,
                        title: 'Estado inicial',
                        text:
                            'El campeonato se creará en estado inscripción. En ese estado podrás registrar equipos y jugadores antes de activarlo.',
                      ),
                      const SizedBox(height: 12),
                      AppInfoBox(
                        title: 'Fixture',
                        text:
                            'Cuando el campeonato tenga sus equipos, el fixture se genera desde el módulo Fixture respetando este formato.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
