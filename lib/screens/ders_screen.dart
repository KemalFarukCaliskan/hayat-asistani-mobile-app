import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DersScreen extends StatefulWidget {
  const DersScreen({super.key});

  @override
  State<DersScreen> createState() => _DersScreenState();
}

class _DersScreenState extends State<DersScreen> {
  final dersAdiController = TextEditingController();
  final manuelSureController = TextEditingController();

  // Kronometre Değişkenleri
  Timer? _timer;
  int _saniye = 0;
  bool _calisiyorMu = false;

  @override
  void dispose() {
    _timer?.cancel();
    dersAdiController.dispose();
    manuelSureController.dispose();
    super.dispose();
  }

  // Kronometreyi Başlatma / Durdurma Fonksiyonu
  void _toggleKronometre() {
    if (dersAdiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen önce ne çalıştığınızı yazın!")),
      );
      return;
    }

    setState(() {
      if (_calisiyorMu) {
        // Durdur
        _timer?.cancel();
        _calisiyorMu = false;
      } else {
        // Başlat (Saniyede bir tetiklenir)
        _calisiyorMu = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _saniye++;
          });
        });
      }
    });
  }

  // Kronometreyi Sıfırlama ve Kaydetme
  void _bitirVeKaydet(int toplamSaniye, bool manuelMi) async {
    if (dersAdiController.text.isEmpty) return;

    int toplamDakika = (toplamSaniye / 60).round();
    if (manuelMi) {
      toplamDakika = int.tryParse(manuelSureController.text) ?? 0;
    }

    if (toplamDakika <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçerli bir çalışma süresi girilmedi!")),
      );
      return;
    }

    int saat = toplamDakika ~/ 60;
    int dakika = toplamDakika % 60;
    String formatliSure = "$saat.${dakika.toString().padLeft(2, '0')}";

    // Hafızaya kaydetme altyapısı (Haftalık raporlama için zemin)
    final prefs = await SharedPreferences.getInstance();
    List<String> calismalar = prefs.getStringList('ders_calismalari') ?? [];
    calismalar.add("${dersAdiController.text} - $formatliSure - ${DateTime.now().day}.${DateTime.now().month}");
    await prefs.setStringList('ders_calismalari', calismalar);

    // Temizlik ve Geri Bildirim
    setState(() {
      _timer?.cancel();
      _saniye = 0;
      _calisiyorMu = false;
      manuelSureController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${dersAdiController.text} çalışması ($formatliSure saat) kaydedildi! 🎉")),
      );
    }
  }

  // Saniyeyi GG:DD:SS formatına çeviren yardımcı görsel fonksiyon
  String _formatSaniye(int toplamSaniye) {
    int saat = toplamSaniye ~/ 3600;
    int dakika = (toplamSaniye % 3600) ~/ 60;
    int saniye = toplamSaniye % 60;
    return "${saat.toString().padLeft(2, '0')}:${dakika.toString().padLeft(2, '0')}:${saniye.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ders Çalışma Takibi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ne Çalışıyorsun?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: dersAdiController,
              decoration: const InputDecoration(
                hintText: "Örn: Veri Yapıları, Sayısal Analiz, Flutter...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // KRONOMETRE ALANI
            Card(
              color: Colors.teal.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    const Text("Canlı Kronometre", style: TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        _formatSaniye(_saniye),
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _calisiyorMu ? Colors.orange : Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _toggleKronometre,
                          icon: Icon(_calisiyorMu ? Icons.pause : Icons.play_arrow),
                          label: Text(_calisiyorMu ? "Duraklat" : "Başlat"),
                        ),
                        if (_saniye > 0) ...[
                          const SizedBox(width: 15),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => _bitirVeKaydet(_saniye, false),
                            icon: const Icon(Icons.stop),
                            label: const Text("Çalışmayı Bitir"),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 50),

            // MANUEL SÜRE GİRİŞ ALANI
            ExpansionTile(
              title: const Text("Süreyi El İle (Manuel) Gir", style: TextStyle(fontWeight: FontWeight.w500)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: manuelSureController,
                          decoration: const InputDecoration(
                            labelText: "Toplam Süre (Dakika)",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                        onPressed: () {
                          if (dersAdiController.text.isNotEmpty && manuelSureController.text.isNotEmpty) {
                            _bitirVeKaydet(0, true);
                            FocusScope.of(context).unfocus();
                          } else if (dersAdiController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Lütfen önce ders adı girin!")),
                            );
                          }
                        },
                        child: const Text("Kaydet"),
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