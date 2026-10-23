import 'package:flutter/widgets.dart';

import 'guias/guias_campeonato.dart';
import 'guias/guias_competencia.dart';
import 'guias/guias_consultas.dart';
import 'guias/guias_inscripcion.dart';

/// Quién usa la app. Por ahora la ayuda es solo para el administrador;
/// el campo existe para que una guía nunca se le ofrezca a alguien que
/// no tiene esa pantalla en su menú.
enum RolAyuda { admin }

/// Las pantallas del administrador que tienen botón de ayuda.
enum PantallaAyuda {
  panel,
  campeonatos,
  nuevoCampeonato,
  detalleCampeonato,
  equipos,
  equipoForm,
  jugadores,
  jugadorForm,
  grupos,
  fixture,
  resultados,
  resultadoForm,
  llaves,
  igualacion,
  historial,
  goleadores,
  sancionados,
  pdfs,
  auditoria,
}

/// Un paso de una guía: una acción y un elemento señalado en la maqueta.
class PasoAyuda {
  /// En imperativo y con el texto real del botón entre comillas.
  final String titulo;

  /// Dónde está el elemento y qué pasa al tocarlo (1 o 2 oraciones).
  final String explicacion;

  /// Solo para lo que puede salir mal o no se puede deshacer.
  final String? consejo;

  /// Dibuja la maqueta del paso.
  final Widget Function() escena;

  const PasoAyuda({
    required this.titulo,
    required this.explicacion,
    required this.escena,
    this.consejo,
  });
}

/// Una tarea concreta que el admin quiere hacer, paso a paso.
class GuiaAyuda {
  final String id;
  final String titulo;
  final String resumen;
  final IconData icono;
  final List<PasoAyuda> pasos;

  /// Pantallas donde esta guía se ofrece primero ("En esta pantalla"),
  /// en el orden en que aparecen las guías de cada una.
  final List<PantallaAyuda> pantallas;

  /// Pantalla donde se hace la tarea: el último paso ofrece ir ahí.
  final PantallaAyuda? pantallaDestino;
  final List<RolAyuda> roles;

  const GuiaAyuda({
    required this.id,
    required this.titulo,
    required this.resumen,
    required this.icono,
    required this.pasos,
    required this.pantallas,
    this.pantallaDestino,
    this.roles = const [RolAyuda.admin],
  });
}

/// Todas las guías, en el orden en que se listan en "Otras guías".
final List<GuiaAyuda> todasLasGuias = [
  ...guiasCampeonato,
  ...guiasInscripcion,
  ...guiasCompetencia,
  ...guiasConsultas,
];

/// Las guías que [rol] puede ver.
List<GuiaAyuda> guiasPara(RolAyuda rol) =>
    todasLasGuias.where((guia) => guia.roles.contains(rol)).toList();

/// Las guías de [pantalla] para [rol], en el orden en que se declararon
/// (de la tarea más frecuente a la menos).
List<GuiaAyuda> guiasDe(PantallaAyuda pantalla, RolAyuda rol) =>
    guiasPara(rol).where((guia) => guia.pantallas.contains(pantalla)).toList();
