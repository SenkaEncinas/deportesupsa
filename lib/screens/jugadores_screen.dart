import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/jugador_model.dart';
import '../services/campeonato_service.dart';
import '../services/jugador_service.dart';
import 'jugador_form_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_dialogs.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_table_container.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';

/// Borra un jugador para siempre, con confirmación: pensado para corregir
/// un error de carga (jugador cargado en el equipo equivocado), no para
/// sacar a alguien de un campeonato ya activo (para eso existe el estado
/// "retirado", que sí deja rastro). El service ya valida que el
/// campeonato esté en inscripción; acá solo se pide confirmación y se
/// muestra el resultado.
Future<void> _eliminarJugador(
  BuildContext context,
  JugadorService service,
  String campeonatoId,
  JugadorModel jugador,
) async {
  final confirmado = await AppDialogs.confirm(
    context: context,
    title: 'Eliminar jugador',
    message:
        '¿Eliminar a "${jugador.nombreCompleto}" (${jugador.codigoEstudiante}) '
        'del equipo ${jugador.equipoNombre}? Esta acción no se puede deshacer.',
    confirmText: 'Eliminar',
    danger: true,
  );

  if (!confirmado || !context.mounted) return;

  try {
    await service.eliminarJugador(
      campeonatoId: campeonatoId,
      jugadorId: jugador.id,
    );

    if (!context.mounted) return;
    AppSnackbars.success(context, 'Jugador eliminado correctamente.');
  } catch (e) {
    if (!context.mounted) return;
    AppSnackbars.error(context, e.toString());
  }
}

class JugadoresScreen extends StatefulWidget {
  final String campeonatoId;

  const JugadoresScreen({super.key, required this.campeonatoId});

  @override
  State<JugadoresScreen> createState() => _JugadoresScreenState();
}

class _JugadoresScreenState extends State<JugadoresScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<JugadorModel> _filtrar(List<JugadorModel> jugadores) {
    final search = _search.trim().toLowerCase();
    if (search.isEmpty) return jugadores;

    return jugadores.where((jugador) {
      final searchable = [
        jugador.nombreCompleto,
        jugador.codigoEstudiante,
        jugador.equipoNombre,
      ].join(' ').toLowerCase();

      return searchable.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final campeonatoService = CampeonatoService();
    final jugadorService = JugadorService();

    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: campeonatoService.streamCampeonato(widget.campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<JugadorModel>>(
            stream: jugadorService.streamJugadores(widget.campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando jugadores...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar jugadores',
                  message: snapshot.error.toString(),
                );
              }

              final jugadores = snapshot.data ?? [];
              final filtrados = _filtrar(jugadores);
              final campeonatoId = widget.campeonatoId;

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Jugadores',
                  subtitle: campeonato == null
                      ? 'Jugadores registrados.'
                      : campeonato.nombre,
                  actions: [
                    AppButton.secondary(
                      text: 'Volver',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (campeonato?.estado != CampeonatoEstado.finalizado)
                      AppButton.primary(
                        text: 'Nuevo jugador',
                        icon: Icons.person_add_alt_1_outlined,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  JugadorFormScreen(campeonatoId: campeonatoId),
                            ),
                          );
                        },
                      ),
                  ],
                  child: jugadores.isEmpty
                      ? AppEmptyState(
                          icon: Icons.person_add_alt_1_outlined,
                          title: 'No hay jugadores registrados',
                          message:
                              'Registra jugadores con código de estudiante y nombre completo.',
                          buttonText:
                              campeonato?.estado == CampeonatoEstado.finalizado
                              ? null
                              : 'Registrar jugador',
                          onPressed:
                              campeonato?.estado == CampeonatoEstado.finalizado
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JugadorFormScreen(
                                        campeonatoId: campeonatoId,
                                      ),
                                    ),
                                  );
                                },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Buscar jugador',
                              hint: 'Nombre, código de estudiante o equipo...',
                              controller: _searchController,
                              prefixIcon: Icons.search_rounded,
                              onChanged: (value) {
                                setState(() => _search = value);
                              },
                            ),
                            const SizedBox(height: 18),
                            if (filtrados.isEmpty)
                              const AppInlineEmptyState(
                                icon: Icons.search_off_rounded,
                                text:
                                    'No hay jugadores que coincidan con la búsqueda.',
                              )
                            else
                              Responsive.isMobile(context)
                                  ? _JugadoresListaMobile(
                                      jugadores: filtrados,
                                      puedeEditar:
                                          campeonato?.estado !=
                                          CampeonatoEstado.finalizado,
                                      puedeEliminar:
                                          campeonato?.estado ==
                                          CampeonatoEstado.inscripcion,
                                      campeonatoId: campeonatoId,
                                      jugadorService: jugadorService,
                                    )
                                  : AppTableContainer(
                                      headers: const [
                                        'Código',
                                        'Nombre',
                                        'Equipo',
                                        'Estado',
                                        'Acción',
                                      ],
                                      rows: filtrados.map((jugador) {
                                        return [
                                          Text(jugador.codigoEstudiante),
                                          Text(jugador.nombreCompleto),
                                          Text(jugador.equipoNombre),
                                          AppBadge(
                                            text: jugador.estado,
                                            type: AppBadge.typeFromEstado(
                                              jugador.estado,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextButton(
                                                onPressed:
                                                    campeonato?.estado ==
                                                        CampeonatoEstado
                                                            .finalizado
                                                    ? null
                                                    : () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                JugadorFormScreen(
                                                                  campeonatoId:
                                                                      campeonatoId,
                                                                  jugador:
                                                                      jugador,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                child: Text(
                                                  'Editar',
                                                  style:
                                                      AppTextStyles.bodyMedium,
                                                ),
                                              ),
                                              if (campeonato?.estado ==
                                                  CampeonatoEstado.inscripcion)
                                                TextButton(
                                                  onPressed: () =>
                                                      _eliminarJugador(
                                                        context,
                                                        jugadorService,
                                                        campeonatoId,
                                                        jugador,
                                                      ),
                                                  child: Text(
                                                    'Eliminar',
                                                    style: AppTextStyles
                                                        .bodyMedium
                                                        .copyWith(
                                                          color:
                                                              AppColors.danger,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ];
                                      }).toList(),
                                      emptyMessage:
                                          'No hay jugadores registrados.',
                                    ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Alternativa a la tabla en móvil: una tabla de 5 columnas obliga a
/// scroll horizontal poco descubrible en pantallas angostas, así que se
/// reemplaza por una card por jugador, igual que se hizo en equipos y en
/// la tabla de posiciones pública.
class _JugadoresListaMobile extends StatelessWidget {
  final List<JugadorModel> jugadores;
  final bool puedeEditar;
  final bool puedeEliminar;
  final String campeonatoId;
  final JugadorService jugadorService;

  const _JugadoresListaMobile({
    required this.jugadores,
    required this.puedeEditar,
    required this.puedeEliminar,
    required this.campeonatoId,
    required this.jugadorService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: jugadores.map((jugador) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            onTap: puedeEditar
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JugadorFormScreen(
                          campeonatoId: campeonatoId,
                          jugador: jugador,
                        ),
                      ),
                    );
                  }
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        jugador.nombreCompleto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppBadge(
                      text: jugador.estado,
                      type: AppBadge.typeFromEstado(jugador.estado),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        jugador.codigoEstudiante,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_2_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        jugador.equipoNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small,
                      ),
                    ),
                  ],
                ),
                if (puedeEditar || puedeEliminar) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (puedeEliminar)
                        TextButton(
                          onPressed: () => _eliminarJugador(
                            context,
                            jugadorService,
                            campeonatoId,
                            jugador,
                          ),
                          child: Text(
                            'Eliminar',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (puedeEditar)
                        Text(
                          'Toca para editar',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
