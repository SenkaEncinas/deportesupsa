import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/admin_model.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _admins =>
      _db.collection('admins');

  Stream<User?> get authChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('No se pudo iniciar sesión.');
    }

    final esAdmin = await esAdminActivo(user.uid);
    if (!esAdmin) {
      await _auth.signOut();
      throw Exception('Esta cuenta no tiene permisos de administrador.');
    }

    await actualizarUltimaConexion(user.uid);

    return credential;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> esAdminActivo([String? uid]) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _admins.doc(userId).get();
    if (!doc.exists) return false;

    final data = doc.data();
    if (data == null) return false;

    return data['activo'] == true;
  }

  Future<AdminModel?> getAdminActual() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _admins.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;

    return AdminModel.fromMap(doc.id, doc.data()!);
  }

  Stream<AdminModel?> adminActualStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<AdminModel?>.value(null);
      }

      return _admins.doc(user.uid).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return AdminModel.fromMap(doc.id, doc.data()!);
      });
    });
  }

  Future<AdminModel> requireAdmin() async {
    final admin = await getAdminActual();

    if (admin == null || !admin.activo) {
      throw Exception('No tienes permisos de administrador.');
    }

    return admin;
  }

  Future<void> actualizarUltimaConexion(String uid) async {
    await _admins.doc(uid).set({
      'ultimaConexion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
