import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Konversi foto ke Base64 string
  Future<String> uploadAttendancePhoto(File photo, String appointmentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Baca file sebagai bytes
      final List<int> imageBytes = await photo.readAsBytes();

      // Konversi bytes ke Base64 string
      final String base64Image = base64Encode(imageBytes);

      // Tambahkan prefix untuk menunjukkan bahwa ini adalah gambar JPEG
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      throw Exception('Failed to encode attendance photo: $e');
    }
  }

  // Tidak perlu menghapus foto karena disimpan di Firestore
  // Method ini tetap ada untuk kompatibilitas
  Future<void> deleteAttendancePhoto(String photoBase64) async {
    // Tidak perlu melakukan apa-apa karena foto disimpan di Firestore
    // dan akan dihapus bersama dengan dokumen appointment
  }

  // Konversi Base64 string ke Image widget
  // Method ini bisa digunakan untuk menampilkan foto dari Base64 string
  static Uint8List? base64ToImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }

    try {
      // Hapus prefix jika ada
      String pureBase64 = base64String;
      if (base64String.contains(';base64,')) {
        pureBase64 = base64String.split(';base64,')[1];
      }

      // Decode Base64 string ke bytes
      return base64Decode(pureBase64);
    } catch (e) {
      // Silently handle error and return null
      return null;
    }
  }
}
