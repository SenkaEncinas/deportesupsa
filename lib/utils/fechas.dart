/// Formatos de fecha de la app.
///
/// Todos se arman igual (día y mes con dos dígitos, hora de 24 horas):
/// entre una pantalla y otra lo único que cambia es qué pedazos se
/// muestran y con qué se separan. Antes cada pantalla tenía su propia
/// copia de este armado.
class Fechas {
  Fechas._();

  static String _dos(int numero) => numero.toString().padLeft(2, '0');

  /// `05/10/2026`
  static String dia(DateTime fecha) {
    return '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year}';
  }

  /// `2026-10-05`: sirve de clave para agrupar por día, porque ordena
  /// bien como texto.
  static String clave(DateTime fecha) {
    return '${fecha.year}-${_dos(fecha.month)}-${_dos(fecha.day)}';
  }

  /// `05/10`
  static String diaCorto(DateTime fecha) {
    return '${_dos(fecha.day)}/${_dos(fecha.month)}';
  }

  /// `18:30`
  static String hora(DateTime fecha) {
    return '${_dos(fecha.hour)}:${_dos(fecha.minute)}';
  }

  /// `05/10/2026 18:30`, o con el [separador] que se pida entre la fecha
  /// y la hora.
  static String diaYHora(DateTime fecha, {String separador = ' '}) {
    return '${dia(fecha)}$separador${hora(fecha)}';
  }
}
