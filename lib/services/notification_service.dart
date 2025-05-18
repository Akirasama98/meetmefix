import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission for iOS
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Background message handler is registered in main.dart

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      // Kita tidak menggunakan flutter_local_notifications lagi
      // Notifikasi akan ditampilkan oleh sistem Android/iOS
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap
      print('Notification tapped: ${message.data}');
    });

    // Tambahkan ini untuk menangani refresh token
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        saveTokenToDatabase(currentUser.uid, token);
      }
    });
  }

  // Get FCM token for this device
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Save token to user document in Firestore
  static Future<void> saveTokenToDatabase(String userId, String? token) async {
    if (token == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });

      print('FCM Token berhasil disimpan untuk user: $userId');
    } catch (e) {
      print('Error menyimpan FCM token: $e');
    }
  }
}
