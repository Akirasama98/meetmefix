import 'package:flutter/material.dart';
import '../../models/meeting_model.dart';
import '../../services/appointment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LecturerAppointmentDetailScreen extends StatefulWidget {
  final MeetingModel appointment;

  const LecturerAppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.appointment.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Map button
            if (widget.appointment.latitude != null &&
                widget.appointment.longitude != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openMap,
                  icon: const Icon(Icons.map),
                  label: const Text('Buka di Google Maps'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Status message
            if (_showStatusMessage)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('berhasil')
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('berhasil')
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
            const SizedBox(height: 16),

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
        statusText = 'Sudah Check-in';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Tidak diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
        ),
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
      'Minggu'
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
      'Des'
    ];

    final day = days[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];

    return '$day, ${dateTime.day} $month ${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openMap() async {
    if (widget.appointment.latitude == null ||
        widget.appointment.longitude == null) {
      return;
    }

    final url =
        'https://www.google.com/maps/search/?api=1&query=${widget.appointment.latitude},${widget.appointment.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka peta'),
        ),
      );
    }
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
}