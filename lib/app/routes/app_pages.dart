import 'package:get/get.dart';

import '../modules/account_switcher/bindings/account_switcher_binding.dart';
import '../modules/account_switcher/views/account_switcher_view.dart';
import '../modules/catatan_bk/bindings/catatan_bk_binding.dart';
import '../modules/catatan_bk/views/catatan_bk_detail_view.dart';
import '../modules/catatan_bk/views/catatan_bk_list_view.dart';
import '../modules/daftar_mata_pelajaran/bindings/daftar_mata_pelajaran_binding.dart';
import '../modules/daftar_mata_pelajaran/views/daftar_mata_pelajaran_view.dart';
import '../modules/daftar_nilai_matapelajaran/bindings/daftar_nilai_matapelajaran_binding.dart';
import '../modules/daftar_nilai_matapelajaran/views/daftar_nilai_matapelajaran_view.dart';
import '../modules/daftar_pembayaran_komite/bindings/daftar_pembayaran_komite_binding.dart';
import '../modules/daftar_pembayaran_komite/views/daftar_pembayaran_komite_view.dart';
import '../modules/daftar_spp/bindings/daftar_spp_binding.dart';
import '../modules/daftar_spp/views/daftar_spp_view.dart';
import '../modules/detail_keuangan_siswa/bindings/detail_keuangan_siswa_binding.dart';
import '../modules/detail_keuangan_siswa/views/detail_keuangan_siswa_view.dart';
import '../modules/detail_mapel_siswa/bindings/detail_mapel_siswa_binding.dart';
import '../modules/detail_mapel_siswa/views/detail_mapel_siswa_view.dart';
import '../modules/ekskul_siswa/bindings/ekskul_siswa_binding.dart';
import '../modules/ekskul_siswa/views/ekskul_siswa_view.dart';
import '../modules/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/forgot_password/views/forgot_password_view.dart';
import '../modules/halaqah-ummi-riwayat-siswa/bindings/halaqah_ummi_riwayat_siswa_binding.dart';
import '../modules/halaqah-ummi-riwayat-siswa/views/halaqah_ummi_riwayat_siswa_view.dart';
import '../modules/halaqah_riwayat_siswa/bindings/halaqah_riwayat_siswa_binding.dart';
import '../modules/halaqah_riwayat_siswa/views/halaqah_riwayat_siswa_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/info_sekolah/bindings/info_sekolah_binding.dart';
import '../modules/info_sekolah/views/info_sekolah_view.dart';
import '../modules/info_sekolah_detail/bindings/info_sekolah_detail_binding.dart';
import '../modules/info_sekolah_detail/views/info_sekolah_detail_view.dart';
import '../modules/info_sekolah_list/bindings/info_sekolah_list_binding.dart';
import '../modules/info_sekolah_list/views/info_sekolah_list_view.dart';
import '../modules/input_dana_komite/bindings/input_dana_komite_binding.dart';
import '../modules/input_dana_komite/views/input_dana_komite_view.dart';
import '../modules/input_jadwal_agis/bindings/input_jadwal_agis_binding.dart';
import '../modules/input_jadwal_agis/views/input_jadwal_agis_view.dart';
import '../modules/jadwal_agis/bindings/jadwal_agis_binding.dart';
import '../modules/jadwal_agis/views/jadwal_agis_view.dart';
import '../modules/jadwal_siswa/bindings/jadwal_siswa_binding.dart';
import '../modules/jadwal_siswa/views/jadwal_siswa_view.dart';
import '../modules/kalender_akademik/bindings/kalender_akademik_binding.dart';
import '../modules/kalender_akademik/views/kalender_akademik_view.dart';
import '../modules/kas_komite/bindings/kas_komite_binding.dart';
import '../modules/kas_komite/views/kas_komite_view.dart';
import '../modules/laporan_komite/bindings/laporan_komite_binding.dart';
import '../modules/laporan_komite/views/laporan_komite_view.dart';
import '../modules/lengkapi_profil/bindings/lengkapi_profil_binding.dart';
import '../modules/lengkapi_profil/views/lengkapi_profil_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/manajemen_agis/bindings/manajemen_agis_binding.dart';
import '../modules/manajemen_agis/views/manajemen_agis_view.dart';
import '../modules/manajemen_iuran/bindings/manajemen_iuran_binding.dart';
import '../modules/manajemen_iuran/views/manajemen_iuran_view.dart';
import '../modules/manajemen_komite_sekolah/bindings/manajemen_komite_sekolah_binding.dart';
import '../modules/manajemen_komite_sekolah/views/manajemen_komite_sekolah_view.dart';
import '../modules/marketplace/bindings/marketplace_binding.dart';
import '../modules/marketplace/views/marketplace_view.dart';
import '../modules/new_password/bindings/new_password_binding.dart';
import '../modules/new_password/views/new_password_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/pembelian_buku/bindings/pembelian_buku_binding.dart';
import '../modules/pembelian_buku/views/pembelian_buku_view.dart';
import '../modules/root/bindings/root_binding.dart';
import '../modules/root/views/root_view.dart';
import '../modules/semua_notifikasi/bindings/semua_notifikasi_binding.dart';
import '../modules/semua_notifikasi/views/semua_notifikasi_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/tampilkan_info_sekolah/bindings/tampilkan_info_sekolah_binding.dart';
import '../modules/tampilkan_info_sekolah/views/tampilkan_info_sekolah_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.NEW_PASSWORD,
      page: () => const NewPasswordView(),
      binding: NewPasswordBinding(),
    ),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_MATA_PELAJARAN,
      page: () => DaftarMataPelajaranView(),
      binding: DaftarMataPelajaranBinding(),
    ),
    GetPage(
      name: _Paths.INFO_SEKOLAH,
      page: () => InfoSekolahView(),
      binding: InfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.TAMPILKAN_INFO_SEKOLAH,
      page: () => TampilkanInfoSekolahView(),
      binding: TampilkanInfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.ACCOUNT_SWITCHER,
      page: () => const AccountSwitcherView(),
      binding: AccountSwitcherBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SPP,
      page: () => const DaftarSppView(),
      binding: DaftarSppBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_PEMBAYARAN_KOMITE,
      page: () => const DaftarPembayaranKomiteView(),
      binding: DaftarPembayaranKomiteBinding(),
    ),
    GetPage(
      name: _Paths.JADWAL_AGIS,
      page: () => const JadwalAgisView(),
      binding: JadwalAgisBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_JADWAL_AGIS,
      page: () => const InputJadwalAgisView(),
      binding: InputJadwalAgisBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_DANA_KOMITE,
      page: () => const InputDanaKomiteView(),
      binding: InputDanaKomiteBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_NILAI_MATAPELAJARAN,
      page: () => const DaftarNilaiMatapelajaranView(),
      binding: DaftarNilaiMatapelajaranBinding(),
    ),
    GetPage(
      name: _Paths.INFO_SEKOLAH_DETAIL,
      page: () => const InfoSekolahDetailView(),
      binding: InfoSekolahDetailBinding(),
    ),
    GetPage(
      name: _Paths.ROOT,
      page: () => const RootView(),
      binding: RootBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.LENGKAPI_PROFIL,
      page: () => const LengkapiProfilView(),
      binding: LengkapiProfilBinding(),
    ),
    GetPage(
      name: _Paths.SEMUA_NOTIFIKASI,
      page: () => const SemuaNotifikasiView(),
      binding: SemuaNotifikasiBinding(),
    ),
    GetPage(
      name: _Paths.DETAIL_MAPEL_SISWA,
      page: () => const DetailMapelSiswaView(),
      binding: DetailMapelSiswaBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_RIWAYAT_SISWA,
      page: () => const HalaqahRiwayatSiswaView(),
      binding: HalaqahRiwayatSiswaBinding(),
    ),
    GetPage(
      name: _Paths.EKSKUL_SISWA,
      page: () => const EkskulSiswaView(),
      binding: EkskulSiswaBinding(),
    ),
    GetPage(
      name: _Paths.KALENDER_AKADEMIK,
      page: () => const KalenderAkademikView(),
      binding: KalenderAkademikBinding(),
    ),
    GetPage(
      name: _Paths.INFO_SEKOLAH_LIST,
      page: () => const InfoSekolahListView(),
      binding: InfoSekolahListBinding(),
    ),
    GetPage(
      name: _Paths.JADWAL_SISWA,
      page: () => const JadwalSiswaView(),
      binding: JadwalSiswaBinding(),
    ),
    GetPage(
      name: _Paths.MARKETPLACE,
      page: () => const MarketplaceView(),
      binding: MarketplaceBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.DETAIL_KEUANGAN_SISWA,
      page: () => const DetailKeuanganSiswaView(),
      binding: DetailKeuanganSiswaBinding(),
    ),
    GetPage(
      name: _Paths.PEMBELIAN_BUKU,
      page: () => const PembelianBukuView(),
      binding: PembelianBukuBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_IURAN,
      page: () => const ManajemenIuranView(),
      binding: ManajemenIuranBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_AGIS,
      page: () => const ManajemenAgisView(),
      binding: ManajemenAgisBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_KOMITE_SEKOLAH,
      page: () => const ManajemenKomiteSekolahView(),
      binding: ManajemenKomiteSekolahBinding(),
    ),
    GetPage(
      name: _Paths.KAS_KOMITE,
      page: () => const KasKomiteView(),
      binding: KasKomiteBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_KOMITE,
      page: () => const LaporanKomiteView(),
      binding: LaporanKomiteBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_RIWAYAT_SISWA,
      page: () => const HalaqahUmmiRiwayatSiswaView(),
      binding: HalaqahUmmiRiwayatSiswaBinding(),
    ),
    GetPage(
      name: _Paths.CATATAN_BK_LIST,
      page: () => const CatatanBkListView(),
      binding: CatatanBkBinding(),
    ),
    GetPage(
      name: _Paths.CATATAN_BK_DETAIL,
      page: () => const CatatanBkDetailView(),
      binding: CatatanBkBinding(),
    ),
  ];
}
