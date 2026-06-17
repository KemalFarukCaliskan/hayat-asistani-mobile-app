import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SuScreen extends StatefulWidget {
  const SuScreen({super.key});

  @override
  State<SuScreen> createState() => _SuScreenState();
}

class _SuScreenState extends State<SuScreen> {
  double targetWater = 2500.0; // Varsayılan hedef (ml)
  double currentWater = 0.0;   // Günlük içilen (ml)
  bool isCustomGoal = false;   // Kullanıcı kendi hedefini mi girdi?
  final customGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Önce kullanıcının kilosuna göre bilimsel su hedefini hesaplayalım
    double weight = prefs.getDouble('user_weight') ?? 75.0;
    double scientificGoal = weight * 35; // UserModel'deki mantık

    setState(() {
      // Eğer kullanıcı daha önce elle özel bir hedef kaydettiyse onu çek, yoksa bilimsel olanı kullan
      isCustomGoal = prefs.getBool('su_ozel_hedef_mi') ?? false;
      if (isCustomGoal) {
        targetWater = prefs.getDouble('su_hedef_ml') ?? scientificGoal;
        customGoalController.text = targetWater.toStringAsFixed(0);
      } else {
        targetWater = scientificGoal;
      }

      // Bugün içilen su miktarını hafızadan çekiyoruz
      currentWater = prefs.getDouble('su_bugun_icilen') ?? 0.0;
    });
  }

  // Su içildiğinde hafızayı güncelleyen fonksiyon
  _addWater(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentWater += amount;
      if (currentWater < 0) currentWater = 0; // Negatif olmasın
    });
    await prefs.setDouble('su_bugun_icilen', currentWater);
  }

  // Özel hedef belirlendiğinde hafızaya kaydeden fonksiyon
  _saveCustomGoal(double newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      targetWater = newGoal;
      isCustomGoal = true;
    });
    await prefs.setDouble('su_hedef_ml', newGoal);
    await prefs.setBool('su_ozel_hedef_mi', true);
  }

  @override
  Widget build(BuildContext context) {
    double progress = currentWater / targetWater;
    if (progress > 1.0) progress = 1.0; // İlerleme çubuğu taşmasın

    return Scaffold(
      appBar: AppBar(title: const Text("Su Takibi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Hedef Durumu Kartı
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "${currentWater.toStringAsFixed(0)} / ${targetWater.toStringAsFixed(0)} ml",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.blue.shade100,
                      color: Colors.blue,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      progress >= 1.0 ? "Harika! Bugünlük su hedefine ulaştın. 💧" : "Hedefine ulaşmak için içmeye devam et!",
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Senin istediğin o hızlı kısayol butonları
            const Text("Hızlı Ekle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickAddButton("🥛 Bardak", 200),
                _quickAddButton("☕ Kupa", 300),
                _quickAddButton("🍼 Pet Şişe", 500),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _addWater(-200), // Yanlışlıkla eklenirse geri alma kısayolu
              icon: const Icon(Icons.undo, color: Colors.grey),
              label: const Text("200 ml Geri Al", style: TextStyle(color: Colors.grey)),
            ),

            const Divider(height: 50),

            // Kendi Hedefimi Belirle Alanı
            ExpansionTile(
              title: const Text("Hedefimi Özelleştir", style: TextStyle(fontWeight: FontWeight.w500)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: customGoalController,
                          decoration: const InputDecoration(labelText: "Özel Hedef (ml)", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        onPressed: () {
                          if (customGoalController.text.isNotEmpty) {
                            double newGoal = double.parse(customGoalController.text);
                            _saveCustomGoal(newGoal);
                            FocusScope.of(context).unfocus(); // Klavyeyi kapat
                          }
                        },
                        child: const Text("Ayarla"),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: const Text("Sistem Hesaplamasına Dön (Kilo × 35ml)"),
                  trailing: const Icon(Icons.refresh, color: Colors.blue),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('su_ozel_hedef_mi', false);
                    _loadWaterData(); // Yeniden yükle, otomatik hesaba dönsün
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAddButton(String label, double amount) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
      ),
      onPressed: () => _addWater(amount),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("+$amount ml", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}