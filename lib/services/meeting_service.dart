import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';

class MeetingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'meetings';

  // Mendapatkan semua jadwal pertemuan untuk mahasiswa tertentu
  Stream<List<MeetingModel>> getStudentMeetings(String studentId) {
    return _firestore
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MeetingModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Mendapatkan semua jadwal pertemuan untuk dosen tertentu
  Stream<List<MeetingModel>> getLecturerMeetings(String lecturerId) {
    return _firestore
        .collection(_collection)
        .where('lecturerId', isEqualTo: lecturerId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MeetingModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Membuat jadwal pertemuan baru
  Future<String> createMeeting(MeetingModel meeting) async {
    try {
      DocumentReference docRef =
          await _firestore.collection(_collection).add(meeting.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Memperbarui status jadwal pertemuan
  Future<void> updateMeetingStatus(String meetingId, String status) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(meetingId)
          .update({'status': status});
    } catch (e) {
      rethrow;
    }
  }

  // Menghapus jadwal pertemuan
  Future<void> deleteMeeting(String meetingId) async {
    try {
      await _firestore.collection(_collection).doc(meetingId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
