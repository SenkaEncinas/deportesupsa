import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/partido_model.dart';
import '../models/tabla_posicion_model.dart';
import '../services/auth_service.dart';
import '../services/campeonato_service.dart';
import '../services/partido_service.dart';
import '../services/public_home_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_styles.dart';
import '../utils/mensajes.dart';

/// Puntos de igualación: el ajuste manual que el admin le carga a los
/// equipos de un grupo que tiene menos equipos que los demás.
///
/// El caso real: si los grupos son de 4 y uno quedó con 3, ese grupo
/// juega un partido menos, así que sus equipos llegan con menos puntos
/// posibles y quedan en desventaja cuando se comparan los mejores
/// terceros entre grupos. Acá el profe empareja eso.
///
/// Solo se habilita cuando el grupo ya jugó todos sus partidos: la
/// igualación se decide viendo cómo terminó el grupo, no antes.
class IgualacionScreen extends StatefulWidget {
  final String campeonatoId;

  const IgualacionScreen({super.key, required this.campeonatoId});

  @override
  State<IgualacionScreen> createState() => _IgualacionScreenState();
}

class _IgualacionScreenState extends State<IgualacionScreen> {
  final CampeonatoService _campeonatoService = CampeonatoService();
  final PartidoService _partidoService = PartidoService();
  final PublicHomeService _tablaService = PublicHomeService();
  final AuthService _authService = AuthService();

  // Los streams se crean una sola vez y no dentro de build(): si se
  // reconstruyen en cada build, cada setState (una tecla en un
  // buscador, por ejemplo) genera una suscripción nueva, el
  // StreamBuilder vuelve a "waiting" y la pantalla entera se
  // reemplaza por el loading, perdiendo el foco del campo.
  late final Stream<CampeonatoModel?> _campeonatoStream = _campeonatoService
      .streamCampeonato(widget.campeonatoId);
  late final Stream<List<PartidoModel>> _partidosStream = _partidoService
      .streamPartidos(widget.campeonatoId);
  late final Stream<List<TablaPosicionModel>> _tablaStream = _tablaService
      .streamTabla(widget.campeonatoId);

  /// Lo que el admin está editando ahora (equipoId -> puntos). Arranca
  /// vacío y se llena con lo guardado la primera vez que llegan datos.
  final Map<String, int> _editado = {};
  bool _inicializado = false;
  bool _guardando = false;

  void _inicializar(CampeonatoModel campeonato) {
    if (_inicializado) return;
    _editado
      ..clear()
      ..addAll(campeonato.igualaciones);
    _inicializado = true;
  }

  bool _hayCambios(CampeonatoModel campeonato) {
    final guardado = campeonato.igualaciones;
    final actuales = {..._editado}..removeWhere((_, puntos) => puntos == 0);

    if (guardado.length != actuales.length) return true;

    for (final entrada in actuales.entries) {
      if (guardado[entrada.key] != entrada.value) return true;
    }

    return false;
  }

  Future<void> _guardar(CampeonatoModel campeonato) async {
    setState(() => _guardando = true);

    try {
      final admin = await _authService.requireAdmin();

      await _campeonatoService.guardarIgualaciones(
        campeonato: campeonato,
        igualaciones: _editado,
        usuarioId: admin.id,
        usuarioNombre: admin.nombre,
      );

      if (!mounted) return;
      AppSnackbars.success(
        context,
        'Igualación guardada: la tabla ya quedó recalculada.',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: _campeonatoStream,
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          if (campeonato == null) {
            return const AppLoading(message: 'Cargando campeonato...');
          }

          _inicializar(campeonato);

          return StreamBuilder<List<PartidoModel>>(
            stream: _partidosStream,
            builder: (context, partidosSnapshot) {
              return StreamBuilder<List<TablaPosicionModel>>(
                stream: _tablaStream,
                builder: (context, tablaSnapshot) {
                  if (tablaSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const AppLoading(message: 'Cargando tabla...');
                  }

                  final tabla = tablaSnapshot.data ?? [];
                  final partidos = partidosSnapshot.data ?? [];
                  final grupos = _armarGrupos(tabla, partidos);

                  return SingleChildScrollView(
                    child: AppPage(
                      title: 'Igualación de puntos',
                      subtitle: campeonato.nombre,
                      actions: [
                        AppButton.secondary(
                          text: 'Volver',
                          icon: Icons.arrow_back,
                          onPressed: () => Navigator.pop(context),
                        ),
                        AppButton.primary(
                          text: 'Guardar',
                          icon: Icons.save_outlined,
                          loading: _guardando,
                          onPressed: _hayCambios(campeonato)
                              ? () => _guardar(campeonato)
                              : null,
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _ExplicacionCard(),
                          const SizedBox(height: 18),
                          if (grupos.isEmpty)
                            const AppEmptyState(
                              icon: Icons.balance_outlined,
                              title: 'Todavía no hay tabla',
                              message:
                                  'La igualación se carga sobre la tabla de posiciones. Cuando se registre el primer resultado, los equipos van a aparecer acá.',
                            )
                          else
                            ...grupos.map(
                              (grupo) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _GrupoIgualacion(
                                  grupo: grupo,
                                  valores: _editado,
                                  onCambio: (equipoId, puntos) {
                                    setState(() {
                                      if (puntos == 0) {
                                        _editado.remove(equipoId);
                                      } else {
                                        _editado[equipoId] = puntos;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Arma los grupos con sus equipos y con cuántos partidos les faltan
  /// por jugar. Si el campeonato no usa grupos, devuelve uno solo con
  /// todos los equipos ("General").
  List<_GrupoDatos> _armarGrupos(
    List<TablaPosicionModel> tabla,
    List<PartidoModel> partidos,
  ) {
    final porGrupo = <String?, List<TablaPosicionModel>>{};

    for (final fila in tabla) {
      porGrupo.putIfAbsent(fila.grupoId, () => []).add(fila);
    }

    final claves = porGrupo.keys.toList()
      ..sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });

    return claves.map((clave) {
      // Partidos del grupo (los de fase final no tienen grupoId y no
      // cuentan para la fase de grupos).
      final delGrupo = partidos.where((p) {
        if (clave == null) return !p.tieneGrupo;
        return p.grupoId == clave;
      }).toList();

      final pendientes = delGrupo
          .where(
            (p) =>
                p.estado != PartidoEstado.finalizado || !p.resultadoRegistrado,
          )
          .length;

      return _GrupoDatos(
        grupoId: clave,
        equipos: porGrupo[clave]!
          ..sort((a, b) => a.posicion.compareTo(b.posicion)),
        partidosTotales: delGrupo.length,
        partidosPendientes: pendientes,
      );
    }).toList();
  }
}

class _GrupoDatos {
  final String? grupoId;
  final List<TablaPosicionModel> equipos;
  final int partidosTotales;
  final int partidosPendientes;

  const _GrupoDatos({
    required this.grupoId,
    required this.equipos,
    required this.partidosTotales,
    required this.partidosPendientes,
  });

  /// El grupo terminó: tiene partidos y todos con resultado cargado.
  bool get completo => partidosTotales > 0 && partidosPendientes == 0;

  String get titulo => grupoId == null || grupoId!.isEmpty
      ? 'General'
      : (grupoId!.toLowerCase().startsWith('grupo')
            ? grupoId!
            : 'Grupo $grupoId');
}

class _ExplicacionCard extends StatelessWidget {
  const _ExplicacionCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Para qué sirve la igualación',
                  style: AppTextStyles.heading3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Cuando un grupo tiene menos equipos que los demás (por ejemplo, grupos de 4 y uno de 3), '
            'ese grupo juega un partido menos y sus equipos llegan con menos puntos posibles. '
            'Acá podés sumarles puntos para compararlos en igualdad de condiciones, sobre todo al '
            'definir los mejores terceros.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            'Los puntos se suman a la tabla apenas guardás y se ven tanto en el panel de admin '
            'como en la vista pública. Solo se habilita en los grupos que ya jugaron todos sus partidos.',
            style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _GrupoIgualacion extends StatelessWidget {
  final _GrupoDatos grupo;
  final Map<String, int> valores;
  final void Function(String equipoId, int puntos) onCambio;

  const _GrupoIgualacion({
    required this.grupo,
    required this.valores,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppSectionHeader(
                  title: grupo.titulo,
                  subtitle:
                      '${grupo.equipos.length} equipos · ${grupo.partidosTotales} partidos',
                ),
              ),
              AppBadge(
                text: grupo.completo
                    ? 'Grupo terminado'
                    : '${grupo.partidosPendientes} sin jugar',
                type: grupo.completo
                    ? AppBadgeType.success
                    : AppBadgeType.warning,
              ),
            ],
          ),
          if (!grupo.completo) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                grupo.partidosTotales == 0
                    ? 'Este grupo todavía no tiene partidos cargados.'
                    : 'Faltan resultados en este grupo. La igualación se habilita cuando estén todos cargados.',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...grupo.equipos.map(
            (equipo) => _FilaEquipo(
              equipo: equipo,
              valor: valores[equipo.equipoId] ?? 0,
              habilitado: grupo.completo,
              onCambio: (puntos) => onCambio(equipo.equipoId, puntos),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaEquipo extends StatefulWidget {
  final TablaPosicionModel equipo;
  final int valor;
  final bool habilitado;
  final ValueChanged<int> onCambio;

  const _FilaEquipo({
    required this.equipo,
    required this.valor,
    required this.habilitado,
    required this.onCambio,
  });

  @override
  State<_FilaEquipo> createState() => _FilaEquipoState();
}

class _FilaEquipoState extends State<_FilaEquipo> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.valor == 0 ? '' : '${widget.valor}',
  );

  @override
  void didUpdateWidget(covariant _FilaEquipo oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si el valor cambió desde afuera (por ejemplo al recargar lo
    // guardado), se refleja en el campo sin pisar lo que se está
    // tipeando.
    final texto = widget.valor == 0 ? '' : '${widget.valor}';
    if (widget.valor != oldWidget.valor && texto != _controller.text) {
      _controller.text = texto;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Puntos sin la igualación ya aplicada, para mostrar la cuenta.
    final base = widget.equipo.puntos - widget.equipo.puntosIgualacion;
    final total = base + widget.valor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${widget.equipo.posicion}',
              style: AppTextStyles.small.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.equipo.equipoNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.valor == 0
                      ? '$base pts · ${widget.equipo.partidosJugados} PJ'
                      : '$base + ${widget.valor} = $total pts',
                  style: AppTextStyles.small.copyWith(
                    color: widget.valor == 0
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    fontWeight: widget.valor == 0
                        ? FontWeight.w400
                        : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: TextField(
              controller: _controller,
              enabled: widget.habilitado,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: '0',
                labelText: '+ pts',
                isDense: true,
              ),
              onChanged: (texto) {
                final limpio = texto.trim();
                if (limpio.isEmpty) {
                  widget.onCambio(0);
                  return;
                }

                final puntos = int.tryParse(limpio);
                if (puntos == null || puntos < 0) return;

                widget.onCambio(puntos);
              },
            ),
          ),
        ],
      ),
    );
  }
}
