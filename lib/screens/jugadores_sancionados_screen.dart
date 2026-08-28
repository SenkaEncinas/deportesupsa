import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/partido_model.dart';
import '../models/tarjeta_model.dart';
import '../services/campeonato_service.dart';
import '../services/partido_service.dart';
import '../services/resultado_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_filter_pill.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/stat_card.dart';

enum _FiltroSancion { todas, amarillas, rojas }

/// Todas las tarjetas/sanciones a jugadores del campeonato en un solo
/// lugar: amarillas, rojas/expulsiones (fútbol) o sanciones por mesa /
/// forzadas (vóley, básquet), con el jugador, el equipo y el partido
/// (con fecha) en el que ocurrió.
class JugadoresSancionadosScreen extends StatefulWidget {
  final String campeonatoId;

  const JugadoresSancionadosScreen({super.key, required this.campeonatoId});

  @override
  State<JugadoresSancionadosScreen> createState() =>
      _JugadoresSancionadosScreenState();
}

class _JugadoresSancionadosScreenState
    extends State<JugadoresSancionadosScreen> {
  final CampeonatoService _campeonatoService = CampeonatoService();
  final PartidoService _partidoService = PartidoService();
  final ResultadoService _resultadoService = ResultadoService();

  _FiltroSancion _filtro = _FiltroSancion.todas;

  List<TarjetaModel> _aplicarFiltro(List<TarjetaModel> tarjetas) {
    switch (_filtro) {
      case _FiltroSancion.amarillas:
        return tarjetas.where((t) => t.amarillas > 0).toList();
      case _FiltroSancion.rojas:
        return tarjetas.where((t) => t.esExpulsion).toList();
      case _FiltroSancion.todas:
        return tarjetas;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: _campeonatoService.streamCampeonato(widget.campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<PartidoModel>>(
            stream: _partidoService.streamPartidos(widget.campeonatoId),
            builder: (context, partidosSnapshot) {
              final partidosPorId = {
                for (final partido in partidosSnapshot.data ?? <PartidoModel>[])
                  partido.id: partido,
              };

              return StreamBuilder<List<TarjetaModel>>(
                stream: _resultadoService.streamTarjetas(widget.campeonatoId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoading(message: 'Cargando sanciones...');
                  }

                  if (snapshot.hasError) {
                    return AppEmptyState(
                      icon: Icons.error_outline,
                      title: 'Error al cargar sanciones',
                      message: snapshot.error.toString(),
                    );
                  }

                  final todas = snapshot.data ?? [];
                  final filtradas = _aplicarFiltro(todas);

                  final totalAmarillas = todas.fold<int>(
                    0,
                    (total, t) => total + t.amarillas,
                  );
                  final totalRojas = todas.fold<int>(
                    0,
                    (total, t) => total + t.rojas,
                  );
                  final jugadoresAfectados = todas
                      .map((t) => t.jugadorId)
                      .toSet()
                      .length;

                  final esFutbol = campeonato?.esFutbol ?? true;

                  return SingleChildScrollView(
                    child: AppPage(
                      title: 'Jugadores sancionados',
                      subtitle: campeonato == null
                          ? 'Amarillas, rojas y sanciones registradas.'
                          : campeonato.nombre,
                      actions: [
                        AppButton.secondary(
                          text: 'Volver',
                          icon: Icons.arrow_back,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppResponsiveGrid(
                            mobileColumns: 2,
                            tabletColumns: 3,
                            desktopColumns: 3,
                            spacing: 12,
                            children: [
                              StatCard(
                                title: esFutbol ? 'Amarillas' : 'Por mesa',
                                value: '$totalAmarillas',
                                icon: Icons.square_rounded,
                                subtitle: esFutbol
                                    ? 'Tarjetas amarillas'
                                    : 'Sanciones por mesa',
                                color: AppColors.warning,
                              ),
                              StatCard(
                                title: esFutbol ? 'Rojas' : 'Forzadas',
                                value: '$totalRojas',
                                icon: Icons.square_rounded,
                                subtitle: esFutbol
                                    ? 'Expulsiones'
                                    : 'Sanciones forzadas',
                                color: AppColors.danger,
                              ),
                              StatCard(
                                title: 'Jugadores',
                                value: '$jugadoresAfectados',
                                icon: Icons.person_off_outlined,
                                subtitle: 'Con al menos una sanción',
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppFilterPill(
                                text: 'Todas',
                                count: todas.length,
                                selected: _filtro == _FiltroSancion.todas,
                                onTap: () => setState(() {
                                  _filtro = _FiltroSancion.todas;
                                }),
                              ),
                              AppFilterPill(
                                text: esFutbol ? 'Amarillas' : 'Por mesa',
                                count: todas
                                    .where((t) => t.amarillas > 0)
                                    .length,
                                selected: _filtro == _FiltroSancion.amarillas,
                                onTap: () => setState(() {
                                  _filtro = _FiltroSancion.amarillas;
                                }),
                              ),
                              AppFilterPill(
                                text: esFutbol ? 'Rojas' : 'Forzadas',
                                count: todas.where((t) => t.esExpulsion).length,
                                selected: _filtro == _FiltroSancion.rojas,
                                onTap: () => setState(() {
                                  _filtro = _FiltroSancion.rojas;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (filtradas.isEmpty)
                            AppEmptyState(
                              icon: Icons.shield_outlined,
                              title: 'Sin sanciones registradas',
                              message: esFutbol
                                  ? 'Cuando se registren tarjetas al cargar un resultado, aparecerán aquí.'
                                  : 'Cuando se registre una sanción por mesa o forzada al cargar un resultado, aparecerá aquí.',
                            )
                          else
                            Column(
                              children: filtradas.map((tarjeta) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SancionCard(
                                    tarjeta: tarjeta,
                                    partido: partidosPorId[tarjeta.partidoId],
                                    esFutbol: esFutbol,
                                  ),
                                );
                              }).toList(),
                            ),
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

class _SancionCard extends StatelessWidget {
  final TarjetaModel tarjeta;
  final PartidoModel? partido;
  final bool esFutbol;

  const _SancionCard({
    required this.tarjeta,
    required this.partido,
    required this.esFutbol,
  });

  String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (tarjeta.amarillas > 0) {
      badges.add(
        AppBadge(
          text: esFutbol
              ? 'Amarilla ×${tarjeta.amarillas}'
              : 'Sanción por mesa',
          type: AppBadgeType.warning,
        ),
      );
    }

    if (tarjeta.rojas > 0) {
      badges.add(
        AppBadge(
          text: esFutbol ? 'Roja · Expulsión' : 'Sanción forzada',
          type: AppBadgeType.danger,
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: badges,
          ),
          const SizedBox(height: 12),
          Text(tarjeta.jugadorNombre, style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(
            tarjeta.equipoNombre,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.sports_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  partido == null
                      ? 'Partido no encontrado'
                      : '${partido!.equipoLocalNombre} vs ${partido!.equipoVisitanteNombre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _fechaTexto(
                  partido?.fechaHora ?? tarjeta.fechaRegistro,
                ),
                style: AppTextStyles.small,
              ),
            ],
          ),
          if (tarjeta.motivo != null && tarjeta.motivo!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tarjeta.motivo!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
