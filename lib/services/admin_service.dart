import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_model.dart';

class AdminService {
  AdminService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _admins =>
      _db.collection('admins');

  Stream<List<AdminModel>> streamAdmins() {
    return _admins.orderBy('nombre').snapshots().map((snap) {
      return snap.docs.map((doc) {
        return AdminModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<AdminModel?> getAdmin(String uid) async {
    final doc = await _admins.doc(uid).get();

    if (!doc.exists || doc.data() == null) return null;

    return AdminModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> guardarAdmin({
    required String uid,
    required String nombre,
    required String email,
    bool activo = true,
  }) async {
    final docRef = _admins.doc(uid);
    final actual = await docRef.get();

    final data = {
      'nombre': nombre.trim(),
      'email': email.trim(),
      'activo': activo,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };

    if (!actual.exists) {
      data['fechaCreacion'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  Future<void> cambiarEstadoAdmin({
    required String uid,
    required bool activo,
  }) async {
    await _admins.doc(uid).update({
      'activo': activo,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }
}