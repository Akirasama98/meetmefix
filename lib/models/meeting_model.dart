import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String lecturerId;
  final String studentId;
  String status; // 'pending', 'approved', 'rejected', 'completed', 'checked-in'
  final String? lecturerName; // Nama dosen
  final String? studentName; // Nama mahasiswa
  final DateTime? createdAt; // Waktu pembuatan
  double? latitude; // Koordinat latitude lokasi
  double? longitude; // Koordinat longitude lokasi

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
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
    };
  }
}
