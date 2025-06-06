import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meeting_model.dart';
import '../services/appointment_service.dart';
import '../services/storage_service.dart';
import 'fixed_location_picker_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final MeetingModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String _statusMessage = '';
  bool _showStatusMessage = false;

  File? _attendancePhoto;
  bool _isCapturingPhoto = false;

  String formatDate(DateTime date, String format) {
    return DateFormat(format, 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Janji'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            _buildStatusBadge(),
            const SizedBox(height: 16),

            // Judul
            Text(
              widget.appointment.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Informasi Dosen
            _buildInfoSection(
              'Dosen',
              widget.appointment.lecturerName ?? 'Tidak diketahui',
              Icons.person,
            ),
            const SizedBox(height: 8),

            // Tanggal dan Waktu
            _buildInfoSection(
              'Tanggal',
              formatDate(widget.appointment.dateTime, 'EEEE, d MMMM yyyy'),
              Icons.calendar_today,
            ),
            const SizedBox(height: 8),

            // Waktu
            _buildInfoSection(
              'Waktu',
              formatDate(widget.appointment.dateTime, 'HH:mm'),
              Icons.access_time,
            ),
            const SizedBox(height: 8),

            // Lokasi
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: const Color(0xFF5BBFCB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lokasi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        widget.appointment.location,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.appointment.latitude != null &&
                          widget.appointment.longitude != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => FixedLocationPickerScreen(
                                        initialLatitude:
                                            widget.appointment.latitude,
                                        initialLongitude:
                                            widget.appointment.longitude,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Lihat di Peta'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5BBFCB),
                              side: const BorderSide(color: Color(0xFF5BBFCB)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deskripsi
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5BBFCB),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.appointment.description,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Status message
            if (_showStatusMessage)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _statusMessage.contains('berhasil')
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color:
                        _statusMessage.contains('berhasil')
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Photo preview if available
            if (_attendancePhoto != null &&
                widget.appointment.status == 'approved')
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Foto Kehadiran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5BBFCB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _attendancePhoto!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _capturePhoto,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Ambil Ulang'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF5BBFCB),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Check-in and photo buttons (only for approved appointments)
            if (widget.appointment.status == 'approved')
              Column(
                children: [
                  // Photo capture button
                  if (_attendancePhoto == null)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _capturePhoto,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5BBFCB),
                          side: const BorderSide(color: Color(0xFF5BBFCB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text(
                          'Ambil Foto Kehadiran (Wajib)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Note about check-in time limit
                  Text(
                    'Catatan: Batas waktu check-in adalah 1 jam setelah waktu janji.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Check-in button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _checkIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BBFCB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon:
                          _isLoading
                              ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                              : const Icon(Icons.check_circle),
                      label: Text(
                        _isLoading ? 'Memproses...' : 'Check-in Janji',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    String statusText;

    switch (widget.appointment.status) {
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
        statusText = 'Sudah Bimbingan';
        break;
      case 'late':
        statusColor = Colors.red.shade700;
        statusText = 'Terlambat';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Tidak diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5BBFCB)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1280,
        maxHeight: 960,
      );

      if (photo != null) {
        if (!mounted) return;

        setState(() {
          _attendancePhoto = File(photo.path);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto berhasil diambil. Silakan lanjutkan check-in.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      _isLoading = true;
      _showStatusMessage = false;
    });

    try {
      // Request location permission
      await _requestLocationPermission();

      // Get current location
      final position = await Geolocator.getCurrentPosition();

      // Try to check in with photo if available
      final bool success = await _appointmentService.checkInAppointment(
        widget.appointment.id,
        position.latitude,
        position.longitude,
        attendancePhoto: _attendancePhoto,
      );

      setState(() {
        _isLoading = false;
        _showStatusMessage = true;
        if (success) {
          _statusMessage =
              'Check-in berhasil! Anda berada di lokasi yang benar.';
          // Update the appointment status locally
          widget.appointment.status = 'checked-in';
          if (_attendancePhoto != null) {
            _statusMessage += ' Foto kehadiran berhasil diunggah.';
          }
        } else {
          _statusMessage =
              'Check-in gagal! Anda tidak berada di lokasi yang ditentukan.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showStatusMessage = true;
        _statusMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      throw Exception(
        'Layanan lokasi tidak aktif. Mohon aktifkan lokasi di pengaturan perangkat Anda.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        throw Exception(
          'Izin lokasi ditolak. Aplikasi memerlukan akses lokasi untuk check-in.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      throw Exception(
        'Izin lokasi ditolak secara permanen. Mohon ubah pengaturan izin aplikasi di pengaturan perangkat Anda.',
      );
    }
  }
}
