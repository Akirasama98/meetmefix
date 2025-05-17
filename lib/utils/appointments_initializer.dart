import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility class untuk menginisialisasi data janji temu di Firestore
class AppointmentsInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inisialisasi collection appointments dengan data sample
  Future<void> initializeAppointments() async {
    try {
      // Cek apakah collection appointments sudah ada data
      final appointmentsSnapshot = await _firestore.collection('appointments').limit(1).get();
      if (appointmentsSnapshot.docs.isNotEmpty) {
        print('Collection appointments sudah memiliki data. Melewati inisialisasi.');
        return;
      }

      // Dapatkan daftar user dari Firestore
      final usersSnapshot = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> users = [];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        users.add({
          'id': doc.id,
          'name': data['name'] ?? '',
          'role': data['role'] ?? '',
        });
      }

      // Filter daftar mahasiswa dan dosen
      final students = users.where((user) => user['role'] == 'student').toList();
      final lecturers = users.where((user) => user['role'] == 'lecturer').toList();

      // Jika tidak ada user, buat data dummy
      if (students.isEmpty || lecturers.isEmpty) {
        print('Tidak ada data user yang cukup. Membuat data dummy...');
        await _createDummyAppointments();
        return;
      }

      // Buat janji temu untuk setiap mahasiswa dengan beberapa dosen
      for (var student in students) {
        // Pilih 2 dosen secara acak (atau semua jika kurang dari 2)
        final selectedLecturers = lecturers.length > 2 
            ? lecturers.sublist(0, 2) 
            : lecturers;
        
        for (var lecturer in selectedLecturers) {
          // Buat 2 janji temu untuk setiap pasangan mahasiswa-dosen
          await _createAppointment(
            studentId: student['id'],
            studentName: student['name'],
            lecturerId: lecturer['id'],
            lecturerName: lecturer['name'],
            title: 'Bimbingan Skripsi',
            description: 'Diskusi tentang proposal penelitian',
            dateTime: DateTime.now().add(Duration(days: 1, hours: 2)),
            location: 'Ruang Dosen 101',
            status: 'approved',
          );
          
          await _createAppointment(
            studentId: student['id'],
            studentName: student['name'],
            lecturerId: lecturer['id'],
            lecturerName: lecturer['name'],
            title: 'Konsultasi KRS',
            description: 'Pemilihan mata kuliah semester depan',
            dateTime: DateTime.now().add(Duration(days: 2)),
            location: 'Online via Zoom',
            status: 'pending',
          );
        }
      }

      print('Inisialisasi appointments berhasil.');
    } catch (e) {
      print('Error inisialisasi appointments: $e');
    }
  }

  /// Membuat data janji temu dummy jika tidak ada user
  Future<void> _createDummyAppointments() async {
    try {
      // Buat beberapa janji temu dummy
      await _firestore.collection('appointments').add({
        'title': 'Bimbingan Skripsi',
        'description': 'Diskusi tentang bab 1 dan 2',
        'dateTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))),
        'location': 'Ruang Dosen 101',
        'lecturerId': 'lecturer1',
        'lecturerName': 'DR. PRIZA PANDUNATA',
        'studentId': 'student1',
        'studentName': 'DWI RIFQI NOFRIANTO',
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('appointments').add({
        'title': 'Konsultasi KRS',
        'description': 'Pemilihan mata kuliah semester depan',
        'dateTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 1))),
        'location': 'Online via Zoom',
        'lecturerId': 'lecturer2',
        'lecturerName': 'DR. DWI WIJONARKO',
        'studentId': 'student1',
        'studentName': 'DWI RIFQI NOFRIANTO',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('appointments').add({
        'title': 'Review Tugas Akhir',
        'description': 'Evaluasi progress tugas akhir',
        'dateTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 2))),
        'location': 'Ruang Rapat Fakultas',
        'lecturerId': 'lecturer1',
        'lecturerName': 'DR. PRIZA PANDUNATA',
        'studentId': 'student1',
        'studentName': 'DWI RIFQI NOFRIANTO',
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Data dummy appointments berhasil dibuat.');
    } catch (e) {
      print('Error membuat data dummy appointments: $e');
    }
  }

  /// Membuat satu janji temu
  Future<void> _createAppointment({
    required String studentId,
    required String studentName,
    required String lecturerId,
    required String lecturerName,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required String status,
  }) async {
    try {
      await _firestore.collection('appointments').add({
        'title': title,
        'description': description,
        'dateTime': Timestamp.fromDate(dateTime),
        'location': location,
        'lecturerId': lecturerId,
        'lecturerName': lecturerName,
        'studentId': studentId,
        'studentName': studentName,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error membuat appointment: $e');
    }
  }
}
