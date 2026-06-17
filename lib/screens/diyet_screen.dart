import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiyetScreen extends StatefulWidget {
  const DiyetScreen({super.key});

  @override
  State<DiyetScreen> createState() => _DiyetScreenState();
}

class _DiyetScreenState extends State<DiyetScreen> {
  // Profil Verileri
  int userAge = 20;
  double userHeight = 175.0;
  double userKilo = 70.0;
  String userGender = "Erkek";

  // Manuel Giriş Kontrolü (Senin İstediğin Anahtar Detay)
  bool isManuelInput = false;

  // Manuel Giriş Controller'ları
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final kiloController = TextEditingController();

  // Diyet Seçimleri
  String activityLevel = "Hafif Aktif";
  String dietGoal = "Kilo Korumak";

  // Hesaplanan Nihai Hedefler
  double targetCalories = 2000;
  double targetProtein = 150;
  double targetCarb = 200;
  double targetFat = 70;

  final List<String> activityLevels = ["Sedanter (Hareketsiz)", "Hafif Aktif", "Orta Aktif", "Çok Aktif"];
  final List<String> dietGoals = ["Kilo Vermek", "Kilo Korumak", "Kas Kazanarak Kilo Almak", "Hızlı Kilo Almak (Dirty Bulk)"];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    kiloController.dispose();
    super.dispose();
  }

  // Hafızadan profil bilgilerini çeken fonksiyon
  _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userAge = prefs.getInt('user_age') ?? 20;
      userHeight = prefs.getDouble('user_height') ?? 175.0;
      userKilo = prefs.getDouble('user_kilo') ?? 70.0;
      userGender = prefs.getString('user_gender') ?? "Erkek";
      
      activityLevel = prefs.getString('diyet_hareket_sikligi') ?? "Hafif Aktif";
      dietGoal = prefs.getString('diyet_hedefi') ?? "Kilo Korumak";

      // Manuel controller'ları da başlangıçta dolduralım kanka kolaylık olsun
      ageController.text = userAge.toString();
      heightController.text = userHeight.toStringAsFixed(0);
      kiloController.text = userKilo.toStringAsFixed(1);

      _calculateMacroDistribution();
    });
  }

  // Akıllı Hesaplama Motoru (İster Profil, İster Manuel Veriyi İşler)
  _calculateMacroDistribution() {
    double bmr = 0.0;

    // Eğer manuel giriş aktifse controller'lardaki değerleri al, değilse profili al devrem
    int currentAge = isManuelInput ? (int.tryParse(ageController.text) ?? userAge) : userAge;
    double currentHeight = isManuelInput ? (double.tryParse(heightController.text) ?? userHeight) : userHeight;
    double currentKilo = isManuelInput ? (double.tryParse(kiloController.text) ?? userKilo) : userKilo;

    // 1. Adım: BMR Hesaplama
    if (userGender == "Erkek") {
      bmr = (10 * currentKilo) + (6.25 * currentHeight) - (5 * currentAge) + 5;
    } else {
      bmr = (10 * currentKilo) + (6.25 * currentHeight) - (5 * currentAge) - 161;
    }

    // 2. Adım: Hareket Sıklığı Çarpanı
    double multiplier = 1.2;
    if (activityLevel == "Hafif Aktif") multiplier = 1.375;
    if (activityLevel == "Orta Aktif") multiplier = 1.55;
    if (activityLevel == "Çok Aktif") multiplier = 1.725;

    double tdee = bmr * multiplier;

    // 3. Adım: Hedefe Göre Dağılım
    if (dietGoal == "Kilo Vermek") {
      targetCalories = tdee - 500;
      targetProtein = (targetCalories * 0.40) / 4;
      targetCarb = (targetCalories * 0.35) / 4;
      targetFat = (targetCalories * 0.25) / 9;
    } else if (dietGoal == "Kas Kazanarak Kilo Almak") {
      targetCalories = tdee + 300;
      targetProtein = (targetCalories * 0.30) / 4;
      targetCarb = (targetCalories * 0.50) / 4;
      targetFat = (targetCalories * 0.20) / 9;
    } else if (dietGoal == "Hızlı Kilo Almak (Dirty Bulk)") {
      targetCalories = tdee + 700;
      targetProtein = (targetCalories * 0.25) / 4;
      targetCarb = (targetCalories * 0.55) / 4;
      targetFat = (targetCalories * 0.20) / 9;
    } else {
      targetCalories = tdee;
      targetProtein = (targetCalories * 0.25) / 4;
      targetCarb = (targetCalories * 0.50) / 4;
      targetFat = (targetCalories * 0.25) / 9;
    }
  }

  _saveDietSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('diyet_hareket_sikligi', activityLevel);
    await prefs.setString('diyet_hedefi', dietGoal);
    await prefs.setDouble('diyet_hedef_kalori', targetCalories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Akıllı Diyet & Makro")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SİZİN ONAYLAMA VEYA DEĞİŞTİRME SEÇENEĞİNİZ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Profil Verilerimi Kullan", style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: !isManuelInput, // Manuel değilse profili kullan aktiftir devrem
                  activeColor: Colors.orange,
                  onChanged: (value) {
                    setState(() {
                      isManuelInput = !value;
                      if (!value) {
                        // Manuel modu açıldıysa mevcut verileri doldur
                        ageController.text = userAge.toString();
                        heightController.text = userHeight.toStringAsFixed(0);
                        kiloController.text = userKilo.toStringAsFixed(1);
                      }
                      _calculateMacroDistribution();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // DURUMA GÖRE AÇILAN PANEL
            if (!isManuelInput)
              // Profil Verileri Kartı (Onay modu)
              Card(
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Onaylanan Profil Değerleri (Yaş: $userAge | Boy: ${userHeight.toStringAsFixed(0)}cm | Kilo: ${userKilo.toStringAsFixed(1)}kg)", 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.orange)),
                    ],
                  ),
                ),
              )
            else
              // Manuel Giriş Alanları (Onaylamazsa kendi yeni değerler yazar kısmı)
              Card(
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ageController,
                          decoration: const InputDecoration(labelText: "Yaş", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() => _calculateMacroDistribution()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: heightController,
                          decoration: const InputDecoration(labelText: "Boy (cm)", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() => _calculateMacroDistribution()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: kiloController,
                          decoration: const InputDecoration(labelText: "Kilo (kg)", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() => _calculateMacroDistribution()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 25),

            // DİYET VE HAREKET SEÇİMLERİ
            const Text("Diyet Detaylarını Belirle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: activityLevel,
              decoration: const InputDecoration(labelText: "Hareket Sıklığı", border: OutlineInputBorder()),
              items: activityLevels.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (value) {
                setState(() {
                  activityLevel = value!;
                  _calculateMacroDistribution();
                  _saveDietSettings();
                });
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: dietGoal,
              decoration: const InputDecoration(labelText: "Diyet Hedefin", border: OutlineInputBorder()),
              items: dietGoals.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (value) {
                setState(() {
                  dietGoal = value!;
                  _calculateMacroDistribution();
                  _saveDietSettings();
                });
              },
            ),
            const SizedBox(height: 30),

            // MAKRO PANELİ GÖSTERİMİ
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blueGrey.shade900, borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  Text("${targetCalories.toStringAsFixed(0)} kcal", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  const Text("HEDEF GÜNLÜK KALORİ", style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                  const Divider(height: 30, color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMacroColumn("PROTEİN", "${targetProtein.toStringAsFixed(0)}g", Colors.redAccent),
                      _buildMacroColumn("KARB", "${targetCarb.toStringAsFixed(0)}g", Colors.amberAccent),
                      _buildMacroColumn("YAĞ", "${targetFat.toStringAsFixed(0)}g", Colors.lightBlueAccent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroColumn(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}