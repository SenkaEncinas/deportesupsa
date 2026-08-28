// Tests de responsividad de la sección Deportes UPSA.
//
// Verifican que los componentes visuales principales no produzcan
// "RenderFlex overflowed" en los tres anchos de referencia:
// móvil (375), tablet (768) y desktop (1440).
//
// Se prueban los componentes puros de UI (sin Firebase): las pantallas
// completas dependen de Firestore y no se pueden montar en un widget
// test sin mocks externos.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/models/tabla_posicion_model.dart';
import 'package:futsal/screens/reciclaje/app_badge.dart';
import 'package:futsal/screens/reciclaje/app_bracket_view.dart';
import 'package:futsal/screens/reciclaje/app_card.dart';
import 'package:futsal/screens/reciclaje/app_hero_card.dart';
import 'package:futsal/screens/reciclaje/app_match_card.dart';
import 'package:futsal/screens/reciclaje/app_responsive_grid.dart';
import 'package:futsal/screens/reciclaje/app_section_header.dart';
import 'package:futsal/screens/reciclaje/app_standing_card.dart';
import 'package:futsal/screens/reciclaje/championship_public_card.dart';

const _anchosReferencia = <String, Size>{
  'mobile (375px)': Size(375, 812),
  'tablet (768px)': Size(768, 1024),
  'desktop (1440px)': Size(1440, 900),
};

CampeonatoModel _campeonatoDePrueba() {
  return CampeonatoModel.fromMap('test-id', {
    'nombre': 'Campeonato UPSA Futsal Intercarreras Temporada Larga 2026',
    'descripcion':
        'Descripción larga para forzar varias líneas de texto en la card '
        'y comprobar que nada se corta ni desborda en pantallas chicas.',
    'temporada': '2026',
    'cancha': 'Polideportivo UPSA - Cancha principal techada',
    'tipoCampeonato': TipoCampeonato.gruposEliminacion,
    'estado': CampeonatoEstado.activo,
  });
}

PartidoModel _partidoDePrueba() {
  return PartidoModel.fromMap('partido-id', {
    'jornada': 3,
    'vuelta': 2,
    'equipoLocalId': 'a',
    'equipoLocalNombre': 'Ingeniería de Sistemas Computacionales UPSA',
    'equipoVisitanteId': 'b',
    'equipoVisitanteNombre': 'Administración de Empresas y Negocios',
    'golesLocal': 1,
    'golesVisitante': 1,
    'resultadoRegistrado': true,
    'definidoPorPenales': true,
    'penalesLocal': 4,
    'penalesVisitante': 3,
  });
}

TablaPosicionModel _posicionDePrueba({
  required int posicion,
  required String equipoNombre,
}) {
  return TablaPosicionModel(
    equipoId: 'equipo-$posicion',
    equipoNombre: equipoNombre,
    partidosJugados: 12,
    partidosGanados: 9,
    partidosEmpatados: 2,
    partidosPerdidos: 1,
    golesFavor: 34,
    golesContra: 12,
    diferenciaGoles: 22,
    puntos: 29,
    posicion: posicion,
    puntosFavor: 456,
    puntosContra: 398,
    diferenciaPuntos: 58,
  );
}

/// Llave de cuartos → semifinal → final, con nombres largos de equipo
/// para forzar el peor caso de ancho dentro de cada card de la llave.
List<MapEntry<String, List<PartidoModel>>> _rondasLlaveDePrueba() {
  PartidoModel partido(String local, String visitante, {bool jugado = false}) {
    return PartidoModel.fromMap('p-$local-$visitante', {
      'jornada': 1,
      'vuelta': 1,
      'equipoLocalId': local,
      'equipoLocalNombre': local,
      'equipoVisitanteId': visitante,
      'equipoVisitanteNombre': visitante,
      'golesLocal': jugado ? 2 : null,
      'golesVisitante': jugado ? 1 : null,
      'resultadoRegistrado': jugado,
      'ganadorId': jugado ? local : null,
    });
  }

  return [
    MapEntry('Cuartos de final', [
      partido('Ingeniería de Sistemas Computacionales', 'Derecho', jugado: true),
      partido('Administración de Empresas y Negocios', 'Psicología'),
      partido('Arquitectura y Urbanismo', 'Comunicación Social', jugado: true),
      partido('Medicina', 'Ingeniería Industrial'),
    ]),
    MapEntry('Semifinales', [
      partido('Ingeniería de Sistemas Computacionales', 'Administración de Empresas y Negocios'),
      partido('Arquitectura y Urbanismo', 'Medicina'),
    ]),
    MapEntry('Final', [
      partido('Ingeniería de Sistemas Computacionales', 'Arquitectura y Urbanismo'),
    ]),
  ];
}

/// Caso más ancho posible: vóley usa 9 estadísticas además de
/// posición/nombre/puntos (PJ, G, P, SF, SC, DS, PF, PC, DP).
List<MapEntry<String, String>> _statsVoleyDePrueba() {
  return const [
    MapEntry('PJ', '12'),
    MapEntry('G', '9'),
    MapEntry('P', '3'),
    MapEntry('SF', '30'),
    MapEntry('SC', '14'),
    MapEntry('DS', '16'),
    MapEntry('PF', '456'),
    MapEntry('PC', '398'),
    MapEntry('DP', '58'),
  ];
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('ChampionshipPublicCard sin overflow', () {
    for (final entry in _anchosReferencia.entries) {
      testWidgets('en ${entry.key}', (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          ChampionshipPublicCard(
            campeonato: _campeonatoDePrueba(),
            onTap: () {},
          ),
        );

        // Un RenderFlex overflow se reporta como excepción del framework.
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AppMatchCard sin overflow', () {
    for (final entry in _anchosReferencia.entries) {
      testWidgets('en ${entry.key}', (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          AppMatchCard(partido: _partidoDePrueba(), showResult: true),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AppHeroCard sin overflow', () {
    // Caso real reportado: el hero con caja de info (Cancha, Modalidad,
    // Formato, Temporada) ocupaba casi toda la pantalla en móvil y con
    // textos largos desbordaba. Se prueba con los mismos 4 datos.
    for (final entry in _anchosReferencia.entries) {
      testWidgets('en ${entry.key}', (tester) async {
        final campeonato = _campeonatoDePrueba();

        await _pumpAt(
          tester,
          entry.value,
          AppHeroCard(
            title: campeonato.nombre,
            description: campeonato.descripcion,
            badges: const [],
            chips: const [
              AppHeroChipData(
                icon: Icons.school_outlined,
                text: 'Universidad Privada de Santa Cruz',
              ),
              AppHeroChipData(
                icon: Icons.public_outlined,
                text: 'Vista pública',
              ),
            ],
            infoItems: [
              AppHeroInfoItem(
                icon: Icons.place_outlined,
                label: 'Cancha',
                value: campeonato.cancha,
              ),
              AppHeroInfoItem(
                icon: Icons.category_outlined,
                label: 'Modalidad',
                value: campeonato.modalidad,
              ),
              AppHeroInfoItem(
                icon: Icons.account_tree_outlined,
                label: 'Formato',
                value: campeonato.tipoCampeonato,
              ),
              AppHeroInfoItem(
                icon: Icons.calendar_today_outlined,
                label: 'Temporada',
                value: campeonato.temporada,
              ),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'el hero completo cabe en una pantalla móvil de 812px de alto',
      (tester) async {
        // Verifica que el hero compacto no ocupe "mucha pantalla en el
        // celular": debe caber holgado en un iPhone SE (375x812) dejando
        // espacio para el resto del contenido de la pantalla.
        final campeonato = _campeonatoDePrueba();

        // SingleChildScrollView (igual que en cada pantalla real) da
        // altura ilimitada y sin forzar: así se mide la altura
        // intrínseca del hero en vez de la altura del Scaffold.
        await _pumpAt(
          tester,
          const Size(375, 812),
          AppHeroCard(
            title: campeonato.nombre,
            description: campeonato.descripcion,
            badges: [AppBadge(text: 'Activo', type: AppBadgeType.success)],
            infoItems: [
              AppHeroInfoItem(
                icon: Icons.place_outlined,
                label: 'Cancha',
                value: campeonato.cancha,
              ),
              AppHeroInfoItem(
                icon: Icons.category_outlined,
                label: 'Modalidad',
                value: campeonato.modalidad,
              ),
              AppHeroInfoItem(
                icon: Icons.account_tree_outlined,
                label: 'Formato',
                value: campeonato.tipoCampeonato,
              ),
              AppHeroInfoItem(
                icon: Icons.calendar_today_outlined,
                label: 'Temporada',
                value: campeonato.temporada,
              ),
            ],
          ),
        );

        expect(tester.takeException(), isNull);

        final heroHeight = tester.getSize(find.byType(AppHeroCard)).height;

        // Antes de este fix el hero equivalente superaba los 700px de alto
        // en un dispositivo de 812px; debe quedar bastante por debajo para
        // dejar lugar al resto de la pantalla.
        expect(heroHeight, lessThan(420));
      },
    );
  });

  group('Sección de próximos partidos / últimos resultados sin overflow', () {
    // Reproduce el patrón exacto usado en championship_detail_screen.dart:
    // un AppCard con AppSectionHeader y una lista de AppMatchCard, algunos
    // con nombres de equipo muy largos y marcador con penales.
    for (final entry in _anchosReferencia.entries) {
      testWidgets('en ${entry.key}', (tester) async {
        final partidos = [
          _partidoDePrueba(),
          PartidoModel.fromMap('partido-2', {
            'jornada': 1,
            'vuelta': 1,
            'equipoLocalId': 'c',
            'equipoLocalNombre':
                'Facultad de Ciencias Empresariales y Económicas',
            'equipoVisitanteId': 'd',
            'equipoVisitanteNombre': 'Derecho y Ciencias Políticas UPSA',
            'golesLocal': 3,
            'golesVisitante': 0,
            'resultadoRegistrado': true,
          }),
        ];

        await _pumpAt(
          tester,
          entry.value,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(
                  title: 'Próximos partidos',
                  subtitle: 'Programación oficial del campeonato.',
                ),
                const SizedBox(height: 16),
                ...partidos.map((partido) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppMatchCard(partido: partido, showResult: true),
                  );
                }),
              ],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AppStandingCard sin overflow', () {
    // Caso más exigente: vóley con 9 estadísticas y un nombre de equipo
    // muy largo, que es exactamente lo que reemplaza a la DataTable de
    // hasta 12 columnas en la tabla de posiciones en móvil.
    for (final entry in _anchosReferencia.entries) {
      testWidgets('en ${entry.key}', (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          AppStandingCard(
            item: _posicionDePrueba(
              posicion: 1,
              equipoNombre:
                  'Facultad de Ciencias Empresariales y Económicas UPSA',
            ),
            stats: _statsVoleyDePrueba(),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('varias cards seguidas sin overflow (mobile)', (tester) async {
      await _pumpAt(
        tester,
        const Size(375, 812),
        Column(
          children: List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppStandingCard(
                item: _posicionDePrueba(
                  posicion: index + 1,
                  equipoNombre: 'Equipo número ${index + 1} de la facultad',
                ),
                stats: _statsVoleyDePrueba(),
              ),
            );
          }),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('AppBracketView sin overflow', () {
    for (final entry in _anchosReferencia.entries) {
      testWidgets('en ${entry.key}', (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          AppBracketView(
            rondas: _rondasLlaveDePrueba(),
            deporte: DeporteTipo.futbol,
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AppResponsiveGrid sin overflow', () {
    for (final entry in _anchosReferencia.entries) {
      testWidgets('en ${entry.key}', (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          AppResponsiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            children: List.generate(6, (index) {
              return ChampionshipPublicCard(
                campeonato: _campeonatoDePrueba(),
                onTap: () {},
              );
            }),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
