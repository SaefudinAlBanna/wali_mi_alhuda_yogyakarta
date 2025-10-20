// [READ-ONLY VERSION]
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../models/acara_kalender_model.dart';
import '../controllers/kalender_akademik_controller.dart';

class KalenderAkademikView extends GetView<KalenderAkademikController> {
  const KalenderAkademikView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kalender Akademik")),
      body: Obx(() {
        // Tampilkan loading jika tahun ajaran belum siap
        if (controller.configC.isKonfigurasiLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        // Tampilkan pesan jika tidak ada tahun ajaran aktif
        if (controller.configC.tahunAjaranAktif.value.contains("TIDAK")) {
          return const Center(child: Text("Kalender akademik belum tersedia."));
        }
        // Tampilkan kalender jika semua sudah siap
        return Column(
          children: [
            _buildTableCalendar(),
            _buildAgendaHeader(),
            Expanded(child: _buildMonthlyEventList()),
          ],
        );
      }),
    );
  }

  Widget _buildTableCalendar() {
    // Kode ini identik dengan versi final di Aplikasi Sekolah
    return Obx(() => TableCalendar<AcaraKalender>(
          locale: 'id_ID',
          firstDay: DateTime.utc(2022, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: controller.focusedDay.value,
          selectedDayPredicate: (day) => isSameDay(controller.selectedDay.value, day),
          calendarFormat: controller.calendarFormat.value,
          eventLoader: controller.getEventsForDay,
          holidayPredicate: (day) {
            return controller.getEventsForDay(day).any((acara) => acara.isLibur);
          },
          onDaySelected: controller.onDaySelected,
          onFormatChanged: (format) => controller.calendarFormat.value = format,
          onPageChanged: controller.onPageChanged,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  bottom: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((event) {
                      final acara = event as AcaraKalender;
                      return Container(
                        width: 7, height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: acara.warna),
                      );
                    }).toList(),
                  ),
                );
              }
              return null;
            },
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Colors.orange.shade200, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Get.theme.primaryColor.withOpacity(0.7), shape: BoxShape.circle),
            holidayTextStyle: const TextStyle(color: Colors.red),
          ),
          headerStyle: const HeaderStyle(formatButtonShowsNext: false, titleCentered: true),
        ));
  }

  Widget _buildAgendaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Obx(() => Text(
            "Agenda Bulan ${DateFormat('MMMM yyyy', 'id_ID').format(controller.focusedDay.value)}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          )),
    );
  }

  Widget _buildMonthlyEventList() {
    return Obx(() {
      if (controller.monthlyEvents.isEmpty) {
        return const Center(child: Text("Tidak ada agenda pada bulan ini.", style: TextStyle(color: Colors.grey)));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.monthlyEvents.length,
        itemBuilder: (context, index) {
          final acara = controller.monthlyEvents[index];
          final tglMulai = DateFormat('d', 'id_ID').format(acara.mulai);
          final tglSelesai = DateFormat('d MMM yyyy', 'id_ID').format(acara.selesai);
          final tanggal = acara.mulai.day == acara.selesai.day
              ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(acara.mulai)
              : "$tglMulai - $tglSelesai";
              
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: Container(width: 8, decoration: BoxDecoration(color: acara.warna, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)))),
              title: Text(acara.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(tanggal),
              isThreeLine: false, // [READ-ONLY] Disederhanakan
            ),
          );
        },
      );
    });
  }
}