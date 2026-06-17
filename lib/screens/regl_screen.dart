import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReglScreen extends StatefulWidget {
  const ReglScreen({super.key});

  @override
  State<ReglScreen> createState() => _ReglScreenState();
}

class _ReglScreenState extends State<ReglScreen> {
  DateTime? lastPeriodDate;
  int cycleLength = 28;  // Varsayılan dünya ortalaması döngü süresi
  int periodLength = 5; // Varsayılan kanama süresi
  List<String> periodHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPeriodData();
  }

  // Hafızadan geçmiş regl verilerini yükleyen fonksiyon
  _loadPeriodData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      periodLength = prefs.getInt('regl_kanama_suresi') ?? 5;
      cycleLength = prefs.getInt('regl_dongu_suresi') ?? 28;
      
      String? lastDateStr = prefs.getString('regl_son_baslangic_tarihi');
      if (lastDateStr != null) {
        lastPeriodDate = DateTime.parse(lastDateStr);
      }
      
      periodHistory = prefs.getStringList('regl_gecmis_listesi') ?? [];
    });
  }

  // Yeni regl dönemi ekleme ve dinamik döngü ortalaması hesaplama motoru
  _addPeriodDate(DateTime pickedDate) async {
    final prefs = await SharedPreferences.getInstance();
    String pickedDateStr = pickedDate.toIso8601String().split('T')[0];

    // Eğer aynı gün zaten ekliyse tekrar eklemesin
    if (periodHistory.contains(pickedDateStr)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu tarih zaten geçmişinizde kayıtlı kanka!")),
        );
      }
      return;
    }

    setState(() {
      // Eğer daha önce girilmiş bir tarih varsa, yeni girilen tarihle arasındaki gün farkını bulup döngüyü güncelliyoruz
      if (lastPeriodDate != null) {
        int difference = pickedDate.difference(lastPeriodDate!).inDays.abs();
        // Mantıklı bir döngü süresiyse (21 ile 40 gün arasındaysa) döngü süresini kişiye özel güncelle
        if (difference >= 21 && difference <= 40) {
          cycleLength = difference;
          prefs.setInt('regl_dongu_suresi', cycleLength);
        }
      }

      lastPeriodDate = pickedDate;
      periodHistory.add(pickedDateStr);
      // Geçmişi yeniden eskiye doğru sırala
      periodHistory.sort((a, b) => b.compareTo(a));
    });

    await prefs.setString('regl_son_baslangic_tarihi', pickedDate.toIso8601String());
    await prefs.setStringList('regl_gecmis_listesi', periodHistory);
  }

  // Takvimden regl başlangıç tarihi seçtiren fonksiyon
  _selectPeriodDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _addPeriodDate(picked);
    }
  }

  // Akıllı Tahmin Çıktıları Alanı
  Map<String, dynamic> _calculatePredictions() {
    if (lastPeriodDate == null) {
      return {
        'daysLeft': 0,
        'nextDateStr': "Veri Yok",
        'status': "Lütfen son regl tarihinizi girerek takip başlatın kanka."
      };
    }

    DateTime nextPeriodDate = lastPeriodDate!.add(Duration(days: cycleLength));
    DateTime today = DateTime.now();
    
    // Sadece gün bazlı karşılaştırma yapabilmek için saatleri sıfırlıyoruz kanka
    DateTime todayPure = DateTime(today.year, today.month, today.day);
    DateTime nextPure = DateTime(nextPeriodDate.year, nextPeriodDate.month, nextPeriodDate.year == today.year ? nextPeriodDate.month : nextPeriodDate.month, nextPeriodDate.day);

    int daysLeft = nextPeriodDate.difference(todayPure).inDays;
    String nextDateStr = "${nextPeriodDate.day}.${nextPeriodDate.month}.${nextPeriodDate.year}";
    String status = "";

    if (daysLeft > 0) {
      status = "Sonraki regl döneminiz tahminlere göre $nextDateStr tarihinde başlayacak.";
    } else if (daysLeft == 0) {
      status = "Tahmin motoruna göre bugün regl gününüz kanka! 🔔";
    } else {
      status = "Regl döneminiz gecikmiş görünüyor (${daysLeft.abs()} gün).";
    }

    return {
      'daysLeft': daysLeft,
      'nextDateStr': nextDateStr,
      'status': status
    };
  }

  @override
  Widget build(BuildContext context) {
    var prediction = _calculatePredictions();
    int daysLeft = prediction['daysLeft'];

    return Scaffold(
      appBar: AppBar(title: const Text("Regl Döngüsü Takibi")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // 1. ÜST BÖLÜM: BÜYÜK SAYAÇ HALKASI (FLO TARZI)
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: lastPeriodDate != null ? Colors.pink.shade50 : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: lastPeriodDate != null ? Colors.pink : Colors.grey, 
                  width: 4
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (lastPeriodDate == null) ...[
                    const Icon(Icons.calendar_today, size: 40, color: Colors.grey),
                    const SizedBox(height: 5),
                    const Text("Veri Yok", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ] else ...[
                    Text(
                      daysLeft >= 0 ? "$daysLeft" : "${daysLeft.abs()}",
                      style: TextStyle(
                        fontSize: 48, 
                        fontWeight: FontWeight.bold, 
                        color: daysLeft >= 0 ? Colors.pink.shade900 : Colors.red.shade900
                      ),
                    ),
                    Text(
                      daysLeft >= 0 ? "GÜN KALDI" : "GÜN GECİKTİ", 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)
                    ),
                  ]
                ],
              ),
            ),
          ),

          // 2. TAHMİN BİLGİLENDİRME KARTI
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              color: Colors.pink.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  prediction['status'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
                ),
              ),
            ),
          ),

          // REGL GİRİŞ BUTONU
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)
                ),
                onPressed: () => _selectPeriodDate(context),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Regl Başlangıcı Ekle", style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          
          const Divider(height: 40, thickness: 1),

          // 3. ALT BÖLÜM: GEÇMİŞ DÖNGÜLER LİSTESİ
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Geçmiş Dönemler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: periodHistory.isEmpty
                ? const Center(child: Text("Henüz kaydedilmiş bir geçmiş yok."))
                : ListView.builder(
                    itemCount: periodHistory.length,
                    itemBuilder: (context, index) {
                      String dateStr = periodHistory[index];
                      // YYYY-MM-DD formatını DD.MM.YYYY formatına çeviriyoruz kanka
                      List<String> parts = dateStr.split('-');
                      String formatted = "${parts[2]}.${parts[1]}.${parts[0]}";

                      return ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.pink),
                        title: Text("$formatted tarihinde başladı"),
                        trailing: Text("$cycleLength Günlük Döngü", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}