// Guías de inscripción: equipos, jugadores y grupos.
//
// SI CAMBIA EL TEXTO DE UN BOTÓN EN LA APP, ACTUALIZAR SU GUÍA (y su
// maqueta en escenas.dart).

import 'package:flutter/material.dart';

import '../ayuda_modelo.dart';
import 'escenas.dart';
import 'pasos_comunes.dart';

final guiasInscripcion = <GuiaAyuda>[
  // ----------------------------------------------------------- Equipos
  GuiaAyuda(
    id: 'registrar-equipo',
    titulo: 'Registrar un equipo',
    resumen: 'Sumar un equipo con su representante.',
    icono: Icons.group_add_outlined,
    pantallas: const [
      PantallaAyuda.equipos,
      PantallaAyuda.equipoForm,
      PantallaAyuda.detalleCampeonato,
    ],
    pantallaDestino: PantallaAyuda.equipos,
    pasos: [
      pasoAbrirModulo('Equipos'),
      PasoAyuda(
        titulo: 'Tocá "Nuevo equipo"',
        explicacion: 'Arriba a la derecha de la pantalla de equipos.',
        escena: () => escenaEquipos(FocoEquipos.nuevo),
      ),
      PasoAyuda(
        titulo: 'Completá "Nombre del equipo"',
        explicacion:
            'Y también "Representante". Carrera y facultad son opcionales.',
        escena: () => escenaEquipoForm(FocoEquipoForm.nombre),
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar"',
        explicacion: 'Arriba a la derecha del formulario.',
        escena: () => escenaEquipoForm(FocoEquipoForm.guardar),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El equipo aparece en la lista. Ahora cargale sus jugadores en '
            '"Jugadores".',
        escena: () =>
            escenaEquipos(FocoEquipos.ninguno, listo: true, sinCivil: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'editar-equipo',
    titulo: 'Cambiar el nombre o el estado de un equipo',
    resumen: 'Corregir el nombre o marcarlo retirado.',
    icono: Icons.edit_note_rounded,
    pantallas: const [PantallaAyuda.equipos, PantallaAyuda.equipoForm],
    pantallaDestino: PantallaAyuda.equipos,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá la tarjeta del equipo',
        explicacion: 'En la pantalla "Equipos". Se abre "Editar equipo".',
        escena: () => escenaEquipos(FocoEquipos.tarjeta),
      ),
      PasoAyuda(
        titulo: 'Cambiá el nombre o el "Estado del equipo"',
        explicacion:
            'Si el equipo dejó de participar, elegí "Retirado" en vez de '
            'borrarlo.',
        escena: () => escenaEquipoForm(FocoEquipoForm.estado, editando: true),
      ),
      PasoAyuda(
        titulo: 'Escribí la "Observación obligatoria"',
        explicacion: 'Queda en el historial del equipo y en la auditoría.',
        escena: () =>
            escenaEquipoForm(FocoEquipoForm.observacion, editando: true),
      ),
      PasoAyuda(
        titulo: 'Tocá "Actualizar"',
        explicacion:
            'El nombre nuevo se copia solo al fixture, la tabla y los PDF.',
        escena: () => escenaEquipoForm(FocoEquipoForm.guardar, editando: true),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'La tarjeta del equipo ya muestra el cambio.',
        escena: () => escenaEquipos(FocoEquipos.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'eliminar-equipo',
    titulo: 'Eliminar un equipo cargado por error',
    resumen: 'Borrarlo junto con sus jugadores.',
    icono: Icons.delete_outline,
    pantallas: const [PantallaAyuda.equipos],
    pantallaDestino: PantallaAyuda.equipos,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá el tacho de la tarjeta',
        explicacion:
            'Arriba a la derecha de la tarjeta del equipo (dice "Eliminar '
            'equipo" al dejarlo apretado o pasar el mouse).',
        consejo:
            'Solo se puede si el equipo todavía no está en el fixture. Si ya '
            'jugó, marcalo "Retirado".',
        escena: () => escenaEquipos(FocoEquipos.eliminar),
      ),
      PasoAyuda(
        titulo: 'Confirmá con "Eliminar"',
        explicacion: 'Se borran el equipo y sus jugadores.',
        consejo: 'No se puede deshacer.',
        escena: () => escenaConfirmar(
          fondo: (d) => escenaEquipos(FocoEquipos.ninguno, superpuesto: d),
          titulo: 'Eliminar equipo',
          mensaje: '¿Eliminar a "ING. CIVIL" y a sus 12 jugadores?',
          boton: 'Eliminar',
          peligro: true,
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'El equipo ya no aparece en la lista ni en sus grupos.',
        escena: () =>
            escenaEquipos(FocoEquipos.ninguno, listo: true, sinCivil: true),
      ),
    ],
  ),

  // --------------------------------------------------------- Jugadores
  GuiaAyuda(
    id: 'registrar-jugadores',
    titulo: 'Registrar jugadores',
    resumen: 'Cargar la lista de un equipo.',
    icono: Icons.person_add_alt_1_outlined,
    pantallas: const [
      PantallaAyuda.jugadores,
      PantallaAyuda.jugadorForm,
      PantallaAyuda.detalleCampeonato,
    ],
    pantallaDestino: PantallaAyuda.jugadores,
    pasos: [
      pasoAbrirModulo('Jugadores'),
      PasoAyuda(
        titulo: 'Tocá "Nuevo jugador"',
        explicacion: 'Arriba a la derecha de la pantalla de jugadores.',
        escena: () => escenaJugadores(FocoJugadores.nuevo),
      ),
      PasoAyuda(
        titulo: 'Elegí el "Equipo"',
        explicacion: 'Todos los jugadores que cargues van a ese equipo.',
        escena: () => escenaJugadorForm(FocoJugadorForm.equipo),
      ),
      PasoAyuda(
        titulo: 'Completá "Número de registro" y "Nombre completo"',
        explicacion:
            'Una fila por jugador. Se agregan filas a medida que '
            'escribís.',
        escena: () => escenaJugadorForm(FocoJugadorForm.datos),
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar jugadores"',
        explicacion: 'Arriba a la derecha. Se guardan todos juntos.',
        escena: () => escenaJugadorForm(FocoJugadorForm.guardar),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Los jugadores aparecen en la lista con su equipo.',
        escena: () => escenaJugadores(FocoJugadores.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'pegar-excel',
    titulo: 'Cargar jugadores pegando desde Excel',
    resumen: 'Pasar una lista entera de una sola vez.',
    icono: Icons.content_paste_rounded,
    pantallas: const [PantallaAyuda.jugadores, PantallaAyuda.jugadorForm],
    pantallaDestino: PantallaAyuda.jugadores,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Nuevo jugador"',
        explicacion: 'En la pantalla "Jugadores", arriba a la derecha.',
        escena: () => escenaJugadores(FocoJugadores.nuevo),
      ),
      PasoAyuda(
        titulo: 'Tocá "Pegar desde Excel"',
        explicacion: 'Antes elegí el "Equipo" de esos jugadores.',
        escena: () => escenaJugadorForm(FocoJugadorForm.excel),
      ),
      PasoAyuda(
        titulo: 'Pegá las filas y tocá "Rellenar lista"',
        explicacion:
            'Copiá en Excel las columnas de número y nombre, pegalas en el '
            'cuadro y se arma una fila por jugador.',
        escena: escenaPegarExcel,
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar jugadores"',
        explicacion: 'Revisá la lista antes: cada fila se puede corregir.',
        escena: () => escenaJugadorForm(FocoJugadorForm.guardar),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Todos los jugadores quedan cargados en su equipo.',
        escena: () => escenaJugadores(FocoJugadores.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'editar-jugador',
    titulo: 'Corregir los datos de un jugador',
    resumen: 'Cambiar su número, nombre o estado.',
    icono: Icons.manage_accounts_outlined,
    pantallas: const [PantallaAyuda.jugadores, PantallaAyuda.jugadorForm],
    pantallaDestino: PantallaAyuda.jugadores,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Editar" en el jugador',
        explicacion:
            'En la lista de "Jugadores". En el celular, tocá la tarjeta del '
            'jugador.',
        escena: () => escenaJugadores(FocoJugadores.editar),
      ),
      PasoAyuda(
        titulo: 'Cambiá los datos o el "Estado"',
        explicacion:
            'Si un jugador ya no juega, elegí "Retirado" o "Suspendido".',
        escena: () => escenaJugadorForm(FocoJugadorForm.estado, editando: true),
      ),
      PasoAyuda(
        titulo: 'Escribí la "Observación obligatoria"',
        explicacion: 'Queda guardada en el historial del jugador.',
        escena: () =>
            escenaJugadorForm(FocoJugadorForm.observacion, editando: true),
      ),
      PasoAyuda(
        titulo: 'Tocá "Actualizar"',
        explicacion: 'Arriba a la derecha.',
        escena: () =>
            escenaJugadorForm(FocoJugadorForm.guardar, editando: true),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'La lista muestra el dato corregido.',
        escena: () => escenaJugadores(FocoJugadores.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'eliminar-jugador',
    titulo: 'Eliminar un jugador cargado por error',
    resumen: 'Solo mientras el campeonato está en inscripción.',
    icono: Icons.person_remove_outlined,
    pantallas: const [PantallaAyuda.jugadores],
    pantallaDestino: PantallaAyuda.jugadores,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Eliminar" en el jugador',
        explicacion: 'En la lista de "Jugadores".',
        consejo:
            'Con el campeonato activo no se puede: cambiá su "Estado" a '
            '"Retirado".',
        escena: () => escenaJugadores(FocoJugadores.eliminar),
      ),
      PasoAyuda(
        titulo: 'Confirmá con "Eliminar"',
        explicacion: 'No se puede deshacer.',
        escena: () => escenaConfirmar(
          fondo: (d) => escenaJugadores(FocoJugadores.ninguno, superpuesto: d),
          titulo: 'Eliminar jugador',
          mensaje: '¿Eliminar a "Carlos Méndez" (219034512)?',
          boton: 'Eliminar',
          peligro: true,
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'El jugador ya no figura en su equipo.',
        escena: () => escenaJugadores(FocoJugadores.ninguno),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'historial-jugador',
    titulo: 'Ver los cambios de un jugador',
    resumen: 'Quién lo cargó o editó, y cuándo.',
    icono: Icons.history,
    pantallas: const [PantallaAyuda.jugadores],
    pantallaDestino: PantallaAyuda.jugadores,
    pasos: [
      pasoAbrirModulo('Jugadores'),
      PasoAyuda(
        titulo: 'Tocá "Historial" en el jugador',
        explicacion: 'En la lista de "Jugadores", al lado de "Editar".',
        escena: () => escenaJugadores(FocoJugadores.historial),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'Ves cada cambio con su fecha y la observación que se escribió.',
        escena: escenaHistorialJugador,
      ),
    ],
  ),

  // ------------------------------------------------------------ Grupos
  GuiaAyuda(
    id: 'armar-grupos',
    titulo: 'Armar los grupos',
    resumen: 'Repartir los equipos en grupos de forma automática.',
    icono: Icons.grid_view_rounded,
    pantallas: const [PantallaAyuda.grupos, PantallaAyuda.detalleCampeonato],
    pantallaDestino: PantallaAyuda.grupos,
    pasos: [
      pasoAbrirModulo('Grupos'),
      PasoAyuda(
        titulo: 'Tocá "Generar grupos automáticamente"',
        explicacion:
            'Reparte los equipos activos en la cantidad de grupos del '
            'campeonato. Si preferís, usá "Armar manualmente".',
        escena: () => escenaGrupos(FocoGrupos.generar, vacio: true),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'Cada grupo muestra sus equipos. Podés moverlos antes de generar '
            'el fixture.',
        escena: () => escenaGrupos(FocoGrupos.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'mover-equipo-grupo',
    titulo: 'Pasar un equipo a otro grupo',
    resumen: 'Corregir en qué grupo quedó un equipo.',
    icono: Icons.compare_arrows_rounded,
    pantallas: const [PantallaAyuda.grupos],
    pantallaDestino: PantallaAyuda.grupos,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá las flechas del equipo',
        explicacion:
            'En la tarjeta de su grupo, al lado del nombre (dice "Mover a '
            'otro grupo").',
        consejo: 'Solo se puede mientras no haya fixture generado.',
        escena: () => escenaGrupos(FocoGrupos.mover),
      ),
      PasoAyuda(
        titulo: 'Elegí el grupo nuevo',
        explicacion:
            'Se abre la lista de grupos con cuántos equipos tiene '
            'cada uno.',
        escena: () =>
            escenaGrupos(FocoGrupos.ninguno, superpuesto: const _ListaGrupos()),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'El equipo ya figura en su grupo nuevo.',
        escena: () => escenaGrupos(FocoGrupos.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'quitar-equipo-grupo',
    titulo: 'Sacar un equipo de su grupo',
    resumen: 'Dejarlo sin grupo para inscribirlo de nuevo.',
    icono: Icons.person_remove_outlined,
    pantallas: const [PantallaAyuda.grupos],
    pantallaDestino: PantallaAyuda.grupos,
    pasos: [
      pasoAbrirModulo('Grupos'),
      PasoAyuda(
        titulo: 'Tocá el ícono rojo del equipo',
        explicacion:
            'Al lado del nombre, en la tarjeta de su grupo (dice "Quitar del '
            'grupo").',
        escena: () => escenaGrupos(FocoGrupos.quitar),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El equipo pasa a "sin grupo": inscribilo donde corresponda.',
        escena: () => escenaGrupos(FocoGrupos.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'editar-clasificacion',
    titulo: 'Cambiar cuántos clasifican por grupo',
    resumen: 'Ajustar clasificados y mejores terceros.',
    icono: Icons.tune,
    pantallas: const [PantallaAyuda.grupos],
    pantallaDestino: PantallaAyuda.grupos,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Editar clasificación"',
        explicacion: 'Arriba a la derecha de la pantalla de grupos.',
        escena: () => escenaGrupos(FocoGrupos.clasificacion),
      ),
      PasoAyuda(
        titulo: 'Elegí los clasificados y tocá "Guardar"',
        explicacion:
            'Cuántos pasan por grupo y cuántos mejores terceros. El total '
            'define la ronda inicial del cuadro.',
        escena: () => escenaGrupos(
          FocoGrupos.ninguno,
          superpuesto: const _ClasificacionDialogo(),
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'La lista de "Clasificados a la fase final" se recalcula en vivo.',
        escena: () => escenaGrupos(FocoGrupos.ninguno, listo: true),
      ),
    ],
  ),
];

class _ListaGrupos extends StatelessWidget {
  const _ListaGrupos();

  @override
  Widget build(BuildContext context) {
    return escenaDialogoLista('Inscribir a ING. CIVIL', const [
      'Grupo A · 3 equipos',
      'Grupo B · 2 equipos',
    ], senalar: 1);
  }
}

class _ClasificacionDialogo extends StatelessWidget {
  const _ClasificacionDialogo();

  @override
  Widget build(BuildContext context) => escenaDialogoClasificacion();
}
