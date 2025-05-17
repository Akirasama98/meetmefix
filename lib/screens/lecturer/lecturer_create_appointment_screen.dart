import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import '../fixed_location_picker_screen.dart';

class LecturerCreateAppointmentScreen extends StatefulWidget {
  final bool showBackButton;

  const LecturerCreateAppointmentScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<LecturerCreateAppointmentScreen> createState() =>
      _LecturerCreateAppointmentScreenState();
}

class _LecturerCreateAppointmentScreenState
    extends State<LecturerCreateAppointmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Data untuk dropdown
  List<Map<String, dynamic>> _students = [];
  bool _isLoadingStudents = true;
  bool _isLoading = false; // Tambahkan variabel _isLoading

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
    '12:00 - 13:00',
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

  // State untuk tanggal yang dipilih
  DateTime _selectedDate = DateTime.now();

  // State untuk dropdown
  Map<String, dynamic>? _selectedStudent;
  String? _selectedTimeSlot;

  // State untuk dropdown terbuka/tertutup
  bool _isStudentDropdownOpen = false;
  bool _isTimeDropdownOpen = false;
  bool _isSubmitting = false;

  // State untuk lokasi
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      // Dapatkan daftar mahasiswa dari Firestore
      final students = await _appointmentService.getStudents();
      setState(() {
        _students = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Janji Baru'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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

            // Dropdown Mahasiswa
            _buildStudentDropdown(),
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
            const SizedBox(height: 16),

            // Lokasi Janji
            const Text(
              'Lokasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5BBFCB),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan lokasi janji',
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
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickLocation,
                  icon: const Icon(Icons.map, color: Color(0xFF5BBFCB)),
                  tooltip: 'Pilih lokasi di peta',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tombol Buat Janji
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BBFCB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
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

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FixedLocationPickerScreen(
              initialLatitude: _latitude,
              initialLongitude: _longitude,
            ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationController.text = result['address'];
      });
    }
  }

  Widget _buildStudentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama Mahasiswa',
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
                    _isStudentDropdownOpen = !_isStudentDropdownOpen;
                    // Tutup dropdown lain jika yang ini dibuka
                    if (_isStudentDropdownOpen) {
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
                        _selectedStudent != null
                            ? _selectedStudent!['name'] as String
                            : 'Nama Mahasiswa',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _selectedStudent != null
                                  ? Colors.black
                                  : Colors.grey,
                        ),
                      ),
                      Icon(
                        _isStudentDropdownOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF5BBFCB),
                      ),
                    ],
                  ),
                ),
              ),
              // Daftar dropdown
              if (_isStudentDropdownOpen)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child:
                      _isLoadingStudents
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedStudent = student;
                                    _isStudentDropdownOpen = false;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    student['name'] as String,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectionRow() {
    // Format tanggal untuk display
    final String formattedDate = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(_selectedDate);
    final String day = DateFormat('d').format(_selectedDate);
    final String month = DateFormat('MMMM', 'id_ID').format(_selectedDate);
    final String year = DateFormat('yyyy').format(_selectedDate);

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
                      _isStudentDropdownOpen = false;
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
              // Daftar dropdown
              if (_isTimeDropdownOpen)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _timeSlots.length,
                    itemBuilder: (context, index) {
                      final timeSlot = _timeSlots[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTimeSlot = timeSlot;
                            _isTimeDropdownOpen = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            timeSlot,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime initialDate = _selectedDate;
    final DateTime firstAllowedDate = DateTime.now();
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _createAppointment() async {
    // Validasi input
    if (_selectedStudent == null) {
      _showErrorSnackBar('Silakan pilih mahasiswa');
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

    if (_locationController.text.trim().isEmpty) {
      _showErrorSnackBar('Silakan masukkan lokasi janji');
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

    // Dapatkan data dosen
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final UserModel? lecturer = authProvider.userModel;

    if (lecturer == null) {
      _showErrorSnackBar('Data dosen tidak ditemukan');
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
                Text('Mahasiswa: ${_selectedStudent!['name']}'),
                const SizedBox(height: 8),
                Text(
                  'Tanggal: ${DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate)}',
                ),
                const SizedBox(height: 8),
                Text('Jam: $_selectedTimeSlot'),
                const SizedBox(height: 8),
                Text('Lokasi: ${_locationController.text}'),
              ],
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

                  // Buat janji temu
                  _submitAppointment();
                },
                child: const Text('Konfirmasi'),
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

      // Create appointment in Firestore
      await _appointmentService.createAppointmentByLecturer(
        studentId: _selectedStudent!['id'] as String,
        studentName: _selectedStudent!['name'] as String,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: appointmentDateTime,
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
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
}









