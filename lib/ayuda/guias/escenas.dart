// Maquetas de las pantallas del administrador para las guías de ayuda.
//
// SI CAMBIA EL TEXTO DE UN BOTÓN O UN TÍTULO EN LA APP, ACTUALIZARLO
// ACÁ Y EN SU GUÍA: las maquetas tienen que decir exactamente lo mismo.
//
// Cada función dibuja una pantalla y recibe qué elemento señalar
// (`foco`). `listo` marca el resultado del último paso en verde.

import 'package:flutter/material.dart';

import '../../screens/reciclaje/app_colors.dart';
import '../maqueta.dart';

/// Envuelve [w] con el indicador "tocá acá" si [on].
Widget _t(bool on, Widget w) => on ? MqTocaAca(child: w) : w;

/// Envuelve [w] con el resaltado de resultado si [on].
Widget _ok(bool on, Widget w) => on ? MqTocaAca.resultado(child: w) : w;

const _camp = 'INTERCARRERAS SEMESTRE 2/2026';

// ---------------------------------------------------------------- Panel

enum FocoPanel { ninguno, nuevo, verTodos, administrar, verPublico, salir }

Widget escenaPanel(FocoPanel foco) {
  return MqMarco(
    titulo: 'Panel administrativo',
    volver: false,
    acciones: [
      _t(foco == FocoPanel.salir, const MqBoton.peligro('Cerrar sesión')),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Expanded(
                child: MqTexto(
                  'Campeonatos UPSA',
                  size: 11,
                  fuerte: true,
                  color: AppColors.white,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _t(
                    foco == FocoPanel.nuevo,
                    const MqBoton.borde(
                      'Nuevo campeonato',
                      icono: Icons.add_rounded,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _t(
                    foco == FocoPanel.verTodos,
                    const MqBoton.borde(
                      'Ver todos los campeonatos',
                      icono: Icons.list_alt_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        const MqSeccion('Campeonatos en curso'),
        MqTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MqTexto(_camp, size: 10, fuerte: true),
              const SizedBox(height: 4),
              const Row(
                children: [
                  MqEtiqueta.exito('Activo'),
                  SizedBox(width: 4),
                  MqEtiqueta('Fútbol 11'),
                  SizedBox(width: 4),
                  MqEtiqueta.info('Fase de grupos'),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  _t(
                    foco == FocoPanel.administrar,
                    const MqBoton(
                      'Administrar',
                      icono: Icons.settings_outlined,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _t(
                    foco == FocoPanel.verPublico,
                    const MqBoton.borde(
                      'Ver público',
                      icono: Icons.visibility_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// -------------------------------------------- Listado de campeonatos

enum FocoLista { ninguno, buscar, finalizado, administrar }

Widget escenaListaCampeonatos(FocoLista foco, {bool listo = false}) {
  return MqMarco(
    titulo: 'Campeonatos',
    acciones: const [MqBoton('Nuevo campeonato', icono: Icons.add_rounded)],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MqTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _t(
                foco == FocoLista.buscar,
                const MqCampo(
                  'Buscar campeonato',
                  'interamigos',
                  icono: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const MqEtiqueta.neutra('Todos'),
                  const SizedBox(width: 4),
                  const MqEtiqueta.neutra('Inscripción'),
                  const SizedBox(width: 4),
                  const MqEtiqueta.neutra('Activo'),
                  const SizedBox(width: 4),
                  _t(
                    foco == FocoLista.finalizado,
                    listo || foco == FocoLista.administrar
                        ? const MqEtiqueta('Finalizado')
                        : const MqEtiqueta.neutra('Finalizado'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _ok(
          listo,
          MqTarjeta(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MqTexto(
                        'INTERAMIGOS COPA MUNDIAL 2026',
                        size: 10,
                        fuerte: true,
                      ),
                      SizedBox(height: 3),
                      MqEtiqueta.neutra('Finalizado'),
                    ],
                  ),
                ),
                _t(
                  foco == FocoLista.administrar,
                  const MqBoton('Administrar', icono: Icons.settings_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// --------------------------------------------- Nuevo campeonato

enum FocoNuevo { ninguno, nombre, deporte, formato, guardar }

Widget escenaNuevoCampeonato(FocoNuevo foco) {
  return MqMarco(
    titulo: 'Nuevo campeonato',
    acciones: [
      const MqBoton.borde('Cancelar'),
      _t(
        foco == FocoNuevo.guardar,
        const MqBoton('Guardar', icono: Icons.save_outlined),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MqSeccion('Datos generales'),
        _t(
          foco == FocoNuevo.nombre,
          const MqCampo('Nombre del campeonato', _camp),
        ),
        const SizedBox(height: 8),
        const MqSeccion('Deporte'),
        Wrap(
          spacing: 5,
          runSpacing: 4,
          children: [
            _t(
              foco == FocoNuevo.deporte,
              const MqBoton('Fútbol / Futsal', icono: Icons.sports_soccer),
            ),
            const MqBoton.borde('Vóley', icono: Icons.sports_volleyball),
            const MqBoton.borde('Básquet', icono: Icons.sports_basketball),
          ],
        ),
        const SizedBox(height: 8),
        const MqSeccion('Formato del campeonato'),
        Row(
          children: [
            const Expanded(
              child: MqTarjeta(child: MqTexto('Fase de grupos', size: 9)),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _t(
                foco == FocoNuevo.formato,
                const MqTarjeta(
                  child: MqTexto('Grupos + eliminación', size: 9, fuerte: true),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ------------------------------------------- Detalle del campeonato

enum FocoDetalle {
  ninguno,
  editar,
  activar,
  finalizar,
  pendiente,
  modulo,
  estadoActivo,
  estadoFinalizado,
}

/// [modulo] es el nombre del módulo a señalar cuando foco es `modulo`.
Widget escenaDetalle(
  FocoDetalle foco, {
  String modulo = '',
  bool enInscripcion = false,
  Widget? superpuesto,
}) {
  Widget mod(String titulo, IconData icono) => _t(
    foco == FocoDetalle.modulo && modulo == titulo,
    MqModulo(titulo, icono),
  );

  final estado = switch (foco) {
    FocoDetalle.estadoActivo => _ok(true, const MqEtiqueta.exito('Activo')),
    FocoDetalle.estadoFinalizado => _ok(
      true,
      const MqEtiqueta.neutra('Finalizado'),
    ),
    _ =>
      enInscripcion
          ? const MqEtiqueta.info('Inscripción')
          : const MqEtiqueta.exito('Activo'),
  };

  return MqMarco(
    titulo: _camp,
    superpuesto: superpuesto,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            estado,
            const Spacer(),
            _t(
              foco == FocoDetalle.editar,
              const MqBoton.borde('Editar datos', icono: Icons.edit_outlined),
            ),
            const SizedBox(width: 5),
            if (enInscripcion)
              _t(
                foco == FocoDetalle.activar,
                const MqBoton(
                  'Activar campeonato',
                  icono: Icons.play_arrow_rounded,
                ),
              )
            else
              _t(
                foco == FocoDetalle.finalizar,
                const MqBoton.peligro(
                  'Finalizar campeonato',
                  icono: Icons.flag_outlined,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        MqTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MqTexto('Pendientes', size: 10, fuerte: true),
              const SizedBox(height: 4),
              _t(
                foco == FocoDetalle.pendiente,
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        size: 12,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: MqTexto(
                          '3 partidos ya se jugaron y no tienen resultado.',
                          size: 8.5,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        const MqSeccion('Inscripción'),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            mod('Equipos', Icons.groups_2_outlined),
            mod('Jugadores', Icons.person_add_alt_1_outlined),
            mod('Grupos', Icons.grid_view_rounded),
          ],
        ),
        const SizedBox(height: 6),
        const MqSeccion('Competencia'),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            mod('Fixture', Icons.calendar_month_outlined),
            mod('Resultados', Icons.fact_check_outlined),
            mod('Llaves', Icons.account_tree_outlined),
            mod('Igualación', Icons.balance_outlined),
          ],
        ),
      ],
    ),
  );
}

/// Más módulos (los de consulta), para las guías de esa sección.
Widget escenaDetalleConsulta(String modulo) {
  Widget mod(String titulo, IconData icono) =>
      _t(modulo == titulo, MqModulo(titulo, icono));

  return MqMarco(
    titulo: _camp,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MqTexto('Módulos del campeonato', size: 11, fuerte: true),
        const SizedBox(height: 8),
        const MqSeccion('Consulta'),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            mod('Tabla', Icons.leaderboard_outlined),
            mod('Goleadores', Icons.sports_soccer),
          ],
        ),
        const SizedBox(height: 8),
        const MqSeccion('Control y documentos'),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            mod('Sancionados', Icons.shield_outlined),
            mod('PDFs', Icons.picture_as_pdf_outlined),
            mod('Auditoría', Icons.history),
          ],
        ),
      ],
    ),
  );
}

/// Diálogo "Editar campeonato" sobre el detalle.
Widget escenaEditarCampeonato({
  bool focoNombre = false,
  bool focoGuardar = false,
}) {
  return escenaDetalle(
    FocoDetalle.ninguno,
    superpuesto: MqDialogo(
      titulo: 'Editar campeonato',
      acciones: [
        const MqBoton.texto('Cancelar'),
        _t(focoGuardar, const MqBoton('Guardar', icono: Icons.check_rounded)),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _t(focoNombre, const MqCampo('Nombre', 'INTERCARRERAS 2/2026')),
          const SizedBox(height: 5),
          const MqCampo('Cancha', 'Cancha UPSA'),
        ],
      ),
    ),
  );
}

/// Diálogo de confirmación genérico encima de [fondo].
Widget escenaConfirmar({
  required Widget Function(Widget superpuesto) fondo,
  required String titulo,
  required String mensaje,
  required String boton,
  bool peligro = false,
}) {
  return fondo(
    MqDialogo(
      titulo: titulo,
      acciones: [
        const MqBoton.texto('Cancelar'),
        MqTocaAca(child: peligro ? MqBoton.peligro(boton) : MqBoton(boton)),
      ],
      child: MqTexto(mensaje, size: 9, color: AppColors.textSecondary),
    ),
  );
}

// ---------------------------------------------------------- Equipos

enum FocoEquipos { ninguno, nuevo, tarjeta, eliminar }

Widget escenaEquipos(
  FocoEquipos foco, {
  bool listo = false,
  bool sinCivil = false,
  Widget? superpuesto,
}) {
  Widget equipo(String nombre, String rep, {bool senalar = false}) {
    return MqTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MqEtiqueta.exito('Activo'),
              const Spacer(),
              _t(
                senalar && foco == FocoEquipos.eliminar,
                const MqIcono(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 3),
          MqTexto(nombre, size: 10, fuerte: true),
          MqTexto(
            'Representante: $rep',
            size: 8.5,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  return MqMarco(
    titulo: 'Equipos',
    superpuesto: superpuesto,
    acciones: [
      _t(
        foco == FocoEquipos.nuevo,
        const MqBoton('Nuevo equipo', icono: Icons.add),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MqCampo(
          'Buscar equipo',
          'Nombre, representante, carrera o facultad...',
          icono: Icons.search_rounded,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!sinCivil)
              Expanded(
                child: _t(
                  foco == FocoEquipos.tarjeta,
                  _ok(
                    listo,
                    equipo('ING. CIVIL', 'Mariana Rojas', senalar: true),
                  ),
                ),
              ),
            if (!sinCivil) const SizedBox(width: 6),
            Expanded(child: equipo('DERECHO', 'Luis Vaca')),
            if (sinCivil) ...[
              const SizedBox(width: 6),
              Expanded(child: _ok(listo, equipo('MEDICINA', 'Ana Suárez'))),
            ],
          ],
        ),
      ],
    ),
  );
}

enum FocoEquipoForm { ninguno, nombre, estado, observacion, guardar }

Widget escenaEquipoForm(FocoEquipoForm foco, {bool editando = false}) {
  return MqMarco(
    titulo: editando ? 'Editar equipo' : 'Nuevo equipo',
    acciones: [
      const MqBoton.borde('Cancelar'),
      _t(
        foco == FocoEquipoForm.guardar,
        MqBoton(
          editando ? 'Actualizar' : 'Guardar',
          icono: Icons.save_outlined,
        ),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MqSeccion('Datos del equipo'),
        _t(
          foco == FocoEquipoForm.nombre,
          MqCampo('Nombre del equipo', editando ? 'ING. CIVIL' : 'MEDICINA'),
        ),
        const SizedBox(height: 6),
        MqCampo('Representante', editando ? 'Mariana Rojas' : 'Ana Suárez'),
        if (editando) ...[
          const SizedBox(height: 8),
          const MqSeccion('Estado y observación'),
          Row(
            children: [
              Expanded(
                child: _t(
                  foco == FocoEquipoForm.estado,
                  const MqCampo(
                    'Estado del equipo',
                    'Activo',
                    desplegable: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _t(
                  foco == FocoEquipoForm.observacion,
                  const MqCampo(
                    'Observación obligatoria',
                    'Cambio de nombre pedido',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

// -------------------------------------------------------- Jugadores

enum FocoJugadores { ninguno, nuevo, editar, eliminar, historial }

Widget escenaJugadores(
  FocoJugadores foco, {
  bool listo = false,
  Widget? superpuesto,
}) {
  Widget acciones() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _t(foco == FocoJugadores.historial, const MqBoton.texto('Historial')),
      _t(foco == FocoJugadores.editar, const MqBoton.texto('Editar')),
      _t(foco == FocoJugadores.eliminar, const MqBoton.texto('Eliminar')),
    ],
  );

  return MqMarco(
    titulo: 'Jugadores',
    superpuesto: superpuesto,
    acciones: [
      _t(
        foco == FocoJugadores.nuevo,
        const MqBoton('Nuevo jugador', icono: Icons.add),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MqCampo(
          'Buscar jugador',
          'Nombre, código o equipo...',
          icono: Icons.search_rounded,
        ),
        const SizedBox(height: 8),
        MqLista([
          _ok(
            listo,
            MqFila(
              'Carlos Méndez',
              detalle: '219034512 · ING. CIVIL',
              icono: Icons.person_outline,
              derecha: acciones(),
            ),
          ),
          const MqFila(
            'Lucía Paz',
            detalle: '220118733 · DERECHO',
            icono: Icons.person_outline,
          ),
        ]),
      ],
    ),
  );
}

enum FocoJugadorForm {
  ninguno,
  equipo,
  datos,
  excel,
  estado,
  observacion,
  guardar,
}

Widget escenaJugadorForm(
  FocoJugadorForm foco, {
  bool editando = false,
  Widget? superpuesto,
}) {
  return MqMarco(
    titulo: editando ? 'Editar jugador' : 'Nuevo jugador',
    superpuesto: superpuesto,
    acciones: [
      _t(
        foco == FocoJugadorForm.guardar,
        MqBoton(
          editando ? 'Actualizar' : 'Guardar jugadores',
          icono: Icons.save_outlined,
        ),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _t(
          foco == FocoJugadorForm.equipo,
          const MqCampo('Equipo', 'ING. CIVIL', desplegable: true),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _t(
                foco == FocoJugadorForm.datos,
                const MqCampo('Número de registro', '219034512'),
              ),
            ),
            const SizedBox(width: 6),
            const Expanded(
              flex: 2,
              child: MqCampo('Nombre completo', 'Carlos Méndez'),
            ),
          ],
        ),
        const SizedBox(height: 7),
        if (editando)
          Row(
            children: [
              Expanded(
                child: _t(
                  foco == FocoJugadorForm.estado,
                  const MqCampo('Estado', 'Activo', desplegable: true),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _t(
                  foco == FocoJugadorForm.observacion,
                  const MqCampo(
                    'Observación obligatoria',
                    'Número mal cargado',
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              _t(
                foco == FocoJugadorForm.excel,
                const MqBoton.borde(
                  'Pegar desde Excel',
                  icono: Icons.content_paste_rounded,
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

Widget escenaPegarExcel() {
  return escenaJugadorForm(
    FocoJugadorForm.ninguno,
    superpuesto: MqDialogo(
      titulo: 'Pegar lista desde Excel',
      acciones: [
        const MqBoton.texto('Cancelar'),
        MqTocaAca(child: const MqBoton('Rellenar lista')),
      ],
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const MqTexto(
          '219034512   Carlos Méndez\n220118733   Lucía Paz',
          size: 8.5,
        ),
      ),
    ),
  );
}

Widget escenaHistorialJugador() {
  return MqMarco(
    titulo: 'Historial de cambios',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MqTexto('Carlos Méndez', size: 10, fuerte: true),
        const SizedBox(height: 7),
        _ok(
          true,
          const MqLista([
            MqFila(
              'Editar jugador',
              detalle: '20/10/2026 18:42 · Número mal cargado',
              icono: Icons.history,
            ),
            MqFila(
              'Agregar jugador',
              detalle: '02/10/2026 10:15',
              icono: Icons.history,
            ),
          ]),
        ),
      ],
    ),
  );
}

// ----------------------------------------------------------- Grupos

enum FocoGrupos { ninguno, generar, mover, quitar, clasificacion }

Widget escenaGrupos(
  FocoGrupos foco, {
  bool listo = false,
  bool vacio = false,
  Widget? superpuesto,
}) {
  Widget grupo(String nombre, List<String> equipos, {bool senalar = false}) {
    return Expanded(
      child: MqTarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MqTexto(nombre, size: 10, fuerte: true),
            const SizedBox(height: 4),
            for (var i = 0; i < equipos.length; i++)
              Row(
                children: [
                  Expanded(child: MqTexto(equipos[i], size: 8.5)),
                  _t(
                    senalar && i == 0 && foco == FocoGrupos.mover,
                    const MqIcono(Icons.compare_arrows_rounded),
                  ),
                  _t(
                    senalar && i == 0 && foco == FocoGrupos.quitar,
                    const MqIcono(
                      Icons.person_remove_outlined,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  return MqMarco(
    titulo: 'Grupos',
    superpuesto: superpuesto,
    acciones: [
      if (vacio)
        _t(
          foco == FocoGrupos.generar,
          const MqBoton('Generar grupos automáticamente', icono: Icons.shuffle),
        )
      else
        _t(
          foco == FocoGrupos.clasificacion,
          const MqBoton.borde('Editar clasificación', icono: Icons.tune),
        ),
    ],
    child: vacio
        ? const Center(
            child: MqTexto(
              'Todavía no hay grupos armados',
              size: 11,
              fuerte: true,
              color: AppColors.textSecondary,
            ),
          )
        : _ok(
            listo,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                grupo('Grupo A', [
                  'ING. CIVIL',
                  'DERECHO',
                  'MEDICINA',
                ], senalar: true),
                const SizedBox(width: 6),
                grupo('Grupo B', ['ARQUITECTURA', 'ING. COMERCIAL']),
              ],
            ),
          ),
  );
}

/// Diálogo con una lista para elegir (grupo de destino, por ejemplo).
Widget escenaDialogoLista(
  String titulo,
  List<String> opciones, {
  int senalar = 0,
}) {
  return MqDialogo(
    titulo: titulo,
    acciones: const [MqBoton.texto('Cancelar')],
    child: MqLista([
      for (var i = 0; i < opciones.length; i++)
        _t(i == senalar, MqFila(opciones[i], icono: Icons.grid_view_rounded)),
    ]),
  );
}

/// Diálogo "Editar clasificación" de la pantalla de grupos.
Widget escenaDialogoClasificacion() {
  return MqDialogo(
    titulo: 'Editar clasificación',
    acciones: [
      const MqBoton.texto('Cancelar'),
      MqTocaAca(child: const MqBoton('Guardar')),
    ],
    child: const Row(
      children: [
        Expanded(child: MqCampo('Clasifican por grupo', '2')),
        SizedBox(width: 6),
        Expanded(child: MqCampo('Mejores terceros', '0')),
      ],
    ),
  );
}

// ---------------------------------------------------------- Fixture

enum FocoFixture {
  ninguno,
  generar,
  programar,
  cruce,
  activar,
  borrar,
  pdf,
  llaves,
}

Widget escenaFixture(
  FocoFixture foco, {
  bool vacio = false,
  bool listo = false,
  bool programado = false,
  Widget? superpuesto,
}) {
  return MqMarco(
    titulo: 'Fixture',
    superpuesto: superpuesto,
    acciones: [
      if (vacio)
        _t(
          foco == FocoFixture.generar,
          const MqBoton('Generar fixture', icono: Icons.shuffle),
        )
      else ...[
        _t(
          foco == FocoFixture.activar,
          const MqBoton.borde('Activar fase eliminatoria', icono: Icons.bolt),
        ),
      ],
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            _t(
              foco == FocoFixture.cruce,
              const MqBoton.borde('Agregar cruce manual', icono: Icons.add),
            ),
            if (!vacio) ...[
              _t(
                foco == FocoFixture.borrar,
                const MqBoton.peligro(
                  'Borrar fixture',
                  icono: Icons.delete_sweep_outlined,
                ),
              ),
              _t(
                foco == FocoFixture.pdf,
                const MqBoton.borde(
                  'Descargar PDF',
                  icono: Icons.picture_as_pdf_outlined,
                ),
              ),
              _t(
                foco == FocoFixture.llaves,
                const MqBoton.borde(
                  'Llaves',
                  icono: Icons.account_tree_outlined,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (vacio)
          const Expanded(
            child: Center(
              child: MqTexto(
                'No hay fixture generado',
                size: 11,
                fuerte: true,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          _ok(
            listo,
            MqLista([
              MqFila(
                'ING. CIVIL vs DERECHO',
                detalle: programado
                    ? 'Grupo A · Sáb 24/10/2026 · 15:00'
                    : 'Grupo A · Jornada 1 · Sin fecha',
                icono: Icons.sports_soccer,
                derecha: programado
                    ? const MqEtiqueta.exito('Programado')
                    : _t(
                        foco == FocoFixture.programar,
                        const MqBoton.borde(
                          'Programar',
                          icono: Icons.edit_calendar_outlined,
                        ),
                      ),
              ),
              const MqFila(
                'MEDICINA vs ARQUITECTURA',
                detalle: 'Grupo B · Jornada 1 · Sin fecha',
                icono: Icons.sports_soccer,
                derecha: MqEtiqueta.aviso('Sin programar'),
              ),
            ]),
          ),
      ],
    ),
  );
}

Widget escenaCalendario() {
  return escenaFixture(
    FocoFixture.ninguno,
    superpuesto: MqDialogo(
      titulo: 'Seleccionar fecha',
      acciones: [
        const MqBoton.texto('Cancelar'),
        MqTocaAca(child: const MqBoton.texto('Aceptar')),
      ],
      child: const Center(child: MqCalendario()),
    ),
  );
}

Widget escenaReloj() {
  return escenaFixture(
    FocoFixture.ninguno,
    superpuesto: MqDialogo(
      titulo: 'Seleccionar hora',
      acciones: [
        const MqBoton.texto('Cancelar'),
        MqTocaAca(child: const MqBoton.texto('Aceptar')),
      ],
      child: const Center(child: MqReloj('15:00')),
    ),
  );
}

Widget escenaCruceManual({bool focoEquipos = false, bool focoCrear = false}) {
  return escenaFixture(
    FocoFixture.ninguno,
    superpuesto: MqDialogo(
      titulo: 'Agregar cruce manual',
      acciones: [
        const MqBoton.texto('Cancelar'),
        _t(focoCrear, const MqBoton('Crear cruce')),
      ],
      child: _t(
        focoEquipos,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MqCampo('Equipo local', 'ING. CIVIL', desplegable: true),
            SizedBox(height: 5),
            MqCampo('Equipo visitante', 'MEDICINA', desplegable: true),
          ],
        ),
      ),
    ),
  );
}

// ------------------------------------------------------- Resultados

enum FocoResultados { ninguno, porCargar, conResultado, cargar, editar, anular }

Widget escenaResultados(
  FocoResultados foco, {
  bool listo = false,
  bool mostrarJugado = false,
  Widget? superpuesto,
}) {
  final jugado =
      mostrarJugado ||
      foco == FocoResultados.conResultado ||
      foco == FocoResultados.editar ||
      foco == FocoResultados.anular;

  return MqMarco(
    titulo: 'Resultados',
    superpuesto: superpuesto,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _t(
              foco == FocoResultados.porCargar,
              jugado
                  ? const MqEtiqueta.neutra('Por cargar 3')
                  : const MqEtiqueta('Por cargar 3'),
            ),
            const SizedBox(width: 4),
            _t(
              foco == FocoResultados.conResultado,
              jugado
                  ? const MqEtiqueta('Con resultado 12')
                  : const MqEtiqueta.neutra('Con resultado 12'),
            ),
            const SizedBox(width: 4),
            const MqEtiqueta.neutra('Todos 15'),
          ],
        ),
        const SizedBox(height: 8),
        _ok(
          listo,
          MqTarjeta(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          jugado
                              ? const MqEtiqueta.exito('Con resultado')
                              : const MqEtiqueta.exito('Programado'),
                          const SizedBox(width: 4),
                          const MqEtiqueta.info('Grupo A · Jornada 1'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const MqTexto(
                        'ING. CIVIL vs DERECHO',
                        size: 10,
                        fuerte: true,
                      ),
                      const MqTexto(
                        '24/10/2026 · 15:00',
                        size: 8.5,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                if (jugado) ...[
                  const MqTexto('2 - 1', size: 12, fuerte: true),
                  const SizedBox(width: 4),
                  _t(
                    foco == FocoResultados.anular,
                    const MqIcono(Icons.undo_rounded, color: AppColors.danger),
                  ),
                  _t(
                    foco == FocoResultados.editar,
                    const MqBoton.borde('Editar', icono: Icons.edit_outlined),
                  ),
                ] else
                  _t(
                    foco == FocoResultados.cargar,
                    const MqBoton(
                      'Cargar resultado',
                      icono: Icons.add_task_rounded,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget escenaAnular() {
  return escenaResultados(
    FocoResultados.ninguno,
    mostrarJugado: true,
    superpuesto: MqDialogo(
      titulo: 'Anular resultado',
      acciones: [
        const MqBoton.texto('Cancelar'),
        MqTocaAca(child: const MqBoton.peligro('Anular')),
      ],
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MqTexto(
            'ING. CIVIL 2 - 1 DERECHO vuelve a quedar sin jugar.',
            size: 8.5,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 5),
          MqCampo('Motivo', 'Se cargó el marcador al revés.'),
        ],
      ),
    ),
  );
}

enum FocoCarga {
  ninguno,
  marcador,
  agregarGol,
  goleador,
  sets,
  penales,
  tipo,
  observacion,
  guardar,
}

enum VarianteCarga { futbol, voley, penales, walkover }

Widget escenaCargarResultado(
  FocoCarga foco, {
  VarianteCarga variante = VarianteCarga.futbol,
}) {
  final esLlave = variante == VarianteCarga.penales;
  final local = esLlave ? 'BELGICA' : 'ING. CIVIL';
  final visitante = esLlave ? 'MEXICO' : 'DERECHO';
  final (golesL, golesV) = switch (variante) {
    VarianteCarga.penales => ('1', '1'),
    VarianteCarga.walkover => ('—', '—'),
    _ => ('2', '1'),
  };

  final List<Widget> detalle = switch (variante) {
    VarianteCarga.voley => [
      _t(
        foco == FocoCarga.agregarGol,
        const MqBoton.borde('Agregar set', icono: Icons.add),
      ),
      const SizedBox(height: 5),
      _t(
        foco == FocoCarga.sets,
        const MqLista([
          MqFila('Set 1', derecha: MqTexto('25 - 20', size: 9.5, fuerte: true)),
          MqFila('Set 2', derecha: MqTexto('23 - 25', size: 9.5, fuerte: true)),
        ]),
      ),
    ],
    VarianteCarga.penales => [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const MqTexto(
          'Empate en la fase final: registrá los penales para definir quién avanza.',
          size: 8.5,
        ),
      ),
      const SizedBox(height: 5),
      _t(
        foco == FocoCarga.penales,
        const Row(
          children: [
            Expanded(child: MqCampo('Penales BELGICA', '4')),
            SizedBox(width: 6),
            Expanded(child: MqCampo('Penales MEXICO', '3')),
          ],
        ),
      ),
    ],
    VarianteCarga.walkover => [
      _t(
        foco == FocoCarga.observacion,
        const MqCampo('Observación obligatoria', 'DERECHO no se presentó.'),
      ),
    ],
    VarianteCarga.futbol => [
      Row(
        children: [
          const Expanded(
            child: MqTexto('Goles por jugador', size: 9.5, fuerte: true),
          ),
          _t(
            foco == FocoCarga.agregarGol,
            const MqBoton.borde('Agregar gol', icono: Icons.add),
          ),
        ],
      ),
      const SizedBox(height: 5),
      _t(
        foco == FocoCarga.goleador,
        const MqCampo(
          'Jugador',
          'Carlos Méndez - ING. CIVIL',
          desplegable: true,
        ),
      ),
    ],
  };

  return MqMarco(
    titulo: 'Registrar resultado',
    acciones: [
      _t(
        foco == FocoCarga.guardar,
        const MqBoton('Guardar resultado', icono: Icons.save_outlined),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _t(
          foco == FocoCarga.tipo,
          MqCampo(
            'Tipo de resultado',
            variante == VarianteCarga.walkover ? 'Walkover' : 'Normal',
            desplegable: true,
          ),
        ),
        const SizedBox(height: 6),
        if (variante != VarianteCarga.walkover &&
            variante != VarianteCarga.voley)
          _t(
            foco == FocoCarga.marcador,
            Row(
              children: [
                Expanded(child: MqCampo(local, golesL)),
                const SizedBox(width: 6),
                Expanded(child: MqCampo(visitante, golesV)),
              ],
            ),
          ),
        if (variante != VarianteCarga.walkover &&
            variante != VarianteCarga.voley)
          const SizedBox(height: 6),
        ...detalle,
      ],
    ),
  );
}

// ----------------------------------------------------------- Llaves

enum FocoLlaves { ninguno, generar, lapiz }

Widget escenaLlaves(
  FocoLlaves foco, {
  bool listo = false,
  bool vacio = false,
  Widget? superpuesto,
}) {
  Widget cruce(String a, String b, {bool senalar = false}) => MqTarjeta(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MqTexto(a, size: 9, fuerte: true),
              MqTexto(b, size: 9, fuerte: true),
            ],
          ),
        ),
        _t(
          senalar && foco == FocoLlaves.lapiz,
          const MqIcono(Icons.edit_outlined),
        ),
      ],
    ),
  );

  return MqMarco(
    titulo: 'Llaves eliminatorias',
    superpuesto: superpuesto,
    acciones: [
      _t(
        foco == FocoLlaves.generar,
        MqBoton(
          vacio ? 'Generar llaves' : 'Regenerar llaves',
          icono: Icons.account_tree_outlined,
        ),
      ),
    ],
    child: vacio
        ? const Center(
            child: MqTexto(
              'Todavía no hay cuadro armado.',
              size: 11,
              fuerte: true,
              color: AppColors.textSecondary,
            ),
          )
        : _ok(
            listo,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MqSeccion('Semifinales'),
                cruce('BELGICA', 'PARAGUAY', senalar: true),
                const SizedBox(height: 5),
                cruce('ESPAÑA', 'MEXICO'),
                const SizedBox(height: 6),
                const MqSeccion('Final'),
                cruce('Ganador llave 1', 'Ganador llave 2'),
              ],
            ),
          ),
  );
}

Widget escenaGenerarLlaves({bool focoRonda = false, bool focoGenerar = false}) {
  return escenaLlaves(
    FocoLlaves.ninguno,
    vacio: true,
    superpuesto: MqDialogo(
      titulo: 'Generar llaves',
      acciones: [
        const MqBoton.texto('Cancelar'),
        _t(focoGenerar, const MqBoton('Generar')),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MqTexto('Hay 8 clasificados.', size: 9, fuerte: true),
          const SizedBox(height: 5),
          _t(
            focoRonda,
            const MqCampo(
              'Arrancar el cuadro en',
              'Automático · cuartos de final',
              desplegable: true,
            ),
          ),
          const SizedBox(height: 5),
          const MqInterruptor('Sembrar con la tabla'),
        ],
      ),
    ),
  );
}

Widget escenaEditarCruce({bool focoEquipos = false, bool focoGuardar = false}) {
  return escenaLlaves(
    FocoLlaves.ninguno,
    superpuesto: MqDialogo(
      titulo: 'Cambiar equipos',
      acciones: [
        const MqBoton.texto('Cancelar'),
        _t(focoGuardar, const MqBoton('Guardar')),
      ],
      child: _t(
        focoEquipos,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MqCampo('Equipo local', 'BELGICA', desplegable: true),
            SizedBox(height: 5),
            MqCampo('Equipo visitante', 'CURAZAO', desplegable: true),
          ],
        ),
      ),
    ),
  );
}

// -------------------------------------------------------- Igualación

enum FocoIgualacion { ninguno, puntos, guardar }

Widget escenaIgualacion(FocoIgualacion foco, {bool listo = false}) {
  return MqMarco(
    titulo: 'Igualación de puntos',
    acciones: [
      _t(
        foco == FocoIgualacion.guardar,
        const MqBoton('Guardar', icono: Icons.save_outlined),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MqTexto(
          'Grupo C · 3 equipos (los demás tienen 4)',
          size: 9.5,
          fuerte: true,
        ),
        const SizedBox(height: 7),
        _ok(
          listo,
          MqLista([
            MqFila(
              'ING. COMERCIAL',
              detalle: '6 pts',
              derecha: SizedBox(
                width: 54,
                child: _t(
                  foco == FocoIgualacion.puntos,
                  const MqCampo('+ pts', '1'),
                ),
              ),
            ),
            const MqFila(
              'ING. FINANCIERA',
              detalle: '3 pts',
              derecha: SizedBox(width: 54, child: MqCampo('+ pts', '1')),
            ),
          ]),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------- PDFs

enum FocoPdfs { ninguno, planilla, resultados, todasPlanillas, fixture }

Widget escenaPdfs(FocoPdfs foco) {
  return MqMarco(
    titulo: 'Centro de impresión',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            _t(
              foco == FocoPdfs.fixture,
              const MqBoton.borde(
                'Fixture completo',
                icono: Icons.calendar_month,
              ),
            ),
            _t(
              foco == FocoPdfs.resultados,
              const MqBoton.borde(
                'Imprimir resultados',
                icono: Icons.scoreboard,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const MqSeccion('Planillas de control por partido'),
        MqLista([
          MqFila(
            'ING. CIVIL vs DERECHO',
            detalle: 'Sáb 24/10/2026 · 15:00',
            icono: Icons.sports_soccer,
            derecha: _t(
              foco == FocoPdfs.planilla,
              const MqBoton.borde('Planilla', icono: Icons.print_outlined),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: MqSeccion('Planillas de equipos')),
            _t(
              foco == FocoPdfs.todasPlanillas,
              const MqBoton.borde(
                'Imprimir todas las planillas',
                icono: Icons.print_outlined,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Un PDF abierto: la vista previa que se descarga o imprime.
Widget escenaPdfListo(String titulo, String detalle) {
  return MqMarco(
    titulo: titulo,
    child: Center(
      child: _ok(
        true,
        Container(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 26,
                color: AppColors.danger,
              ),
              const SizedBox(height: 5),
              MqTexto(detalle, size: 8.5, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    ),
  );
}

// ----------------------------------------------- Pantallas de consulta

Widget escenaConsulta({
  required String titulo,
  required String buscar,
  required List<MqFila> filas,
  bool focoBuscar = false,
  bool listo = false,
}) {
  return MqMarco(
    titulo: titulo,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _t(focoBuscar, MqCampo('Buscar', buscar, icono: Icons.search_rounded)),
        const SizedBox(height: 8),
        _ok(listo, MqLista(filas)),
      ],
    ),
  );
}

// ------------------------------------------------------ Vista pública

Widget escenaPublica({bool cuadro = false}) {
  return MqMarco(
    titulo: _camp,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            MqEtiqueta.exito('Activo'),
            SizedBox(width: 4),
            MqEtiqueta.aviso('Fase eliminatoria'),
          ],
        ),
        const SizedBox(height: 8),
        _ok(
          true,
          cuadro
              ? const MqLista([
                  MqFila(
                    'BELGICA  3 (4)',
                    detalle: 'Final',
                    icono: Icons.emoji_events_outlined,
                  ),
                  MqFila(
                    'MEXICO  3 (3)',
                    detalle: 'Final',
                    icono: Icons.emoji_events_outlined,
                  ),
                ])
              : const MqLista([
                  MqFila(
                    'Próximos partidos',
                    detalle: 'ING. CIVIL vs DERECHO · Sáb 24/10 · 15:00',
                    icono: Icons.event_outlined,
                  ),
                  MqFila(
                    'Tabla de posiciones',
                    detalle: '1. ING. CIVIL · 9 pts',
                    icono: Icons.leaderboard_outlined,
                  ),
                ]),
        ),
      ],
    ),
  );
}
