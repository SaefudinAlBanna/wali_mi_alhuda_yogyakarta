// [READ-ONLY VERSION]
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/acara_kalender_model.dart';

class KalenderAkademikController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late final CollectionReference<Map<String, dynamic>> _acaraRef;
  StreamSubscription? _acaraSubscription;

  final RxMap<DateTime, List<AcaraKalender>> events = <DateTime, List<AcaraKalender>>{}.obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rxn<DateTime> selectedDay = Rxn<DateTime>();
  final Rx<CalendarFormat> calendarFormat = CalendarFormat.month.obs;
  final RxList<AcaraKalender> monthlyEvents = <AcaraKalender>[].obs;

  @override
  void onInit() {
    super.onInit();
    selectedDay.value = focusedDay.value;
    final String tahunAjaran = configC.tahunAjaranAktif.value;

    if (tahunAjaran.isNotEmpty && !tahunAjaran.contains("TIDAK")) {
      _acaraRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kalender_akademik');
      _listenToEvents();
    }
  }

  @override
  void onClose() {
    _acaraSubscription?.cancel();
    super.onClose();
  }

  void _listenToEvents() {
    _acaraSubscription = _acaraRef.snapshots().listen((snapshot) {
      final Map<DateTime, List<AcaraKalender>> tempEvents = {};
      for (var doc in snapshot.docs) {
        try {
          final acara = AcaraKalender.fromFirestore(doc);
          for (var day = acara.mulai; day.isBefore(acara.selesai.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
            final dateWithoutTime = DateTime(day.year, day.month, day.day);
            if (tempEvents[dateWithoutTime] == null) tempEvents[dateWithoutTime] = [];
            tempEvents[dateWithoutTime]!.add(acara);
          }
        } catch (e) {
          print("Error parsing acara: ${doc.id}, error: $e");
        }
      }
      events.value = tempEvents;
      _updateMonthlyEvents();
    }, onError: (error) {
      print("Error listening to calendar events: $error");
    });
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    if (!isSameDay(selectedDay.value, selected)) {
      selectedDay.value = selected;
      focusedDay.value = focused;
    }
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = focused;
    _updateMonthlyEvents();
  }

  void _updateMonthlyEvents() {
    final List<AcaraKalender> eventsInMonth = [];
    final Set<String> uniqueEventIds = {};
    events.forEach((date, acaraList) {
      if (date.month == focusedDay.value.month && date.year == focusedDay.value.year) {
        for (var acara in acaraList) {
          if (uniqueEventIds.add(acara.id)) eventsInMonth.add(acara);
        }
      }
    });
    eventsInMonth.sort((a, b) => a.mulai.compareTo(b.mulai));
    monthlyEvents.value = eventsInMonth;
  }

  List<AcaraKalender> getEventsForDay(DateTime day) {
    return events[DateTime(day.year, day.month, day.day)] ?? [];
  }
}