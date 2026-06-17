import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AntrenmanScreen extends StatefulWidget {
  const AntrenmanScreen({super.key});

  @override
  State<AntrenmanScreen> createState() => _AntrenmanScreenState();
}

class _AntrenmanScreenState extends State<AntrenmanScreen> {
  double userKilo = 70.0; // Varsayılan kilo (profilden çekilecek)
  String selectedSport = "Fitness";
  int durationMinutes = 30;

  double burnedCalories = 0.0;
  String developmentFeedback = "";

  final durationController = TextEditingController();

  // Spor türleri ve bilimsel MET değerleri (Kilo başına saatlik harcanan enerji çarpanı)
  final Map<String, double> sportMetValues = {
    "Fitness": 5.0,
    "Koşu": 9.8,
    "Yüzme": 5.8,
    "Bisiklet": 7.5,
    "Toplu Sporlar (Futbol/Basketbol)": 7.0,
    "Yoga": 2.5,
    "Pilates": 3.0,
    "Powerlifting": 6.0,
    "Yürüyüş": 3.5,
  };

  @override
  void initState() {
    super.initState();
    _loadUserKiloAndCalculate();
  }

  @override
  void dispose() {
    durationController.dispose();
    super.dispose();
  }

  // Hafızadan kullanıcının kilosunu çeken fonksiyon (Madde 3 entegrasyonu)
  _loadUserKiloAndCalculate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userKilo = prefs.getDouble('user_kilo') ?? 70.0;
      durationController.text = durationMinutes.toString();
      _calculateBurnedCalories();
    });
  }

  // Kiloya ve Spor Türüne Özel Bilimsel Kalori Hesaplama Motoru
  _calculateBurnedCalories() {
    double met = sportMetValues[selectedSport] ?? 5.0;
    int duration = int.tryParse(durationController.text) ?? 30;
    
    setState(() {
      durationMinutes = duration;
      // Formül: MET * 3.5 * Kilo / 200 * Süre (Dakika)
      burnedCalories = met * 3.5 * userKilo / 200 * durationMinutes;
      _generateDevelopmentFeedback();
    });
  }

  // Spor türüne göre gelişim çıktısı üreten asistan motoru
  _generateDevelopmentFeedback() {
    if (selectedSport == "Fitness" || selectedSport == "Powerlifting") {
      developmentFeedback = "💪 Bu antrenman senin kas kütleni artırırken, kemik yoğunluğunu ve patlayıcı gücünü tepeye çıkardı devrem. Harika bir anaerobik gelişim!";
    } else if (selectedSport == "Koşu" || selectedSport == "Bisiklet" || selectedSport == "Yüzme") {
      developmentFeedback = "🫁 Harika bir kardiyo seansı! Bu aktivite senin akciğer kapasiteni, kalp sağlığını ve dayanıklılığını maksimum seviyede geliştirdi.";
    } else if (selectedSport == "Yoga" || selectedSport == "Pilates") {
      developmentFeedback = "🧘‍♂️ Esneklik ve denge tavan! Bu antrenman senin merkez (core) bölgesini güçlendirirken, kas boyunu uzattı ve zihinsel odaklanmanı keskinleştirdi.";
    } else if (selectedSport == "Yürüyüş") {
      developmentFeedback = "🚶‍♂️ Harika bir aktif toparlanma (recovery) ve yağ yakım seansı. Eklemlerini zorlamadan metabolizmanı tıkır tıkır çalıştırdın.";
    } else {
      developmentFeedback = "⚽ Takım ruhu ve koordinasyon! Bu toplu spor seansı senin çevikliğini, reaksiyon hızını ve yüksek yoğunluklu dayanıklılığını acayip geliştirdi.";
    }
  }

  // Antrenmanı haftalık rapora kaydetme fonksiyonu
  _saveAntrenmanLog() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> workoutLogs = prefs.getStringList('antrenman_kayitlari') ?? [];
    
    String recordStr = "Spor: $selectedSport - Süre: $durationMinutes dk - Kalori: ${burnedCalories.toStringAsFixed(0)} kcal - Tarih: ${DateTime.now().day}.${DateTime.now().month}";
    workoutLogs.add(recordStr);
    
    await prefs.setStringList('antrenman_kayitlari', workoutLogs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Antrenman kaydı haftalık rapora fırlatıldı! 🔥")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Akıllı Antrenman")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           // KİLO BİLGİSİ GÖSTERİMİ
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Mevcut Kilonuz: $userKilo kg (Hesaplamalar bu kiloya göre yapılır)",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SPOR TÜRÜ SEÇİMİ
            const Text("Yapılan Spor Türü", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              value: selectedSport,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: sportMetValues.keys.map((String sport) {
                return DropdownMenuItem<String>(value: sport, child: Text(sport));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedSport = newValue!;
                  _calculateBurnedCalories();
                });
              },
            ),
            const SizedBox(height: 20),

            // SÜRE GİRİŞİ
            const Text("Aktivite Süresi (Dakika)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Örn: 45"),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateBurnedCalories(),
            ),
            const SizedBox(height: 30),

            // CANLI SONUÇ PANELİ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    "~${burnedCalories.toStringAsFixed(0)} kcal",
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text("YAKILAN TAHMİNİ ENERJİ", style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // GELİŞİM ÇIKTISI KUTUSU (Senin İstediğin Güzel Çıktılar)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  developmentFeedback,
                  style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // KAYDETME BUTONU
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade900, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)
                ),
                onPressed: _saveAntrenmanLog,
                icon: const Icon(Icons.bookmark_add),
                label: const Text("Antrenmanı Kaydet ve Raporla", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}