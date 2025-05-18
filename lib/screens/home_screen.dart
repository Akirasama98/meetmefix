import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/meeting_model.dart';
import '../services/appointment_service.dart';
import 'create_appointment_screen.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  List<MeetingModel> _meetings = [];
  bool _isLoading = true;
  final AppointmentService _appointmentService = AppointmentService();
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

    _fetchMeetings();
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
        }
      });
    } catch (e) {
      if (mounted) {
        // Tampilkan error dan gunakan data dummy sebagai fallback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat janji bimbingan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _meetings = _getDummyMeetings();
          _isLoading = false;
        });
      }
    }
  }

  // Data dummy sebagai fallback
  List<MeetingModel> _getDummyMeetings() {
    return [
      MeetingModel(
        id: '1',
        title: 'Bimbingan Skripsi',
        description: 'Diskusi tentang bab 1 dan 2',
        dateTime: DateTime.now().add(const Duration(hours: 2)),
        location: 'Ruang Dosen 101',
        lecturerId: 'lecturer1',
        studentId: 'student1',
        status: 'approved',
      ),
      MeetingModel(
        id: '2',
        title: 'Konsultasi KRS',
        description: 'Pemilihan mata kuliah semester depan',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Online via Zoom',
        lecturerId: 'lecturer2',
        studentId: 'student1',
        status: 'pending',
      ),
      MeetingModel(
        id: '3',
        title: 'Review Tugas Akhir',
        description: 'Evaluasi progress tugas akhir',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        location: 'Ruang Rapat Fakultas',
        lecturerId: 'lecturer1',
        studentId: 'student1',
        status: 'approved',
      ),
    ];
  }

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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Universitas dan Profil Pengguna
                _buildCombinedProfileCard(
                  user?.name ?? 'DWI RIFQI NOFRIANTO',
                  user?.nim ?? '232410102021',
                ),
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
    );
  }

  Widget _buildCombinedProfileCard(String name, String nim) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final size = MediaQuery.of(context).size;

    // Mengambil data dari Firebase
    final String displayName = user?.name ?? name;
    final String displayId =
        user?.role == 'student' ? (user?.nim ?? nim) : (user?.nip ?? '');
    final String photoUrl =
        user?.photoUrl ?? 'https://randomuser.me/api/portraits/men/10.jpg';
    final String department = user?.department ?? 'Teknik Informatika';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF5BBFCB),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04), // Padding responsif
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo dan Nama Universitas
            Row(
              children: [
                // Logo Universitas
                Container(
                  width: size.width * 0.09, // Ukuran responsif
                  height: size.width * 0.09,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
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
                    fontSize: size.width * 0.04, // Font responsif
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),

            // Informasi Pengguna
            Row(
              children: [
                // Avatar Pengguna
                CircleAvatar(
                  radius: size.width * 0.08, // Ukuran responsif
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      photoUrl.startsWith('data:image')
                          ? MemoryImage(StorageService.base64ToImage(photoUrl)!)
                          : NetworkImage(photoUrl) as ImageProvider,
                  onBackgroundImageError: (_, __) {},
                  child:
                      (photoUrl.isEmpty ||
                              (photoUrl.startsWith('data:image') &&
                                  StorageService.base64ToImage(photoUrl) ==
                                      null))
                          ? Icon(
                            Icons.person,
                            size: size.width * 0.08,
                            color: Colors.grey.shade400,
                          )
                          : null,
                ),
                SizedBox(width: size.width * 0.04),
                // Nama dan NIM
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.045, // Font responsif
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text(
                        displayId,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: size.width * 0.035, // Font responsif
                        ),
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text(
                        department,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: size.width * 0.035, // Font responsif
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

    // Hitung lebar item hari berdasarkan lebar layar
    final double dayItemWidth = (size.width - 64) / 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul Jadwal
        Padding(
          padding: EdgeInsets.only(
            left: size.width * 0.01,
            bottom: size.width * 0.02,
          ),
          child: Text(
            'Janji',
            style: TextStyle(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
        ),

        // Card Kalender
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              children: [
                // Header dengan navigasi minggu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol minggu sebelumnya
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _previousWeek,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.all(size.width * 0.02),
                          child: Icon(
                            Icons.chevron_left,
                            color: const Color(0xFF5BBFCB),
                            size: size.width * 0.07,
                          ),
                        ),
                      ),
                    ),

                    // Rentang tanggal minggu yang ditampilkan
                    GestureDetector(
                      onTap: () {
                        // Reset ke minggu saat ini saat header diklik
                        setState(() {
                          _selectedDate = DateTime.now();

                          // Reset juga ke minggu saat ini
                          final now = DateTime.now();
                          final weekday = now.weekday;
                          _weekStartDate = now.subtract(
                            Duration(days: weekday - 1),
                          );
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                          vertical: size.width * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5BBFCB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${formatDate(_weekStartDate, 'd MMM')} - ${formatDate(_weekStartDate.add(const Duration(days: 6)), 'd MMM yyyy')}',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5BBFCB),
                          ),
                        ),
                      ),
                    ),

                    // Tombol minggu berikutnya
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _nextWeek,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.all(size.width * 0.02),
                          child: Icon(
                            Icons.chevron_right,
                            color: const Color(0xFF5BBFCB),
                            size: size.width * 0.07,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.02),

                // Hari-hari dalam seminggu dengan tanggal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                        width: dayItemWidth,
                        padding: EdgeInsets.symmetric(
                          vertical: size.width * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFFF79762)
                                  : isToday
                                  ? const Color(0xFFF79762).withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Nama hari
                            Text(
                              dayNames[index],
                              style: TextStyle(
                                fontSize: size.width * 0.03,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : const Color(0xFF5BBFCB),
                              ),
                            ),
                            SizedBox(height: size.height * 0.008),
                            // Tanggal
                            Container(
                              width: dayItemWidth * 0.75,
                              height: dayItemWidth * 0.75,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isSelected
                                        ? Colors.white.withOpacity(0.3)
                                        : hasAppointment
                                        ? const Color(
                                          0xFF5BBFCB,
                                        ).withOpacity(0.2)
                                        : Colors.transparent,
                                border:
                                    hasAppointment && !isSelected
                                        ? Border.all(
                                          color: const Color(0xFF5BBFCB),
                                          width: 1,
                                        )
                                        : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: size.width * 0.035,
                                    fontWeight:
                                        isSelected || isToday || hasAppointment
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : isToday
                                            ? const Color(0xFFF79762)
                                            : hasAppointment
                                            ? const Color(0xFF5BBFCB)
                                            : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            // Indikator janji
                            if (hasAppointment && !isSelected)
                              Container(
                                margin: EdgeInsets.only(top: size.width * 0.01),
                                width: size.width * 0.01,
                                height: size.width * 0.01,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF5BBFCB),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard() {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul Jadwal
        Padding(
          padding: EdgeInsets.only(
            left: size.width * 0.01,
            bottom: size.width * 0.02,
          ),
          child: Text(
            'Jadwal Bimbingan',
            style: TextStyle(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
        ),

        // Daftar Jadwal
        _isLoading
            ? Center(
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.05),
                child: const CircularProgressIndicator(),
              ),
            )
            : _filteredMeetings.isEmpty
            ? Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.05),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: size.width * 0.15,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        'Tidak ada jadwal bimbingan pada tanggal ini',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildMeetingCard(MeetingModel meeting, Size size) {
    // Format tanggal dan waktu
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(meeting.dateTime);
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
                    color: _getStatusColor(meeting.status).withOpacity(0.1),
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
}
