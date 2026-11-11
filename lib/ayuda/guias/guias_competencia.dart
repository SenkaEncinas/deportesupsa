// Guías de competencia: fixture, resultados, llaves e igualación.
//
// SI CAMBIA EL TEXTO DE UN BOTÓN EN LA APP, ACTUALIZAR SU GUÍA (y su
// maqueta en escenas.dart).

import 'package:flutter/material.dart';

import '../ayuda_modelo.dart';
import 'escenas.dart';
import 'pasos_comunes.dart';

final _pasoAbrirCargar = PasoAyuda(
  titulo: 'Tocá "Cargar resultado"',
  explicacion:
      'En "Resultados", filtro "Por cargar". Cada partido tiene su botón a '
      'la derecha.',
  escena: () => escenaResultados(FocoResultados.cargar),
);

final _pasoGuardarResultado = PasoAyuda(
  titulo: 'Tocá "Guardar resultado"',
  explicacion:
      'Arriba a la derecha. La tabla, el ranking y el cuadro se actualizan '
      'solos.',
  escena: () => escenaCargarResultado(FocoCarga.guardar),
);

final guiasCompetencia = <GuiaAyuda>[
  // ----------------------------------------------------------- Fixture
  GuiaAyuda(
    id: 'generar-fixture',
    titulo: 'Generar el fixture',
    resumen: 'Crear todos los partidos según el formato.',
    icono: Icons.calendar_month_outlined,
    pantallas: const [PantallaAyuda.fixture, PantallaAyuda.detalleCampeonato],
    pantallaDestino: PantallaAyuda.fixture,
    pasos: [
      pasoAbrirModulo('Fixture'),
      PasoAyuda(
        titulo: 'Tocá "Generar fixture"',
        explicacion:
            'Arriba a la derecha. En los formatos con grupos, primero armá los '
            'grupos en "Grupos".',
        escena: () => escenaFixture(FocoFixture.generar, vacio: true),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'Se crean todos los partidos "Sin programar". Ahora poneles fecha '
            'y hora.',
        escena: () => escenaFixture(FocoFixture.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'programar-partido',
    titulo: 'Programar un partido',
    resumen: 'Ponerle día y hora a un partido.',
    icono: Icons.edit_calendar_outlined,
    pantallas: const [PantallaAyuda.fixture],
    pantallaDestino: PantallaAyuda.fixture,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Programar" en el partido',
        explicacion:
            'En el fixture, a la derecha de cada partido. Si ya tiene fecha '
            'dice "Reprogramar".',
        escena: () => escenaFixture(FocoFixture.programar),
      ),
      PasoAyuda(
        titulo: 'Elegí el día y tocá "Aceptar"',
        explicacion: 'Se abre el calendario "Seleccionar fecha".',
        escena: escenaCalendario,
      ),
      PasoAyuda(
        titulo: 'Elegí la hora y tocá "Aceptar"',
        explicacion: 'Primero la hora y después los minutos.',
        consejo:
            'No se pueden programar dos partidos exactamente a la misma fecha '
            'y hora.',
        escena: escenaReloj,
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El partido queda "Programado" y aparece en "Próximos partidos" de '
            'la página pública.',
        escena: () =>
            escenaFixture(FocoFixture.ninguno, listo: true, programado: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'cruce-manual',
    titulo: 'Agregar un partido a mano',
    resumen: 'Crear un cruce que el fixture no generó.',
    icono: Icons.add_circle_outline,
    pantallas: const [PantallaAyuda.fixture],
    pantallaDestino: PantallaAyuda.fixture,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Agregar cruce manual"',
        explicacion: 'Arriba del listado de partidos del fixture.',
        consejo: 'En fase de grupos solo deja cruzar equipos del mismo grupo.',
        escena: () => escenaFixture(FocoFixture.cruce),
      ),
      PasoAyuda(
        titulo: 'Elegí "Equipo local" y "Equipo visitante"',
        explicacion: 'Las dos listas muestran los equipos activos.',
        escena: () => escenaCruceManual(focoEquipos: true),
      ),
      PasoAyuda(
        titulo: 'Tocá "Crear cruce"',
        explicacion: 'El partido se suma al fixture "Sin programar".',
        escena: () => escenaCruceManual(focoCrear: true),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Ahora programalo con "Programar".',
        escena: () => escenaFixture(FocoFixture.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'activar-eliminatoria',
    titulo: 'Pasar a la fase eliminatoria',
    resumen: 'Cerrar los grupos y empezar las llaves.',
    icono: Icons.bolt_outlined,
    pantallas: const [PantallaAyuda.fixture, PantallaAyuda.llaves],
    pantallaDestino: PantallaAyuda.fixture,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Activar fase eliminatoria"',
        explicacion:
            'Arriba del fixture. Aparece mientras el campeonato está en fase '
            'de grupos o de liga.',
        consejo:
            '¿No aparece? Si el campeonato se creó como "Fase de grupos" '
            '(solo grupos), primero tocá "Agregar fase eliminatoria" y elegí '
            'cuántos pasan por grupo.',
        escena: () => escenaFixture(FocoFixture.activar),
      ),
      PasoAyuda(
        titulo: 'Confirmá con "Activar"',
        explicacion: 'Después se abre "Llaves" para generar el cuadro.',
        consejo:
            'No se puede deshacer. Generar las llaves también activa esta '
            'fase.',
        escena: () => escenaConfirmar(
          fondo: (d) => escenaFixture(FocoFixture.ninguno, superpuesto: d),
          titulo: 'Activar fase eliminatoria',
          mensaje:
              'Da por terminada la fase de grupos y pasa a la eliminatoria.',
          boton: 'Activar',
          peligro: true,
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Generá el cuadro desde "Llaves" con "Generar llaves".',
        escena: () => escenaLlaves(FocoLlaves.generar, vacio: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'borrar-fixture',
    titulo: 'Borrar el fixture para rehacerlo',
    resumen: 'Si se generó mal y todavía no se jugó nada.',
    icono: Icons.delete_sweep_outlined,
    pantallas: const [PantallaAyuda.fixture],
    pantallaDestino: PantallaAyuda.fixture,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá "Borrar fixture"',
        explicacion:
            'Arriba del listado, en rojo. Solo aparece si ningún partido tiene '
            'resultado.',
        escena: () => escenaFixture(FocoFixture.borrar),
      ),
      PasoAyuda(
        titulo: 'Confirmá con "Borrar"',
        explicacion: 'Se borran todos los partidos.',
        consejo: 'Las fechas que ya habías programado se pierden.',
        escena: () => escenaConfirmar(
          fondo: (d) => escenaFixture(FocoFixture.ninguno, superpuesto: d),
          titulo: 'Borrar fixture',
          mensaje: 'Se borran los 16 partidos para poder generarlo de nuevo.',
          boton: 'Borrar',
          peligro: true,
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Corregí lo que haga falta y tocá "Generar fixture".',
        escena: () => escenaFixture(FocoFixture.generar, vacio: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'descargar-fixture',
    titulo: 'Descargar el fixture en PDF',
    resumen: 'Tener el fixture para imprimir o compartir.',
    icono: Icons.picture_as_pdf_outlined,
    pantallas: const [PantallaAyuda.fixture],
    pantallaDestino: PantallaAyuda.fixture,
    pasos: [
      pasoAbrirModulo('Fixture'),
      PasoAyuda(
        titulo: 'Tocá "Descargar PDF"',
        explicacion: 'Arriba del listado de partidos.',
        escena: () => escenaFixture(FocoFixture.pdf),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'Se descarga el PDF con todos los partidos y sus fechas.',
        escena: () => escenaPdfListo('Fixture', 'fixture_intercarreras.pdf'),
      ),
    ],
  ),

  // -------------------------------------------------------- Resultados
  GuiaAyuda(
    id: 'cargar-resultado',
    titulo: 'Cargar el resultado de un partido',
    resumen: 'Marcador y goleadores de un partido de fútbol.',
    icono: Icons.add_task_rounded,
    pantallas: const [
      PantallaAyuda.resultados,
      PantallaAyuda.resultadoForm,
      PantallaAyuda.detalleCampeonato,
    ],
    pantallaDestino: PantallaAyuda.resultados,
    pasos: [
      pasoAbrirModulo('Resultados'),
      _pasoAbrirCargar,
      PasoAyuda(
        titulo: 'Escribí el marcador',
        explicacion: 'Los goles de cada equipo, debajo de su nombre.',
        escena: () => escenaCargarResultado(FocoCarga.marcador),
      ),
      PasoAyuda(
        titulo: 'Tocá "Agregar gol" y elegí el jugador',
        explicacion:
            'Uno por goleador, con su cantidad. La suma tiene que coincidir '
            'con el marcador.',
        escena: () => escenaCargarResultado(FocoCarga.agregarGol),
      ),
      _pasoGuardarResultado,
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El partido pasa a "Con resultado" y la tabla se actualiza al '
            'instante.',
        escena: () => escenaResultados(
          FocoResultados.ninguno,
          listo: true,
          mostrarJugado: true,
        ),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'cargar-resultado-voley',
    titulo: 'Cargar un resultado de vóley',
    resumen: 'Los puntos de cada set.',
    icono: Icons.sports_volleyball_outlined,
    pantallas: const [PantallaAyuda.resultados, PantallaAyuda.resultadoForm],
    pantallaDestino: PantallaAyuda.resultados,
    pasos: [
      _pasoAbrirCargar,
      PasoAyuda(
        titulo: 'Tocá "Agregar set"',
        explicacion: 'Uno por cada set jugado.',
        escena: () => escenaCargarResultado(
          FocoCarga.agregarGol,
          variante: VarianteCarga.voley,
        ),
      ),
      PasoAyuda(
        titulo: 'Escribí los puntos de cada set',
        explicacion: 'Local y visitante. El marcador en sets se calcula solo.',
        consejo: 'Un set no puede terminar empatado.',
        escena: () => escenaCargarResultado(
          FocoCarga.sets,
          variante: VarianteCarga.voley,
        ),
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar resultado"',
        explicacion: 'Arriba a la derecha.',
        escena: () => escenaCargarResultado(
          FocoCarga.guardar,
          variante: VarianteCarga.voley,
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'La tabla cuenta sets y puntos para el desempate.',
        escena: () => escenaResultados(
          FocoResultados.ninguno,
          listo: true,
          mostrarJugado: true,
        ),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'cargar-penales',
    titulo: 'Cargar un empate de fase final con penales',
    resumen: 'Definir quién avanza en una llave empatada.',
    icono: Icons.sports_soccer,
    pantallas: const [PantallaAyuda.resultados, PantallaAyuda.resultadoForm],
    pantallaDestino: PantallaAyuda.resultados,
    pasos: [
      _pasoAbrirCargar,
      PasoAyuda(
        titulo: 'Escribí el marcador empatado',
        explicacion:
            'En un cruce de la fase final, al empatar aparecen los campos de '
            'penales.',
        consejo:
            'En la fase de grupos o de liga no hay penales: el empate vale 1 '
            'punto.',
        escena: () => escenaCargarResultado(
          FocoCarga.marcador,
          variante: VarianteCarga.penales,
        ),
      ),
      PasoAyuda(
        titulo: 'Completá los penales de cada equipo',
        explicacion: 'Los dos campos son obligatorios y no pueden empatar.',
        escena: () => escenaCargarResultado(
          FocoCarga.penales,
          variante: VarianteCarga.penales,
        ),
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar resultado"',
        explicacion:
            'El ganador por penales pasa solo a la ronda siguiente del cuadro.',
        escena: () => escenaCargarResultado(
          FocoCarga.guardar,
          variante: VarianteCarga.penales,
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'El cuadro público muestra los penales entre paréntesis.',
        escena: () => escenaPublica(cuadro: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'cargar-walkover',
    titulo: 'Cargar un walkover (equipo que no se presentó)',
    resumen: 'Darle el partido a quien sí se presentó.',
    icono: Icons.no_accounts_outlined,
    pantallas: const [PantallaAyuda.resultados, PantallaAyuda.resultadoForm],
    pantallaDestino: PantallaAyuda.resultados,
    pasos: [
      _pasoAbrirCargar,
      PasoAyuda(
        titulo: 'Elegí "Walkover" en "Tipo de resultado"',
        explicacion: 'Es la primera lista del formulario.',
        escena: () => escenaCargarResultado(
          FocoCarga.tipo,
          variante: VarianteCarga.walkover,
        ),
      ),
      PasoAyuda(
        titulo: 'Escribí la "Observación obligatoria"',
        explicacion:
            'Qué pasó. El marcador lo fija el reglamento, no hay que '
            'escribirlo.',
        escena: () => escenaCargarResultado(
          FocoCarga.observacion,
          variante: VarianteCarga.walkover,
        ),
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar resultado"',
        explicacion: 'Arriba a la derecha.',
        escena: () => escenaCargarResultado(
          FocoCarga.guardar,
          variante: VarianteCarga.walkover,
        ),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'El partido queda con la etiqueta "Walkover".',
        escena: () => escenaResultados(
          FocoResultados.ninguno,
          listo: true,
          mostrarJugado: true,
        ),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'editar-resultado',
    titulo: 'Corregir un resultado',
    resumen: 'Cambiar un marcador o goleador mal cargado.',
    icono: Icons.edit_outlined,
    pantallas: const [PantallaAyuda.resultados, PantallaAyuda.resultadoForm],
    pantallaDestino: PantallaAyuda.resultados,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá el filtro "Con resultado"',
        explicacion: 'Arriba de la lista de "Resultados".',
        escena: () => escenaResultados(FocoResultados.conResultado),
      ),
      PasoAyuda(
        titulo: 'Tocá "Editar" en el partido',
        explicacion: 'Se abre el formulario con lo que ya estaba cargado.',
        escena: () => escenaResultados(FocoResultados.editar),
      ),
      PasoAyuda(
        titulo: 'Corregí el marcador',
        explicacion: 'Y los goleadores, si cambiaron.',
        escena: () => escenaCargarResultado(FocoCarga.marcador),
      ),
      _pasoGuardarResultado,
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'La tabla y el ranking se recalculan con el cambio.',
        escena: () => escenaResultados(
          FocoResultados.ninguno,
          listo: true,
          mostrarJugado: true,
        ),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'anular-resultado',
    titulo: 'Anular un resultado cargado por error',
    resumen: 'Dejar el partido otra vez sin jugar.',
    icono: Icons.undo_rounded,
    pantallas: const [PantallaAyuda.resultados],
    pantallaDestino: PantallaAyuda.resultados,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá el filtro "Con resultado"',
        explicacion: 'Arriba de la lista de "Resultados".',
        escena: () => escenaResultados(FocoResultados.conResultado),
      ),
      PasoAyuda(
        titulo: 'Tocá la flecha roja del partido',
        explicacion:
            'A la izquierda de "Editar" (dice "Anular resultado" al dejarlo '
            'apretado o pasar el mouse).',
        consejo:
            'En las llaves, si el ganador ya jugó la ronda siguiente, anulá '
            'primero ese partido.',
        escena: () => escenaResultados(FocoResultados.anular),
      ),
      PasoAyuda(
        titulo: 'Escribí el motivo y tocá "Anular"',
        explicacion:
            'Se borran sus goles y tarjetas, y queda registrado en la '
            'auditoría.',
        escena: escenaAnular,
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El partido vuelve a "Por cargar" y la tabla se recalcula.',
        escena: () => escenaResultados(FocoResultados.ninguno, listo: true),
      ),
    ],
  ),

  // ------------------------------------------------------------ Llaves
  GuiaAyuda(
    id: 'generar-llaves',
    titulo: 'Generar las llaves',
    resumen: 'Armar el cuadro con los clasificados.',
    icono: Icons.account_tree_outlined,
    pantallas: const [PantallaAyuda.llaves, PantallaAyuda.detalleCampeonato],
    pantallaDestino: PantallaAyuda.llaves,
    pasos: [
      pasoAbrirModulo('Llaves'),
      PasoAyuda(
        titulo: 'Tocá "Generar llaves"',
        explicacion:
            'Arriba a la derecha. Si ya hay un cuadro, el botón dice '
            '"Regenerar llaves".',
        escena: () => escenaLlaves(FocoLlaves.generar, vacio: true),
      ),
      PasoAyuda(
        titulo: 'Elegí "Arrancar el cuadro en"',
        explicacion:
            'Con "Automático" se deduce de los clasificados. Elegí una ronda '
            'si el cuadro no cuadra (por ejemplo, 12 equipos).',
        escena: () => escenaGenerarLlaves(focoRonda: true),
      ),
      PasoAyuda(
        titulo: 'Tocá "Generar"',
        explicacion:
            'Si el campeonato seguía en fase de grupos, pasa a la fase '
            'eliminatoria.',
        consejo:
            'Las llaves que ya tienen resultado no se tocan. Para rehacerlas, '
            'anulá esos resultados.',
        escena: () => escenaGenerarLlaves(focoGenerar: true),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'El cuadro queda armado y los ganadores avanzan solos al cargar '
            'cada resultado.',
        escena: () => escenaLlaves(FocoLlaves.ninguno, listo: true),
      ),
    ],
  ),
  GuiaAyuda(
    id: 'editar-cruce',
    titulo: 'Cambiar los equipos de un cruce',
    resumen: 'Completar un cruce armado a mano.',
    icono: Icons.swap_horiz_rounded,
    pantallas: const [PantallaAyuda.llaves],
    pantallaDestino: PantallaAyuda.llaves,
    pasos: [
      PasoAyuda(
        titulo: 'Tocá el lápiz del cruce',
        explicacion:
            'A la derecha de cada cruce (dice "Cambiar equipos"). Los que '
            'esperan a otra llave se completan solos.',
        escena: () => escenaLlaves(FocoLlaves.lapiz),
      ),
      PasoAyuda(
        titulo: 'Elegí "Equipo local" y "Equipo visitante"',
        explicacion: 'Las listas muestran los equipos activos.',
        escena: () => escenaEditarCruce(focoEquipos: true),
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar"',
        explicacion: 'El cruce queda listo para programar.',
        escena: () => escenaEditarCruce(focoGuardar: true),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion: 'El público ve el cruce con sus dos equipos.',
        escena: () => escenaLlaves(FocoLlaves.ninguno, listo: true),
      ),
    ],
  ),

  // -------------------------------------------------------- Igualación
  GuiaAyuda(
    id: 'igualacion',
    titulo: 'Igualar los puntos de un grupo más chico',
    resumen: 'Compensar al grupo que jugó un partido menos.',
    icono: Icons.balance_outlined,
    pantallas: const [PantallaAyuda.igualacion],
    pantallaDestino: PantallaAyuda.igualacion,
    pasos: [
      pasoAbrirModulo('Igualación'),
      PasoAyuda(
        titulo: 'Escribí los puntos de cada equipo',
        explicacion:
            'En el grupo con menos equipos, los puntos que se suman a cada uno.',
        consejo:
            'Solo se puede cuando ese grupo tiene todos sus partidos con '
            'resultado.',
        escena: () => escenaIgualacion(FocoIgualacion.puntos),
      ),
      PasoAyuda(
        titulo: 'Tocá "Guardar"',
        explicacion: 'Arriba a la derecha.',
        escena: () => escenaIgualacion(FocoIgualacion.guardar),
      ),
      PasoAyuda(
        titulo: '¡Listo!',
        explicacion:
            'La tabla y los clasificados se recalculan con los puntos nuevos.',
        escena: () => escenaIgualacion(FocoIgualacion.ninguno, listo: true),
      ),
    ],
  ),
];
