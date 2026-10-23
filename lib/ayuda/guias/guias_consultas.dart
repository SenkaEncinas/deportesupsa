// Guías de consulta y documentos: PDFs, sancionados, auditoría,
// historial de partidos y goleadores.
//
// SI CAMBIA EL TEXTO DE UN BOTÓN EN LA APP, ACTUALIZAR SU GUÍA (y su
// maqueta en escenas.dart).

import 'package:flutter/material.dart';

import '../maqueta.dart';
import '../ayuda_modelo.dart';
import 'escenas.dart';
import 'pasos_comunes.dart';

final guiasConsultas = <GuiaAyuda>[
  GuiaAyuda(
    id: 'imprimir-planilla',
    titulo: 'Imprimir la planilla de un partido',
    resumen: 'La planilla de control para la mesa.',
    icono: Icons.print_outlined,
    pantallas: const [PantallaAyuda.pdfs],
    pantallaDestino: PantallaAyuda.pdfs,
    pasos: [
      pasoAbrirModuloConsulta('PDFs'),
      PasoAyuda(
        titulo: 'Tocá "Planilla" en el partido',
        explicacion:
            'En "Planillas de control por partido". Podés filtrar por fecha '
            'para encontrarlo.',
        escena: () => escenaPdfs(FocoPdfs.planilla),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'Se descarga la planilla con los jugadores de los dos equipos, '
            'según el deporte.',
        escena: () => escenaPdfListo('Planilla', 'planilla_civil_derecho.pdf'),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'imprimir-resultados',
    titulo: 'Imprimir los resultados de la semana',
    resumen: 'El flyer con los resultados para redes.',
    icono: Icons.scoreboard_outlined,
    pantallas: const [PantallaAyuda.pdfs],
    pantallaDestino: PantallaAyuda.pdfs,
    pasos: [
      pasoAbrirModuloConsulta('PDFs'),
      PasoAyuda(
        titulo: 'Tocá "Imprimir resultados"',
        explicacion:
            'En el "Centro de impresión". Toma los partidos del rango de '
            'fechas elegido.',
        escena: () => escenaPdfs(FocoPdfs.resultados),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Se descarga una placa por día con sus resultados.',
        escena: () => escenaPdfListo('Resultados', 'resultados_semana.pdf'),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'imprimir-planillas-equipos',
    titulo: 'Imprimir las listas de todos los equipos',
    resumen: 'Una hoja por equipo con sus jugadores.',
    icono: Icons.groups_2_outlined,
    pantallas: const [PantallaAyuda.pdfs],
    pantallaDestino: PantallaAyuda.pdfs,
    pasos: [
      pasoAbrirModuloConsulta('PDFs'),
      PasoAyuda(
        titulo: 'Tocá "Imprimir todas las planillas"',
        explicacion:
            'En "Planillas de equipos". Para un solo equipo usá su botón '
            '"Imprimir".',
        escena: () => escenaPdfs(FocoPdfs.todasPlanillas),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Se descarga un PDF con la lista de cada equipo.',
        escena: () => escenaPdfListo('Planillas', 'planillas_equipos.pdf'),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'ver-sancionados',
    titulo: 'Revisar los jugadores sancionados',
    resumen: 'Tarjetas y sanciones por jugador.',
    icono: Icons.shield_outlined,
    pantallas: const [PantallaAyuda.sancionados],
    pantallaDestino: PantallaAyuda.sancionados,
    pasos: [
      pasoAbrirModuloConsulta('Sancionados'),
      PasoAyuda(
        titulo: 'Buscá al jugador',
        explicacion: 'Por nombre o por equipo.',
        escena: () => escenaConsulta(
          titulo: 'Jugadores sancionados',
          buscar: 'Méndez',
          focoBuscar: true,
          filas: const [
            MqFila(
              'Carlos Méndez',
              detalle: 'ING. CIVIL · 2 amarillas',
              icono: Icons.shield_outlined,
            ),
          ],
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Ves sus tarjetas, en qué partido y el motivo.',
        escena: () => escenaConsulta(
          titulo: 'Jugadores sancionados',
          buscar: 'Méndez',
          listo: true,
          filas: const [
            MqFila(
              'Carlos Méndez',
              detalle: 'ING. CIVIL · 2 amarillas',
              icono: Icons.shield_outlined,
            ),
            MqFila(
              'vs DERECHO · 24/10/2026',
              detalle: 'Amarilla · conducta antideportiva',
            ),
          ],
        ),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'ver-auditoria',
    titulo: 'Ver quién cambió algo',
    resumen: 'El registro de cada cambio del campeonato.',
    icono: Icons.history,
    pantallas: const [PantallaAyuda.auditoria],
    pantallaDestino: PantallaAyuda.auditoria,
    pasos: [
      pasoAbrirModuloConsulta('Auditoría'),
      PasoAyuda(
        titulo: 'Buscá el cambio',
        explicacion: 'Cada registro dice el módulo, la acción y quién la hizo.',
        escena: () => escenaConsulta(
          titulo: 'Auditoría',
          buscar: 'Resultados',
          focoBuscar: true,
          filas: const [
            MqFila(
              'Anular resultado',
              detalle: 'Resultados · Admin UPSA · 23/10/2026 19:10',
              icono: Icons.history,
            ),
          ],
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Ves el detalle y la observación de ese cambio.',
        escena: () => escenaConsulta(
          titulo: 'Auditoría',
          buscar: 'Resultados',
          listo: true,
          filas: const [
            MqFila(
              'Anular resultado',
              detalle: 'Se cargó el marcador al revés.',
              icono: Icons.history,
            ),
          ],
        ),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'ver-historial',
    titulo: 'Ver el historial de partidos jugados',
    resumen: 'Cada partido con sus goles y tarjetas.',
    icono: Icons.leaderboard_outlined,
    pantallas: const [PantallaAyuda.historial],
    pantallaDestino: PantallaAyuda.historial,
    pasos: [
      pasoAbrirModuloConsulta('Tabla'),
      PasoAyuda(
        titulo: 'Buscá el partido',
        explicacion: 'Están ordenados del más reciente al más viejo.',
        escena: () => escenaConsulta(
          titulo: 'Historial de partidos',
          buscar: 'ING. CIVIL',
          focoBuscar: true,
          filas: const [
            MqFila(
              'ING. CIVIL 2 - 1 DERECHO',
              detalle: 'Grupo A · 24/10/2026',
              icono: Icons.sports_soccer,
            ),
          ],
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Debajo del marcador están los goles y las tarjetas.',
        escena: () => escenaConsulta(
          titulo: 'Historial de partidos',
          buscar: 'ING. CIVIL',
          listo: true,
          filas: const [
            MqFila(
              'ING. CIVIL 2 - 1 DERECHO',
              detalle: 'Goles: Carlos Méndez (2)',
              icono: Icons.sports_soccer,
            ),
          ],
        ),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'ver-goleadores',
    titulo: 'Ver el ranking de goleadores',
    resumen: 'Quién lleva más goles en el campeonato.',
    icono: Icons.sports_soccer,
    pantallas: const [PantallaAyuda.goleadores],
    pantallaDestino: PantallaAyuda.goleadores,
    pasos: [
      pasoAbrirModuloConsulta('Goleadores'),
      PasoAyuda(
        titulo: 'Buscá al goleador',
        explicacion: 'Por nombre del jugador o del equipo.',
        escena: () => escenaConsulta(
          titulo: 'Ranking de goleadores',
          buscar: 'Méndez',
          focoBuscar: true,
          filas: const [
            MqFila(
              '1. Carlos Méndez',
              detalle: 'ING. CIVIL · 7 goles',
              icono: Icons.sports_soccer,
            ),
          ],
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El ranking se actualiza solo con cada resultado. El top 10 se '
            'imprime desde "PDFs".',
        escena: () => escenaConsulta(
          titulo: 'Ranking de goleadores',
          buscar: 'Méndez',
          listo: true,
          filas: const [
            MqFila(
              '1. Carlos Méndez',
              detalle: 'ING. CIVIL · 7 goles',
              icono: Icons.sports_soccer,
            ),
          ],
        ),
      ),
    ],
  ),
];
