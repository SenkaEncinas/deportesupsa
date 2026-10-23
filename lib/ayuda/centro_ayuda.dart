import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/admin_panel_screen.dart';
import '../screens/auditoria_screen.dart';
import '../screens/campeonato_form_screen.dart';
import '../screens/campeonatos_screen.dart';
import '../screens/detalle_campeonato_screen.dart';
import '../screens/equipos_screen.dart';
import '../screens/fixture_screen.dart';
import '../screens/grupos_screen.dart';
import '../screens/igualacion_screen.dart';
import '../screens/jugadores_sancionados_screen.dart';
import '../screens/jugadores_screen.dart';
import '../screens/llaves_screen.dart';
import '../screens/pdfs_screen.dart';
import '../screens/ranking_goleadores_screen.dart';
import '../screens/reciclaje/app_button.dart';
import '../screens/reciclaje/app_colors.dart';
import '../screens/reciclaje/app_text_styles.dart';
import '../screens/reciclaje/responsive.dart';
import '../screens/resultados_screen.dart';
import '../screens/tabla_posiciones_screen.dart';
import 'ayuda_modelo.dart';
import 'maqueta.dart';

/// Botón "?" de las pantallas del administrador. Va arriba, al lado de
/// "Volver", y abre el centro de ayuda con las guías de esa pantalla.
class AyudaBoton extends StatelessWidget {
  final PantallaAyuda pantalla;

  /// El campeonato abierto, para que "Ir a la pantalla y hacerlo" pueda
  /// llevar a sus módulos.
  final String? campeonatoId;
  final RolAyuda rol;

  const AyudaBoton({
    super.key,
    required this.pantalla,
    this.campeonatoId,
    this.rol = RolAyuda.admin,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ayuda: cómo se usa esta pantalla',
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => abrirCentroAyuda(
              context,
              pantalla: pantalla,
              campeonatoId: campeonatoId,
              rol: rol,
            ),
            child: const Center(
              child: Text(
                '?',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre el centro de ayuda: diálogo de hasta 560 px en escritorio y
/// pantalla completa en el celular.
Future<void> abrirCentroAyuda(
  BuildContext context, {
  required PantallaAyuda pantalla,
  String? campeonatoId,
  RolAyuda rol = RolAyuda.admin,
}) {
  final completa = Responsive.isMobile(context);
  final centro = CentroAyuda(
    pantalla: pantalla,
    campeonatoId: campeonatoId,
    rol: rol,
  );

  if (completa) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(child: centro),
        ),
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: centro,
      ),
    ),
  );
}

/// Pantalla a la que lleva "Ir a la pantalla y hacerlo". Null si hace
/// falta un campeonato abierto y no hay.
Widget? _destino(PantallaAyuda pantalla, String? id) {
  switch (pantalla) {
    case PantallaAyuda.panel:
      return const AdminPanelScreen();
    case PantallaAyuda.campeonatos:
      return const CampeonatosScreen();
    case PantallaAyuda.nuevoCampeonato:
      return const CampeonatoFormScreen();
    default:
      break;
  }
  if (id == null) return null;
  return switch (pantalla) {
    PantallaAyuda.detalleCampeonato => DetalleCampeonatoScreen(
      campeonatoId: id,
    ),
    PantallaAyuda.equipos => EquiposScreen(campeonatoId: id),
    PantallaAyuda.jugadores => JugadoresScreen(campeonatoId: id),
    PantallaAyuda.grupos => GruposScreen(campeonatoId: id),
    PantallaAyuda.fixture => FixtureScreen(campeonatoId: id),
    PantallaAyuda.resultados => ResultadosScreen(campeonatoId: id),
    PantallaAyuda.llaves => LlavesScreen(campeonatoId: id),
    PantallaAyuda.igualacion => IgualacionScreen(campeonatoId: id),
    PantallaAyuda.historial => TablaPosicionesScreen(campeonatoId: id),
    PantallaAyuda.goleadores => RankingGoleadoresScreen(campeonatoId: id),
    PantallaAyuda.sancionados => JugadoresSancionadosScreen(campeonatoId: id),
    PantallaAyuda.pdfs => PdfsScreen(campeonatoId: id),
    PantallaAyuda.auditoria => AuditoriaScreen(campeonatoId: id),
    _ => null,
  };
}

/// Lista de guías y reproductor, en el mismo diálogo: elegir una guía
/// reemplaza el contenido (fundido de 220 ms), nunca abre otro diálogo.
class CentroAyuda extends StatefulWidget {
  final PantallaAyuda pantalla;
  final String? campeonatoId;
  final RolAyuda rol;

  /// Para los tests: abre directo en esta guía.
  final GuiaAyuda? guiaInicial;

  const CentroAyuda({
    super.key,
    required this.pantalla,
    this.campeonatoId,
    this.rol = RolAyuda.admin,
    this.guiaInicial,
  });

  @override
  State<CentroAyuda> createState() => _CentroAyudaState();
}

class _CentroAyudaState extends State<CentroAyuda> {
  late GuiaAyuda? _guia = widget.guiaInicial;

  void _cerrar() => Navigator.of(context).pop();

  void _irA(Widget pantalla) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final guia = _guia;

    Widget? destino;
    if (guia != null &&
        guia.pantallaDestino != null &&
        guia.pantallaDestino != widget.pantalla) {
      destino = _destino(guia.pantallaDestino!, widget.campeonatoId);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: guia == null
          ? _ListaGuias(
              key: const ValueKey('lista'),
              pantalla: widget.pantalla,
              rol: widget.rol,
              onElegir: (g) => setState(() => _guia = g),
              onCerrar: _cerrar,
            )
          : ReproductorGuia(
              key: ValueKey(guia.id),
              guia: guia,
              onVolver: () => setState(() => _guia = null),
              onCerrar: _cerrar,
              onIrAPantalla: destino == null ? null : () => _irA(destino!),
            ),
    );
  }
}

class _ListaGuias extends StatelessWidget {
  final PantallaAyuda pantalla;
  final RolAyuda rol;
  final ValueChanged<GuiaAyuda> onElegir;
  final VoidCallback onCerrar;

  const _ListaGuias({
    super.key,
    required this.pantalla,
    required this.rol,
    required this.onElegir,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final deAca = guiasDe(pantalla, rol);
    final otras = guiasPara(rol).where((g) => !deAca.contains(g)).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '?',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Qué querés hacer?', style: AppTextStyles.heading3),
                    Text(
                      'Elegí una guía y te lo mostramos paso a paso',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: onCerrar,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            children: [
              if (deAca.isNotEmpty) ...[
                const _Etiqueta('En esta pantalla'),
                for (final guia in deAca)
                  _ItemGuia(
                    guia: guia,
                    destacada: true,
                    onTap: () => onElegir(guia),
                  ),
                const SizedBox(height: 12),
              ],
              if (otras.isNotEmpty) ...[
                const _Etiqueta('Otras guías'),
                for (final guia in otras)
                  _ItemGuia(guia: guia, onTap: () => onElegir(guia)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Text(
        texto.toUpperCase(),
        style: AppTextStyles.small.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ItemGuia extends StatelessWidget {
  final GuiaAyuda guia;
  final bool destacada;
  final VoidCallback onTap;

  const _ItemGuia({
    required this.guia,
    required this.onTap,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: destacada
                        ? AppColors.primaryLight
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    guia.icono,
                    size: 21,
                    color: destacada
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guia.titulo,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${guia.resumen} · ${guia.pasos.length} pasos',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reproductor de una guía: progreso, maqueta del paso, explicación y
/// botones para avanzar. Las flechas ← → del teclado también navegan.
class ReproductorGuia extends StatefulWidget {
  final GuiaAyuda guia;
  final VoidCallback onVolver;
  final VoidCallback onCerrar;
  final VoidCallback? onIrAPantalla;
  final int pasoInicial;

  const ReproductorGuia({
    super.key,
    required this.guia,
    required this.onVolver,
    required this.onCerrar,
    this.onIrAPantalla,
    this.pasoInicial = 0,
  });

  @override
  State<ReproductorGuia> createState() => _ReproductorGuiaState();
}

class _ReproductorGuiaState extends State<ReproductorGuia> {
  late int _paso = widget.pasoInicial;
  final _foco = FocusNode();

  int get _total => widget.guia.pasos.length;
  bool get _esUltimo => _paso == _total - 1;

  void _ir(int paso) {
    if (paso < 0 || paso >= _total) return;
    setState(() => _paso = paso);
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paso = widget.guia.pasos[_paso];

    return Focus(
      focusNode: _foco,
      autofocus: true,
      onKeyEvent: (_, evento) {
        if (evento is! KeyDownEvent) return KeyEventResult.ignored;
        if (evento.logicalKey == LogicalKeyboardKey.arrowRight) {
          _ir(_paso + 1);
          return KeyEventResult.handled;
        }
        if (evento.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _ir(_paso - 1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Volver a las guías',
                  onPressed: widget.onVolver,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    widget.guia.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: widget.onCerrar,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (var i = 0; i < _total; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _paso
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animacion) => FadeTransition(
                  opacity: animacion,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animacion),
                    child: child,
                  ),
                ),
                child: _ContenidoPaso(
                  key: ValueKey(_paso),
                  paso: paso,
                  numero: _paso + 1,
                  total: _total,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Paso anterior',
                  onPressed: _paso == 0 ? null : () => _ir(_paso - 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const Spacer(),
                if (_esUltimo && widget.onIrAPantalla != null) ...[
                  Flexible(
                    child: AppButton.secondary(
                      text: 'Ir a la pantalla y hacerlo',
                      onPressed: widget.onIrAPantalla,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                AppButton.primary(
                  text: _esUltimo ? '¡Entendido!' : 'Siguiente ›',
                  onPressed: _esUltimo ? widget.onCerrar : () => _ir(_paso + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContenidoPaso extends StatelessWidget {
  final PasoAyuda paso;
  final int numero;
  final int total;

  const _ContenidoPaso({
    super.key,
    required this.paso,
    required this.numero,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // La maqueta, sobre gris claro y con margen para que la mano no
        // se corte en los bordes. Se escala entera al ancho disponible.
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 30, 30),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AspectRatio(
            aspectRatio: MqMarco.ancho / MqMarco.alto,
            child: FittedBox(child: paso.escena()),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'PASO $numero DE $total',
          style: AppTextStyles.small.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(paso.titulo, style: AppTextStyles.heading3),
        const SizedBox(height: 6),
        Text(
          paso.explicacion,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        if (paso.consejo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: AppColors.secondaryDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paso.consejo!,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.onSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
