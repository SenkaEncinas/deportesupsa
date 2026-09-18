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
import 'reciclaje/app_inline_empty_state.dart';
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

  // Los streams se crean una sola vez y no dentro de build(): si se
  // reconstruyen en cada build, cada setState (una tecla en un
  // buscador, por ejemplo) genera una suscripción nueva, el
  // StreamBuilder vuelve a "waiting" y la pantalla entera se
  // reemplaza por el loading, perdiendo el foco del campo.
  late final Stream<CampeonatoModel?> _campeonatoStream = _campeonatoService
      .streamCampeonato(widget.campeonatoId);
  late final Stream<List<PartidoModel>> _partidosStream = _partidoService
      .streamPartidos(widget.campeonatoId);
  late final Stream<List<TarjetaModel>> _tarjetasStream = _resultadoService
      .streamTarjetas(widget.campeonatoId);

  final TextEditingController _busquedaController = TextEditingController();
  String _busqueda = '';

  /// Equipo elegido en el filtro; `null` = todos los equipos.
  String? _equipo;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  bool get _hayFiltrosActivos =>
      _busqueda.trim().isNotEmpty ||
      _equipo != null ||
      _filtro != _FiltroSancion.todas;

  void _limpiarFiltros() {
    setState(() {
      _busquedaController.clear();
      _busqueda = '';
      _equipo = null;
      _filtro = _FiltroSancion.todas;
    });
  }

  /// Quita tildes y pasa a minúsculas: así "Martinez" encuentra a
  /// "Martínez" y la búsqueda no depende de cómo se escribió el nombre.
  String _normalizar(String texto) {
    const conTilde = 'áéíóúüñ';
    const sinTilde = 'aeiouun';
    final buffer = StringBuffer();
    for (final letra in texto.toLowerCase().split('')) {
      final i = conTilde.indexOf(letra);
      buffer.write(i == -1 ? letra : sinTilde[i]);
    }
    return buffer.toString().trim();
  }

  /// Busca en el nombre del jugador, su equipo y los equipos de los
  /// partidos donde lo sancionaron.
  bool _coincideBusqueda(_JugadorSancionado jugador) {
    final consulta = _normalizar(_busqueda);
    if (consulta.isEmpty) return true;

    final campos = <String>[
      jugador.nombre,
      jugador.equipo,
      for (final o in jugador.ocasiones) ...[
        o.partido?.equipoLocalNombre ?? '',
        o.partido?.equipoVisitanteNombre ?? '',
      ],
    ];

    // Todas las palabras tienen que aparecer, en cualquier orden:
    // "mateo inge" encuentra a Mateo de Ingeniería.
    final texto = _normalizar(campos.join(' '));
    return consulta
        .split(RegExp(r'\s+'))
        .every((palabra) => texto.contains(palabra));
  }

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

  /// Clave del jugador para agrupar: el id si está, y si no (registros
  /// viejos) nombre + equipo, para no mezclar a dos "Mateo" distintos.
  String _claveJugador(TarjetaModel t) {
    if (t.jugadorId.trim().isNotEmpty) return t.jugadorId;
    return '${t.jugadorNombre.trim().toLowerCase()}|${t.equipoId}';
  }

  int _contarJugadores(Iterable<TarjetaModel> tarjetas) {
    return tarjetas.map(_claveJugador).toSet().length;
  }

  /// Una entrada por jugador con todas sus tarjetas adentro, en vez de
  /// una card por tarjeta (antes "Mateo" aparecía tres veces si le
  /// sacaron tres amarillas). Las ocasiones van ordenadas por fecha del
  /// partido, y los jugadores con más tarjetas quedan primero.
  List<_JugadorSancionado> _agruparPorJugador(
    List<TarjetaModel> tarjetas,
    Map<String, PartidoModel> partidosPorId,
  ) {
    final grupos = <String, List<TarjetaModel>>{};

    for (final tarjeta in tarjetas) {
      grupos.putIfAbsent(_claveJugador(tarjeta), () => []).add(tarjeta);
    }

    final jugadores = grupos.values.map((lista) {
      final ocasiones =
          lista
              .map(
                (t) => _OcasionSancion(
                  tarjeta: t,
                  partido: partidosPorId[t.partidoId],
                ),
              )
              .toList()
            ..sort((a, b) {
              final fa = a.fecha;
              final fb = b.fecha;
              if (fa == null && fb == null) return 0;
              if (fa == null) return 1;
              if (fb == null) return -1;
              return fa.compareTo(fb);
            });

      return _JugadorSancionado(
        nombre: lista.first.jugadorNombre,
        equipo: lista.first.equipoNombre,
        ocasiones: ocasiones,
      );
    }).toList();

    jugadores.sort((a, b) {
      final porRojas = b.totalRojas.compareTo(a.totalRojas);
      if (porRojas != 0) return porRojas;
      final porAmarillas = b.totalAmarillas.compareTo(a.totalAmarillas);
      if (porAmarillas != 0) return porAmarillas;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });

    return jugadores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: _campeonatoStream,
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<PartidoModel>>(
            stream: _partidosStream,
            builder: (context, partidosSnapshot) {
              final partidosPorId = {
                for (final partido in partidosSnapshot.data ?? <PartidoModel>[])
                  partido.id: partido,
              };

              return StreamBuilder<List<TarjetaModel>>(
                stream: _tarjetasStream,
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

                  final equipos =
                      todas
                          .map((t) => t.equipoNombre.trim())
                          .where((e) => e.isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort(
                          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                        );

                  // Si el equipo elegido ya no tiene sanciones (se borró
                  // la última), se vuelve a "todos" en vez de dejar la
                  // lista vacía sin explicación.
                  final equipoActivo =
                      _equipo != null && equipos.contains(_equipo)
                      ? _equipo
                      : null;

                  final delEquipo = equipoActivo == null
                      ? todas
                      : todas
                            .where((t) => t.equipoNombre.trim() == equipoActivo)
                            .toList();

                  final filtradas = _aplicarFiltro(delEquipo);
                  final jugadores = _agruparPorJugador(
                    filtradas,
                    partidosPorId,
                  ).where(_coincideBusqueda).toList();

                  final totalAmarillas = todas.fold<int>(
                    0,
                    (total, t) => total + t.amarillas,
                  );
                  final totalRojas = todas.fold<int>(
                    0,
                    (total, t) => total + t.rojas,
                  );
                  final jugadoresAfectados = _contarJugadores(todas);

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
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _BuscadorYEquipo(
                                  controller: _busquedaController,
                                  equipos: equipos,
                                  equipo: equipoActivo,
                                  onBuscar: (valor) =>
                                      setState(() => _busqueda = valor),
                                  onEquipo: (valor) =>
                                      setState(() => _equipo = valor),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Los contadores cuentan jugadores, no
                                    // tarjetas: la lista ahora muestra una sola
                                    // card por jugador.
                                    AppFilterPill(
                                      text: 'Todas',
                                      count: _contarJugadores(delEquipo),
                                      selected: _filtro == _FiltroSancion.todas,
                                      onTap: () => setState(() {
                                        _filtro = _FiltroSancion.todas;
                                      }),
                                    ),
                                    AppFilterPill(
                                      text: esFutbol ? 'Amarillas' : 'Por mesa',
                                      count: _contarJugadores(
                                        delEquipo.where((t) => t.amarillas > 0),
                                      ),
                                      selected:
                                          _filtro == _FiltroSancion.amarillas,
                                      onTap: () => setState(() {
                                        _filtro = _FiltroSancion.amarillas;
                                      }),
                                    ),
                                    AppFilterPill(
                                      text: esFutbol ? 'Rojas' : 'Forzadas',
                                      count: _contarJugadores(
                                        delEquipo.where((t) => t.esExpulsion),
                                      ),
                                      selected: _filtro == _FiltroSancion.rojas,
                                      onTap: () => setState(() {
                                        _filtro = _FiltroSancion.rojas;
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (todas.isNotEmpty) ...[
                            _ResumenResultados(
                              cantidad: jugadores.length,
                              hayFiltros: _hayFiltrosActivos,
                              onLimpiar: _limpiarFiltros,
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (todas.isEmpty)
                            AppEmptyState(
                              icon: Icons.shield_outlined,
                              title: 'Sin sanciones registradas',
                              message: esFutbol
                                  ? 'Cuando se registren tarjetas al cargar un resultado, aparecerán aquí.'
                                  : 'Cuando se registre una sanción por mesa o forzada al cargar un resultado, aparecerá aquí.',
                            )
                          else if (jugadores.isEmpty)
                            const AppInlineEmptyState(
                              icon: Icons.search_off_rounded,
                              text: 'Ningún jugador coincide con la búsqueda.',
                              subtitle:
                                  'Probá con otro nombre, otro equipo o limpiá los filtros.',
                            )
                          else
                            Column(
                              children: jugadores.map((jugador) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _JugadorSancionadoCard(
                                    jugador: jugador,
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

/// Buscador por nombre (jugador, equipo o rival) y selector de equipo.
/// En pantallas anchas van en una fila; en celular, apilados.
class _BuscadorYEquipo extends StatelessWidget {
  final TextEditingController controller;
  final List<String> equipos;
  final String? equipo;
  final ValueChanged<String> onBuscar;
  final ValueChanged<String?> onEquipo;

  const _BuscadorYEquipo({
    required this.controller,
    required this.equipos,
    required this.equipo,
    required this.onBuscar,
    required this.onEquipo,
  });

  @override
  Widget build(BuildContext context) {
    final buscador = TextField(
      controller: controller,
      onChanged: onBuscar,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: 'Buscar jugador o equipo...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                onPressed: () {
                  controller.clear();
                  onBuscar('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );

    final selectorEquipo = DropdownButtonFormField<String?>(
      key: ValueKey(equipo),
      initialValue: equipo,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.groups_outlined, color: AppColors.textSecondary),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Todos los equipos'),
        ),
        ...equipos.map(
          (nombre) => DropdownMenuItem<String?>(
            value: nombre,
            child: Text(nombre, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onEquipo,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [buscador, const SizedBox(height: 12), selectorEquipo],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: buscador),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: selectorEquipo),
          ],
        );
      },
    );
  }
}

/// "N jugadores" y, si hay algún filtro puesto, un botón para limpiarlos.
class _ResumenResultados extends StatelessWidget {
  final int cantidad;
  final bool hayFiltros;
  final VoidCallback onLimpiar;

  const _ResumenResultados({
    required this.cantidad,
    required this.hayFiltros,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            cantidad == 1 ? '1 jugador' : '$cantidad jugadores',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (hayFiltros)
          TextButton.icon(
            onPressed: onLimpiar,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Limpiar filtros'),
          ),
      ],
    );
  }
}

class _OcasionSancion {
  final TarjetaModel tarjeta;
  final PartidoModel? partido;

  const _OcasionSancion({required this.tarjeta, required this.partido});

  /// Fecha del partido; si el partido ya no existe, la de registro.
  DateTime? get fecha => partido?.fechaHora ?? tarjeta.fechaRegistro;
}

class _JugadorSancionado {
  final String nombre;
  final String equipo;
  final List<_OcasionSancion> ocasiones;

  const _JugadorSancionado({
    required this.nombre,
    required this.equipo,
    required this.ocasiones,
  });

  int get totalAmarillas =>
      ocasiones.fold(0, (total, o) => total + o.tarjeta.amarillas);

  int get totalRojas =>
      ocasiones.fold(0, (total, o) => total + o.tarjeta.rojas);
}

/// Una sola card por jugador: nombre, equipo, totales y la lista de cada
/// ocasión en que lo sancionaron, con la fecha y el partido.
class _JugadorSancionadoCard extends StatelessWidget {
  final _JugadorSancionado jugador;
  final bool esFutbol;

  const _JugadorSancionadoCard({required this.jugador, required this.esFutbol});

  @override
  Widget build(BuildContext context) {
    final amarillas = jugador.totalAmarillas;
    final rojas = jugador.totalRojas;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jugador.nombre, style: AppTextStyles.heading3),
                    const SizedBox(height: 4),
                    Text(
                      jugador.equipo,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  if (amarillas > 0)
                    AppBadge(
                      text: esFutbol
                          ? (amarillas == 1
                                ? '1 amarilla'
                                : '$amarillas amarillas')
                          : (amarillas == 1
                                ? '1 por mesa'
                                : '$amarillas por mesa'),
                      type: AppBadgeType.warning,
                    ),
                  if (rojas > 0)
                    AppBadge(
                      text: esFutbol
                          ? (rojas == 1 ? '1 roja' : '$rojas rojas')
                          : (rojas == 1 ? '1 forzada' : '$rojas forzadas'),
                      type: AppBadgeType.danger,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 6),
          ...jugador.ocasiones.map(
            (ocasion) => _FilaOcasion(ocasion: ocasion, esFutbol: esFutbol),
          ),
        ],
      ),
    );
  }
}

class _FilaOcasion extends StatelessWidget {
  final _OcasionSancion ocasion;
  final bool esFutbol;

  const _FilaOcasion({required this.ocasion, required this.esFutbol});

  String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year} · $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final tarjeta = ocasion.tarjeta;
    final partido = ocasion.partido;
    final esRoja = tarjeta.rojas > 0;
    final color = esRoja ? AppColors.danger : AppColors.warning;

    final etiqueta = esRoja
        ? (esFutbol ? 'Roja' : 'Forzada')
        : esFutbol
        ? (tarjeta.amarillas > 1
              ? 'Amarilla ×${tarjeta.amarillas}'
              : 'Amarilla')
        : 'Por mesa';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetita de color como marcador visual de la ocasión.
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 12,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _fechaTexto(ocasion.fecha),
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      etiqueta,
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: esRoja
                            ? AppColors.danger
                            : AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  partido == null
                      ? 'Partido no encontrado'
                      : '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (tarjeta.motivo != null &&
                    tarjeta.motivo!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tarjeta.motivo!,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primaryDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
