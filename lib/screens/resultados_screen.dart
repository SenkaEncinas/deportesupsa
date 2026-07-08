import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/partido_model.dart';
import '../services/campeonato_service.dart';
import '../services/partido_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';
import 'resultado_form_screen.dart';

class ResultadosScreen extends StatelessWidget {
  final String campeonatoId;

  const ResultadosScreen({
    super.key,
    required this.campeonatoId,
  });

  String _resultadoTexto(PartidoModel partido, CampeonatoModel? campeonato) {
    if (!partido.resultadoRegistrado) return 'Sin resultado';

    // Para vóley el marcador son sets ganados.
    if (campeonato != null && campeonato.esVolley) {
      return '${partido.marcadorTexto} en sets';
    }

    return partido.marcadorTexto;
  }

  @override
  Widget build(BuildContext context) {
    final campeonatoService = CampeonatoService();
    final partidoService = PartidoService();

    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: campeonatoService.streamCampeonato(campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<PartidoModel>>(
            stream: partidoService.streamPartidos(campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando partidos...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar partidos',
                  message: snapshot.error.toString(),
                );
              }

              final partidos = snapshot.data ?? [];

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Resultados',
                  subtitle: campeonato == null
                      ? 'Registro de resultados.'
                      : campeonato.nombre,
                  actions: [
                    AppButton.secondary(
                      text: 'Volver',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                  child: partidos.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.fact_check_outlined,
                          title: 'No hay partidos',
                          message:
                              'Primero genera el fixture para poder registrar resultados.',
                        )
                      : Column(
                          children: partidos.map((partido) {
                            final habilitado =
                                campeonato?.estado == CampeonatoEstado.activo &&
                                    partido.estado !=
                                        PartidoEstado.pendienteProgramacion;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ResultadoCard(
                                partido: partido,
                                campeonato: campeonato,
                                resultadoTexto:
                                    _resultadoTexto(partido, campeonato),
                                habilitado: habilitado,
                                onEditar: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResultadoFormScreen(
                                        campeonatoId: campeonatoId,
                                        partido: partido,
                                        campeonato: campeonato,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
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

class _ResultadoCard extends StatelessWidget {
  final PartidoModel partido;
  final CampeonatoModel? campeonato;
  final String resultadoTexto;
  final bool habilitado;
  final VoidCallback onEditar;

  const _ResultadoCard({
    required this.partido,
    required this.campeonato,
    required this.resultadoTexto,
    required this.habilitado,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppBadge(
              text: partido.estado,
              type: AppBadge.typeFromEstado(partido.estado),
            ),
            if (partido.grupoId != null && partido.grupoId!.isNotEmpty)
              AppBadge(
                text: partido.grupoId!,
                type: AppBadgeType.info,
              ),
            if (partido.definidoPorPenales)
              const AppBadge(
                text: 'Penales',
                type: AppBadgeType.warning,
              ),
            if (partido.definidoPorProrroga)
              const AppBadge(
                text: 'Prórroga',
                type: AppBadgeType.warning,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 6),
        Text(
          'Vuelta ${partido.vuelta} · Jornada ${partido.jornada}',
          style: AppTextStyles.small,
        ),
        if (partido.sets.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Sets: ${partido.setsTexto}',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );

    final marcador = Text(
      resultadoTexto,
      style: AppTextStyles.heading3,
    );

    final boton = AppButton.secondary(
      text: partido.resultadoRegistrado ? 'Editar' : 'Registrar',
      icon: Icons.edit_outlined,
      onPressed: habilitado ? onEditar : null,
    );

    if (isMobile) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            info,
            const SizedBox(height: 12),
            marcador,
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: boton),
          ],
        ),
      );
    }

    return AppCard(
      child: Row(
        children: [
          Expanded(child: info),
          marcador,
          const SizedBox(width: 14),
          boton,
        ],
      ),
    );
  }
}
