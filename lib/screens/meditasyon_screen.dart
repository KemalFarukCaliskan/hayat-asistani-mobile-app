import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeditasyonScreen extends StatefulWidget {
  const MeditasyonScreen({super.key});

  @override
  State<MeditasyonScreen> createState() => _MeditasyonScreenState();
}

class _Highlight {
  final String title;
  final IconData icon;
  _Highlight(this.title, this.icon);
}

class _MeditasyonScreenState extends State<MeditasyonScreen> {
  String selectedTheme = "Zihinsel Odaklanma (Orman)";
  int _saniye = 0;
  Timer? _timer;
  bool _calisiyorMu = false;
  final manuelSureController = TextEditingController();

  final List<String> themes = [
    "Zihinsel Odaklanma (Orman)", 
    "Derin Gevşeme (Yağmur)", 
    "İçsel Huzur (Deniz Dalgaları)", 
    "Stres Azaltma (Boşluk Sesleri)"
  ];

  @override
  void dispose() {
    _timer?.cancel();
    manuelSureController.dispose();
    super.dispose();
  }

  void _toggleMeditasyon() {
    setState(() {
      if (_calisiyorMu) {
        _timer?.cancel();
        _calisiyorMu = false;
      } else {
        _calisiyorMu = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _saniye++;
            
            // Senin istediğin kural: Her 10 dakikada bir (600 saniyede bir) gong uyarısı tetikleme mantığı
            if (_saniye > 0 && _saniye % 600 == 0) {
              _triggerGongAlert();
            }
          });
        });
      }
    });
  }

  // 10 dakikada bir meditasyonu bozmadan ekrandan uyarı geçme fonksiyonu
  void _triggerGongAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🔔 *GONG* - 10 dakika tamamlandı. Derin bir nefes al ve odağını koru..."),
        duration: Duration(seconds: 4),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  void _bitirVeKaydet(int toplamSaniye, bool manuelMi) async {
    int toplamDakika = (toplamSaniye / 60).round();
    if (manuelMi) {
      toplamDakika = int.tryParse(manuelSureController.text) ?? 0;
    }

    if (toplamDakika <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçerli bir meditasyon süresi girmediniz!")),
      );
      return;
    }

    // Haftalık rapor için veriyi SharedPreferences'a yazıyoruz
    final prefs = await SharedPreferences.getInstance();
    List<String> meditasyonlar = prefs.getStringList('meditasyon_kayitlari') ?? [];
    meditasyonlar.add("$selectedTheme - $toplamDakika dk - ${DateTime.now().day}.${DateTime.now().month}");
    await prefs.setStringList('meditasyon_kayitlari', meditasyonlar);

    setState(() {
      _timer?.cancel();
      _saniye = 0;
      _calisiyorMu = false;
      manuelSureController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Harika bir seans! $toplamDakika dakikalık meditasyon kaydedildi. 🧘‍♂️")),
      );
    }
  }

  String _formatSaniye(int toplamSaniye) {
    int dakika = toplamSaniye ~/ 60;
    int saniye = toplamSaniye % 60;
    return "${dakika.toString().padLeft(2, '0')}:${saniye.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meditasyon & Zihin Sağlığı")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Meditasyon Teması Seç", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            DropdownButton<String>(
              value: selectedTheme,
              isExpanded: true,
              items: themes.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: _calisiyorMu ? null : (newValue) { // Meditasyon yaparken tema değiştirilemesin
                setState(() {
                  selectedTheme = newValue!;
                });
              },
            ),
            const SizedBox(height: 30),

            // MEDİTASYON SEANS KARTI
            Card(
              color: Colors.deepPurple.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Text(
                      _calisiyorMu ? "Zihnini Serbest Bırak..." : "Seansa Hazır mısın?",
                      style: TextStyle(fontSize: 16, color: Colors.deepPurple.shade700, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        _formatSaniye(_saniye),
                        style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w300, color: Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _calisiyorMu ? Colors.indigo : Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: _toggleMeditasyon,
                          icon: Icon(_calisiyorMu ? Icons.pause_circle_filled : Icons.play_circle_filled),
                          label: Text(_calisiyorMu ? "Seansı Duraklat" : "Meditasyona Başla"),
                        ),
                        if (_saniye > 0) ...[
                          const SizedBox(width: 15),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                            onPressed: () => _bitirVeKaydet(_saniye, false),
                            icon: const Icon(Icons.check_circle),
                            label: const Text("Bitir"),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 50),

            // MANUEL GİRİŞ ALANI
            ExpansionTile(
              title: const Text("Uygulama Dışında Yaptığım Meditasyonu Ekle", style: TextStyle(fontWeight: FontWeight.w500)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: manuelSureController,
                          decoration: const InputDecoration(
                            labelText: "Kaç Dakika Yaptın?",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                        onPressed: () {
                          if (manuelSureController.text.isNotEmpty) {
                            _bitirVeKaydet(0, true);
                            FocusScope.of(context).unfocus();
                          }
                        },
                        child: const Text("Ekle"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}