import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';
import 'dart:math';
import '../models/meeting_model.dart';
import 'package:intl/intl.dart';

class ScheduleNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    // Initialize notification settings for Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize notification settings for iOS
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Initialize settings for all platforms
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    _initialized = true;
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? result =
          await androidImplementation?.requestNotificationsPermission();
      return result ?? false;
    }
    return false;
  }

  // Check if notification permissions are granted
  static Future<bool> checkNotificationPermissions() async {
    if (!_initialized) {
      await initialize();
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Pada Android 13+, kita bisa memeriksa status izin
      final bool? areNotificationsEnabled =
          await androidImplementation?.areNotificationsEnabled();
      return areNotificationsEnabled ?? false;
    } else if (Platform.isIOS) {
      // Pada iOS, kita tidak bisa memeriksa status izin secara langsung
      // Kita hanya bisa mencoba meminta izin dan melihat hasilnya
      return true; // Kita asumsikan izin diberikan pada iOS
    }

    return false;
  }

  // Check if notification permissions are granted and request if not
  static Future<void> checkAndRequestPermissions() async {
    if (!_initialized) {
      await initialize();
    }

    // Periksa status izin terlebih dahulu
    final bool permissionsEnabled = await checkNotificationPermissions();

    if (!permissionsEnabled) {
      // Jika izin belum diberikan, minta izin
      final bool permissionGranted = await requestPermissions();

      if (!permissionGranted) {
        // Jika izin tidak diberikan, tampilkan notifikasi untuk meminta izin
        print(
          'Notification permissions not granted. Please enable notifications for better experience.',
        );

        // Tampilkan notifikasi langsung untuk mengingatkan pengguna
        await showInstantNotification(
          title: 'Izin Notifikasi Diperlukan',
          body:
              'Mohon aktifkan izin notifikasi untuk mendapatkan pengingat jadwal bimbingan.',
        );
      } else {
        print('Notification permissions granted.');
      }
    } else {
      print('Notification permissions already granted.');
    }
  }

  // Schedule a notification for an upcoming appointment
  static Future<void> scheduleAppointmentNotification(
    MeetingModel meeting,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    // Request permissions
    final bool permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      print('Notification permissions not granted');
      return;
    }

    // Generate a unique ID for the notification
    final int notificationId = meeting.id.hashCode;

    // Create notification details for Android
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'meetme_schedule_channel',
          'Jadwal Bimbingan',
          channelDescription: 'Notifikasi untuk jadwal bimbingan',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF5BBFCB),
          styleInformation: BigTextStyleInformation(''),
        );

    // Create notification details for iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Create notification details for all platforms
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule notification 1 hour before the appointment
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      meeting.dateTime.subtract(const Duration(hours: 1)),
      tz.local,
    );

    // Only schedule if the appointment is in the future
    if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      // Format the time
      final String formattedTime = DateFormat(
        'HH:mm',
        'id_ID',
      ).format(meeting.dateTime);

      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        'Pengingat Jadwal Bimbingan',
        'Anda memiliki jadwal bimbingan "${meeting.title}" pada pukul $formattedTime di ${meeting.location}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: meeting.id,
      );

      print(
        'Scheduled notification for appointment: ${meeting.title} at ${meeting.dateTime}',
      );
    }
  }

  // Schedule notifications for multiple appointments
  static Future<void> scheduleAppointmentNotifications(
    List<MeetingModel> meetings,
  ) async {
    for (final meeting in meetings) {
      if (meeting.status == 'approved') {
        await scheduleAppointmentNotification(meeting);
      }
    }
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Show an immediate notification
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Request permissions
    final bool permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      print('Notification permissions not granted');
      return;
    }

    // Generate a random ID for the notification
    final int notificationId = Random().nextInt(100000);

    // Create notification details for Android
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'meetme_instant_channel',
          'Notifikasi Langsung',
          channelDescription: 'Notifikasi langsung untuk aplikasi MeetMe',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF5BBFCB),
        );

    // Create notification details for iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Create notification details for all platforms
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show the notification
    await _notifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Schedule a notification for a specific time
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Request permissions
    final bool permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      print('Notification permissions not granted');
      return;
    }

    // Generate a random ID for the notification
    final int notificationId = Random().nextInt(100000);

    // Create notification details for Android
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'meetme_scheduled_channel',
          'Notifikasi Terjadwal',
          channelDescription: 'Notifikasi terjadwal untuk aplikasi MeetMe',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF5BBFCB),
        );

    // Create notification details for iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Create notification details for all platforms
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert to TZ DateTime
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    // Schedule the notification
    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    print('Scheduled notification for: $scheduledTime');
  }
}
