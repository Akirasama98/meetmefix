import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class to initialize Firestore with sample data
class FirestoreInitializer {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firestore with sample users
  Future<void> initializeUsers() async {
    try {
      // Check if users collection already has data
      final usersSnapshot = await _firestore.collection('users').limit(1).get();
      if (usersSnapshot.docs.isNotEmpty) {
        print('Firestore already has user data. Skipping initialization.');
        return;
      }

      // Sample student accounts
      await _createUserWithEmailAndPassword(
        email: 'mahasiswa@example.com',
        password: 'password',
        userData: {
          'name': 'DWI RIFQI NOFRIANTO',
          'role': 'student',
          'nim': '232410102021',
          'department': 'Teknik Informatika',
          'faculty': 'Fakultas Ilmu Komputer',
          'phone': '+62 812-3456-7890',
          'photoUrl': 'https://randomuser.me/api/portraits/men/10.jpg',
        },
      );

      await _createUserWithEmailAndPassword(
        email: 'ahmad@example.com',
        password: 'password',
        userData: {
          'name': 'Ahmad Fauzi',
          'role': 'student',
          'nim': '232410102022',
          'department': 'Teknik Informatika',
          'faculty': 'Fakultas Ilmu Komputer',
          'phone': '+62 812-3456-7891',
          'photoUrl': 'https://randomuser.me/api/portraits/men/11.jpg',
        },
      );

      await _createUserWithEmailAndPassword(
        email: 'siti@example.com',
        password: 'password',
        userData: {
          'name': 'Siti Nurhaliza',
          'role': 'student',
          'nim': '232410102023',
          'department': 'Sistem Informasi',
          'faculty': 'Fakultas Ilmu Komputer',
          'phone': '+62 812-3456-7892',
          'photoUrl': 'https://randomuser.me/api/portraits/women/12.jpg',
        },
      );

      // Sample lecturer accounts
      await _createUserWithEmailAndPassword(
        email: 'dosen@example.com',
        password: 'password',
        userData: {
          'name': 'DR. PRIZA PANDUNATA',
          'role': 'lecturer',
          'nip': '198201182008121002',
          'department': 'Teknik Informatika',
          'faculty': 'Fakultas Ilmu Komputer',
          'phone': '+62 812-3456-7893',
          'photoUrl': 'https://randomuser.me/api/portraits/men/1.jpg',
        },
      );

      await _createUserWithEmailAndPassword(
        email: 'dwi@example.com',
        password: 'password',
        userData: {
          'name': 'DR. DWI WIJONARKO',
          'role': 'lecturer',
          'nip': '198201182008121003',
          'department': 'Teknik Informatika',
          'faculty': 'Fakultas Ilmu Komputer',
          'phone': '+62 812-3456-7894',
          'photoUrl': 'https://randomuser.me/api/portraits/men/2.jpg',
        },
      );

      await _createUserWithEmailAndPassword(
        email: 'budi@example.com',
        password: 'password',
        userData: {
          'name': 'DR. BUDI SANTOSO',
          'role': 'lecturer',
          'nip': '198201182008121004',
          'department': 'Sistem Informasi',
          'faculty': 'Fakultas Ilmu Komputer',
          'phone': '+62 812-3456-7895',
          'photoUrl': 'https://randomuser.me/api/portraits/men/3.jpg',
        },
      );

      print('Firestore initialized with sample users.');
    } catch (e) {
      print('Error initializing Firestore: $e');
    }
  }

  /// Create a user with email and password and store user data in Firestore
  Future<void> _createUserWithEmailAndPassword({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        ...userData,
        'email': email,
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('Email $email already exists. Skipping creation.');
      } else {
        rethrow;
      }
    }
  }
}
