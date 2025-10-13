// lib/app/modules/home/controllers/home_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/carousel_item_model.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/account_manager_controller.dart'; 
import '../../../models/halaqah_setoran_ummi_model.dart';
import '../../../routes/app_pages.dart';
import '../../../models/halaqah_setoran_model.dart';

class HomeController extends GetxController {
  final AuthController authC = Get.find<AuthController>();
  final ConfigController configC = Get.find<ConfigController>();
  final AccountManagerController _accountManager = Get.find<AccountManagerController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late PersistentTabController tabController;

  final RxBool isCarouselLoading = true.obs;
  final RxList<CarouselItemModel> daftarCarousel = <CarouselItemModel>[].obs;

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _notificationMetadataSubscription;
  int _previousUnreadCount = 0;
  
  // Gunakan UID dari akun siswa yang sedang aktif di AccountManagerController
  DocumentReference<Map<String, dynamic>>? get _siswaDocRef {
    final activeStudentUid = _accountManager.currentActiveStudent.value?.uid;
    if (activeStudentUid == null || configC.idSekolah.isEmpty) {
      return null;
    }
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(activeStudentUid);
  }

   @override
  void onInit() {
    super.onInit();
    tabController = PersistentTabController(initialIndex: 0);
  }

   @override
  void onReady() {
    super.onReady();
    // Listener untuk currentActiveStudent juga
    ever(_accountManager.currentActiveStudent, (_) {
      print("[HomeController] _accountManager.currentActiveStudent changed. Re-fetching carousel and notifications.");
      _maybeFetchCarouselAndNotifications();
    });

    ever(configC.infoUser, (_) {
      print("[HomeController] configC.infoUser changed. Re-fetching carousel and notifications.");
      _maybeFetchCarouselAndNotifications();
    });

    ever(configC.isKonfigurasiLoading, (bool isLoadingConfig) {
      print("[HomeController] configC.isKonfigurasiLoading changed: $isLoadingConfig.");
      if (!isLoadingConfig && configC.infoUser.isNotEmpty && _accountManager.currentActiveStudent.value != null) {
        _maybeFetchCarouselAndNotifications();
      } else if (isLoadingConfig) {
        _notificationMetadataSubscription?.cancel();
        _notificationMetadataSubscription = null;
        daftarCarousel.clear();
      }
    });

    // Inisialisasi awal
    if (!configC.isKonfigurasiLoading.value && 
        configC.infoUser.isNotEmpty &&
        _accountManager.currentActiveStudent.value != null) {
      print("[HomeController] Initial state ready. Fetching carousel and notifications.");
      _maybeFetchCarouselAndNotifications();
    } else {
      print("[HomeController] Initial state not fully ready yet.");
    }
  }

  void _maybeFetchCarouselAndNotifications() {
    final currentActiveStudent = _accountManager.currentActiveStudent.value;
    // Gunakan _auth.currentUser.uid untuk check apakah ada user login di firebase auth.
    // Jika tidak ada user login di firebase auth, maka tidak bisa melakukan query data firebase.
    if (authC.auth.currentUser == null ||
        currentActiveStudent == null || 
        configC.infoUser.isEmpty || 
        configC.tahunAjaranAktif.value.isEmpty || 
        configC.tahunAjaranAktif.value.contains("TIDAK") || 
        configC.semesterAktif.value.isEmpty ||
        (currentActiveStudent.kelasId).isEmpty) {
      
      print("[HomeController] Essential config/active student data not ready. Skipping fetch.");
      daftarCarousel.clear();
      isCarouselLoading.value = false;
      _notificationMetadataSubscription?.cancel();
      _notificationMetadataSubscription = null;
      return;
    }
    print("[HomeController] All essential config/active student data ready. Proceeding with fetch.");
    fetchCarouselData();
    _listenToNotifications();
  }

  @override
  void onClose() {
    tabController.dispose();
    _notificationMetadataSubscription?.cancel();
    _audioPlayer.dispose();
    super.onClose();
  }

  Future<void> fetchCarouselData() async {
    isCarouselLoading.value = true;
    try {
      final now = DateTime.now();
      final todayWithoutTime = DateTime(now.year, now.month, now.day);
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final String semester = configC.semesterAktif.value;
      final String namaHari = DateFormat('EEEE', 'id_ID').format(now);
      
      final String kelasId = _accountManager.currentActiveStudent.value!.kelasId; 
      final String uidSiswa = _accountManager.currentActiveStudent.value!.uid;

      final List<CarouselItemModel> tempCarouselItems = [];

      // [Prioritas #0: Pesan Pimpinan]
      final pesanPimpinan = configC.konfigurasiDashboard['pesanPimpinan'] as Map<String, dynamic>?;
      if (pesanPimpinan != null) {
        final berlakuHingga = (pesanPimpinan['berlakuHingga'] as Timestamp?)?.toDate();
        if (berlakuHingga != null && now.isBefore(berlakuHingga)) {
          tempCarouselItems.add(CarouselItemModel(namaKelas: "Info Sekolah", tipe: CarouselContentType.Prioritas, judul: "PENGUMUMAN PENTING", isi: pesanPimpinan['pesan'] ?? '', ikon: Icons.campaign_rounded, warna: Colors.red.shade700));
        }
      }

      // [Prioritas #1: Kalender Akademik]
      final kalenderSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('kalender_akademik').where('tanggalMulai', isLessThanOrEqualTo: now).get();
      for (var doc in kalenderSnap.docs) {
        final data = doc.data();
        final tglSelesai = (data['tanggalSelesai'] as Timestamp).toDate();
        if (todayWithoutTime.isBefore(tglSelesai.add(const Duration(days: 1)))) {
          final isLibur = data['isLibur'] as bool? ?? false;
          tempCarouselItems.add(CarouselItemModel(namaKelas: "Info Sekolah", tipe: CarouselContentType.Info, 
          judul: isLibur ? "HARI LIBUR" : "INFO KEGIATAN", isi: data['namaKegiatan'] ?? 'Tanpa Judul', 
          ikon: isLibur ? Icons.weekend_rounded : Icons.event_note_rounded, 
          warna: isLibur ? Colors.red.shade400 : Colors.teal.shade700));
          break;
        }
      }
      
      // [Prioritas #2: Hari Libur (Sabtu/Minggu)]
      if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
        final String pesanLiburDariDb = configC.konfigurasiDashboard['pesanDefaultLibur'] as String? ?? "";
        final String pesanLiburFinal = pesanLiburDariDb.isEmpty ? "Selamat beristirahat dan tetap semangat belajar di rumah ya!" : pesanLiburDariDb;
        tempCarouselItems.add(CarouselItemModel(namaKelas: "Info Sekolah", tipe: CarouselContentType.Default, 
        judul: "SELAMAT BERAKHIR PEKAN", isi: pesanLiburFinal, 
        ikon: Icons.beach_access_rounded, warna: Colors.blue.shade700));
      }

      // [Prioritas #3: Jadwal KBM Hari Ini (Sedang Berlangsung / Berikutnya)]
      final jadwalDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('jadwalkelas').doc(kelasId).get();
      if(jadwalDoc.exists) {
        final jadwalData = jadwalDoc.data()!;
        final listSlot = (jadwalData[namaHari] ?? jadwalData[namaHari.toLowerCase()]) as List? ?? [];
        listSlot.sort((a,b) => (a['jam'] as String).compareTo(b['jam'] as String));

        final nowTime = DateFormat("HH:mm").parse(DateFormat("HH:mm").format(now));
        Map<String, dynamic>? slotBerlangsung;
        Map<String, dynamic>? slotBerikutnya;
        for (var slot in listSlot) { try { final timeParts = (slot['jam'] as String? ?? "00:00-00:00").split('-'); 
        final startTime = DateFormat("HH:mm").parse(timeParts[0].trim()); 
        final endTime = DateFormat("HH:mm").parse(timeParts[1].trim()); 
        if (nowTime.isAfter(startTime) && nowTime.isBefore(endTime)) { slotBerlangsung = slot; break; } 
        if (nowTime.isBefore(startTime) && slotBerikutnya == null) { slotBerikutnya = slot; } } catch(e) {} } 
        
        if (slotBerlangsung != null) {
          tempCarouselItems.add(CarouselItemModel(namaKelas: "Kelas ${kelasId.split('-').first}", tipe: CarouselContentType.KBM, 
          judul: "Saat Ini Berlangsung", isi: slotBerlangsung['namaMapel'] ?? 'N/A', 
          subJudul: "Oleh: ${slotBerlangsung['namaGuru'] ?? 'N/A'}", ikon: Icons.school_rounded, warna: Colors.indigo.shade700));
        } else if (slotBerikutnya != null) {
          tempCarouselItems.add(CarouselItemModel(namaKelas: "Kelas ${kelasId.split('-').first}", tipe: CarouselContentType.KBM, 
          judul: "Pelajaran Berikutnya", isi: slotBerikutnya['namaMapel'] ?? 'N/A', 
          subJudul: "Jam: ${slotBerikutnya['jam'] ?? 'N/A'}", ikon: Icons.update_rounded, warna: Colors.blue.shade700));
        } else {
          final String pesanSelesaiDariDb = configC.konfigurasiDashboard['pesanDefaultSetelahKBM'] as String? ?? "";
          final String pesanSelesaiFinal = pesanSelesaiDariDb.isEmpty ? "Aktivitas belajar telah usai, tetap belajar dirumah ya" : pesanSelesaiDariDb;

          tempCarouselItems.add(CarouselItemModel(namaKelas: "Info Kelas", tipe: CarouselContentType.Default, 
          judul: "KBM Telah Selesai", isi: pesanSelesaiFinal, 
          ikon: Icons.check_circle_outline_rounded, warna: Colors.blueGrey.shade700));

          final tomorrow = now.add(const Duration(days: 1));
          final namaHariBesok = DateFormat('EEEE', 'id_ID').format(tomorrow);
          final listSlotBesok = (jadwalData[namaHariBesok] ?? jadwalData[namaHariBesok.toLowerCase()]) as List? ?? [];
          if (listSlotBesok.isNotEmpty) {
            listSlotBesok.sort((a,b) => (a['jam'] as String).compareTo(b['jam'] as String));
            final firstSlotBesok = listSlotBesok.first;
            tempCarouselItems.add(CarouselItemModel(namaKelas: "Kelas ${kelasId.split('-').first}", tipe: CarouselContentType.Info,
              judul: "Jadwal Besok", isi: firstSlotBesok['namaMapel'] ?? 'N/A',
              subJudul: "Jam: ${firstSlotBesok['jam'] ?? 'N/A'}", ikon: Icons.calendar_today_rounded, warna: Colors.orange.shade700));
          }
        }
      } else {
        tempCarouselItems.add(CarouselItemModel(namaKelas: "Info", tipe: CarouselContentType.Default, judul: "Selamat Belajar!", 
        isi: "Manfaatkan waktu sebaik-baiknya untuk menuntut ilmu.", 
        ikon: Icons.auto_stories, warna: Colors.green.shade800));
      }

      // [BARU] Informasi Halaqah Hari Ini
      final halaqahUmmiSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(uidSiswa)
        .collection('halaqah_setoran_ummi')
        .where('tanggalSetor', isGreaterThanOrEqualTo: Timestamp.fromDate(todayWithoutTime))
        .where('tanggalSetor', isLessThan: Timestamp.fromDate(todayWithoutTime.add(const Duration(days: 1))))
        .orderBy('tanggalSetor', descending: true)
        .limit(1).get();
    
    if (halaqahUmmiSnap.docs.isNotEmpty) {
      // Skenario 1: ADA setoran hari ini, tampilkan hasilnya
      final setoran = HalaqahSetoranUmmiModel.fromFirestore(halaqahUmmiSnap.docs.first);
      final penilaian = setoran.penilaian;
      
      String judul = "Setoran Halaqah Hari Ini";
      String isi = "${penilaian.status} (Nilai: ${penilaian.nilaiHuruf})";
      String subJudul = "Dinilai oleh: ${setoran.namaPenilai}";
      Color warna;
      IconData ikon;

      switch (penilaian.status) {
        case 'Lancar':
          warna = Colors.green.shade700;
          ikon = Icons.check_circle_outline_rounded;
          break;
        case 'Perlu Perbaikan':
          warna = Colors.orange.shade800;
          ikon = Icons.info_outline_rounded;
          break;
        case 'Mengulang':
          warna = Colors.red.shade700;
          ikon = Icons.repeat_rounded;
          break;
        default:
          warna = Colors.grey.shade700;
          ikon = Icons.hourglass_empty_rounded;
      }
      
      tempCarouselItems.add(CarouselItemModel(
        namaKelas: "Halaqah", tipe: CarouselContentType.Info,
        judul: judul, isi: isi, subJudul: subJudul,
        ikon: ikon, warna: warna
      ));
    } else {
      // Skenario 2: TIDAK ADA setoran hari ini, tampilkan progres terakhir
      final siswaData = configC.infoUser;
      if (siswaData.containsKey('halaqahUmmi')) {
        final halaqaData = siswaData['halaqahUmmi'] as Map<String, dynamic>;
        final progres = halaqaData['progres'] as Map<String, dynamic>? ?? {};

        String isi = "${progres['tingkat']} ${progres['detailTingkat']} - Halaman ${progres['halaman']}";
        String subJudul = "Pengampu: ${halaqaData['namaPengampu'] ?? 'N/A'}";

        tempCarouselItems.add(CarouselItemModel(
          namaKelas: "Halaqah", tipe: CarouselContentType.Default,
          judul: "Progres Halaqah Terkini", isi: isi, subJudul: subJudul,
          ikon: Icons.menu_book_rounded, warna: Colors.purple.shade700
        ));
      } else {
        // Fallback jika siswa belum punya data halaqah sama sekali
        tempCarouselItems.add(CarouselItemModel(
          namaKelas: "Halaqah", tipe: CarouselContentType.Default,
          judul: "Info Halaqah", isi: "Progres halaqah Ananda belum diatur.",
          ikon: Icons.help_outline_rounded, warna: Colors.blueGrey.shade700
        ));
      }
    }


      // [BARU] Rekap Absensi Siswa Harian (diri sendiri)
      final absensiSiswaSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(kelasId)
          .collection('daftarsiswa').doc(uidSiswa)
          .collection('semester').doc(semester)
          .collection('absensi_siswa').doc(DateFormat('yyyy-MM-dd').format(now)).get();
      
      if (absensiSiswaSnap.exists) {
        final statusAbsen = absensiSiswaSnap.data()?['status'] ?? 'Belum Tercatat';
        Color absensiColor = Colors.grey;
        String absensiDesc = "Status absensi hari ini: $statusAbsen";
        if (statusAbsen == 'Hadir') absensiColor = Colors.green.shade700;
        else if (statusAbsen == 'Sakit') absensiColor = Colors.orange.shade700;
        else if (statusAbsen == 'Izin') absensiColor = Colors.blue.shade700;
        else if (statusAbsen == 'Alfa') absensiColor = Colors.red.shade700;

        tempCarouselItems.add(CarouselItemModel(namaKelas: "Absensi", tipe: CarouselContentType.Info,
          judul: "Kehadiran Hari Ini", isi: absensiDesc,
          ikon: Icons.person_pin_rounded, warna: absensiColor));
      }

      // [BARU] Tugas/Ulangan Mendekat (atau yang Diumumkan Hari Ini)
      final tugasUlanganSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(kelasId)
          .collection('semester').doc(semester)
          .collection('tugas_ulangan')
          .where('tanggal_dibuat', isGreaterThanOrEqualTo: Timestamp.fromDate(todayWithoutTime))
          .orderBy('tanggal_dibuat', descending: true)
          .limit(1).get();

      if (tugasUlanganSnap.docs.isNotEmpty) {
        final tugas = tugasUlanganSnap.docs.first.data();
        final kategori = tugas['kategori'] ?? 'Tugas';
        final judulTugas = tugas['judul'] ?? 'Tanpa Judul';
        final deskripsiTugas = tugas['deskripsi'] ?? '';
        
        tempCarouselItems.add(CarouselItemModel(namaKelas: "Peringatan", tipe: CarouselContentType.Info,
          judul: "$kategori Baru", isi: "$judulTugas: $deskripsiTugas",
          ikon: kategori == 'PR' ? Icons.assignment_rounded : Icons.quiz_rounded, warna: Colors.purple.shade700));
      }

      daftarCarousel.assignAll(tempCarouselItems);

    } catch (e) {
      print("### Gagal membangun carousel: $e");
      daftarCarousel.assign(CarouselItemModel(namaKelas: "Error", tipe: CarouselContentType.Default, judul: "GAGAL MEMUAT DATA", isi: "Silakan coba lagi.", ikon: Icons.error_outline_rounded, warna: Colors.grey.shade700));
    } finally {
      isCarouselLoading.value = false;
      print("[HomeController] Carousel loading finished. DaftarCarousel size: ${daftarCarousel.length}");
    }
  }

  void _listenToNotifications() {
    final siswaRef = _siswaDocRef;
    if (siswaRef == null) {
      print("[HomeController] Not listening to notifications: _siswaDocRef is null.");
      _notificationMetadataSubscription?.cancel();
      _notificationMetadataSubscription = null;
      return;
    }

    _notificationMetadataSubscription?.cancel();
    _notificationMetadataSubscription = streamNotificationMetadata().listen((snapshot) {
      if (snapshot.exists) {
        final newCount = snapshot.data()?['unreadCount'] ?? 0;
        if (newCount > _previousUnreadCount) {
          _playNotificationSound();
        }
        _previousUnreadCount = newCount;
      }
    }, onError: (error) {
      print("Error listening to notification metadata: $error");
    });
  }

  void _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/notifikasi.mp3'));
    } catch (e) {
      print("Error saat memutar suara notifikasi: $e");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSemuaInfoSekolah() {
    final String tahunAjaran = configC.tahunAjaranAktif.value;
    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
      return const Stream.empty();
    }
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('info_sekolah')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamInfoDashboard() {
    final String tahunAjaran = configC.tahunAjaranAktif.value;
    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
      return const Stream.empty();
    }
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('info_sekolah')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();
  }

  void goToHalaqahRiwayat() {
    // Get.toNamed(Routes.HALAQAH_RIWAYAT_SISWA);
    Get.toNamed(Routes.HALAQAH_UMMI_RIWAYAT_SISWA);
  }

  void goToJadwalSiswa() {
    Get.toNamed(Routes.JADWAL_SISWA);
  }

  void goToSemuaInformasi() {
    Get.toNamed(Routes.INFO_SEKOLAH_LIST);
  }

  void goToEkskulSiswa() {
    Get.toNamed(Routes.EKSKUL_SISWA);
  }

  void goToKalenderAkademik() {
    Get.toNamed(Routes.KALENDER_AKADEMIK);
  }

  void logout() {
    authC.logout();
  }

  void goToEditProfil() {
    Get.toNamed(Routes.LENGKAPI_PROFIL, arguments: configC.infoUser);
  }

  void goToDaftarMapel() {
    Get.toNamed(Routes.DAFTAR_MATA_PELAJARAN);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserData() {
    final siswaRef = _siswaDocRef;
    if (siswaRef == null) return const Stream.empty();
    return siswaRef.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamLatestNotifications() {
    final siswaRef = _siswaDocRef;
    if (siswaRef == null) return const Stream.empty();
    return siswaRef
        .collection('notifikasi')
        .orderBy('tanggal', descending: true)
        .limit(5)
        .snapshots();
  }
  
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamNotificationMetadata() {
    final siswaRef = _siswaDocRef;
    if (siswaRef == null) return const Stream.empty();
    return siswaRef
        .collection('notifikasi_meta')
        .doc('metadata')
        .snapshots();
  }

  void goToSemuaNotifikasi() {
    final siswaRef = _siswaDocRef;
    if (siswaRef == null) {
      Get.snackbar("Peringatan", "Data pengguna belum siap. Silakan coba lagi.");
      return;
    }
    siswaRef
        .collection('notifikasi_meta')
        .doc('metadata')
        .set({'unreadCount': 0}, SetOptions(merge: true));
    
    Get.toNamed(Routes.SEMUA_NOTIFIKASI);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMataPelajaranSiswa() {
    final uid = _accountManager.currentActiveStudent.value?.uid;
    final kelasId = _accountManager.currentActiveStudent.value?.kelasId;

    final String tahunAjaran = configC.tahunAjaranAktif.value;
    final String semester = configC.semesterAktif.value;
    
    if (uid == null || kelasId == null || kelasId.isEmpty || tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK") || semester.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('daftarsiswa').doc(uid)
        .collection('semester').doc(semester)
        .collection('matapelajaran')
        .snapshots();
  }

  // [FIXED]: Method untuk Switch Akun
  void goToAccountSwitcher() {
    Get.toNamed(Routes.ACCOUNT_SWITCHER);
  }
}