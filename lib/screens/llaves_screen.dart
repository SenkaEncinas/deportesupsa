import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../models/tabla_posicion_model.dart';
import '../services/campeonato_service.dart';
import '../services/equipo_service.dart';
import '../services/partido_service.dart';
import '../services/public_home_service.dart';
import '../utils/clasificacion.dart';
import '../utils/fixture_grouping.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_dialogs.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';

/// Llaves de la fase eliminatoria, del lado del admin: se generan solas
/// a partir de los clasificados (1° contra el último, 2° contra el
/// anteúltimo...) y desde acá se pueden retocar cruce por cruce.
///
/// Es la pantalla a la que se llega después de activar la fase
/// eliminatoria, porque justo ahí es cuando hay que armar las llaves.
class LlavesScreen extends StatefulWidget {
  final String campeonatoId;

  const LlavesScreen({super.key, required this.campeonatoId});

  @override
  State<LlavesScreen> createState() => _LlavesScreenState();
}

class _LlavesScreenState extends State<LlavesScreen> {
  final CampeonatoService _campeonatoService = CampeonatoService();
  final PartidoService _partidoService = PartidoService();
  final EquipoService _equipoService = EquipoService();
  final PublicHomeService _tablaService = PublicHomeService();

  // Los streams se crean una sola vez y no dentro de build(): si se
  // reconstruyen en cada build, cada setState (una tecla en un
  // buscador, por ejemplo) genera una suscripción nueva, el
  // StreamBuilder vuelve a "waiting" y la pantalla entera se
  // reemplaza por el loading, perdiendo el foco del campo.
  late final Stream<CampeonatoModel?> _campeonatoStream = _campeonatoService
      .streamCampeonato(widget.campeonatoId);
  late final Stream<List<TablaPosicionModel>> _tablaStream = _tablaService
      .streamTabla(widget.campeonatoId);
  late final Stream<List<PartidoModel>> _partidosStream = _tablaService
      .streamPartidos(widget.campeonatoId);

  bool _loading = false;

  Future<void> _generar(
    CampeonatoModel campeonato,
    List<TablaPosicionModel> tabla,
  ) async {
    final clasificados = Clasificacion.calcular(
      tabla: tabla,
      clasificanPorGrupo: campeonato.configuracion.clasificanPorGrupo,
      mejoresTerceros: campeonato.configuracion.mejoresTerceros,
    );

    if (clasificados.length < 2) {
      AppSnackbars.error(
        context,
        'Todavía no hay suficientes clasificados. Revisa la tabla y la configuración de "clasifican por grupo".',
      );
      return;
    }

    final confirmar = await AppDialogs.confirm(
      context: context,
      title: 'Generar llaves',
      message:
          'Se van a cruzar los ${clasificados.length} clasificados por siembra: el 1° contra el último, el 2° contra el anteúltimo, y así. '
          'Si ya había llaves armadas sin resultados, se reemplazan. Después podés cambiar cualquier cruce a mano.',
      confirmText: 'Generar',
    );

    if (!confirmar || !mounted) return;

    setState(() => _loading = true);

    try {
      final equipos = await _equipoService.getEquipos(widget.campeonatoId);
      final porId = {for (final equipo in equipos) equipo.id: equipo};

      // Se respeta el orden de clasificación para la siembra.
      final ordenados = <EquipoModel>[];

      for (final clasificado in clasificados) {
        final equipo = porId[clasificado.equipo.equipoId];
        if (equipo != null) ordenados.add(equipo);
      }

      await _partidoService.generarLlavesEliminatorias(
        campeonatoId: widget.campeonatoId,
        clasificados: ordenados,
      );

      if (!mounted) return;
      AppSnackbars.success(context, 'Llaves generadas.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editarCruce(PartidoModel partido) async {
    setState(() => _loading = true);

    try {
      final equipos = await _equipoService.getEquipos(widget.campeonatoId);
      final activos = equipos
          .where((equipo) => equipo.estado == EquipoEstado.activo)
          .toList();

      if (!mounted) return;

      final result = await showDialog<_EdicionCruce>(
        context: context,
        builder: (_) => _EditarCruceDialog(partido: partido, equipos: activos),
      );

      if (result == null || !mounted) return;

      await _partidoService.cambiarEquiposPartido(
        campeonatoId: widget.campeonatoId,
        partidoId: partido.id,
        local: result.local,
        visitante: result.visitante,
      );

      if (!mounted) return;
      AppSnackbars.success(context, 'Cruce actualizado.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _eliminarCruce(PartidoModel partido) async {
    final confirmar = await AppDialogs.confirm(
      context: context,
      title: 'Eliminar cruce',
      message:
          '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre} se va a borrar de la llave.',
      confirmText: 'Eliminar',
      danger: true,
    );

    if (!confirmar || !mounted) return;

    setState(() => _loading = true);

    try {
      await _partidoService.eliminarPartido(
        campeonatoId: widget.campeonatoId,
        partidoId: partido.id,
      );

      if (!mounted) return;
      AppSnackbars.success(context, 'Cruce eliminado.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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

          return StreamBuilder<List<TablaPosicionModel>>(
            stream: _tablaStream,
            builder: (context, tablaSnapshot) {
              return StreamBuilder<List<PartidoModel>>(
                stream: _partidosStream,
                builder: (context, partidosSnapshot) {
                  if (partidosSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const AppLoading(message: 'Cargando llaves...');
                  }

                  final partidos = partidosSnapshot.data ?? [];
                  final tabla = tablaSnapshot.data ?? [];

                  final deLlave = _partidoService.soloDeLlave(partidos);
                  final rondas = FixtureGrouping.rondasEliminatorias(deLlave);
                  final privilegios = partidos
                      .where((p) => p.privilegio)
                      .toList();

                  return SingleChildScrollView(
                    child: AppPage(
                      title: 'Llaves eliminatorias',
                      subtitle: campeonato.nombre,
                      actions: [
                        AppButton.secondary(
                          text: 'Volver',
                          icon: Icons.arrow_back,
                          onPressed: () => Navigator.pop(context),
                        ),
                        AppButton.primary(
                          text: rondas.isEmpty
                              ? 'Generar llaves'
                              : 'Regenerar llaves',
                          icon: Icons.account_tree_outlined,
                          loading: _loading,
                          onPressed: () => _generar(campeonato, tabla),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AyudaCard(
                            faseActivada: campeonato.estaEnFaseEliminatoria,
                          ),
                          const SizedBox(height: 18),
                          if (rondas.isEmpty)
                            const AppInlineEmptyState(
                              icon: Icons.account_tree_outlined,
                              text: 'Todavía no hay llaves armadas.',
                              subtitle:
                                  'Usá "Generar llaves" para cruzar a los clasificados, o creá los cruces a mano desde Fixture.',
                            )
                          else
                            ...rondas.map(
                              (ronda) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _RondaCard(
                                  titulo: ronda.key,
                                  partidos: ronda.value,
                                  onEditar: _editarCruce,
                                  onEliminar: _eliminarCruce,
                                ),
                              ),
                            ),
                          if (privilegios.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _PrivilegiosCard(partidos: privilegios),
                          ],
                          const SizedBox(height: 24),
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
}

class _AyudaCard extends StatelessWidget {
  final bool faseActivada;

  const _AyudaCard({required this.faseActivada});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                faseActivada ? Icons.bolt_outlined : Icons.info_outline,
                color: faseActivada ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  faseActivada
                      ? 'Fase eliminatoria activa'
                      : 'Todavía en fase de grupos',
                  style: AppTextStyles.heading3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            faseActivada
                ? 'Las llaves se generan cruzando a los clasificados por siembra: el 1° contra el último, el 2° contra el anteúltimo. Podés cambiar cualquier cruce con el lápiz, o borrarlo.'
                : 'Podés dejar las llaves preparadas, pero recién cuando actives la fase eliminatoria en Fixture los usuarios van a ver solo las llaves.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Un cruce con resultado cargado no se puede cambiar ni borrar: primero hay que borrar el resultado.',
            style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _RondaCard extends StatelessWidget {
  final String titulo;
  final List<PartidoModel> partidos;
  final ValueChanged<PartidoModel> onEditar;
  final ValueChanged<PartidoModel> onEliminar;

  const _RondaCard({
    required this.titulo,
    required this.partidos,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: titulo,
            subtitle: '${partidos.length} cruce(s)',
          ),
          const SizedBox(height: 12),
          ...partidos.map(
            (partido) => _CruceFila(
              partido: partido,
              onEditar: () => onEditar(partido),
              onEliminar: () => onEliminar(partido),
            ),
          ),
        ],
      ),
    );
  }
}

class _CruceFila extends StatelessWidget {
  final PartidoModel partido;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _CruceFila({
    required this.partido,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final bloqueado = partido.resultadoRegistrado;
    final isMobile = Responsive.isMobile(context);

    final equipos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${partido.equipoLocalNombre}  vs  ${partido.equipoVisitanteNombre}',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            AppBadge(
              text: bloqueado ? partido.marcadorTexto : 'Sin jugar',
              type: bloqueado ? AppBadgeType.success : AppBadgeType.neutral,
            ),
          ],
        ),
      ],
    );

    final acciones = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: bloqueado ? 'Tiene resultado cargado' : 'Cambiar equipos',
          onPressed: bloqueado ? null : onEditar,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: bloqueado ? 'Tiene resultado cargado' : 'Eliminar cruce',
          onPressed: bloqueado ? null : onEliminar,
          icon: const Icon(Icons.delete_outline),
          color: AppColors.danger,
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      // En celular las acciones van debajo para que los nombres largos no
      // se aplasten contra los botones.
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                equipos,
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: acciones),
              ],
            )
          : Row(
              children: [
                Expanded(child: equipos),
                const SizedBox(width: 10),
                acciones,
              ],
            ),
    );
  }
}

class _PrivilegiosCard extends StatelessWidget {
  final List<PartidoModel> partidos;

  const _PrivilegiosCard({required this.partidos});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Partidos con privilegio',
            subtitle:
                'Partidos especiales fuera de grupos. No forman parte de la llave ni suman para la tabla.',
          ),
          const SizedBox(height: 12),
          ...partidos.map(
            (partido) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_outline,
                    size: 18,
                    color: AppColors.secondaryDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Jornada ${partido.jornada}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _EdicionCruce {
  final EquipoModel local;
  final EquipoModel visitante;

  const _EdicionCruce({required this.local, required this.visitante});
}

class _EditarCruceDialog extends StatefulWidget {
  final PartidoModel partido;
  final List<EquipoModel> equipos;

  const _EditarCruceDialog({required this.partido, required this.equipos});

  @override
  State<_EditarCruceDialog> createState() => _EditarCruceDialogState();
}

class _EditarCruceDialogState extends State<_EditarCruceDialog> {
  EquipoModel? _local;
  EquipoModel? _visitante;

  @override
  void initState() {
    super.initState();

    for (final equipo in widget.equipos) {
      if (equipo.id == widget.partido.equipoLocalId) _local = equipo;
      if (equipo.id == widget.partido.equipoVisitanteId) _visitante = equipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeGuardar =
        _local != null && _visitante != null && _local!.id != _visitante!.id;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text('Cambiar equipos', style: AppTextStyles.heading3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Selector(
                label: 'Equipo local',
                value: _local,
                equipos: widget.equipos,
                onChanged: (value) => setState(() => _local = value),
              ),
              const SizedBox(height: 14),
              _Selector(
                label: 'Equipo visitante',
                value: _visitante,
                equipos: widget.equipos,
                onChanged: (value) => setState(() => _visitante = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          text: 'Guardar',
          icon: Icons.save_outlined,
          onPressed: puedeGuardar
              ? () => Navigator.pop(
                  context,
                  _EdicionCruce(local: _local!, visitante: _visitante!),
                )
              : null,
        ),
      ],
    );
  }
}

class _Selector extends StatelessWidget {
  final String label;
  final EquipoModel? value;
  final List<EquipoModel> equipos;
  final ValueChanged<EquipoModel?> onChanged;

  const _Selector({
    required this.label,
    required this.value,
    required this.equipos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<EquipoModel>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: equipos
          .map(
            (equipo) => DropdownMenuItem(
              value: equipo,
              child: Text(equipo.nombre, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
