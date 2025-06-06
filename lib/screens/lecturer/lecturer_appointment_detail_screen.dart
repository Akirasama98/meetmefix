import 'package:flutter/material.dart';
import '../../models/meeting_model.dart';
import '../../services/appointment_service.dart';
import '../../services/storage_service.dart';

class LecturerAppointmentDetailScreen extends StatefulWidget {
  final MeetingModel appointment;

  const LecturerAppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<LecturerAppointmentDetailScreen> createState() =>
      _LecturerAppointmentDetailScreenState();
}

class _LecturerAppointmentDetailScreenState
    extends State<LecturerAppointmentDetailScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  bool _isLoading = false;
  bool _showStatusMessage = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Janji Bimbingan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Hapus Janji',
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            _buildStatusBadge(),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.appointment.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            // Date and time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(widget.appointment.dateTime),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.appointment.location,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Student info
            const Text(
              'Mahasiswa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.appointment.studentName ?? 'Nama tidak tersedia',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Deskripsi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.appointment.description,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
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
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Check-in information (only for checked-in or completed appointments)
            if (widget.appointment.status == 'checked-in' ||
                widget.appointment.status == 'completed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.purple),
                        const SizedBox(width: 8),
                        const Text(
                          'Bukti Kehadiran Mahasiswa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Student info
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mahasiswa: ${widget.appointment.studentName ?? "Tidak tersedia"}',
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Check-in time
                    if (widget.appointment.checkedInAt != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Waktu check-in: ${_formatDateTime(widget.appointment.checkedInAt!)}',
                              style: const TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Attendance Photo (if available)
                    if (widget.appointment.attendancePhotoUrl != null) ...[
                      const Text(
                        'Foto Bukti Kehadiran:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildAttendancePhotoWidget(),
                      ),
                      if (widget.appointment.attendancePhotoTimestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Diambil pada: ${_formatDateTime(widget.appointment.attendancePhotoTimestamp!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

            // Complete button (only for checked-in appointments)
            if (widget.appointment.status == 'checked-in')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _completeAppointment,
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
                    _isLoading ? 'Memproses...' : 'Selesaikan Bimbingan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    // Format: Senin, 01 Jan 2023 - 09:00
    final List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = days[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];

    return '$day, ${dateTime.day} $month ${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _completeAppointment() async {
    setState(() {
      _isLoading = true;
      _showStatusMessage = false;
    });

    try {
      await _appointmentService.completeAppointment(widget.appointment.id);

      setState(() {
        _isLoading = false;
        _showStatusMessage = true;
        _statusMessage = 'Bimbingan berhasil diselesaikan!';
        // Update the appointment status locally
        widget.appointment.status = 'completed';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showStatusMessage = true;
        _statusMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  // Menampilkan dialog konfirmasi hapus janji
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Janji'),
            content: Text(
              'Apakah Anda yakin ingin menghapus janji bimbingan dengan ${widget.appointment.studentName ?? "Mahasiswa"}?',
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

                  // Hapus janji
                  _deleteAppointment();
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  // Menghapus janji temu
  Future<void> _deleteAppointment() async {
    setState(() {
      _isLoading = true;
      _showStatusMessage = false;
    });

    try {
      await _appointmentService.deleteAppointment(widget.appointment.id);

      if (!mounted) return;

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Janji bimbingan berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman sebelumnya
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showStatusMessage = true;
        _statusMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  // Build widget to display attendance photo from Base64 string
  Widget _buildAttendancePhotoWidget() {
    if (widget.appointment.attendancePhotoUrl == null ||
        widget.appointment.attendancePhotoUrl!.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(child: Text('Tidak ada foto kehadiran')),
      );
    }

    // Check if it's a Base64 image
    if (widget.appointment.attendancePhotoUrl!.startsWith('data:image')) {
      // Convert Base64 to image
      final imageBytes = StorageService.base64ToImage(
        widget.appointment.attendancePhotoUrl,
      );

      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImageWidget();
          },
        );
      } else {
        return _buildErrorImageWidget();
      }
    } else {
      // Fallback to network image (for backward compatibility)
      return Image.network(
        widget.appointment.attendancePhotoUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingImageWidget(loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImageWidget();
        },
      );
    }
  }

  // Widget for loading state
  Widget _buildLoadingImageWidget(ImageChunkEvent loadingProgress) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: CircularProgressIndicator(
          value:
              loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
        ),
      ),
    );
  }

  // Widget for error state
  Widget _buildErrorImageWidget() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.red, size: 40),
      ),
    );
  }
}
