// Guías del panel, el listado de campeonatos, el formulario de nuevo
// campeonato y el detalle de un campeonato.
//
// SI CAMBIA EL TEXTO DE UN BOTÓN EN LA APP, ACTUALIZAR SU GUÍA (y su
// maqueta en escenas.dart).

import 'package:flutter/material.dart';

import '../ayuda_modelo.dart';
import 'escenas.dart';
import 'pasos_comunes.dart';

final guiasCampeonato = <GuiaAyuda>[
  GuiaAyuda(
    id: 'crear-campeonato',
    titulo: 'Crear un campeonato',
    resumen: 'Darlo de alta con su deporte y su formato.',
    icono: Icons.emoji_events_outlined,
    pantallas: const [
      PantallaAyuda.panel,
      PantallaAyuda.campeonatos,
      PantallaAyuda.nuevoCampeonato,
    ],
    pantallaDestino: PantallaAyuda.nuevoCampeonato,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Nuevo campeonato"',
        explicacion:
            'Está en el banner verde del "Panel administrativo". También '
            'aparece arriba en el listado de campeonatos.',
        escena: () => escenaPanel(FocoPanel.nuevo),
      ),
      PasoAyuda(
        titulo: 'Completá "Nombre del campeonato"',
        explicacion:
            'Es el nombre que verá el público. Abajo podés sumar descripción, '
            'temporada y cancha.',
        escena: () => escenaNuevoCampeonato(FocoNuevo.nombre),
      ),
      PasoAyuda(
        titulo: 'Elegí el deporte',
        explicacion:
            'Fútbol / Futsal, Vóley o Básquet. Define cómo se cargan los '
            'resultados (goles, sets o puntos).',
        consejo:
            'El deporte y el formato no se pueden cambiar después: revisalos '
            'antes de guardar.',
        escena: () => escenaNuevoCampeonato(FocoNuevo.deporte),
      ),
      PasoAyuda(
        titulo: 'Elegí el "Formato del campeonato"',
        explicacion:
            'Por ejemplo "Grupos + eliminación": primero grupos y después '
            'llaves. Cada formato muestra los campos que necesita.',
        escena: () => escenaNuevoCampeonato(FocoNuevo.formato),
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar"',
        explicacion:
            'Arriba a la derecha. El campeonato queda en "Inscripción", listo '
            'para cargar equipos y jugadores.',
        escena: () => escenaNuevoCampeonato(FocoNuevo.guardar),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El campeonato aparece en "Campeonatos en curso". Entrá con '
            '"Administrar" para seguir.',
        escena: () => escenaDetalle(FocoDetalle.ninguno, enInscripcion: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'administrar-campeonato',
    titulo: 'Entrar a administrar un campeonato',
    resumen: 'Llegar a sus equipos, fixture y resultados.',
    icono: Icons.settings_outlined,
    pantallas: const [PantallaAyuda.panel, PantallaAyuda.campeonatos],
    pantallaDestino: PantallaAyuda.panel,
    pasos: [
      pasoAbrirCampeonato,
      PasoAyuda(
        titulo: 'Revisá "Pendientes"',
        explicacion:
            'Arriba del detalle están las tareas que faltan, como resultados '
            'atrasados o partidos sin fecha.',
        escena: () => escenaDetalle(FocoDetalle.pendiente),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'Abajo están los módulos ordenados por etapa: Inscripción, '
            'Competencia, Consulta y documentos.',
        escena: () => escenaDetalle(FocoDetalle.modulo, modulo: 'Fixture'),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'ver-publico',
    titulo: 'Ver la página pública de un campeonato',
    resumen: 'Ver lo mismo que ven los alumnos y el público.',
    icono: Icons.visibility_outlined,
    pantallas: const [PantallaAyuda.panel],
    pantallaDestino: PantallaAyuda.panel,
    pasos: [
      PasoAyuda(
        titulo: 'Buscá el campeonato en "Campeonatos en curso"',
        explicacion:
            'Está en el "Panel administrativo", debajo de los números.',
        escena: () => escenaPanel(FocoPanel.ninguno),
      ),
      PasoAyuda(
        titulo: 'Tocá "Ver público"',
        explicacion:
            'Al lado de "Administrar". Abre la página pública sin cerrar tu '
            'sesión.',
        escena: () => escenaPanel(FocoPanel.verPublico),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'Ves la página tal como la ve el público. Con la flecha de volver '
            'regresás al panel.',
        escena: () => escenaPublica(),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'buscar-finalizado',
    titulo: 'Encontrar un campeonato finalizado',
    resumen: 'Los finalizados no están en el panel: están en el listado.',
    icono: Icons.manage_search_rounded,
    pantallas: const [PantallaAyuda.panel, PantallaAyuda.campeonatos],
    pantallaDestino: PantallaAyuda.campeonatos,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Ver todos los campeonatos"',
        explicacion: 'Está en el banner verde del "Panel administrativo".',
        escena: () => escenaPanel(FocoPanel.verTodos),
      ),
      PasoAyuda(
        titulo: 'Tocá el filtro "Finalizado"',
        explicacion:
            'En "Buscar campeonato". En el celular la fila de filtros se '
            'desliza hacia el costado.',
        escena: () => escenaListaCampeonatos(FocoLista.finalizado),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'Quedan solo los finalizados. También podés escribir el nombre en '
            'el buscador.',
        escena: () => escenaListaCampeonatos(FocoLista.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'cerrar-sesion',
    titulo: 'Cerrar sesión',
    resumen: 'Salir de la cuenta de administrador.',
    icono: Icons.logout,
    pantallas: const [PantallaAyuda.panel],
    pantallaDestino: PantallaAyuda.panel,
    pasos: [
      PasoAyuda(
        titulo: 'Volvé al "Panel administrativo"',
        explicacion:
            'Con la flecha de volver de cada pantalla llegás al panel, que es '
            'la primera pantalla del admin.',
        escena: () => escenaPanel(FocoPanel.ninguno),
      ),
      PasoAyuda(
        titulo: 'Tocá "Cerrar sesión"',
        explicacion:
            'Arriba a la derecha. En el celular el botón dice "Salir".',
        escena: () => escenaPanel(FocoPanel.salir),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'Volvés a la página pública. Para entrar de nuevo usá "Ingresar '
            'admin".',
        escena: () => escenaPublica(),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'editar-datos-campeonato',
    titulo: 'Corregir el nombre o la cancha de un campeonato',
    resumen: 'Cambiar nombre, descripción, temporada o cancha.',
    icono: Icons.edit_outlined,
    pantallas: const [PantallaAyuda.detalleCampeonato],
    pantallaDestino: PantallaAyuda.detalleCampeonato,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Editar datos"',
        explicacion:
            'Arriba del detalle del campeonato. En el celular el botón dice '
            '"Editar".',
        escena: () => escenaDetalle(FocoDetalle.editar),
      ),
      PasoAyuda(
        titulo: 'Corregí "Nombre"',
        explicacion: 'También podés cambiar descripción, temporada y cancha.',
        consejo:
            'El formato y el deporte no se pueden cambiar una vez creado el '
            'campeonato.',
        escena: () => escenaEditarCampeonato(focoNombre: true),
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar"',
        explicacion: 'El cambio queda registrado en la auditoría.',
        escena: () => escenaEditarCampeonato(focoGuardar: true),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El nombre nuevo se ve enseguida en el panel y en la '
            'página pública.',
        escena: () => escenaPublica(),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'activar-campeonato',
    titulo: 'Activar un campeonato',
    resumen: 'Pasar de inscripción a competencia.',
    icono: Icons.play_arrow_rounded,
    pantallas: const [PantallaAyuda.detalleCampeonato],
    pantallaDestino: PantallaAyuda.detalleCampeonato,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Activar campeonato"',
        explicacion:
            'Aparece arriba del detalle mientras el campeonato está en '
            '"Inscripción". En el celular dice "Activar".',
        consejo:
            'Se valida que haya equipos activos con la cantidad mínima de '
            'jugadores. Si falta algo, te avisa qué.',
        escena: () => escenaDetalle(FocoDetalle.activar, enInscripcion: true),
      ),
      PasoAyuda(
        titulo: 'Confirmá con "Activar"',
        explicacion: 'El fixture y las fechas se pueden armar después.',
        escena: () => escenaConfirmar(
          fondo: (d) => escenaDetalle(
            FocoDetalle.ninguno,
            enInscripcion: true,
            superpuesto: d,
          ),
          titulo: 'Activar campeonato',
          mensaje: 'Se validarán los equipos y sus jugadores.',
          boton: 'Activar',
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El campeonato pasa a "Activo" y ya se pueden cargar resultados.',
        escena: () => escenaDetalle(FocoDetalle.estadoActivo),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'resolver-pendientes',
    titulo: 'Ponerse al día con los pendientes',
    resumen: 'Ir directo a lo que falta: resultados o fechas.',
    icono: Icons.task_alt_rounded,
    pantallas: const [PantallaAyuda.detalleCampeonato],
    pantallaDestino: PantallaAyuda.detalleCampeonato,
    pasos: [
      PasoAyuda(
        titulo: 'Mirá el recuadro "Pendientes"',
        explicacion:
            'Arriba del detalle del campeonato. Lo urgente se marca en '
            'naranja.',
        escena: () => escenaDetalle(FocoDetalle.ninguno),
      ),
      PasoAyuda(
        titulo: 'Tocá el pendiente',
        explicacion:
            'Por ejemplo "3 partidos ya se jugaron y no tienen resultado." te '
            'lleva directo a Resultados.',
        escena: () => escenaDetalle(FocoDetalle.pendiente),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'En Resultados se abre el filtro "Por cargar" con los partidos que '
            'faltan.',
        escena: () => escenaResultados(FocoResultados.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'finalizar-campeonato',
    titulo: 'Finalizar un campeonato',
    resumen: 'Cerrarlo cuando se jugó la final.',
    icono: Icons.flag_outlined,
    pantallas: const [PantallaAyuda.detalleCampeonato],
    pantallaDestino: PantallaAyuda.detalleCampeonato,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Finalizar campeonato"',
        explicacion:
            'Arriba del detalle, en rojo. En el celular el botón dice '
            '"Finalizar".',
        escena: () => escenaDetalle(FocoDetalle.finalizar),
      ),
      PasoAyuda(
        titulo: 'Confirmá con "Finalizar"',
        explicacion:
            'Después ya no se cargan resultados ni se cambian equipos.',
        consejo:
            'No se puede deshacer. Hacelo recién cuando estén cargados todos '
            'los resultados.',
        escena: () => escenaConfirmar(
          fondo: (d) => escenaDetalle(FocoDetalle.ninguno, superpuesto: d),
          titulo: 'Finalizar campeonato',
          mensaje: 'Ya no se deberían hacer cambios normales.',
          boton: 'Finalizar',
          peligro: true,
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El campeonato queda "Finalizado". Se encuentra con el filtro '
            '"Finalizado" del listado.',
        escena: () => escenaDetalle(FocoDetalle.estadoFinalizado),
      ),
    ],
  ),
];
