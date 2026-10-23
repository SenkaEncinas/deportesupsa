// Pasos que se repiten en varias guías: se escriben una sola vez acá.
//
// SI CAMBIA EL TEXTO DE UN BOTÓN EN LA APP, ACTUALIZAR SU GUÍA.

import '../ayuda_modelo.dart';
import 'escenas.dart';

/// Llegar al campeonato desde el panel.
final pasoAbrirCampeonato = PasoAyuda(
  titulo: 'Tocá "Administrar" en el campeonato',
  explicacion:
      'En el "Panel administrativo", cada campeonato en curso tiene su botón '
      '"Administrar". Te lleva al detalle, donde están todos sus módulos.',
  escena: () => escenaPanel(FocoPanel.administrar),
);

/// Abrir un módulo de las secciones Inscripción o Competencia.
PasoAyuda pasoAbrirModulo(String modulo) => PasoAyuda(
  titulo: 'Tocá "$modulo"',
  explicacion:
      'En el detalle del campeonato, bajá hasta "Módulos del campeonato" y '
      'tocá la tarjeta "$modulo".',
  escena: () => escenaDetalle(FocoDetalle.modulo, modulo: modulo),
);

/// Abrir un módulo de las secciones Consulta o Control y documentos.
PasoAyuda pasoAbrirModuloConsulta(String modulo) => PasoAyuda(
  titulo: 'Tocá "$modulo"',
  explicacion:
      'En el detalle del campeonato, al final de "Módulos del campeonato", '
      'tocá la tarjeta "$modulo".',
  escena: () => escenaDetalleConsulta(modulo),
);
