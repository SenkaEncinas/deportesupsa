// Reglas que agregó la revisión del panel de administración: los textos
// de la base pasados a algo legible, los errores de Firebase traducidos
// y cuándo un partido queda "pendiente" de resultado o de fecha.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/utils/etiquetas.dart';
import 'package:futsal/utils/mensajes.dart';

PartidoModel _partido({
  String estado = PartidoEstado.programado,
  bool resultado = false,
  DateTime? fecha,
  String local = 'a',
  String visitante = 'b',
  bool esBye = false,
}) {
  return PartidoModel.fromMap('p1', {
    'jornada': 1,
    'vuelta': 1,
    'equipoLocalId': local,
    'equipoLocalNombre': 'A',
    'equipoVisitanteId': visitante,
    'equipoVisitanteNombre': 'B',
    'estado': estado,
    'empate': false,
    'resultadoRegistrado': resultado,
    'generadoPorSistema': true,
    'tipoResultado': TipoResultado.normal,
    'esBye': esBye,
    'fechaHora': fecha,
  });
}

void main() {
  group('Etiquetas', () {
    test('usa tildes y el texto propio de cada valor', () {
      expect(Etiquetas.modalidad(ModalidadDeporte.volleySala), 'Vóley sala');
      expect(
        Etiquetas.tipoCampeonato(TipoCampeonato.gruposEliminacion),
        'Grupos + eliminación',
      );
      expect(
        Etiquetas.estadoCampeonato(CampeonatoEstado.inscripcion),
        'Inscripción',
      );
      expect(
        Etiquetas.estadoPartido(PartidoEstado.pendienteProgramacion),
        'Sin programar',
      );
      expect(Etiquetas.tipoResultado(TipoResultado.sancion), 'Sanción');
    });

    test('un valor desconocido se formatea en vez de mostrarse crudo', () {
      expect(Etiquetas.formatear('algo_nuevo'), 'Algo Nuevo');
      expect(Etiquetas.formatear('  '), 'No definido');
    });
  });

  group('mensajeDeError', () {
    test('saca el prefijo "Exception:"', () {
      expect(mensajeDeError(Exception('Falta el equipo.')), 'Falta el equipo.');
    });

    test('traduce los errores de Firebase', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'The caller does not have permission',
      );

      final texto = mensajeDeError(error);
      expect(texto, contains('No tienes permiso'));
      expect(texto, isNot(contains('cloud_firestore')));
    });
  });

  group('Pendientes de un partido', () {
    final ahora = DateTime(2026, 10, 3, 12);

    test('jugado sin resultado: falta cargarlo', () {
      final partido = _partido(fecha: DateTime(2026, 10, 2, 18));
      expect(partido.faltaResultado, isTrue);
      expect(partido.faltaResultadoAl(ahora), isTrue);
    });

    test('todavía no se jugó: no está atrasado', () {
      final partido = _partido(fecha: DateTime(2026, 10, 5, 18));
      expect(partido.faltaResultadoAl(ahora), isFalse);
    });

    test('con resultado no queda pendiente', () {
      final partido = _partido(
        resultado: true,
        estado: PartidoEstado.finalizado,
        fecha: DateTime(2026, 10, 2, 18),
      );
      expect(partido.faltaResultado, isFalse);
    });

    test('un cruce esperando al ganador de otra llave no cuenta', () {
      final partido = _partido(
        local: '',
        estado: PartidoEstado.pendienteProgramacion,
      );
      expect(partido.faltaResultado, isFalse);
      expect(partido.faltaProgramar, isFalse);
    });

    test('sin fecha: falta programarlo', () {
      final partido = _partido(estado: PartidoEstado.pendienteProgramacion);
      expect(partido.faltaProgramar, isTrue);
    });
  });
}
