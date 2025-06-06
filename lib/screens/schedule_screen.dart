import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/appointment_service.dart';
import '../services/schedule_status_service.dart';
import '../models/meeting_model.dart';
import 'create_appointment_screen.dart';
import 'appointment_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  late TabController _tabController;
  bool _isLoading = true;
  List<MeetingModel> _allAppointments = [];
  List<MeetingModel> _pendingAppointments = [];
  List<MeetingModel> _approvedAppointments = [];
  List<MeetingModel> _historyAppointments = [];
  List<MeetingModel> _lateAppointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      // Ambil janji temu dengan status late
      _appointmentService.getAppointmentsByStatus('late').listen((
        appointments,
      ) {
        if (mounted) {
          setState(() {
            _lateAppointments = appointments;
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
            Tab(text: 'Terlambat'),
            Tab(text: 'Riwayat'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Force check status terlebih dahulu
              await ScheduleStatusService.forceCheckAllAppointments();
              // Kemudian refresh data
              _loadAppointments();
            },
            tooltip: 'Refresh & Check Status',
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
                  _buildAppointmentList(_lateAppointments),
                  _buildAppointmentList(_historyAppointments),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke halaman Buat Janji
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAppointmentScreen(),
            ),
          );

          // Refresh data jika ada perubahan
          if (result == true) {
            _loadAppointments();
          }
        },
        backgroundColor: const Color(0xFF5BBFCB),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppointmentList(List<MeetingModel> appointments) {
    if (appointments.isEmpty) {
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
    final Map<String, List<MeetingModel>> groupedAppointments = {};
    for (var appointment in appointments) {
      final dateKey = formatDate(appointment.dateTime, 'yyyy-MM-dd');
      if (!groupedAppointments.containsKey(dateKey)) {
        groupedAppointments[dateKey] = [];
      }
      groupedAppointments[dateKey]!.add(appointment);
    }

    // Urutkan tanggal
    final sortedDates =
        groupedAppointments.keys.toList()..sort((a, b) => a.compareTo(b));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final appointmentsForDate = groupedAppointments[dateKey]!;
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
            ...appointmentsForDate.map(
              (appointment) => _buildAppointmentItem(appointment),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentItem(MeetingModel appointment) {
    Color statusColor;
    String statusText;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    final bool isStudent = user?.role == 'student';

    // Menentukan nama yang ditampilkan (dosen atau mahasiswa)
    String partnerName = '';
    if (isStudent) {
      partnerName = appointment.lecturerName ?? 'Dosen';
    } else {
      partnerName = appointment.studentName ?? 'Mahasiswa';
    }

    switch (appointment.status) {
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
      case 'checked-in':
        statusColor = Colors.purple;
        statusText = 'Sudah Check-in';
        break;
      case 'late':
        statusColor = Colors.red.shade700;
        statusText = 'Terlambat';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Tidak diketahui';
    }

    return InkWell(
      onTap:
          isStudent
              ? () {
                // Navigate to appointment detail screen (only for students)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AppointmentDetailScreen(appointment: appointment),
                  ),
                ).then((_) {
                  // Refresh data when returning from detail screen
                  _loadAppointments();
                });
              }
              : null,
      child: Card(
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
                  Expanded(
                    child: Text(
                      appointment.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  Expanded(
                    child: Text(
                      partnerName,
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(appointment.dateTime, 'HH:mm'),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment.location,
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                appointment.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
