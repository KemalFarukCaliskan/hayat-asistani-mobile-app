import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UykuScreen extends StatefulWidget {
  const UykuScreen({super.key});

  @override
  State<UykuScreen> createState() => _UykuScreenState();
}

class _UykuScreenState extends State<UykuScreen> {
  TimeOfDay sleepTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
  
  int userAge = 20; // Varsayılan yaş (hafızadan çekilecek)
  double totalSleepHours = 8.0;
  String sleepFeedback = "";

  @override
  void initState() {
    super.initState();
    _loadUserDataAndCalculate();
  }

  // Kullanıcının yaşını çekip uyku hesabı yapan fonksiyon
  _loadUserDataAndCalculate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userAge = prefs.getInt('user_age') ?? 20;
      _calculateSleep();
    });
  }

  // Uyku süresini ve yeterlilik durumunu hesaplayan motor
  _calculateSleep() {
    // Saatleri DateTime formatına çevirip farkı buluyoruz kanka
    final now = DateTime.now();
    final sleepDateTime = DateTime(now.year, now.month, now.day, sleepTime.hour, sleepTime.minute);
    var wakeDateTime = DateTime(now.year, now.month, now.day, wakeTime.hour, wakeTime.minute);

    // Eğer uyanma saati uyuma saatinden küçükse, kullanıcı ertesi gün uyanmıştır (Örn: 23:00'da uyuyup 07:00'da uyanmak)
    if (wakeDateTime.isBefore(sleepDateTime)) {
      wakeDateTime = wakeDateTime.add(const Duration(days: 1));
    }

    final difference = wakeDateTime.difference(sleepDateTime);
    totalSleepHours = difference.inMinutes / 60.0;

    // Yaşa göre bilimsel ideal uyku kontrolü (Genç ve Yetişkinler için 7-9 saat arası)
    if (totalSleepHours >= 7.0 && totalSleepHours <= 9.0) {
      sleepFeedback = "Harika kanka! İdeal uyku süresini (7-9 saat) tam tutturdun. Bugün enerjin tavan yapacak! ⚡";
    } else if (totalSleepHours < 7.0) {
      sleepFeedback = "⚠️ Yetersiz uyku! İdeal sürenin altında kaldın. İlerleyen zamanlarda odaklanma sorunu yaşamamak için bu gece erken yat kanka.";
    } else {
      sleepFeedback = "😴 Fazla uyku! 9 saatin üzerinde uyumuşsun. Bazen fazla uyku da sersemlik yapabilir, kalk bir kahve çak kendine gel kanka.";
    }
  }

  // Uyuma saati seçici çark
  _selectSleepTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: sleepTime,
    );
    if (picked != null) {
      setState(() {
        sleepTime = picked;
        _calculateSleep();
      });
    }
  }

  // Uyanma saati seçici çark
  _selectWakeTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: wakeTime,
    );
    if (picked != null) {
      setState(() {
        wakeTime = picked;
        _calculateSleep();
      });
    }
  }

  // Veriyi haftalık raporlama için hafızaya kaydetme
  _saveSleepRecord() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sleepLogs = prefs.getStringList('uyku_kayitlari') ?? [];
    
    String recordStr = "Süre: ${totalSleepHours.toStringAsFixed(1)} sa - Tarih: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";
    sleepLogs.add(recordStr);
    
    await prefs.setStringList('uyku_kayitlari', sleepLogs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uyku kaydınız başarıyla haftalık rapora eklendi! 🎉")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Uyku Takibi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. ÜST BÖLÜM: SAAT SEÇİM ALANI
            Card(
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Uyku Zamanı Butonu
                    Column(
                      children: [
                        const Text("Uyadığın Saat", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          onPressed: () => _selectSleepTime(context),
                          icon: const Icon(Icons.bedtime),
                          label: Text(sleepTime.format(context)),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.indigo),
                    // Uyanma Zamanı Butonu
                    Column(
                      children: [
                        const Text("Uyardığın Saat", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                          onPressed: () => _selectWakeTime(context),
                          icon: const Icon(Icons.wb_sunny),
                          label: Text(wakeTime.format(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 35),

            // 2. ORTA BÖLÜM: NET SÜRE GÖSTERGESİ
            const Text("Toplam Uyku Süren", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(
              "${totalSleepHours.toStringAsFixed(1)} Saat",
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 25),

            // 3. DEĞERLENDİRME BİLGİ KARTI
            Card(
              color: Colors.grey.shade100,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.indigo, size: 28),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        sleepFeedback,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 4. ALT BÖLÜM: KAYDETME BUTONU
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)
                ),
                onPressed: _saveSleepRecord,
                child: const Text("Uykuyu Kaydet ve Raporla", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}