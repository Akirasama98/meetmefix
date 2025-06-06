import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';

class ScheduleStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Timer? _statusCheckTimer;
  static bool _isInitialized = false;

  // Initialize the service and start periodic status checking
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    // Start periodic checking every 5 minutes
    _statusCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _checkAndUpdateLateAppointments(),
    );
    
    // Run initial check
    await _checkAndUpdateLateAppointments();
    
    print('ScheduleStatusService initialized');
  }

  // Stop the service
  static void dispose() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    _isInitialized = false;
    print('ScheduleStatusService disposed');
  }

  // Check and update appointments that should be marked as late
  static Future<void> _checkAndUpdateLateAppointments() async {
    try {
      final DateTime now = DateTime.now();
      
      // Calculate the cutoff time (1 hour ago)
      final DateTime cutoffTime = now.subtract(const Duration(hours: 1));
      
      // Query appointments that are approved but past the check-in deadline
      final QuerySnapshot snapshot = await _firestore
          .collection('appointments')
          .where('status', isEqualTo: 'approved')
          .where('dateTime', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('No appointments to mark as late');
        return;
      }
      
      // Batch update to mark appointments as late
      final WriteBatch batch = _firestore.batch();
      int updateCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final appointmentTime = (data['dateTime'] as Timestamp).toDate();
        
        // Double check: appointment should be more than 1 hour past due
        final Duration timePassed = now.difference(appointmentTime);
        
        if (timePassed.inHours >= 1) {
          batch.update(doc.reference, {
            'status': 'late',
            'markedLateAt': FieldValue.serverTimestamp(),
          });
          updateCount++;
          
          print('Marking appointment ${doc.id} as late (${timePassed.inHours} hours overdue)');
        }
      }
      
      if (updateCount > 0) {
        await batch.commit();
        print('Successfully marked $updateCount appointments as late');
      }
      
    } catch (e) {
      print('Error checking late appointments: $e');
    }
  }

  // Manual method to check and update a specific appointment
  static Future<bool> checkAndUpdateAppointmentStatus(String appointmentId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (!doc.exists) {
        print('Appointment $appointmentId not found');
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final String currentStatus = data['status'] ?? '';
      
      // Only check approved appointments
      if (currentStatus != 'approved') {
        return false;
      }
      
      final DateTime appointmentTime = (data['dateTime'] as Timestamp).toDate();
      final DateTime now = DateTime.now();
      final Duration timePassed = now.difference(appointmentTime);
      
      // If more than 1 hour has passed, mark as late
      if (timePassed.inHours >= 1) {
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': 'late',
          'markedLateAt': FieldValue.serverTimestamp(),
        });
        
        print('Appointment $appointmentId marked as late');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking appointment $appointmentId: $e');
      return false;
    }
  }

  // Get all late appointments for a specific user
  static Stream<List<MeetingModel>> getLateAppointments(String userId, {bool isLecturer = false}) {
    Query query;
    
    if (isLecturer) {
      query = _firestore
          .collection('appointments')
          .where('lecturerId', isEqualTo: userId)
          .where('status', isEqualTo: 'late')
          .orderBy('dateTime', descending: true);
    } else {
      query = _firestore
          .collection('appointments')
          .where('studentId', isEqualTo: userId)
          .where('status', isEqualTo: 'late')
          .orderBy('dateTime', descending: true);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MeetingModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Get statistics about late appointments
  static Future<Map<String, int>> getLateAppointmentStats(String userId, {bool isLecturer = false}) async {
    try {
      Query query;
      
      if (isLecturer) {
        query = _firestore
            .collection('appointments')
            .where('lecturerId', isEqualTo: userId)
            .where('status', isEqualTo: 'late');
      } else {
        query = _firestore
            .collection('appointments')
            .where('studentId', isEqualTo: userId)
            .where('status', isEqualTo: 'late');
      }
      
      final QuerySnapshot snapshot = await query.get();
      
      // Calculate stats
      final int totalLate = snapshot.docs.length;
      final DateTime now = DateTime.now();
      final DateTime thisMonth = DateTime(now.year, now.month, 1);
      
      int thisMonthLate = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime appointmentTime = (data['dateTime'] as Timestamp).toDate();
        
        if (appointmentTime.isAfter(thisMonth)) {
          thisMonthLate++;
        }
      }
      
      return {
        'total': totalLate,
        'thisMonth': thisMonthLate,
      };
    } catch (e) {
      print('Error getting late appointment stats: $e');
      return {'total': 0, 'thisMonth': 0};
    }
  }

  // Force check all appointments (useful for testing or manual trigger)
  static Future<void> forceCheckAllAppointments() async {
    print('Force checking all appointments...');
    await _checkAndUpdateLateAppointments();
  }
}
