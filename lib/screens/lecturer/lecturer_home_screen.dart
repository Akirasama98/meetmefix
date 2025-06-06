import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/meeting_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import '../../services/storage_service.dart';
import '../../services/schedule_notification_service.dart';

class LecturerHomeScreen extends StatefulWidget {
  const LecturerHomeScreen({super.key});

  @override
  State<LecturerHomeScreen> createState() => _LecturerHomeScreenState();
}

class _LecturerHomeScreenState extends State<LecturerHomeScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<MeetingModel> _meetings = [];
  // State untuk tanggal awal minggu yang ditampilkan
  late DateTime _weekStartDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // Inisialisasi tanggal awal minggu (Senin dari minggu saat ini)
    final now = DateTime.now();
    // Mendapatkan hari dalam seminggu (1-7, dengan 1 = Senin, 7 = Minggu)
    final weekday = now.weekday;
    // Menghitung tanggal Senin dari minggu saat ini
    _weekStartDate = now.subtract(Duration(days: weekday - 1));

    // Inisialisasi layanan notifikasi jadwal
    _initializeNotifications();

    _fetchMeetings();
  }

  // Inisialisasi layanan notifikasi
  Future<void> _initializeNotifications() async {
    try {
      // Inisialisasi layanan notifikasi jadwal
      await ScheduleNotificationService.initialize();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Fungsi untuk navigasi ke minggu sebelumnya
  void _previousWeek() {
    setState(() {
      _weekStartDate = _weekStartDate.subtract(const Duration(days: 7));
    });
  }

  // Fungsi untuk navigasi ke minggu berikutnya
  void _nextWeek() {
    setState(() {
      _weekStartDate = _weekStartDate.add(const Duration(days: 7));
    });
  }

  // Mengambil data janji temu yang sudah disetujui dari Firestore
  Future<void> _fetchMeetings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Gunakan AppointmentService untuk mengambil janji temu yang sudah disetujui
      _appointmentService.getAppointmentsByStatus('approved').listen((
        appointments,
      ) {
        if (mounted) {
          setState(() {
            _meetings = appointments;
            _isLoading = false;
          });

          // Jadwalkan notifikasi untuk janji temu yang disetujui
          _scheduleNotificationsForApprovedMeetings(appointments);
        }
      });
    } catch (e) {
      if (mounted) {
        // Tampilkan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat janji bimbingan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Jadwalkan notifikasi untuk janji temu yang disetujui
  Future<void> _scheduleNotificationsForApprovedMeetings(
    List<MeetingModel> meetings,
  ) async {
    try {
      // Batalkan semua notifikasi yang ada terlebih dahulu
      await ScheduleNotificationService.cancelAllNotifications();

      // Jadwalkan notifikasi untuk semua janji temu yang disetujui
      await ScheduleNotificationService.scheduleAppointmentNotifications(
        meetings,
      );

      // Tampilkan notifikasi langsung jika ada janji temu hari ini
      _showTodayAppointmentNotification(meetings);
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  // Tampilkan notifikasi langsung jika ada janji temu hari ini
  void _showTodayAppointmentNotification(List<MeetingModel> meetings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter janji temu hari ini
    final todayMeetings =
        meetings.where((meeting) {
          final meetingDate = DateTime(
            meeting.dateTime.year,
            meeting.dateTime.month,
            meeting.dateTime.day,
          );
          return meetingDate.isAtSameMomentAs(today);
        }).toList();

    // Jika ada janji temu hari ini, tampilkan notifikasi
    if (todayMeetings.isNotEmpty) {
      final meeting = todayMeetings.first;
      final formattedTime = DateFormat(
        'HH:mm',
        'id_ID',
      ).format(meeting.dateTime);

      ScheduleNotificationService.showInstantNotification(
        title: 'Jadwal Bimbingan Hari Ini',
        body:
            'Anda memiliki jadwal bimbingan dengan ${meeting.studentName} untuk "${meeting.title}" pada pukul $formattedTime di ${meeting.location}',
        payload: meeting.id,
      );
    }
  }

  // Filter jadwal berdasarkan tanggal yang dipilih
  List<MeetingModel> get _filteredMeetings {
    return _meetings.where((meeting) {
      return meeting.dateTime.year == _selectedDate.year &&
          meeting.dateTime.month == _selectedDate.month &&
          meeting.dateTime.day == _selectedDate.day;
    }).toList();
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
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _fetchMeetings,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Universitas dan Profil Dosen
                          _buildCombinedProfileCard(),
                          const SizedBox(height: 20),

                          // Card Tanggal Interaktif
                          _buildDateCard(),
                          const SizedBox(height: 20),

                          // Card Jadwal Bimbingan
                          _buildScheduleCard(),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildCombinedProfileCard() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final size = MediaQuery.of(context).size;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF5BBFCB),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo dan Nama Universitas
            Row(
              children: [
                // Logo Universitas
                Container(
                  width: size.width * 0.10,
                  height: size.width * 0.10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 2.0),
                    ),
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/Logo_unej.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.02),
                // Nama Universitas
                Text(
                  'Universitas Jember',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.04,
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            SizedBox(height: size.height * 0.02),

            // Foto dan Data Dosen
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto Profil
                CircleAvatar(
                  radius: size.width * 0.08,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      (user?.photoUrl != null &&
                              user!.photoUrl!.startsWith('data:image'))
                          ? MemoryImage(
                            StorageService.base64ToImage(user.photoUrl!)!,
                          )
                          : NetworkImage(
                                user?.photoUrl ??
                                    'https://randomuser.me/api/portraits/men/1.jpg',
                              )
                              as ImageProvider,
                  onBackgroundImageError: (_, __) {},
                  child:
                      (user?.photoUrl == null ||
                              user!.photoUrl!.isEmpty ||
                              (user.photoUrl!.startsWith('data:image') &&
                                  StorageService.base64ToImage(
                                        user.photoUrl!,
                                      ) ==
                                      null))
                          ? Icon(
                            Icons.person,
                            size: size.width * 0.08,
                            color: Colors.grey.shade400,
                          )
                          : null,
                ),
                SizedBox(width: size.width * 0.04),
                // Informasi Dosen
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'DR. PRIZA PANDUNATA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.045,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text(
                        user?.nip ?? '198201182008121002',
                        style: TextStyle(
                          color: Colors.white.withAlpha(230),
                          fontSize: size.width * 0.035,
                        ),
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text(
                        'Dosen ${user?.department ?? 'Teknik Informatika'}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(230),
                          fontSize: size.width * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    // Mendapatkan tanggal untuk satu minggu
    final DateTime today = DateTime.now();
    final DateTime selectedDay = _selectedDate;
    final size = MediaQuery.of(context).size;

    // Daftar nama hari dalam bahasa Indonesia
    final List<String> dayNames = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];

    // Lebar item hari diatur langsung di Container

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.03), // Mengurangi padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul dan Bulan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jadwal Bimbingan',
                  style: TextStyle(
                    fontSize: size.width * 0.04, // Mengurangi ukuran font
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  formatDate(
                    _selectedDate,
                    'MMM yyyy',
                  ), // Mempersingkat format bulan
                  style: TextStyle(
                    fontSize: size.width * 0.035, // Mengurangi ukuran font
                    color: const Color(0xFF5BBFCB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.01), // Mengurangi jarak
            // Tombol navigasi minggu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF5BBFCB),
                  ),
                  onPressed: _previousWeek,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: size.width * 0.05,
                ),
                Text(
                  '${formatDate(_weekStartDate, 'd MMM')} - ${formatDate(_weekStartDate.add(const Duration(days: 6)), 'd MMM')}',
                  style: TextStyle(
                    fontSize: size.width * 0.03,
                    color: Colors.grey[600],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF5BBFCB),
                  ),
                  onPressed: _nextWeek,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: size.width * 0.05,
                ),
              ],
            ),
            SizedBox(height: size.height * 0.01), // Mengurangi jarak
            // Hari-hari dalam seminggu dengan tanggal
            SizedBox(
              height: size.height * 0.08, // Tetapkan tinggi tetap
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(7, (index) {
                    final DateTime date = _weekStartDate.add(
                      Duration(days: index),
                    );
                    final bool isSelected =
                        date.year == selectedDay.year &&
                        date.month == selectedDay.month &&
                        date.day == selectedDay.day;
                    final bool isToday =
                        date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day;

                    // Cek apakah ada janji pada tanggal ini
                    final bool hasAppointment = _meetings.any(
                      (meeting) =>
                          meeting.dateTime.year == date.year &&
                          meeting.dateTime.month == date.month &&
                          meeting.dateTime.day == date.day,
                    );

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Container(
                        width: size.width * 0.12,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        padding: EdgeInsets.symmetric(
                          vertical: size.width * 0.01,
                        ), // Mengurangi padding
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFFF79762)
                                  : isToday
                                  ? const Color(0xFFF79762).withAlpha(25)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // Mengurangi radius
                        ),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // Menggunakan mainAxisSize.min
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center, // Memastikan konten di tengah
                          children: [
                            // Nama hari
                            Text(
                              dayNames[index],
                              style: TextStyle(
                                fontSize:
                                    size.width *
                                    0.025, // Mengurangi ukuran font
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : const Color(0xFF5BBFCB),
                              ),
                            ),
                            SizedBox(
                              height: size.height * 0.005,
                            ), // Mengurangi jarak
                            // Tanggal
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize:
                                    size.width *
                                    0.035, // Mengurangi ukuran font
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            // Indikator ada janji
                            if (hasAppointment)
                              Container(
                                width:
                                    size.width *
                                    0.015, // Mengurangi ukuran indikator
                                height: size.width * 0.015,
                                margin: EdgeInsets.only(
                                  top: size.height * 0.003,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : const Color(0xFFF79762),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    final size = MediaQuery.of(context).size;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul dan Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jadwal Hari Ini',
                  style: TextStyle(
                    fontSize: size.width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  formatDate(_selectedDate, 'd MMMM yyyy'),
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),

            // Daftar Janji Temu
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF5BBFCB),
                  ),
                )
                : _filteredMeetings.isEmpty
                ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: size.width * 0.15,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        'Tidak ada jadwal bimbingan',
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredMeetings.length,
                  itemBuilder: (context, index) {
                    final meeting = _filteredMeetings[index];
                    return _buildMeetingCard(meeting, size);
                  },
                ),
          ],
        ),
      ),
    );
  }

  // Unused methods removed

  Widget _buildMeetingCard(MeetingModel meeting, Size size) {
    // Format waktu
    final formattedTime = DateFormat('HH:mm', 'id_ID').format(meeting.dateTime);

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: size.width * 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul dan Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Judul Janji
                Expanded(
                  child: Text(
                    meeting.title,
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status Janji
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.02,
                    vertical: size.width * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(meeting.status).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(meeting.status),
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(meeting.status),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.01),

            // Deskripsi
            Text(
              meeting.description,
              style: TextStyle(
                fontSize: size.width * 0.035,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: size.height * 0.015),

            // Waktu dan Lokasi
            Row(
              children: [
                // Waktu
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: size.width * 0.04,
                      color: const Color(0xFF5BBFCB),
                    ),
                    SizedBox(width: size.width * 0.01),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(width: size.width * 0.04),
                // Lokasi
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: size.width * 0.04,
                        color: const Color(0xFF5BBFCB),
                      ),
                      SizedBox(width: size.width * 0.01),
                      Expanded(
                        child: Text(
                          meeting.location,
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.015),

            // Tombol Aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol Detail
                TextButton(
                  onPressed: () => _showMeetingDetails(meeting),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5BBFCB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Lihat Detail'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'checked-in':
        return Colors.purple;
      case 'late':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  // Fungsi untuk mendapatkan teks status
  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'pending':
        return 'Menunggu';
      case 'rejected':
        return 'Ditolak';
      case 'completed':
        return 'Selesai';
      case 'checked-in':
        return 'Hadir';
      case 'late':
        return 'Terlambat';
      default:
        return 'Tidak diketahui';
    }
  }

  // Fungsi untuk menampilkan detail janji temu
  void _showMeetingDetails(MeetingModel meeting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meeting.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(meeting.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF5BBFCB)),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat(
                      'EEEE, d MMMM yyyy',
                      'id_ID',
                    ).format(meeting.dateTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF5BBFCB)),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('HH:mm', 'id_ID').format(meeting.dateTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF5BBFCB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      meeting.location,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
