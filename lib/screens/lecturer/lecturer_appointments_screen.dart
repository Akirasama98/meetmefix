import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/meeting_model.dart';
import '../../services/appointment_service.dart';
import 'lecturer_create_appointment_screen.dart';
import '../fixed_location_picker_screen.dart';

class LecturerAppointmentsScreen extends StatefulWidget {
  const LecturerAppointmentsScreen({super.key});

  @override
  State<LecturerAppointmentsScreen> createState() =>
      _LecturerAppointmentsScreenState();
}

class _LecturerAppointmentsScreenState extends State<LecturerAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  late TabController _tabController;
  bool _isLoading = true;
  List<MeetingModel> _allAppointments = [];
  List<MeetingModel> _pendingAppointments = [];
  List<MeetingModel> _approvedAppointments = [];
  List<MeetingModel> _historyAppointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ambil semua janji temu
      _appointmentService.getAppointments().listen((appointments) {
        if (mounted) {
          setState(() {
            _allAppointments = appointments;
            _isLoading = false;
          });
        }
      });

      // Ambil janji temu dengan status pending
      _appointmentService.getAppointmentsByStatus('pending').listen((
        appointments,
      ) {
        if (mounted) {
          setState(() {
            _pendingAppointments = appointments;
          });
        }
      });

      // Ambil janji temu dengan status approved
      _appointmentService.getAppointmentsByStatus('approved').listen((
        appointments,
      ) {
        if (mounted) {
          setState(() {
            _approvedAppointments = appointments;
          });
        }
      });

      // Ambil riwayat janji temu
      _appointmentService.getAppointmentHistory().listen((appointments) {
        if (mounted) {
          setState(() {
            _historyAppointments = appointments;
          });
        }
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Format tanggal dengan penanganan locale
  String formatDate(DateTime date, String format) {
    try {
      return DateFormat(format, 'id_ID').format(date);
    } catch (e) {
      // Fallback ke format default jika locale tidak tersedia
      return DateFormat(format).format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Janji Bimbingan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5BBFCB),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF5BBFCB),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Menunggu'),
            Tab(text: 'Disetujui'),
            Tab(text: 'Riwayat'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentList(_allAppointments),
                  _buildAppointmentList(_pendingAppointments),
                  _buildAppointmentList(_approvedAppointments),
                  _buildAppointmentList(_historyAppointments),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke halaman Buat Janji
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LecturerCreateAppointmentScreen(),
            ),
          );

          // Refresh data jika ada perubahan
          if (result == true) {
            _loadAppointments();
          }
        },
        backgroundColor: const Color(0xFF5BBFCB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppointmentList(List<MeetingModel> meetings) {
    if (meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Tidak ada janji bimbingan',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Kelompokkan janji berdasarkan tanggal
    final Map<String, List<MeetingModel>> groupedMeetings = {};
    for (var meeting in meetings) {
      final dateKey = formatDate(meeting.dateTime, 'yyyy-MM-dd');
      if (!groupedMeetings.containsKey(dateKey)) {
        groupedMeetings[dateKey] = [];
      }
      groupedMeetings[dateKey]!.add(meeting);
    }

    // Urutkan tanggal
    final sortedDates =
        groupedMeetings.keys.toList()..sort((a, b) => a.compareTo(b));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final meetingsForDate = groupedMeetings[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                formatDate(date, 'EEEE, d MMMM yyyy'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5BBFCB),
                ),
              ),
            ),
            ...meetingsForDate.map((meeting) => _buildAppointmentItem(meeting)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentItem(MeetingModel meeting) {
    Color statusColor;
    String statusText;
    String studentName =
        meeting.studentName ??
        'Mahasiswa ${meeting.studentId.replaceAll('student', '')}';

    switch (meeting.status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Disetujui';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Menunggu';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Selesai';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Tidak diketahui';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meeting.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  studentName,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  formatDate(meeting.dateTime, 'HH:mm'),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  meeting.location,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(meeting.description, style: const TextStyle(fontSize: 14)),
            if (meeting.status == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Tolak janji
                        _showRejectDialog(meeting);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Tolak'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Setujui janji
                        _showApproveDialog(meeting);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Setujui'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(MeetingModel meeting) {
    // Variables for location
    final TextEditingController locationController = TextEditingController(
      text: meeting.location,
    );
    double? latitude = meeting.latitude;
    double? longitude = meeting.longitude;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Setujui Janji'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apakah Anda yakin ingin menyetujui janji bimbingan dengan ${meeting.studentName ?? "Mahasiswa"}?',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tentukan lokasi bimbingan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Lokasi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: () async {
                          // Navigate to fixed location picker
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FixedLocationPickerScreen(
                                    initialLatitude: latitude,
                                    initialLongitude: longitude,
                                  ),
                            ),
                          );

                          // Update location if result is not null
                          if (result != null) {
                            locationController.text = result['address'];
                            latitude = result['latitude'];
                            longitude = result['longitude'];
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  // Simpan context sebelum async gap
                  final BuildContext dialogContext = context;

                  // Tutup dialog konfirmasi
                  Navigator.of(dialogContext).pop();

                  // Setujui janji dengan lokasi yang ditentukan
                  _approveAppointment(
                    meeting,
                    locationController.text,
                    latitude,
                    longitude,
                  );
                },
                child: const Text(
                  'Setujui',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _approveAppointment(
    MeetingModel meeting,
    String location,
    double? latitude,
    double? longitude,
  ) async {
    if (!mounted) return;

    try {
      // Update status janji di Firestore
      await _appointmentService.updateAppointmentStatus(meeting.id, 'approved');

      // Update lokasi janji di Firestore
      await _appointmentService.updateAppointmentLocation(
        meeting.id,
        location,
        latitude,
        longitude,
      );

      // Refresh data
      _loadAppointments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Janji bimbingan telah disetujui'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui janji: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(MeetingModel meeting) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tolak Janji'),
            content: Text(
              'Apakah Anda yakin ingin menolak janji bimbingan dengan ${meeting.studentName ?? "Mahasiswa"}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  // Simpan context sebelum async gap
                  final BuildContext dialogContext = context;

                  // Tutup dialog konfirmasi
                  Navigator.of(dialogContext).pop();

                  // Tolak janji
                  _rejectAppointment(meeting);
                },
                child: const Text('Tolak', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _rejectAppointment(MeetingModel meeting) async {
    if (!mounted) return;

    try {
      // Update status janji di Firestore
      await _appointmentService.updateAppointmentStatus(meeting.id, 'rejected');

      // Refresh data
      _loadAppointments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Janji bimbingan telah ditolak'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menolak janji: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
