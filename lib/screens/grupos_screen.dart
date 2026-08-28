import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/grupo_model.dart';
import '../models/tabla_posicion_model.dart';
import '../services/campeonato_service.dart';
import '../services/equipo_service.dart';
import '../services/grupo_service.dart';
import '../services/public_home_service.dart';
import '../utils/clasificacion.dart';
import '../utils/fixture_grouping.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_clasificados_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_dialogs.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_styles.dart';

/// Inscribe equipos activos en los grupos de la fase de grupos. Antes,
/// esta asignación se hacía automáticamente y en silencio cada vez que se
/// generaba el fixture, sin quedar guardada ni ser editable: esta
/// pantalla la vuelve explícita y persistente (colección `grupos`).
class GruposScreen extends StatefulWidget {
  final String campeonatoId;

  const GruposScreen({super.key, required this.campeonatoId});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final CampeonatoService _campeonatoService = CampeonatoService();
  final EquipoService _equipoService = EquipoService();
  final GrupoService _grupoService = GrupoService();
  final PublicHomeService _publicHomeService = PublicHomeService();

  bool _loading = false;

  Future<void> _generarAutomatico(CampeonatoModel campeonato) async {
    setState(() => _loading = true);

    try {
      final equipos = await _equipoService.getEquipos(widget.campeonatoId);
      final activos = equipos
          .where((e) => e.estado == EquipoEstado.activo)
          .toList();

      await _grupoService.generarGruposAutomaticos(
        campeonatoId: widget.campeonatoId,
        equiposActivos: activos,
        cantidadGrupos: campeonato.configuracion.cantidadGrupos < 2
            ? 2
            : campeonato.configuracion.cantidadGrupos,
        aleatorio: campeonato.configuracion.generaGruposAleatorios,
      );

      if (!mounted) return;
      AppSnackbars.success(context, 'Grupos generados automáticamente.');
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

  Future<void> _armarManualmente(CampeonatoModel campeonato) async {
    final cantidad = await showDialog<int>(
      context: context,
      builder: (_) => _CantidadGruposDialog(
        cantidadInicial: campeonato.configuracion.cantidadGrupos < 2
            ? 2
            : campeonato.configuracion.cantidadGrupos,
      ),
    );

    if (cantidad == null) return;

    setState(() => _loading = true);

    try {
      await _grupoService.crearGruposVacios(
        campeonatoId: widget.campeonatoId,
        cantidadGrupos: cantidad,
      );

      if (!mounted) return;
      AppSnackbars.success(
        context,
        'Se crearon $cantidad grupos vacíos. Asigna cada equipo desde "Equipos activos sin grupo".',
      );
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

  Future<void> _editarClasificacion(CampeonatoModel campeonato) async {
    final resultado = await showDialog<_ClasificacionResult>(
      context: context,
      builder: (_) => _EditarClasificacionDialog(campeonato: campeonato),
    );

    if (resultado == null) return;

    setState(() => _loading = true);

    try {
      await _campeonatoService.actualizarClasificacionGrupos(
        campeonato: campeonato,
        clasificanPorGrupo: resultado.clasificanPorGrupo,
        mejoresTerceros: resultado.mejoresTerceros,
      );

      if (!mounted) return;
      AppSnackbars.success(context, 'Clasificación actualizada.');
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

  Future<void> _reiniciarGrupos() async {
    final confirm = await AppDialogs.confirm(
      context: context,
      title: 'Reiniciar grupos',
      message:
          'Se eliminará la inscripción actual de equipos en grupos. Podrás volver a generarla o armarla a mano.',
      confirmText: 'Reiniciar',
      danger: true,
    );

    if (!confirm) return;

    setState(() => _loading = true);

    try {
      await _grupoService.eliminarGrupos(widget.campeonatoId);

      if (!mounted) return;
      AppSnackbars.success(context, 'Grupos reiniciados.');
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

  Future<void> _moverEquipo({
    required EquipoModel equipo,
    required List<GrupoModel> grupos,
  }) async {
    final destino = await showDialog<GrupoModel>(
      context: context,
      builder: (_) => _SeleccionarGrupoDialog(equipo: equipo, grupos: grupos),
    );

    if (destino == null) return;

    try {
      await _grupoService.asignarEquipoAGrupo(
        campeonatoId: widget.campeonatoId,
        equipoId: equipo.id,
        grupoDestinoId: destino.id,
      );

      if (!mounted) return;
      AppSnackbars.success(
        context,
        '${equipo.nombre} inscrito en ${destino.nombre}.',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: _campeonatoService.streamCampeonato(widget.campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<EquipoModel>>(
            stream: _equipoService.streamEquipos(widget.campeonatoId),
            builder: (context, equiposSnapshot) {
              final equipos = equiposSnapshot.data ?? [];
              final activos = equipos
                  .where((e) => e.estado == EquipoEstado.activo)
                  .toList();

              return StreamBuilder<List<GrupoModel>>(
                stream: _grupoService.streamGrupos(widget.campeonatoId),
                builder: (context, gruposSnapshot) {
                  if (campeonatoSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      equiposSnapshot.connectionState ==
                          ConnectionState.waiting) {
                    return const AppLoading(message: 'Cargando grupos...');
                  }

                  final grupos = gruposSnapshot.data ?? [];
                  final inscritos = grupos.expand((g) => g.equipoIds).toSet();
                  final sinGrupo = activos
                      .where((e) => !inscritos.contains(e.id))
                      .toList();

                  final puedeEditar =
                      campeonato != null &&
                      campeonato.estado != CampeonatoEstado.finalizado;

                  final equiposPorId = {for (final e in equipos) e.id: e};

                  return SingleChildScrollView(
                    child: AppPage(
                      title: 'Grupos',
                      subtitle: campeonato == null
                          ? 'Inscripción de equipos por grupo.'
                          : '${campeonato.nombre} · fase de grupos',
                      actions: [
                        AppButton.secondary(
                          text: 'Volver',
                          icon: Icons.arrow_back,
                          onPressed: () => Navigator.pop(context),
                        ),
                        if (puedeEditar && grupos.isEmpty)
                          AppButton.primary(
                            text: 'Generar grupos automáticamente',
                            icon: Icons.shuffle,
                            loading: _loading,
                            onPressed: () => _generarAutomatico(campeonato),
                          ),
                        if (puedeEditar && grupos.isEmpty)
                          AppButton.secondary(
                            text: 'Armar manualmente',
                            icon: Icons.edit_note_rounded,
                            loading: _loading,
                            onPressed: () => _armarManualmente(campeonato),
                          ),
                        if (puedeEditar &&
                            campeonato.tipoCampeonato ==
                                TipoCampeonato.gruposEliminacion)
                          AppButton.secondary(
                            text: 'Editar clasificación',
                            icon: Icons.tune_rounded,
                            loading: _loading,
                            onPressed: () => _editarClasificacion(campeonato),
                          ),
                        if (puedeEditar && grupos.isNotEmpty)
                          AppButton.danger(
                            text: 'Reiniciar',
                            icon: Icons.restart_alt,
                            loading: _loading,
                            onPressed: _reiniciarGrupos,
                          ),
                      ],
                      child: grupos.isEmpty
                          ? AppEmptyState(
                              icon: Icons.grid_view_rounded,
                              title: 'Todavía no hay grupos armados',
                              message: activos.length < 2
                                  ? 'Registra al menos 2 equipos activos para poder inscribirlos en grupos.'
                                  : 'Genera los grupos automáticamente, o usa "Armar manualmente" para crear los grupos vacíos e ir asignando cada equipo a mano.',
                              buttonText: puedeEditar && activos.length >= 2
                                  ? 'Generar grupos automáticamente'
                                  : null,
                              onPressed: puedeEditar && activos.length >= 2
                                  ? () => _generarAutomatico(campeonato)
                                  : null,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sinGrupo.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 18,
                                    ),
                                    child: _SinGrupoBox(
                                      equipos: sinGrupo,
                                      grupos: grupos,
                                      puedeEditar: puedeEditar,
                                      onAsignar: (equipo) => _moverEquipo(
                                        equipo: equipo,
                                        grupos: grupos,
                                      ),
                                    ),
                                  ),
                                AppResponsiveGrid(
                                  mobileColumns: 1,
                                  tabletColumns: 2,
                                  desktopColumns: 3,
                                  spacing: 14,
                                  children: grupos.map((grupo) {
                                    final equiposDelGrupo = grupo.equipoIds
                                        .map((id) => equiposPorId[id])
                                        .whereType<EquipoModel>()
                                        .toList();

                                    return _GrupoCard(
                                      grupo: grupo,
                                      equipos: equiposDelGrupo,
                                      otrosGrupos: grupos
                                          .where((g) => g.id != grupo.id)
                                          .toList(),
                                      puedeEditar: puedeEditar,
                                      onMover: (equipo) => _moverEquipo(
                                        equipo: equipo,
                                        grupos: grupos,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (campeonato != null &&
                                    campeonato.tipoCampeonato ==
                                        TipoCampeonato.gruposEliminacion) ...[
                                  const SizedBox(height: 22),
                                  _ClasificadosPreview(
                                    service: _publicHomeService,
                                    campeonato: campeonato,
                                  ),
                                ],
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

class _GrupoCard extends StatelessWidget {
  final GrupoModel grupo;
  final List<EquipoModel> equipos;
  final List<GrupoModel> otrosGrupos;
  final bool puedeEditar;
  final void Function(EquipoModel) onMover;

  const _GrupoCard({
    required this.grupo,
    required this.equipos,
    required this.otrosGrupos,
    required this.puedeEditar,
    required this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(grupo.nombre, style: AppTextStyles.heading3),
              ),
              AppBadge(
                text: '${equipos.length} equipos',
                type: equipos.length < 2
                    ? AppBadgeType.danger
                    : AppBadgeType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (equipos.isEmpty)
            Text(
              'Sin equipos inscritos todavía.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...equipos.map((equipo) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          equipo.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      if (puedeEditar && otrosGrupos.isNotEmpty)
                        IconButton(
                          tooltip: 'Mover a otro grupo',
                          icon: const Icon(
                            Icons.compare_arrows_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          onPressed: () => onMover(equipo),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SinGrupoBox extends StatelessWidget {
  final List<EquipoModel> equipos;
  final List<GrupoModel> grupos;
  final bool puedeEditar;
  final void Function(EquipoModel) onAsignar;

  const _SinGrupoBox({
    required this.equipos,
    required this.grupos,
    required this.puedeEditar,
    required this.onAsignar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Equipos activos sin grupo asignado',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: equipos.map((equipo) {
              return ActionChip(
                label: Text(equipo.nombre),
                avatar: const Icon(Icons.add, size: 16),
                onPressed: puedeEditar && grupos.isNotEmpty
                    ? () => onAsignar(equipo)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ClasificadosPreview extends StatelessWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;

  const _ClasificadosPreview({required this.service, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    final config = campeonato.configuracion;
    final total = config.cantidadGrupos * config.clasificanPorGrupo +
        config.mejoresTerceros;

    return StreamBuilder<List<TablaPosicionModel>>(
      stream: service.streamTabla(campeonato.id),
      builder: (context, snapshot) {
        final tabla = snapshot.data ?? [];

        final clasificados = Clasificacion.calcular(
          tabla: tabla,
          clasificanPorGrupo: config.clasificanPorGrupo,
          mejoresTerceros: config.mejoresTerceros,
        );

        return AppClasificadosCard(
          clasificados: clasificados,
          totalEsperado: total,
        );
      },
    );
  }
}

class _ClasificacionResult {
  final int clasificanPorGrupo;
  final int mejoresTerceros;

  const _ClasificacionResult({
    required this.clasificanPorGrupo,
    required this.mejoresTerceros,
  });
}

class _EditarClasificacionDialog extends StatefulWidget {
  final CampeonatoModel campeonato;

  const _EditarClasificacionDialog({required this.campeonato});

  @override
  State<_EditarClasificacionDialog> createState() =>
      _EditarClasificacionDialogState();
}

class _EditarClasificacionDialogState
    extends State<_EditarClasificacionDialog> {
  late final TextEditingController _clasificanController =
      TextEditingController(
        text: '${widget.campeonato.configuracion.clasificanPorGrupo}',
      );
  late final TextEditingController _tercerosController =
      TextEditingController(
        text: '${widget.campeonato.configuracion.mejoresTerceros}',
      );

  @override
  void dispose() {
    _clasificanController.dispose();
    _tercerosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grupos = widget.campeonato.configuracion.cantidadGrupos;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text('Editar clasificación', style: AppTextStyles.heading3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Este campeonato tiene $grupos grupos ya armados. Ajusta cuántos clasifican directo por grupo y cuántos mejores terceros pasan a la fase final.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clasificanController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Clasifican por grupo',
                prefixIcon: Icon(Icons.military_tech_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _tercerosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mejores terceros',
                prefixIcon: Icon(Icons.workspace_premium_outlined),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: Listenable.merge([
                _clasificanController,
                _tercerosController,
              ]),
              builder: (context, _) {
                final clasifican =
                    int.tryParse(_clasificanController.text.trim()) ?? 0;
                final terceros =
                    int.tryParse(_tercerosController.text.trim()) ?? 0;
                final total = grupos * clasifican + terceros;
                final cuadra = FixtureGrouping.esPotenciaDeDos(total);
                final color = cuadra ? AppColors.success : AppColors.warning;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cuadra
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    total < 2
                        ? 'Define al menos 2 equipos clasificados.'
                        : cuadra
                        ? '$total equipos clasifican · arranca en ${FixtureGrouping.rondaSegunEquipos(total).toLowerCase()}.'
                        : '$total equipos clasifican, pero eso no arma una llave pareja (2, 4, 8, 16, 32).',
                    style: AppTextStyles.body.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          text: 'Guardar',
          onPressed: () {
            final clasifican =
                int.tryParse(_clasificanController.text.trim()) ?? 0;
            final terceros =
                int.tryParse(_tercerosController.text.trim()) ?? 0;

            Navigator.pop(
              context,
              _ClasificacionResult(
                clasificanPorGrupo: clasifican,
                mejoresTerceros: terceros,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SeleccionarGrupoDialog extends StatelessWidget {
  final EquipoModel equipo;
  final List<GrupoModel> grupos;

  const _SeleccionarGrupoDialog({required this.equipo, required this.grupos});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Inscribir a ${equipo.nombre}',
        style: AppTextStyles.heading3,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: grupos.map((grupo) {
            final yaEsta = grupo.equipoIds.contains(equipo.id);

            return ListTile(
              leading: Icon(
                yaEsta
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: yaEsta ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(grupo.nombre),
              subtitle: Text('${grupo.equipoIds.length} equipos'),
              onTap: () => Navigator.pop(context, grupo),
            );
          }).toList(),
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _CantidadGruposDialog extends StatefulWidget {
  final int cantidadInicial;

  const _CantidadGruposDialog({required this.cantidadInicial});

  @override
  State<_CantidadGruposDialog> createState() => _CantidadGruposDialogState();
}

class _CantidadGruposDialogState extends State<_CantidadGruposDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.cantidadInicial}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text('Armar grupos manualmente', style: AppTextStyles.heading3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Se crearán grupos vacíos (Grupo A, Grupo B...) para que asignes cada equipo a mano.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad de grupos',
                prefixIcon: Icon(Icons.grid_view_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          text: 'Crear grupos',
          icon: Icons.add,
          onPressed: () {
            final cantidad = int.tryParse(_controller.text.trim()) ?? 0;
            if (cantidad < 2) return;
            Navigator.pop(context, cantidad);
          },
        ),
      ],
    );
  }
}
