import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String lecturerId;
  final String studentId;
  String
  status; // 'pending', 'approved', 'rejected', 'completed', 'checked-in', 'late'
  final String? lecturerName; // Nama dosen
  final String? studentName; // Nama mahasiswa
  final DateTime? createdAt; // Waktu pembuatan
  double? latitude; // Koordinat latitude lokasi
  double? longitude; // Koordinat longitude lokasi
  String? attendancePhotoUrl; // URL foto kehadiran
  DateTime? attendancePhotoTimestamp; // Waktu pengambilan foto kehadiran
  DateTime? checkedInAt; // Waktu check-in
  DateTime? completedAt; // Waktu selesai bimbingan

  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.lecturerId,
    required this.studentId,
    required this.status,
    this.lecturerName,
    this.studentName,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.attendancePhotoUrl,
    this.attendancePhotoTimestamp,
    this.checkedInAt,
    this.completedAt,
  });

  // Konversi dari Firestore document ke MeetingModel
  factory MeetingModel.fromMap(Map<String, dynamic> map, String id) {
    // Konversi Timestamp ke DateTime
    DateTime dateTime;
    if (map['dateTime'] is Timestamp) {
      dateTime = (map['dateTime'] as Timestamp).toDate();
    } else {
      dateTime = DateTime.now();
    }

    // Konversi createdAt
    DateTime? createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    }

    // Konversi attendancePhotoTimestamp
    DateTime? attendancePhotoTimestamp;
    if (map['attendancePhotoTimestamp'] is Timestamp) {
      attendancePhotoTimestamp =
          (map['attendancePhotoTimestamp'] as Timestamp).toDate();
    }

    // Konversi checkedInAt
    DateTime? checkedInAt;
    if (map['checkedInAt'] is Timestamp) {
      checkedInAt = (map['checkedInAt'] as Timestamp).toDate();
    }

    // Konversi completedAt
    DateTime? completedAt;
    if (map['completedAt'] is Timestamp) {
      completedAt = (map['completedAt'] as Timestamp).toDate();
    }

    return MeetingModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: dateTime,
      location: map['location'] ?? '',
      lecturerId: map['lecturerId'] ?? '',
      studentId: map['studentId'] ?? '',
      status: map['status'] ?? 'pending',
      lecturerName: map['lecturerName'],
      studentName: map['studentName'],
      createdAt: createdAt,
      latitude:
          map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude:
          map['longitude'] != null
              ? (map['longitude'] as num).toDouble()
              : null,
      attendancePhotoUrl: map['attendancePhotoUrl'],
      attendancePhotoTimestamp: attendancePhotoTimestamp,
      checkedInAt: checkedInAt,
      completedAt: completedAt,
    );
  }

  // Konversi dari MeetingModel ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'lecturerId': lecturerId,
      'studentId': studentId,
      'status': status,
      'lecturerName': lecturerName,
      'studentName': studentName,
      'latitude': latitude,
      'longitude': longitude,
      'attendancePhotoUrl': attendancePhotoUrl,
      'attendancePhotoTimestamp':
          attendancePhotoTimestamp != null
              ? Timestamp.fromDate(attendancePhotoTimestamp!)
              : null,
      'checkedInAt':
          checkedInAt != null ? Timestamp.fromDate(checkedInAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
    };
  }
}
