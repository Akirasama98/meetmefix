import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../screens/integrated_login_screen.dart';
import 'edit_profile_screen.dart';
import '../services/storage_service.dart';
import '../services/schedule_notification_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final bool isStudent = user?.role == 'student';

    // Gunakan data dari AuthProvider jika tersedia, atau gunakan data default
    final String name = user?.name ?? 'Nama Pengguna';
    final String id = user?.nim ?? user?.nip ?? 'NIM/NIP';
    final String email = user?.email ?? 'email@example.com';
    final String role = isStudent ? 'Mahasiswa' : 'Dosen';
    final String avatarUrl =
        user?.photoUrl ?? 'https://randomuser.me/api/portraits/men/10.jpg';

    // Informasi tambahan berdasarkan role
    final String department = user?.department ?? 'Teknik Informatika';
    final String faculty = 'Fakultas Ilmu Komputer';

    // Informasi khusus mahasiswa
    final String semester = isStudent ? '6' : '';
    final String studyProgram = isStudent ? 'S1 Informatika' : '';

    // Informasi khusus dosen
    final String position = !isStudent ? 'Dosen Tetap' : '';
    final String specialization = !isStudent ? 'Rekayasa Perangkat Lunak' : '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar dengan efek parallax
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF5BBFCB),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black.withAlpha(75),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF5BBFCB),
                          const Color(0xFF5BBFCB).withAlpha(200),
                        ],
                      ),
                    ),
                  ),
                  // Pattern overlay
                  Opacity(
                    opacity: 0.1,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://www.transparenttextures.com/patterns/cubes.png',
                          ),
                          repeat: ImageRepeat.repeat,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile header with avatar
                _buildProfileHeader(
                  context: context,
                  name: name,
                  id: id,
                  email: email,
                  role: role,
                  avatarUrl: avatarUrl,
                ),

                const SizedBox(height: 20),

                // Academic/Professional Information
                _buildInfoSection(
                  context: context,
                  title: 'Informasi ${isStudent ? 'Akademik' : 'Profesional'}',
                  items: [
                    {
                      'icon': Icons.school,
                      'label': 'Fakultas',
                      'value': faculty,
                    },
                    {
                      'icon': Icons.business,
                      'label': 'Jurusan',
                      'value': department,
                    },
                    if (isStudent)
                      {
                        'icon': Icons.menu_book,
                        'label': 'Program Studi',
                        'value': studyProgram,
                      },
                    if (isStudent)
                      {
                        'icon': Icons.calendar_today,
                        'label': 'Semester',
                        'value': semester,
                      },
                    if (!isStudent)
                      {
                        'icon': Icons.work,
                        'label': 'Jabatan',
                        'value': position,
                      },
                    if (!isStudent)
                      {
                        'icon': Icons.psychology,
                        'label': 'Bidang Keahlian',
                        'value': specialization,
                      },
                  ],
                ),

                // Informasi tambahan untuk dosen
                if (!isStudent) ...[
                  const SizedBox(height: 20),

                  // Statistik Bimbingan
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistik Bimbingan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatItem(
                              icon: Icons.people,
                              value: '12',
                              label: 'Mahasiswa\nBimbingan',
                              color: const Color(0xFF5BBFCB),
                            ),
                            _buildStatItem(
                              icon: Icons.check_circle,
                              value: '8',
                              label: 'Janji\nDisetujui',
                              color: Colors.green,
                            ),
                            _buildStatItem(
                              icon: Icons.pending_actions,
                              value: '3',
                              label: 'Janji\nMenunggu',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildInfoSection(
                    context: context,
                    title: 'Jadwal Konsultasi',
                    items: [
                      {
                        'icon': Icons.access_time,
                        'label': 'Senin',
                        'value': '13:00 - 15:00',
                      },
                      {
                        'icon': Icons.access_time,
                        'label': 'Rabu',
                        'value': '13:00 - 15:00',
                      },
                      {
                        'icon': Icons.access_time,
                        'label': 'Jumat',
                        'value': '09:00 - 11:00',
                      },
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildInfoSection(
                    context: context,
                    title: 'Bidang Penelitian',
                    items: [
                      {
                        'icon': Icons.science,
                        'label': 'Utama',
                        'value': 'Kecerdasan Buatan',
                      },
                      {
                        'icon': Icons.science,
                        'label': 'Pendukung',
                        'value': 'Machine Learning, Mobile Computing',
                      },
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildInfoSection(
                    context: context,
                    title: 'Kontak & Lokasi',
                    items: [
                      {
                        'icon': Icons.phone,
                        'label': 'Telepon',
                        'value': '+62 812-3456-7890',
                      },
                      {
                        'icon': Icons.location_on,
                        'label': 'Ruang Kerja',
                        'value': 'Gedung C Lantai 3, Ruang C3.12',
                      },
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Settings and preferences
                _buildProfileMenus(context, isStudent),

                const SizedBox(height: 20),

                // Tombol Uji Notifikasi
                _buildTestNotificationButton(context),

                const SizedBox(height: 20),

                // Logout button
                _buildLogoutButton(context),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader({
    required BuildContext context,
    required String name,
    required String id,
    required String email,
    required String role,
    required String avatarUrl,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF5BBFCB), width: 3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      avatarUrl.startsWith('data:image')
                          ? MemoryImage(
                            StorageService.base64ToImage(avatarUrl)!,
                          )
                          : NetworkImage(avatarUrl) as ImageProvider,
                  onBackgroundImageError: (_, __) {
                    // Fallback jika gambar tidak dapat dimuat
                  },
                  child:
                      (avatarUrl.isEmpty ||
                              (avatarUrl.startsWith('data:image') &&
                                  StorageService.base64ToImage(avatarUrl) ==
                                      null))
                          ? Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade400,
                          )
                          : null,
                ),
              ),

              // Edit button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5BBFCB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),

          const SizedBox(height: 4),

          // ID (NIM/NIP)
          Text(
            id,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),

          const SizedBox(height: 8),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF5BBFCB).withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5BBFCB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 16),

          // Info items
          ...items.map(
            (item) => _buildInfoItem(
              icon: item['icon'] as IconData,
              label: item['label'] as String,
              value: item['value'] as String,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5BBFCB).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF5BBFCB)),
          ),

          const SizedBox(width: 12),

          // Label and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenus(BuildContext context, bool isStudent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person,
            title: 'Edit Profil',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.notifications,
            title: 'Uji Notifikasi',
            onTap: () {
              _showTestNotificationDialog(context);
            },
          ),
          const Divider(height: 1),

          // Menu khusus berdasarkan role
          if (!isStudent) ...[
            _buildMenuItem(
              icon: Icons.schedule,
              title: 'Jadwal Mengajar',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur jadwal mengajar belum tersedia'),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.people,
              title: 'Daftar Mahasiswa Bimbingan',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Fitur daftar mahasiswa bimbingan belum tersedia',
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.assessment,
              title: 'Laporan Bimbingan',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur laporan bimbingan belum tersedia'),
                  ),
                );
              },
            ),
            const Divider(height: 1),
          ],
          _buildMenuItem(
            icon: Icons.help,
            title: 'Bantuan',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur bantuan belum tersedia')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5BBFCB)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showTestNotificationDialog(context);
        },
        icon: const Icon(Icons.notifications_active),
        label: const Text('Uji Notifikasi'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5BBFCB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showLogoutConfirmationDialog(context);
        },
        icon: const Icon(Icons.logout),
        label: const Text('Keluar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 8),
                Text('Konfirmasi Keluar'),
              ],
            ),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Tutup dialog
                  Navigator.of(dialogContext).pop();

                  // Lakukan logout
                  _performLogout(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Implementasi logout dengan AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      if (context.mounted) {
        // Navigasi ke halaman login yang benar
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const IntegratedLoginScreen(),
          ),
          (route) => false,
        );

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda telah keluar dari aplikasi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Dialog untuk menguji notifikasi
  void _showTestNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.notifications_active, color: Color(0xFF5BBFCB)),
                SizedBox(width: 8),
                Text('Uji Notifikasi'),
              ],
            ),
            content: const Text('Pilih jenis notifikasi yang ingin Anda uji:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  // Kirim notifikasi langsung
                  await ScheduleNotificationService.showInstantNotification(
                    title: 'Notifikasi Pengujian',
                    body:
                        'Ini adalah notifikasi pengujian. Jika Anda melihat ini, berarti notifikasi berfungsi dengan baik!',
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi pengujian telah dikirim'),
                        backgroundColor: Color(0xFF5BBFCB),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BBFCB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Notifikasi Langsung'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  // Kirim notifikasi terjadwal (5 detik dari sekarang)
                  final DateTime scheduledTime = DateTime.now().add(
                    const Duration(seconds: 5),
                  );

                  await ScheduleNotificationService.scheduleNotification(
                    title: 'Notifikasi Terjadwal',
                    body:
                        'Ini adalah notifikasi terjadwal (5 detik). Jika Anda melihat ini, berarti notifikasi terjadwal berfungsi dengan baik!',
                    scheduledTime: scheduledTime,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notifikasi terjadwal akan muncul dalam 5 detik',
                        ),
                        backgroundColor: Color(0xFF5BBFCB),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Notifikasi Terjadwal (5 detik)'),
              ),
            ],
          ),
    );
  }
}
