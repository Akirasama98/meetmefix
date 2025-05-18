import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final bool showBackButton;

  const CreateAppointmentScreen({super.key, this.showBackButton = false});

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Data untuk dropdown
  List<Map<String, dynamic>> _lecturers = [];
  bool _isLoadingLecturers = true;

  final List<String> _timeSlots = [
    '00:00 - 01:00',
    '01:00 - 02:00',
    '02:00 - 03:00',
    '03:00 - 04:00',
    '04:00 - 05:00',
    '05:00 - 06:00',
    '06:00 - 07:00',
    '07:00 - 08:00',
    '08:00 - 09:00',
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
    '16:00 - 17:00',
    '17:00 - 18:00',
    '18:00 - 19:00',
    '19:00 - 20:00',
    '20:00 - 21:00',
    '21:00 - 22:00',
    '22:00 - 23:00',
    '23:00 - 00:00',
  ];

  // State untuk nilai yang dipilih
  Map<String, dynamic>? _selectedLecturer;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;

  // State untuk dropdown terbuka/tertutup
  bool _isLecturerDropdownOpen = false;
  bool _isTimeDropdownOpen = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLecturers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLecturers() async {
    setState(() {
      _isLoadingLecturers = true;
    });

    try {
      final lecturers = await _appointmentService.getLecturers();
      setState(() {
        _lecturers = lecturers;
        _isLoadingLecturers = false;
      });
    } catch (e) {
      print('Error loading lecturers: $e');
      setState(() {
        _isLoadingLecturers = false;
      });
      _showErrorSnackBar('Gagal memuat daftar dosen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Janji'),
        centerTitle: true,
        leading:
            widget.showBackButton
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informasi Janji
            const Text(
              'Informasi Janji',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),

            // Judul Janji
            const Text(
              'Judul Janji',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5BBFCB),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Masukkan judul janji',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Deskripsi Janji
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5BBFCB),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan deskripsi janji',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown Dosen
            _buildLecturerDropdown(),
            const SizedBox(height: 16),

            // Tanggal Bimbingan
            const Text(
              'Tanggal Bimbingan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5BBFCB),
              ),
            ),
            const SizedBox(height: 8),

            // Pilihan Tanggal (3 field: tanggal, bulan, tahun)
            _buildDateSelectionRow(),
            const SizedBox(height: 16),

            // Jam Bimbingan
            _buildTimeDropdown(),
            const SizedBox(height: 24),

            // Tombol Buat Janji
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _createAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BBFCB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Buat Janji',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLecturerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama Dosen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5BBFCB),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header dropdown
              InkWell(
                onTap: () {
                  setState(() {
                    _isLecturerDropdownOpen = !_isLecturerDropdownOpen;
                    // Tutup dropdown lain jika yang ini dibuka
                    if (_isLecturerDropdownOpen) {
                      _isTimeDropdownOpen = false;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedLecturer != null
                            ? _selectedLecturer!['name'] as String
                            : 'Nama Dosen',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _selectedLecturer != null
                                  ? Colors.black
                                  : Colors.grey,
                        ),
                      ),
                      Icon(
                        _isLecturerDropdownOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF5BBFCB),
                      ),
                    ],
                  ),
                ),
              ),

              // Dropdown content
              if (_isLecturerDropdownOpen)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child:
                      _isLoadingLecturers
                          ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                          : Column(
                            children:
                                _lecturers.map((lecturer) {
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedLecturer = lecturer;
                                        _isLecturerDropdownOpen = false;
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        lecturer['name'] as String,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectionRow() {
    // Format tanggal untuk mendapatkan hari, bulan, dan tahun
    final day = _selectedDate.day.toString();
    final month = DateFormat('MMMM', 'id_ID').format(_selectedDate);
    final year = _selectedDate.year.toString();

    // Format tanggal lengkap untuk tooltip
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pilih Tanggal',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Tooltip(
              message: 'Buka kalender untuk memilih tanggal',
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BBFCB).withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Color(0xFF5BBFCB),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: formattedDate,
          child: Row(
            children: [
              // Field Tanggal
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(day, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Field Bulan
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(month, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Field Tahun
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(year, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jam Bimbingan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5BBFCB),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header dropdown
              InkWell(
                onTap: () {
                  setState(() {
                    _isTimeDropdownOpen = !_isTimeDropdownOpen;
                    // Tutup dropdown lain jika yang ini dibuka
                    if (_isTimeDropdownOpen) {
                      _isLecturerDropdownOpen = false;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTimeSlot ?? 'Jam Bimbingan',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _selectedTimeSlot != null
                                  ? Colors.black
                                  : Colors.grey,
                        ),
                      ),
                      Icon(
                        _isTimeDropdownOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF5BBFCB),
                      ),
                    ],
                  ),
                ),
              ),

              // Note about time restrictions
              if (_isToday(_selectedDate))
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Text(
                    'Catatan: Jam yang sudah lewat tidak dapat dipilih',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

              // Dropdown content
              if (_isTimeDropdownOpen)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children:
                        _timeSlots.map((timeSlot) {
                          // Check if this time slot is in the past for today
                          bool isPastTimeSlot = false;
                          if (_isToday(_selectedDate)) {
                            final timeRange = timeSlot.split(' - ');
                            final startTime = timeRange[0];
                            final timeParts = startTime.split(':');
                            final hour = int.parse(timeParts[0]);
                            final minute = int.parse(timeParts[1]);

                            final now = DateTime.now();
                            isPastTimeSlot =
                                now.hour > hour ||
                                (now.hour == hour && now.minute > minute);
                          }

                          return InkWell(
                            onTap:
                                isPastTimeSlot
                                    ? null
                                    : () {
                                      setState(() {
                                        _selectedTimeSlot = timeSlot;
                                        _isTimeDropdownOpen = false;
                                      });
                                    },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color:
                                  isPastTimeSlot ? Colors.grey.shade200 : null,
                              child: Text(
                                timeSlot,
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isPastTimeSlot
                                          ? Colors.grey.shade400
                                          : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    // Hanya memungkinkan pemilihan tanggal mulai dari hari ini
    final DateTime firstAllowedDate = DateTime.now();

    // Jika tanggal yang dipilih sebelumnya lebih awal dari tanggal yang diizinkan,
    // gunakan tanggal yang diizinkan sebagai tanggal awal
    final DateTime initialDate =
        _selectedDate.isBefore(firstAllowedDate)
            ? firstAllowedDate
            : _selectedDate;

    // Batasi pemilihan tanggal hingga 30 hari ke depan
    final DateTime lastAllowedDate = DateTime.now().add(
      const Duration(days: 30),
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowedDate,
      lastDate: lastAllowedDate, // Bisa memilih hingga 30 hari ke depan
      locale: const Locale('id', 'ID'), // Gunakan locale Indonesia
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5BBFCB),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5BBFCB),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createAppointment() async {
    // Validasi input
    if (_selectedLecturer == null) {
      _showErrorSnackBar('Silakan pilih dosen');
      return;
    }

    if (_selectedTimeSlot == null) {
      _showErrorSnackBar('Silakan pilih jam bimbingan');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Silakan masukkan judul janji');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Silakan masukkan deskripsi janji');
      return;
    }

    // Validasi tanggal tidak terlalu jauh di masa depan (maksimal 30 hari dari sekarang)
    final DateTime maxAllowedDate = DateTime.now().add(
      const Duration(days: 30),
    );
    if (_selectedDate.isAfter(maxAllowedDate)) {
      _showErrorSnackBar(
        'Tanggal janji tidak boleh lebih dari 30 hari dari sekarang',
      );
      return;
    }

    // Tampilkan dialog konfirmasi
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Janji'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Judul: ${_titleController.text}'),
                const SizedBox(height: 8),
                Text('Dosen: ${_selectedLecturer!['name']}'),
                const SizedBox(height: 8),
                Text(
                  'Tanggal: ${DateFormat('d MMMM yyyy').format(_selectedDate)}',
                ),
                const SizedBox(height: 8),
                Text('Jam: $_selectedTimeSlot'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitAppointment();
                },
                child: const Text('Buat Janji'),
              ),
            ],
          ),
    );
  }

  Future<void> _submitAppointment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Parse time slot to get start time
      final timeRange = _selectedTimeSlot!.split(' - ');
      final startTime = timeRange[0];

      // Create DateTime with selected date and start time
      final timeParts = startTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );

      // Validate that the appointment time is not in the past
      final now = DateTime.now();
      if (appointmentDateTime.isBefore(now)) {
        throw Exception(
          'Tidak dapat membuat janji untuk waktu yang sudah lewat',
        );
      }

      // Create appointment in Firestore
      await _appointmentService.createAppointment(
        lecturerId: _selectedLecturer!['id'] as String,
        lecturerName: _selectedLecturer!['name'] as String,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: appointmentDateTime,
        location: "Akan ditentukan oleh dosen", // Default location
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Janji berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to previous screen with refresh flag
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Helper method to check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
