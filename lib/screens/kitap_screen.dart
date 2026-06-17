import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kitap_model.dart';

class KitapScreen extends StatefulWidget {
  const KitapScreen({super.key});

  @override
  State<KitapScreen> createState() => _KitapScreenState();
}

class _KitapScreenState extends State<KitapScreen> {
  List<KitapModel> kitaplar = [];
  final kitapAdiController = TextEditingController();
  final toplamSayfaController = TextEditingController();
  final sayfaEkleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKitaplar();
  }

  _loadKitaplar() async {
    final prefs = await SharedPreferences.getInstance();
    final String? kitaplarString = prefs.getString('kitap_listesi');
    if (kitaplarString != null) {
      final List<dynamic> decoded = jsonDecode(kitaplarString);
      setState(() {
        kitaplar = decoded.map((item) => KitapModel.fromMap(item)).toList();
      });
    }
  }

  _saveKitaplar() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(kitaplar.map((k) => k.toMap()).toList());
    await prefs.setString('kitap_listesi', encoded);
  }

  _kitapEkle(String ad, int toplamSayfa) {
    final yeniKitap = KitapModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ad: ad,
      toplamSayfa: toplamSayfa,
      okunanSayfa: 0,
      baslamaTarihi: "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}",
    );
    setState(() {
      kitaplar.add(yeniKitap);
    });
    _saveKitaplar();
  }

  _sayfaGuncelle(KitapModel kitap, int eklenenSayfa) {
    setState(() {
      kitap.okunanSayfa += eklenenSayfa;
      if (kitap.okunanSayfa >= kitap.toplamSayfa) {
        kitap.okunanSayfa = kitap.toplamSayfa;
        kitap.bittiMi = true;
        kitap.bitmeTarihi = "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";
      }
    });
    _saveKitaplar();
  }

  @override
  Widget build(BuildContext context) {
    // Kitapları aktif ve bitenler (Kütüphane) olarak ayırıyoruz
    final aktifKitaplar = kitaplar.where((k) => !k.bittiMi).toList();
    final bitenKitaplar = kitaplar.where((k) => k.bittiMi).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Kitap Takibi"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Okuduklarım 📖"),
              Tab(text: "Kütüphane (Bitenler) 🏆"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Sekme: Aktif Okunan Kitaplar
            _buildAktifKitaplarListesi(aktifKitaplar),
            // 2. Sekme: Kütüphane (Biten Kitaplar)
            _buildKuyenListesi(bitenKitaplar),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          onPressed: () => _showKitapEkleDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildAktifKitaplarListesi(List<KitapModel> liste) {
    if (liste.isEmpty) {
      return const Center(child: Text("Şu an okunan kitap yok. Alttaki butondan ekle!"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: liste.count,
      itemBuilder: (context, index) {
        final kitap = liste[index];
        double yuzde = kitap.okunanSayfa / kitap.toplamSayfa;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kitap.ad, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Başlama: ${kitap.baslamaTarihi}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: yuzde, color: Colors.brown, backgroundColor: Colors.brown.shade100),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${kitap.okunanSayfa} / ${kitap.toplamSayfa} Sayfa (%${(yuzde * 100).toStringAsFixed(0)})"),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                      onPressed: () => _showSayfaEkleDialog(kitap),
                      child: const Text("Sayfa Ekle"),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKuyenListesi(List<KitapModel> liste) {
    if (liste.isEmpty) {
      return const Center(child: Text("Kütüphane henüz boş. Kitap bitirince buraya düşecek! 🎉"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: liste.count,
      itemBuilder: (context, index) {
        final kitap = liste[index];
        return ListTile(
          leading: const Icon(Icons.bookmark, color: Colors.brown, size: 40),
          title: Text(kitap.ad, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Başlama: ${kitap.baslamaTarihi} - Bitiş: ${kitap.bitmeTarihi}"),
          trailing: Text("${kitap.toplamSayfa} Sayfa", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  _showKitapEkleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Kitap Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: kitapAdiController, decoration: const InputDecoration(labelText: "Kitabın Adı")),
            TextField(controller: toplamSayfaController, decoration: const InputDecoration(labelText: "Toplam Sayfa Sayısı"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (kitapAdiController.text.isNotEmpty && toplamSayfaController.text.isNotEmpty) {
                _kitapEkle(kitapAdiController.text, int.parse(toplamSayfaController.text));
                kitapAdiController.clear();
                toplamSayfaController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Ekle"),
          )
        ],
      ),
    );
  }

  _showSayfaEkleDialog(KitapModel kitap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${kitap.ad} İçin İlerleme Gir"),
        content: TextField(
          controller: sayfaEkleController,
          decoration: const InputDecoration(labelText: "Bugün Kaç Sayfa Okudun?"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (sayfaEkleController.text.isNotEmpty) {
                _sayfaGuncelle(kitap, int.parse(sayfaEkleController.text));
                sayfaEkleController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Kaydet"),
          )
        ],
      ),
    );
  }
}

// Küçük bir List extension'ı (.length yerine .count hatası almamak adına standart kalsın diye)
extension ListCount<T> on List<T> {
  int get count => length;
}