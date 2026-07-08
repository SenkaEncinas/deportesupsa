import 'package:cloud_firestore/cloud_firestore.dart';
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

class TablaPosicionesScreen extends StatefulWidget {
  final String campeonatoId;

  const TablaPosicionesScreen({super.key, required this.campeonatoId});

  @override
  State<TablaPosicionesScreen> createState() => _TablaPosicionesScreenState();
}

class _TablaPosicionesScreenState extends State<TablaPosicionesScreen> {
  final CampeonatoService _campeonatoService = CampeonatoService();
  final PartidoService _partidoService = PartidoService();

  late Future<_HistorialPartidosData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_HistorialPartidosData> _loadData() async {
    final campeonato = await _campeonatoService.getCampeonato(
      widget.campeonatoId,
    );

    final partidos = await _partidoService.getPartidos(widget.campeonatoId);

    final golesSnap = await FirebaseFirestore.instance
        .collection('campeonatos')
        .doc(widget.campeonatoId)
        .collection('goles')
        .get();

    final tarjetasSnap = await FirebaseFirestore.instance
        .collection('campeonatos')
        .doc(widget.campeonatoId)
        .collection('tarjetas')
        .get();

    final golesPorPartido = <String, List<_GolHistorial>>{};
    final tarjetasPorPartido = <String, List<_TarjetaHistorial>>{};

    for (final doc in golesSnap.docs) {
      final data = doc.data();

      final partidoId = (data['partidoId'] ?? '').toString();

      if (partidoId.isEmpty) continue;

      golesPorPartido.putIfAbsent(partidoId, () => []);

      golesPorPartido[partidoId]!.add(
        _GolHistorial(
          jugadorNombre: (data['jugadorNombre'] ?? '').toString(),
          equipoNombre: (data['equipoNombre'] ?? '').toString(),
          cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    for (final doc in tarjetasSnap.docs) {
      final data = doc.data();

      final partidoId = (data['partidoId'] ?? '').toString();

      if (partidoId.isEmpty) continue;

      tarjetasPorPartido.putIfAbsent(partidoId, () => []);

      tarjetasPorPartido[partidoId]!.add(
        _TarjetaHistorial(
          jugadorNombre: (data['jugadorNombre'] ?? '').toString(),
          equipoNombre: (data['equipoNombre'] ?? '').toString(),
          amarillas: (data['amarillas'] as num?)?.toInt() ?? 0,
          rojas: (data['rojas'] as num?)?.toInt() ?? 0,
          motivo: (data['motivo'] ?? '').toString(),
        ),
      );
    }

    final partidosConHistorial = partidos.where((partido) {
      final tieneResultado =
          partido.resultadoRegistrado ||
          partido.golesLocal != null ||
          partido.golesVisitante != null;

      final tieneGoles = golesPorPartido[partido.id]?.isNotEmpty ?? false;
      final tieneTarjetas = tarjetasPorPartido[partido.id]?.isNotEmpty ?? false;

      return tieneResultado || tieneGoles || tieneTarjetas;
    }).toList();

    partidosConHistorial.sort((a, b) {
      if (a.fechaHora != null && b.fechaHora != null) {
        return b.fechaHora!.compareTo(a.fechaHora!);
      }

      if (a.fechaHora == null && b.fechaHora != null) return 1;
      if (a.fechaHora != null && b.fechaHora == null) return -1;

      final vueltaCompare = b.vuelta.compareTo(a.vuelta);
      if (vueltaCompare != 0) return vueltaCompare;

      return b.jornada.compareTo(a.jornada);
    });

    final items = partidosConHistorial.map((partido) {
      return _PartidoHistorialItem(
        partido: partido,
        goles: golesPorPartido[partido.id] ?? [],
        tarjetas: tarjetasPorPartido[partido.id] ?? [],
      );
    }).toList();

    return _HistorialPartidosData(campeonato: campeonato, partidos: items);
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha programada';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  String _resultadoTexto(PartidoModel partido) {
    // Incluye penales o prórroga cuando corresponde.
    return partido.marcadorTexto;
  }

  String _tipoResultadoTexto(String tipo) {
    switch (tipo) {
      case TipoResultado.normal:
        return 'Normal';
      case TipoResultado.walkover:
        return 'Walkover';
      case TipoResultado.sancion:
        return 'Sanción';
      default:
        return tipo;
    }
  }

  AppBadgeType _tipoBadgeResultado(String tipo) {
    switch (tipo) {
      case TipoResultado.normal:
        return AppBadgeType.success;
      case TipoResultado.walkover:
        return AppBadgeType.warning;
      case TipoResultado.sancion:
        return AppBadgeType.danger;
      default:
        return AppBadgeType.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_HistorialPartidosData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Cargando historial...');
          }

          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Error al cargar historial',
              message: snapshot.error.toString(),
            );
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            child: AppPage(
              title: 'Historial de partidos',
              subtitle: data.campeonato == null
                  ? 'Goles, tarjetas y resultados registrados.'
                  : data.campeonato!.nombre,
              actions: [
                AppButton.secondary(
                  text: 'Actualizar',
                  icon: Icons.refresh,
                  onPressed: _refresh,
                ),
                AppButton.secondary(
                  text: 'Volver',
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              child: data.partidos.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.history,
                      title: 'Todavía no hay historial',
                      message:
                          'Cuando se registren resultados, goles o tarjetas, aparecerán aquí para que los administradores puedan revisar lo ocurrido.',
                    )
                  : Column(
                      children: data.partidos.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PartidoHistorialCard(
                            item: item,
                            fechaTexto: _fechaTexto,
                            resultadoTexto: _resultadoTexto,
                            tipoResultadoTexto: _tipoResultadoTexto,
                            tipoBadgeResultado: _tipoBadgeResultado,
                          ),
                        );
                      }).toList(),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _PartidoHistorialCard extends StatelessWidget {
  final _PartidoHistorialItem item;
  final String Function(DateTime? fecha) fechaTexto;
  final String Function(PartidoModel partido) resultadoTexto;
  final String Function(String tipo) tipoResultadoTexto;
  final AppBadgeType Function(String tipo) tipoBadgeResultado;

  const _PartidoHistorialCard({
    required this.item,
    required this.fechaTexto,
    required this.resultadoTexto,
    required this.tipoResultadoTexto,
    required this.tipoBadgeResultado,
  });

  @override
  Widget build(BuildContext context) {
    final partido = item.partido;

    final golesLocal = item.goles.where((gol) {
      return gol.equipoNombre == partido.equipoLocalNombre;
    }).toList();

    final golesVisitante = item.goles.where((gol) {
      return gol.equipoNombre == partido.equipoVisitanteNombre;
    }).toList();

    final tarjetasLocal = item.tarjetas.where((tarjeta) {
      return tarjeta.equipoNombre == partido.equipoLocalNombre;
    }).toList();

    final tarjetasVisitante = item.tarjetas.where((tarjeta) {
      return tarjeta.equipoNombre == partido.equipoVisitanteNombre;
    }).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                text: tipoResultadoTexto(partido.tipoResultado),
                type: tipoBadgeResultado(partido.tipoResultado),
                icon: Icons.fact_check_outlined,
              ),
              AppBadge(
                text: partido.estado,
                type: AppBadge.typeFromEstado(partido.estado),
                icon: Icons.sports_soccer,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // En móvil el marcador y los equipos van apilados: la fila
          // aplastaba los nombres con marcadores largos como
          // "1 - 1 (4 - 3 pen.)".
          Builder(
            builder: (context) {
              final marcador = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  resultadoTexto(partido),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.white,
                  ),
                ),
              );

              if (Responsive.isMobile(context)) {
                return Column(
                  children: [
                    Text(
                      partido.equipoLocalNombre,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    marcador,
                    const SizedBox(height: 8),
                    Text(
                      partido.equipoVisitanteNombre,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      partido.equipoLocalNombre,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.heading3,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: marcador,
                  ),
                  Expanded(
                    child: Text(
                      partido.equipoVisitanteNombre,
                      textAlign: TextAlign.left,
                      style: AppTextStyles.heading3,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${fechaTexto(partido.fechaHora)} · Vuelta ${partido.vuelta} · Jornada ${partido.jornada}',
              style: AppTextStyles.small,
            ),
          ),
          if (partido.observacionResultado != null &&
              partido.observacionResultado!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                partido.observacionResultado!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          // En móvil las cajas de cada equipo se apilan: dos columnas
          // de ~150 px eran ilegibles en pantallas chicas.
          if (Responsive.isMobile(context))
            Column(
              children: [
                _EquipoHistorialBox(
                  equipoNombre: partido.equipoLocalNombre,
                  goles: golesLocal,
                  tarjetas: tarjetasLocal,
                ),
                const SizedBox(height: 14),
                _EquipoHistorialBox(
                  equipoNombre: partido.equipoVisitanteNombre,
                  goles: golesVisitante,
                  tarjetas: tarjetasVisitante,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _EquipoHistorialBox(
                    equipoNombre: partido.equipoLocalNombre,
                    goles: golesLocal,
                    tarjetas: tarjetasLocal,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _EquipoHistorialBox(
                    equipoNombre: partido.equipoVisitanteNombre,
                    goles: golesVisitante,
                    tarjetas: tarjetasVisitante,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EquipoHistorialBox extends StatelessWidget {
  final String equipoNombre;
  final List<_GolHistorial> goles;
  final List<_TarjetaHistorial> tarjetas;

  const _EquipoHistorialBox({
    required this.equipoNombre,
    required this.goles,
    required this.tarjetas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(equipoNombre, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          _MiniSectionTitle(icon: Icons.sports_soccer, title: 'Goles'),
          const SizedBox(height: 8),
          if (goles.isEmpty)
            Text('Sin goles registrados.', style: AppTextStyles.small)
          else
            ...goles.map((gol) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(gol.jugadorNombre, style: AppTextStyles.body),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${gol.cantidad}',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 14),
          _MiniSectionTitle(icon: Icons.style_outlined, title: 'Tarjetas'),
          const SizedBox(height: 8),
          if (tarjetas.isEmpty)
            Text('Sin tarjetas registradas.', style: AppTextStyles.small)
          else
            ...tarjetas.map((tarjeta) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TarjetaRow(tarjeta: tarjeta),
              );
            }),
        ],
      ),
    );
  }
}

class _TarjetaRow extends StatelessWidget {
  final _TarjetaHistorial tarjeta;

  const _TarjetaRow({required this.tarjeta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tarjeta.jugadorNombre, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (tarjeta.amarillas > 0)
                _CardBadge(
                  text: 'Amarillas: ${tarjeta.amarillas}',
                  color: Colors.amber.shade700,
                ),
              if (tarjeta.rojas > 0)
                _CardBadge(
                  text: 'Rojas: ${tarjeta.rojas}',
                  color: AppColors.danger,
                ),
            ],
          ),
          if (tarjeta.motivo.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tarjeta.motivo,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _CardBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: AppTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _MiniSectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTextStyles.small.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HistorialPartidosData {
  final CampeonatoModel? campeonato;
  final List<_PartidoHistorialItem> partidos;

  const _HistorialPartidosData({
    required this.campeonato,
    required this.partidos,
  });
}

class _PartidoHistorialItem {
  final PartidoModel partido;
  final List<_GolHistorial> goles;
  final List<_TarjetaHistorial> tarjetas;

  const _PartidoHistorialItem({
    required this.partido,
    required this.goles,
    required this.tarjetas,
  });
}

class _GolHistorial {
  final String jugadorNombre;
  final String equipoNombre;
  final int cantidad;

  const _GolHistorial({
    required this.jugadorNombre,
    required this.equipoNombre,
    required this.cantidad,
  });
}

class _TarjetaHistorial {
  final String jugadorNombre;
  final String equipoNombre;
  final int amarillas;
  final int rojas;
  final String motivo;

  const _TarjetaHistorial({
    required this.jugadorNombre,
    required this.equipoNombre,
    required this.amarillas,
    required this.rojas,
    required this.motivo,
  });
}
