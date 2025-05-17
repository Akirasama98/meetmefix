import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan semua janji temu untuk pengguna saat ini (mahasiswa atau dosen)
  Stream<List<MeetingModel>> getAppointments() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .asStream()
        .asyncMap((userDoc) async {
          if (!userDoc.exists) {
            return [];
          }

          final userData = userDoc.data() as Map<String, dynamic>;
          final String role = userData['role'] ?? '';

          Query query;
          if (role == 'student') {
            query = _firestore
                .collection('appointments')
                .where('studentId', isEqualTo: user.uid);
          } else {
            query = _firestore
                .collection('appointments')
                .where('lecturerId', isEqualTo: user.uid);
          }

          final snapshot = await query.get();
          return snapshot.docs.map((doc) {
            return MeetingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // Mendapatkan janji temu berdasarkan status
  Stream<List<MeetingModel>> getAppointmentsByStatus(String status) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .asStream()
        .asyncMap((userDoc) async {
          if (!userDoc.exists) {
            return [];
          }

          final userData = userDoc.data() as Map<String, dynamic>;
          final String role = userData['role'] ?? '';

          Query query;
          if (role == 'student') {
            query = _firestore
                .collection('appointments')
                .where('studentId', isEqualTo: user.uid)
                .where('status', isEqualTo: status);
          } else {
            query = _firestore
                .collection('appointments')
                .where('lecturerId', isEqualTo: user.uid)
                .where('status', isEqualTo: status);
          }

          final snapshot = await query.get();
          return snapshot.docs.map((doc) {
            return MeetingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // Mendapatkan riwayat janji temu (completed atau rejected)
  Stream<List<MeetingModel>> getAppointmentHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .asStream()
        .asyncMap((userDoc) async {
          if (!userDoc.exists) {
            return [];
          }

          final userData = userDoc.data() as Map<String, dynamic>;
          final String role = userData['role'] ?? '';

          List<QuerySnapshot> snapshots = [];
          if (role == 'student') {
            // Ambil janji temu dengan status completed
            final completedSnapshot =
                await _firestore
                    .collection('appointments')
                    .where('studentId', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'completed')
                    .get();
            snapshots.add(completedSnapshot);

            // Ambil janji temu dengan status rejected
            final rejectedSnapshot =
                await _firestore
                    .collection('appointments')
                    .where('studentId', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'rejected')
                    .get();
            snapshots.add(rejectedSnapshot);
          } else {
            // Ambil janji temu dengan status completed
            final completedSnapshot =
                await _firestore
                    .collection('appointments')
                    .where('lecturerId', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'completed')
                    .get();
            snapshots.add(completedSnapshot);

            // Ambil janji temu dengan status rejected
            final rejectedSnapshot =
                await _firestore
                    .collection('appointments')
                    .where('lecturerId', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'rejected')
                    .get();
            snapshots.add(rejectedSnapshot);
          }

          // Gabungkan hasil query
          List<MeetingModel> meetings = [];
          for (var snapshot in snapshots) {
            meetings.addAll(
              snapshot.docs.map((doc) {
                return MeetingModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              }),
            );
          }
          return meetings;
        });
  }

  // Memeriksa apakah ada jadwal yang bentrok
  Future<bool> hasConflictingAppointment(
    String userId, 
    DateTime dateTime,
    {bool isLecturer = false}
  ) async {
    // Tentukan rentang waktu untuk memeriksa bentrok (1 jam)
    final DateTime startTime = dateTime;
    final DateTime endTime = dateTime.add(const Duration(hours: 1));
    
    // Query untuk memeriksa jadwal yang bentrok
    Query query;
    if (isLecturer) {
      query = _firestore
          .collection('appointments')
          .where('lecturerId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'approved', 'checked-in']);
    } else {
      query = _firestore
          .collection('appointments')
          .where('studentId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'approved', 'checked-in']);
    }
    
    final snapshot = await query.get();
    
    // Periksa apakah ada jadwal yang bentrok
    for (var doc in snapshot.docs) {
      final appointmentData = doc.data() as Map<String, dynamic>;
      final appointmentDateTime = (appointmentData['dateTime'] as Timestamp).toDate();
      
      // Jadwal bentrok jika berada dalam rentang waktu yang sama
      if (appointmentDateTime.isAfter(startTime.subtract(const Duration(hours: 1))) && 
          appointmentDateTime.isBefore(endTime)) {
        return true; // Ada jadwal yang bentrok
      }
    }
    
    return false; // Tidak ada jadwal yang bentrok
  }

  // Membuat janji temu baru
  Future<void> createAppointment({
    required String lecturerId,
    required String lecturerName,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Periksa apakah mahasiswa sudah memiliki jadwal di waktu yang sama
    final bool studentHasConflict = await hasConflictingAppointment(user.uid, dateTime);
    if (studentHasConflict) {
      throw Exception('Anda sudah memiliki jadwal bimbingan di waktu yang sama');
    }
    
    // Periksa apakah dosen sudah memiliki jadwal di waktu yang sama
    final bool lecturerHasConflict = await hasConflictingAppointment(lecturerId, dateTime, isLecturer: true);
    if (lecturerHasConflict) {
      throw Exception('Dosen sudah memiliki jadwal bimbingan di waktu yang sama');
    }

    // Dapatkan data mahasiswa
    final studentDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!studentDoc.exists) {
      throw Exception('Student data not found');
    }

    final studentData = studentDoc.data() as Map<String, dynamic>;
    final String studentName = studentData['name'] ?? 'Unknown Student';

    // Buat janji temu baru
    await _firestore.collection('appointments').add({
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'studentId': user.uid,
      'studentName': studentName,
      'status': 'pending',
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Membuat janji temu oleh dosen
  Future<void> createAppointmentByLecturer({
    required String studentId,
    required String studentName,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Periksa apakah dosen sudah memiliki jadwal di waktu yang sama
    final bool lecturerHasConflict = await hasConflictingAppointment(user.uid, dateTime, isLecturer: true);
    if (lecturerHasConflict) {
      throw Exception('Anda sudah memiliki jadwal bimbingan di waktu yang sama');
    }
    
    // Periksa apakah mahasiswa sudah memiliki jadwal di waktu yang sama
    final bool studentHasConflict = await hasConflictingAppointment(studentId, dateTime);
    if (studentHasConflict) {
      throw Exception('Mahasiswa sudah memiliki jadwal bimbingan di waktu yang sama');
    }

    // Dapatkan data dosen
    final lecturerDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!lecturerDoc.exists) {
      throw Exception('Lecturer data not found');
    }

    final lecturerData = lecturerDoc.data() as Map<String, dynamic>;
    final String lecturerName = lecturerData['name'] ?? 'Unknown Lecturer';

    // Buat janji temu baru (langsung approved karena dibuat oleh dosen)
    await _firestore.collection('appointments').add({
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'lecturerId': user.uid,
      'lecturerName': lecturerName,
      'studentId': studentId,
      'studentName': studentName,
      'status': 'approved', // Langsung disetujui
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Mengubah status janji temu
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mengubah lokasi janji temu
  Future<void> updateAppointmentLocation(
    String appointmentId,
    String location,
    double? latitude,
    double? longitude,
  ) async {
    final Map<String, dynamic> updateData = {
      'location': location,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (latitude != null) {
      updateData['latitude'] = latitude;
    }

    if (longitude != null) {
      updateData['longitude'] = longitude;
    }

    await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .update(updateData);
  }

  // Mendapatkan daftar dosen
  Future<List<Map<String, dynamic>>> getLecturers() async {
    final snapshot =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: 'lecturer')
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'department': data['department'] ?? '',
        'faculty': data['faculty'] ?? '',
      };
    }).toList();
  }

  // Mendapatkan daftar mahasiswa
  Future<List<Map<String, dynamic>>> getStudents() async {
    final snapshot =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'nim': data['nim'] ?? '',
        'department': data['department'] ?? '',
      };
    }).toList();
  }

  // Melakukan check-in untuk janji temu
  Future<bool> checkInAppointment(
    String appointmentId,
    double currentLatitude,
    double currentLongitude,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get the appointment
    final appointmentDoc =
        await _firestore.collection('appointments').doc(appointmentId).get();
    if (!appointmentDoc.exists) {
      throw Exception('Appointment not found');
    }

    final appointmentData = appointmentDoc.data() as Map<String, dynamic>;

    // Check if the appointment is approved
    if (appointmentData['status'] != 'approved') {
      throw Exception('Appointment is not approved');
    }

    // Check if the appointment belongs to the current user
    if (appointmentData['studentId'] != user.uid) {
      throw Exception('This appointment does not belong to you');
    }
    
    // Validasi waktu check-in
    final DateTime appointmentTime = (appointmentData['dateTime'] as Timestamp).toDate();
    final DateTime now = DateTime.now();
    
    // Hanya boleh check-in 15 menit sebelum hingga 15 menit setelah waktu janji
    final DateTime earliestCheckIn = appointmentTime.subtract(const Duration(minutes: 15));
    final DateTime latestCheckIn = appointmentTime.add(const Duration(minutes: 15));
    
    if (now.isBefore(earliestCheckIn)) {
      throw Exception('Terlalu dini untuk check-in. Anda dapat check-in 15 menit sebelum waktu janji.');
    }
    
    if (now.isAfter(latestCheckIn)) {
      throw Exception('Waktu check-in telah berakhir. Batas check-in adalah 15 menit setelah waktu janji.');
    }

    // Check if the appointment has location data
    final double? appointmentLatitude =
        appointmentData['latitude'] != null
            ? (appointmentData['latitude'] as num).toDouble()
            : null;
    final double? appointmentLongitude =
        appointmentData['longitude'] != null
            ? (appointmentData['longitude'] as num).toDouble()
            : null;

    if (appointmentLatitude == null || appointmentLongitude == null) {
      throw Exception('Appointment location is not set');
    }

    // Calculate distance between current location and appointment location
    final double distance = _calculateDistance(
      currentLatitude,
      currentLongitude,
      appointmentLatitude,
      appointmentLongitude,
    );

    // If distance is less than 100 meters, allow check-in
    final bool isNearby = distance <= 100; // 100 meters radius

    if (isNearby) {
      // Update appointment status to 'checked-in'
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'checked-in',
        'checkedInAt': FieldValue.serverTimestamp(),
        'checkedInLatitude': currentLatitude,
        'checkedInLongitude': currentLongitude,
      });
      return true;
    } else {
      // Not close enough to check in
      return false;
    }
  }

  // Calculate distance between two coordinates in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Menyelesaikan janji temu (menandai sebagai completed)
  Future<void> completeAppointment(String appointmentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get the appointment
    final appointmentDoc = 
        await _firestore.collection('appointments').doc(appointmentId).get();
    if (!appointmentDoc.exists) {
      throw Exception('Appointment not found');
    }

    final appointmentData = appointmentDoc.data() as Map<String, dynamic>;

    // Hanya dosen yang bisa menyelesaikan janji temu
    if (appointmentData['lecturerId'] != user.uid) {
      throw Exception('Only lecturers can complete appointments');
    }

    // Hanya janji temu dengan status checked-in yang bisa diselesaikan
    if (appointmentData['status'] != 'checked-in') {
      throw Exception('Only checked-in appointments can be completed');
    }

    // Update status janji temu menjadi completed
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}




