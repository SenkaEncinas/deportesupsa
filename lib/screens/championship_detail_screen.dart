import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';
import '../services/datos_campeonato.dart';
import '../services/public_home_service.dart';
import '../utils/fixture_grouping.dart';
import '../utils/tabla_calculo.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_bracket_view.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_clasificados_card.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_filter_pill.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_logo_mark.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_match_card.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_public_footer.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_responsive_pair.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_skeleton.dart';
import 'reciclaje/app_standing_card.dart';
import 'reciclaje/app_table_container.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';
import '../utils/etiquetas.dart';
import 'reciclaje/app_fase_badge.dart';
import 'reciclaje/app_fondo.dart';

part 'campeonato_publico/navegacion.dart';
part 'campeonato_publico/partidos.dart';
part 'campeonato_publico/tabla.dart';

class ChampionshipDetailScreen extends StatefulWidget {
  final CampeonatoModel campeonato;

  /// Solo para los tests, que necesitan apuntar a un Firestore de
  /// mentira. En la app queda en null y se usa el de siempre.
  final PublicHomeService? service;

  const ChampionshipDetailScreen({
    super.key,
    required this.campeonato,
    this.service,
  });

  @override
  State<ChampionshipDetailScreen> createState() =>
      _ChampionshipDetailScreenState();
}

class _ChampionshipDetailScreenState extends State<ChampionshipDetailScreen> {
  /// Una sola conexión por dato para toda la pantalla (ver
  /// [DatosCampeonato]).
  late final DatosCampeonato datos = DatosCampeonato(
    widget.service ?? PublicHomeService(),
    widget.campeonato.id,
  );

  CampeonatoModel get campeonato => widget.campeonato;

  @override
  void dispose() {
    datos.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppFondo(
      child: isMobile
          ? _MobileChampionshipView(datos: datos, campeonato: campeonato)
          : SingleChildScrollView(
              child: Column(
                children: [
                  AppPage(
                    title: campeonato.nombre,
                    subtitle: 'Información pública del campeonato.',
                    actions: [
                      AppButton.secondary(
                        text: 'Volver',
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                    child: _ChampionshipContent(
                      datos: datos,
                      campeonato: campeonato,
                    ),
                  ),
                  const AppPublicFooter(),
                ],
              ),
            ),
    );
  }
}

/// El contenido completo del campeonato, sin encabezado ni scroll
/// propios (eso lo pone quien lo use): pensado para desktop/tablet, que
/// ya tenían lugar de sobra para ver todo en una sola columna larga. En
/// vez del cartel verde grande de antes (con descripción, universidad,
/// cancha, modalidad...) solo se muestra el logo de la UPSA: esa info ya
/// la vio el usuario al entrar al campeonato, no hace falta repetirla.
class _ChampionshipContent extends StatelessWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  const _ChampionshipContent({required this.datos, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    final estadoTexto = Etiquetas.estadoCampeonato(campeonato.estado);

    // En fase eliminatoria la vista pública se reduce a la llave, la
    // tabla de la fase de grupos y, en fútbol, los goleadores: los
    // próximos partidos y las estadísticas ya no aportan nada.
    if (campeonato.estaEnFaseEliminatoria) {
      return _ContenidoEliminatoria(datos: datos, campeonato: campeonato);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLogoMark(compact: true),
            const SizedBox(width: 12),
            AppBadge(
              text: estadoTexto,
              type: AppBadge.tipoEstadoCampeonato(campeonato.estado),
              icon: deporteIcono(campeonato.deporteEfectivo),
            ),
            if (campeonato.tieneFasesSeparadas) ...[
              const SizedBox(width: 8),
              AppFaseBadge(campeonato: campeonato),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _StatsSection(
          datos: datos,
          campeonato: campeonato,
          estadoTexto: estadoTexto,
        ),
        const SizedBox(height: 24),
        AppResponsivePair(
          first: _NextMatchesSection(
            datos: datos,
            deporte: campeonato.deporteEfectivo,
          ),
          second: _LastResultsSection(
            datos: datos,
            deporte: campeonato.deporteEfectivo,
          ),
        ),
        const SizedBox(height: 24),
        // Fuera de la eliminatoria, el cuadro solo existe en la
        // eliminación directa. En una liga o en la fase de grupos esta
        // sección solo decía "Todavía no hay partidos de fase final".
        if (campeonato.muestraLlave) ...[
          _FixtureSection(datos: datos, campeonato: campeonato),
          const SizedBox(height: 24),
        ],
        // Vóley y básquet no registran goles/puntos por jugador: sin esa
        // sección, la tabla usa todo el ancho en vez de dejar un hueco
        // al lado.
        if (campeonato.esFutbol)
          AppResponsivePair(
            firstFlex: 3,
            secondFlex: 2,
            first: _TableSection(datos: datos, campeonato: campeonato),
            second: _ScorersSection(datos: datos, campeonato: campeonato),
          )
        else
          _TableSection(datos: datos, campeonato: campeonato),
        // Desplegada, debajo de la tabla: muestra en vivo quién va
        // clasificando y en qué puesto de siembra, para que nadie tenga
        // que deducirlo de la tabla general.
        if (campeonato.tieneFasesSeparadas) ...[
          const SizedBox(height: 24),
          AppClasificadosEnVivo(
            campeonato: campeonato,
            tabla: () => datos.tabla,
            colapsable: false,
          ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }
}

/// Lo que se ve al entrar en fase eliminatoria: el cuadro y, debajo, la
/// lista de partidos de fase final, que hace de fixture (los que faltan,
/// con su fecha) y de resultados (los jugados, con su marcador). La
/// tabla y los clasificados se abren desde la barra lateral.
///
/// "Próximos partidos" y "Últimos resultados" no van acá: repetían los
/// mismos cruces que ya muestra esa lista, cada uno dos veces.
///
/// La usan escritorio y móvil, así que lo que aparece en la pantalla
/// principal es lo mismo en los dos.
class _PrincipalEliminatoria extends StatelessWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  /// En móvil el título de la sección ya dice "Llaves eliminatorias".
  final bool conEncabezado;

  const _PrincipalEliminatoria({
    required this.datos,
    required this.campeonato,
    this.conEncabezado = true,
  });

  @override
  Widget build(BuildContext context) {
    return _FixtureSection(
      datos: datos,
      campeonato: campeonato,
      conEncabezado: conEncabezado,
    );
  }
}

/// Contenido público de escritorio cuando el campeonato está en fase
/// eliminatoria: una barra lateral, igual a la del menú del celular,
/// y al lado la sección elegida. Arranca en las llaves; la tabla de la
/// fase de grupos (con los goleadores en fútbol) y los clasificados
/// quedan a un toque, en vez de estar siempre debajo del cuadro.
///
/// Los partidos de la fase final no modifican esa tabla: no tienen
/// grupo y el cálculo los ignora.
class _ContenidoEliminatoria extends StatefulWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  const _ContenidoEliminatoria({required this.datos, required this.campeonato});

  @override
  State<_ContenidoEliminatoria> createState() => _ContenidoEliminatoriaState();
}

class _ContenidoEliminatoriaState extends State<_ContenidoEliminatoria> {
  _SeccionPublica _seccion = _SeccionPublica.llaves;
  _VistaTabla _vistaTabla = _VistaTabla.general;

  CampeonatoModel get campeonato => widget.campeonato;
  DatosCampeonato get datos => widget.datos;

  void _ir(_SeccionPublica seccion, {_VistaTabla? vistaTabla}) {
    setState(() {
      _seccion = seccion;
      if (vistaTabla != null) _vistaTabla = vistaTabla;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 250,
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _MenuSecciones(
              campeonato: campeonato,
              seccionActual: _seccion,
              vistaTabla: _vistaTabla,
              // El resumen ya está en la pantalla de llaves, debajo del
              // cuadro: en escritorio sería la misma información dos
              // veces.
              conResumen: false,
              onSelect: _ir,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: switch (_seccion) {
            _SeccionPublica.tabla => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TableSection(
                  // La key hace que cambiar entre "general" y "por
                  // grupos" desde la barra se aplique aunque la sección
                  // ya estuviera abierta.
                  key: ValueKey(_vistaTabla),
                  datos: datos,
                  campeonato: campeonato,
                  vistaInicial: _vistaTabla,
                ),
                if (campeonato.esFutbol) ...[
                  const SizedBox(height: 24),
                  _ScorersSection(datos: datos, campeonato: campeonato),
                ],
              ],
            ),
            _SeccionPublica.clasificados => AppClasificadosEnVivo(
              campeonato: campeonato,
              tabla: () => datos.tabla,
              colapsable: false,
            ),
            _SeccionPublica.llaves || _SeccionPublica.resumen =>
              _PrincipalEliminatoria(datos: datos, campeonato: campeonato),
          },
        ),
      ],
    );
  }
}
