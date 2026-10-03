import 'package:firebase_core/firebase_core.dart';

/// El texto de un error listo para mostrarle al usuario.
///
/// Los servicios avisan de los problemas con `throw Exception('...')`, y
/// al pasar eso a texto Dart le antepone "Exception: ". Acá se saca ese
/// prefijo, que no le dice nada a quien usa la app.
///
/// Los errores de Firebase llegan como
/// "[cloud_firestore/permission-denied] The caller does not have...":
/// en inglés y con el código adelante. Se traducen a algo que se
/// entienda y que diga qué hacer.
String mensajeDeError(Object error) {
  if (error is FirebaseException) {
    return _mensajeFirebase(error.code);
  }

  return error.toString().replaceAll('Exception:', '').trim();
}

String _mensajeFirebase(String code) {
  switch (code) {
    case 'permission-denied':
    case 'unauthenticated':
      return 'No tienes permiso para hacer esto. Vuelve a iniciar sesión como administrador.';
    case 'unavailable':
    case 'deadline-exceeded':
      return 'No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.';
    case 'not-found':
      return 'Ese dato ya no existe: puede que alguien lo haya borrado.';
    case 'already-exists':
      return 'Ese dato ya existe.';
    case 'failed-precondition':
      return 'La consulta todavía no está lista en el servidor. Inténtalo de nuevo en unos minutos.';
    case 'resource-exhausted':
      return 'Se alcanzó el límite de uso del servidor por hoy. Inténtalo más tarde.';
    case 'network-request-failed':
      return 'No hay conexión. Revisa tu internet e inténtalo de nuevo.';
    case 'wrong-password':
    case 'invalid-credential':
    case 'user-not-found':
    case 'invalid-email':
      return 'Correo o contraseña incorrectos.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espera un momento antes de volver a probar.';
    default:
      return 'Ocurrió un error inesperado ($code). Inténtalo de nuevo.';
  }
}
