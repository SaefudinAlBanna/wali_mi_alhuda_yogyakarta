// lib/app/modules/home/pages/home.dart (Dashboard Utama)

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/carousel_item_model.dart';
import '../../../models/mapel_siswa_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';

class DashboardHomePage extends GetView<HomeController> {
  const DashboardHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _buildNotificationIcon(),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: controller.streamUserData(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
            return const Center(child: Text("Tidak dapat memuat data pengguna."));
          }
          
          final userData = userSnapshot.data!.data()!;

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _FuturisticHeaderCard(userData: userData),
                
                // --- [FIX] Padding atas dikurangi agar tidak terlalu jauh ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), 
                  child: Column(
                    children: [
                      const _MenuGrid(),

                      // --- [PERBAIKAN UI] Kurangi jarak di sini ---
                      const SizedBox(height: 16), // Nilai sebelumnya: 24
                      // ------------------------------------------

                      _AkademikSection(), // Carousel cerdas

                      // --- [PERBAIKAN UI] Kurangi juga jarak di sini ---
                      const SizedBox(height: 16), // Nilai sebelumnya: 24
                 
                       // --- [PERBAIKAN] Ganti _JurnalSectionPlaceholder dengan widget baru ---
                       _SectionHeader(
                         title: "Informasi Sekolah",
                         onSeeAll: controller.goToSemuaInformasi,
                       ),
                       const _InformasiList(), // Widget baru yang menampilkan 5 item
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget ini tetap sama, hanya lokasinya saja yang dipanggil dari AppBar
  Widget _buildNotificationIcon() {
    return IconButton(
      onPressed: controller.goToSemuaNotifikasi,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_rounded, size: 30, color: Colors.white),
          Positioned(
            top: 0, // Disesuaikan sedikit agar pas di AppBar
            right: 0,
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: controller.streamNotificationMetadata(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final unreadCount = snapshot.data!.data()?['unreadCount'] ?? 0;
                  if (unreadCount > 0) {
                    return Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5)),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET HEADER SEKARANG BENAR-BENAR BERSIH, TANPA TOMBOL ---
class _FuturisticHeaderCard extends GetView<HomeController> {
  final Map<String, dynamic> userData;
  const _FuturisticHeaderCard({required this.userData});

  @override
  Widget build(BuildContext context) {
    final String? imageUrlFromDb = userData['fotoProfilUrl'];
    // Cek keamanan: pastikan URL tidak null dan tidak kosong
    final bool isUrlValid = imageUrlFromDb != null && imageUrlFromDb.isNotEmpty;
    final peranKomite = controller.configC.infoUser['peranKomite'] as Map<String, dynamic>?;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Background Gradien (selalu full)
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.7)],
            ),
          ),
        ),
        // Gambar Latar Belakang
        SizedBox(
          height: 240,
          width: double.infinity,
          child: Image.asset("assets/png/profile.png", fit: BoxFit.contain),
        ),
        // Konten Profil
        Positioned(
          top: 80,
          child: Column(
            children: [
              CircleAvatar(
                radius: 47,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[200],
                  child: isUrlValid
                      ? ClipOval( // Pastikan gambar bundar
                          child: CachedNetworkImage(
                            imageUrl: imageUrlFromDb!, // Aman karena sudah dicek
                            fit: BoxFit.cover,
                            width: 90, height: 90,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.person),
                          ),
                        )
                      : Text( // Fallback jika tidak ada URL
                          (userData['namaLengkap'] ?? "S")[0].toUpperCase(),
                          style: TextStyle(fontSize: 40, color: Get.theme.primaryColorDark),
                        ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (userData['namaPanggilan'] as String?)?.toUpperCase() ??  'NAMA SISWA',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 5, color: Colors.black54)]),
              ),
              const SizedBox(height: 4),
              Text(
                "Kelas: ${userData['kelasId'] ?? '...'}",
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
              ),

              // [WIDGET BARU DITAMBAHKAN DI SINI]
              if (peranKomite != null && peranKomite['jabatan'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      peranKomite['jabatan'].toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- WIDGET-WIDGET PLACEHOLDER SESUAI REFERENSI ---

class _AkademikSection extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isCarouselLoading.value) {
        return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
      }
      if (controller.daftarCarousel.isEmpty) {
        return const SizedBox.shrink(); // Jangan tampilkan apa-apa jika kosong
      }
      return CarouselSlider.builder(
        itemCount: controller.daftarCarousel.length,
        itemBuilder: (context, index, realIndex) {
          final item = controller.daftarCarousel[index];
          return _buildCarouselCard(item);
        },
        options: CarouselOptions(
          height: 160,
          autoPlay: controller.daftarCarousel.length > 1,
          autoPlayInterval: const Duration(seconds: 10),
          enlargeCenterPage: true,
          viewportFraction: 0.95,
          aspectRatio: 16 / 9,
        ),
      );
    });
  }

  Widget _buildCarouselCard(CarouselItemModel item) {
    return Card(
      elevation: 4, shadowColor: item.warna.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [item.warna.withOpacity(0.8), item.warna], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(item.ikon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.judul.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(item.namaKelas, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              const Spacer(),
              Text(item.isi, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (item.subJudul != null && item.subJudul!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(item.subJudul!, style: const TextStyle(fontSize: 12, color: Colors.white70))),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuGrid extends GetView<HomeController> {
  const _MenuGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final peranKomite = controller.configC.infoUser['peranKomite'] as Map<String, dynamic>?;
    final isBendahara = peranKomite?['jabatan'] == 'Bendahara Kelas';
    final isPjAgis = peranKomite?['jabatan'] == 'PJ AGIS';
    final isKetuaKomite = peranKomite?['jabatan'] == 'Ketua Komite Sekolah';
    final isBendaharaSekolah = peranKomite?['jabatan'] == 'Bendahara Komite Sekolah';

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Akademik','image': 'assets/png/tumpukan_buku.png','onTap': () => controller.goToDaftarMapel()},
      {'title': 'Halaqoh','image': 'assets/png/daftar_tes.png','onTap': () => controller.goToHalaqahRiwayat()},
      {'title': 'Ekskul','image': 'assets/png/list_nilai.png','onTap': () => controller.goToEkskulSiswa()},
      {'title': 'Keuangan','image': 'assets/png/uang.png','onTap': () => Get.toNamed(Routes.DETAIL_KEUANGAN_SISWA)},
      {'title': 'Jadwal Pelajaran', 'image': 'assets/png/layar.png', 'onTap': controller.goToJadwalSiswa},
      {'title': 'Kalender Akademik','image': 'assets/png/akademik_2.png','onTap': () => controller.goToKalenderAkademik()},
      // {'title': 'AGIIS','image': 'assets/png/pengumuman.png','onTap': () => Get.toNamed(Routes.MANAJEMEN_AGIS)},
      {'title': 'Catatan Perkembangan','image': 'assets/png/pengumuman.png','onTap': controller.goToCatatanPerkembangan},
      {'title': 'Buku','image': 'assets/png/akademik_1.png','onTap': () => Get.toNamed(Routes.PEMBELIAN_BUKU)},
    ];

    // [MENU BARU KONDISIONAL]
    if (isBendahara) {
      menuItems.add({'title': 'Kelola Iuran','image': 'assets/png/buku_uang.png','onTap': () => Get.toNamed(Routes.MANAJEMEN_IURAN)});
    }
    if (isPjAgis) {
      menuItems.add({'title': 'Kelola AGIS','image': 'assets/png/pengumuman.png','onTap': () => Get.toNamed(Routes.MANAJEMEN_AGIS)});
    }
    if (isKetuaKomite) {
      menuItems.add({'title': 'Manajemen Komite','image': 'assets/png/ktp.png','onTap': () => Get.toNamed(Routes.MANAJEMEN_KOMITE_SEKOLAH)});
    }
    if (isBendahara) {
      menuItems.add({'title': 'Kas Kelas','image': 'assets/png/buku_uang.png','onTap': () => Get.toNamed(Routes.KAS_KOMITE)});
    }

    if (isBendaharaSekolah || isKetuaKomite) {
      menuItems.add({'title': 'Kas Komite Pusat','image': 'assets/png/uang.png','onTap': () => Get.toNamed(Routes.KAS_KOMITE)});
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Widget Padding luar sudah dihapus. Padding sekarang ada di dalam GridView.
      child: GridView.builder(
        // <-- ATUR DI SINI: Posisi vertikal semua 8 item dari tepi Card
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _MenuItem(
            title: item['title'],
            image: item['image'],
            onTap: item['onTap'],
          );
        },
      ),
    );
  }
}

// --- [FIX] _MenuItem DIUBAH UNTUK MENCEGAH OVERFLOW ---
class _MenuItem extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onTap;

  const _MenuItem({required this.title, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Get.theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.asset(image, width: 30, height: 30),
          ),
          const SizedBox(height: 4), // [FIX] Jarak dikurangi sedikit
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InformasiSekolahSection extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Informasi Sekolah", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            // --- [PERBAIKAN] Panggil fungsi navigasi dari HomeController ---
            TextButton(
              onPressed: controller.goToSemuaInformasi,
              child: const Text("Lihat Semua"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // --- [PERBAIKAN] Gunakan stream langsung dari HomeController ---
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: controller.streamInfoDashboard(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Tampilkan placeholder loading yang lebih bagus
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("Belum ada informasi.")))
              );
            }
            final latestInfo = snapshot.data!.docs.first.data();
            final docId = snapshot.data!.docs.first.id;
            
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Get.toNamed(Routes.INFO_SEKOLAH_DETAIL, arguments: docId),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (latestInfo['imageUrl'] != null && latestInfo['imageUrl'].isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: latestInfo['imageUrl'],
                        height: 150, width: double.infinity, fit: BoxFit.cover,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(latestInfo['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(latestInfo['isi'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Disesuaikan untuk non-sliver
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: onSeeAll, child: const Text("Lihat Semua")),
        ],
      ),
    );
  }
}

class _InformasiList extends GetView<HomeController> {
  const _InformasiList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Gunakan stream baru yang ada limitnya
      stream: controller.streamInfoDashboard(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Belum ada informasi.')));
        }
        final daftarInfo = snapshot.data!.docs;
        
        // Gunakan ListView.builder karena kita di dalam Column
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daftarInfo.length,
          itemBuilder: (context, index) {
            final doc = daftarInfo[index];
            final data = doc.data();
            final timestamp = data['timestamp'] as Timestamp?;
            final tanggal = timestamp?.toDate() ?? DateTime.now();
            final imageUrl = data['imageUrl'] as String? ?? '';

            // Card UI yang direplikasi dari aplikasi sekolah
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => Get.toNamed(Routes.INFO_SEKOLAH_DETAIL, arguments: doc.id),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110, height: 110,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl, fit: BoxFit.cover,
                        placeholder: (c, u) => Container(color: Colors.grey.shade200),
                        errorWidget: (c, u, e) => Container(color: Colors.grey.shade200, child: const Icon(Icons.newspaper, color: Colors.grey)),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(data['judul'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(data['isi'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time_filled, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(timeago.format(tanggal, locale: 'id'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}