import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});

  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends State<RaporScreen> {
  String selectedLanguage = "Türkçe";
  String selectedReportDay = "Pazar";
  
  // Özet verileri tutacağımız değişkenler
  double totalWaterDrunk = 0.0;
  int totalStudyMinutes = 0;
  int totalReadPages = 0;
  int totalMeditationMinutes = 0;
  int completedBooksCount = 0;

  final List<String> languages = ["Türkçe", "English"];
  final List<String> days = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];

  @override
  void initState() {
    super.initState();
    _loadReportSettingsAndData();
  }

  // Hafızadan hem ayarları hem de diğer 14 modülden gelen verileri analiz eden fonksiyon
  _loadReportSettingsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      selectedLanguage = prefs.getString('rapor_dili') ?? "Türkçe";
      selectedReportDay = prefs.getString('rapor_günü') ?? "Pazar";

      // 1. SU MODÜLÜ ANALİZİ
      totalWaterDrunk = prefs.getDouble('su_bugun_icilen') ?? 0.0;

      // 2. DERS MODÜLÜ ANALİZİ
      List<String> studyLogs = prefs.getStringList('ders_calismalari') ?? [];
      totalStudyMinutes = 0;
      for (var log in studyLogs) {
        // Log formatı: "Ders Adı - 1.45 - Tarih"
        try {
          List<String> parts = log.split(' - ');
          if (parts.length >= 2) {
            double hours = double.tryParse(parts[1]) ?? 0.0;
            totalStudyMinutes += (hours * 60).round();
          }
        } catch (_) {}
      }

      // 3. KİTAP MODÜLÜ ANALİZİ
      String kitaplarStr = prefs.getString('kitap_listesi') ?? "[]";
      List<dynamic> decodedKitaplar = jsonDecode(kitaplarStr);
      totalReadPages = 0;
      completedBooksCount = 0;
      for (var item in decodedKitaplar) {
        totalReadPages += (item['okunanSayfa'] as int? ?? 0);
        if (item['bittiMi'] == 1 || item['bittiMi'] == true) {
          completedBooksCount++;
        }
      }

      // 4. MEDİTASYON MODÜLÜ ANALİZİ
      List<String> medLogs = prefs.getStringList('meditasyon_kayitlari') ?? [];
      totalMeditationMinutes = 0;
      for (var log in medLogs) {
        // Log formatı: "Tema - 20 dk - Tarih"
        try {
          List<String> parts = log.split(' - ');
          if (parts.length >= 2) {
            String minStr = parts[1].replaceAll(' dk', '');
            totalMeditationMinutes += int.tryParse(minStr) ?? 0;
          }
        } catch (_) {}
      }
    });
  }

  // Ayarları Hafızaya Kaydetme
  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rapor_dili', selectedLanguage);
    await prefs.setString('rapor_günü', selectedReportDay);
    _showSnackBar("Rapor tercihleri güncellendi!");
  }

  // Senin istediğin o akıllı ve dinamik feedback (Geri Bildirim) motoru
  String _generateFeedback() {
    String pztPazKurali = selectedLanguage == "Türkçe" 
        ? "Pazartesi - Pazar" 
        : "Pazar - Cumartesi";
        
    String text = "📊 **HAFTALIK ÖZET PERİYODU ($pztPazKurali):**\n\n";

    // Su Feedback'i
    if (totalWaterDrunk >= 2000) {
      text += "💧 **Su:** Bu hafta hidrasyon hedefini harika tutturdun, vücudun sana minnettar kanka!\n";
    } else {
      text += "💧 **Su:** Su tüketimin bu hafta biraz düşük kalmış, hücreleri susuz bırakma kanka.\n";
    }

    // Ders Feedback'i
    if (totalStudyMinutes > 0) {
      int hours = totalStudyMinutes ~/ 60;
      int mins = totalStudyMinutes % 60;
      text += "📚 **Ders Çalışma:** Bu hafta toplam $hours saat $mins dakika odaklandın. Mühendislik vizyonu tıkır tıkır işliyor! 🚀\n";
    } else {
      text += "📚 **Ders Çalışma:** Bu hafta hiç ders çalışma kaydı girmemişsin, finaller kapıda unutma kanka!\n";
    }

    // Kitap Feedback'i
    if (totalReadPages > 0) {
      text += "📖 **Kitap:** Haftalık bilançoda $totalReadPages sayfa yutulmuş! ";
      if (completedBooksCount > 0) {
        text += "Ayrıca tam $completedBooksCount kitap bitirip kütüphanene fırlattın, kralsın. 🎉\n";
      } else {
        text += "Kitabı bitirmeye az kalmış, tempoyu düşürme.\n";
      }
    } else {
      text += "📖 **Kitap:** Bu hafta sayfalar pek çevrilmemiş gibi, raflar tozlanmasın kanka.\n";
    }

    // Meditasyon Feedback'i
    if (totalMeditationMinutes > 0) {
      text += "🧘‍♂️ **Meditasyon:** Zihnini dinlendirmek için bu hafta $totalMeditationMinutes dakika ayırdın. İçsel huzur okey.\n";
    }

    text += "\n🔔 **Hatırlatma:** Haftalık raporun her **$selectedReportDay** günü senin seçtiğin ayarlara göre özel olarak derlenecektir.";
    return text;
  }

  _showSnackBar(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Akıllı Haftalık Rapor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ÖZELLEŞTİRME ALANI (DİL VE GÜN AYARI)
            Card(
              color: Colors.blueGrey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Rapor Tercihleri", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        // Dil Seçimi
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedLanguage,
                            decoration: const InputDecoration(labelText: "Rapor Dili", border: OutlineInputBorder()),
                            items: languages.map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedLanguage = value!;
                                _saveSettings();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Gün Seçimi
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedReportDay,
                            decoration: const InputDecoration(labelText: "Rapor Günü", border: OutlineInputBorder()),
                            items: days.map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedReportDay = value!;
                                _saveSettings();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 2. DİNAMİK ASİSTAN FEEDBACK PANELİ
            const Text("Asistan Değerlendirmesi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.blue.shade200)),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.analytics, color: Colors.blue, size: 28),
                        SizedBox(width: 10),
                        Text("Bu Haftaki Performansın", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    const Divider(height: 30),
                    Text(
                      _generateFeedback(),
                      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // VERİLERİ MANUEL YENİLEME BUTONU
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), foregroundColor: Colors.blueGrey),
                onPressed: _loadReportSettingsAndData,
                icon: const Icon(Icons.refresh),
                label: const Text("Verileri ve Analizi Yenile"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}