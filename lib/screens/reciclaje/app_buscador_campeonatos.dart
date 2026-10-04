import 'package:flutter/material.dart';

import '../../models/campeonato_model.dart';
import 'app_card.dart';
import 'app_colors.dart';
import 'app_filter_pill.dart';
import 'app_inline_empty_state.dart';
import 'app_responsive_grid.dart';
import 'app_section_header.dart';
import 'app_text_styles.dart';

/// Buscador de campeonatos con filtro por estado y la grilla de
/// resultados. Lo usan la portada pública y el listado del admin, que
/// tenían cada uno su copia completa.
///
/// El texto de búsqueda y el filtro viven acá adentro: escribir solo
/// redibuja esta parte, no la pantalla entera con su encabezado.
class AppBuscadorCampeonatos extends StatefulWidget {
  final List<CampeonatoModel> campeonatos;
  final String titulo;
  final String subtitulo;

  /// Qué mostrar cuando no hay ningún campeonato creado.
  final Widget vacio;
  final Widget Function(CampeonatoModel campeonato) itemBuilder;

  const AppBuscadorCampeonatos({
    super.key,
    required this.campeonatos,
    required this.titulo,
    required this.subtitulo,
    required this.vacio,
    required this.itemBuilder,
  });

  @override
  State<AppBuscadorCampeonatos> createState() => _AppBuscadorCampeonatosState();
}

class _AppBuscadorCampeonatosState extends State<AppBuscadorCampeonatos> {
  final _controller = TextEditingController();

  /// `null` = todos los estados.
  String? _estado;
  String _busqueda = '';

  static const _filtros = <(String texto, String? estado)>[
    ('Todos', null),
    ('Inscripción', CampeonatoEstado.inscripcion),
    ('Activo', CampeonatoEstado.activo),
    ('Finalizado', CampeonatoEstado.finalizado),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CampeonatoModel> get _filtrados {
    final texto = _busqueda.trim().toLowerCase();

    return widget.campeonatos.where((campeonato) {
      if (_estado != null && campeonato.estado != _estado) return false;
      if (texto.isEmpty) return true;

      return [
        campeonato.nombre,
        campeonato.descripcion,
        campeonato.temporada,
        campeonato.modalidad,
        campeonato.tipoCampeonato,
        campeonato.cancha,
      ].join(' ').toLowerCase().contains(texto);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buscar campeonato', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: (valor) => setState(() => _busqueda = valor),
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText:
                      'Buscar por nombre, temporada, modalidad o cancha...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _busqueda.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Borrar búsqueda',
                          onPressed: () {
                            _controller.clear();
                            setState(() => _busqueda = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (texto, estado) in _filtros)
                    AppFilterPill(
                      text: texto,
                      selected: _estado == estado,
                      onTap: () => setState(() => _estado = estado),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AppSectionHeader(title: widget.titulo, subtitle: widget.subtitulo),
        const SizedBox(height: 14),
        if (widget.campeonatos.isEmpty)
          widget.vacio
        else if (filtrados.isEmpty)
          const AppInlineEmptyState(
            icon: Icons.search_off_rounded,
            text: 'No hay campeonatos con esos filtros.',
            subtitle: 'Prueba cambiando el estado o el texto de búsqueda.',
          )
        else
          AppResponsiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            spacing: 16,
            children: filtrados.map(widget.itemBuilder).toList(),
          ),
      ],
    );
  }
}
