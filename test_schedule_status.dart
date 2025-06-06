import 'package:flutter/material.dart';
import 'lib/services/schedule_status_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Testing ScheduleStatusService...');
  
  try {
    // Test initialization
    await ScheduleStatusService.initialize();
    print('✓ Service initialized successfully');
    
    // Test force check
    await ScheduleStatusService.forceCheckAllAppointments();
    print('✓ Force check completed successfully');
    
    // Test dispose
    ScheduleStatusService.dispose();
    print('✓ Service disposed successfully');
    
    print('All tests passed!');
  } catch (e) {
    print('✗ Error: $e');
  }
}
