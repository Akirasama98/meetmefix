import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/meeting_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';

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
                  width: size.width * 0.09,
                  height: size.width * 0.09,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: const Color(0xFF5BBFCB),
                        fontWeight: FontWeight.bold,
                        fontSize: size.width * 0.05,
                      ),
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
            SizedBox(height: size.height * 0.02),

            // Foto dan Data Dosen
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto Profil
                CircleAvatar(
                  radius: size.width * 0.08,
                  backgroundImage: NetworkImage(
                    user?.photoUrl ?? 'https://randomuser.me/api/portraits/men/1.jpg',
                  ),
                  onBackgroundImageError: (_, __) {},
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
                          color: Colors.white.withOpacity(0.9),
                          fontSize: size.width * 0.035,
                        ),
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text(
                        'Dosen ${user?.department ?? 'Teknik Informatika'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
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
    final List<String> dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    
    // Hitung lebar item hari
    final double dayItemWidth = (size.width - 32) / 7;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
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
                    fontSize: size.width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  formatDate(_selectedDate, 'MMMM yyyy'),
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    color: const Color(0xFF5BBFCB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),

            // Hari-hari dalam seminggu dengan tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final DateTime date = _weekStartDate.add(Duration(days: index));
                final bool isSelected = date.year == selectedDay.year &&
                    date.month == selectedDay.month &&
                    date.day == selectedDay.day;
                final bool isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                
                // Cek apakah ada janji pada tanggal ini
                final bool hasAppointment = _meetings.any((meeting) =>
                    meeting.dateTime.year == date.year &&
                    meeting.dateTime.month == date.month &&
                    meeting.dateTime.day == date.day);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: dayItemWidth,
                    padding: EdgeInsets.symmetric(vertical: size.width * 0.02),
                    decoration: BoxDecoration(
                      color: isSelected
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
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF5BBFCB),
                          ),
                        ),
                        SizedBox(height: size.height * 0.01),
                        // Tanggal
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: size.height * 0.005),
                        // Indikator ada janji
                        if (hasAppointment)
                          Container(
                            width: size.width * 0.02,
                            height: size.width * 0.02,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
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

  Widget _buildEmptySchedule() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Tidak ada janji bimbingan',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Pada tanggal ${formatDate(_selectedDate, 'd MMMM yyyy')}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(MeetingModel meeting) {
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
      default:
        statusColor = Colors.blue;
        statusText = 'Selesai';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              Text(studentName, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                formatDate(meeting.dateTime, 'HH:mm'),
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
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
        ],
      ),
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
}





