/// El texto de un error listo para mostrarle al usuario.
///
/// Los servicios avisan de los problemas con `throw Exception('...')`, y
/// al pasar eso a texto Dart le antepone "Exception: ". Acá se saca ese
/// prefijo, que no le dice nada a quien usa la app.
String mensajeDeError(Object error) {
  return error.toString().replaceAll('Exception:', '').trim();
}
