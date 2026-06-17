import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OzelTakipScreen extends StatefulWidget {
  const OzelTakipScreen({super.key});

  @override
  State<OzelTakipScreen> createState() => _OzelTakipScreenState();
}

class _OzelTakipScreenState extends State<OzelTakipScreen> {
  final titleController = TextEditingController();
  int selectedFrequency = 1; // Haftada kaç gün takip edilecek (1-7)

  List<Map<String, dynamic>> customTrackers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomTrackers();
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  // Hafızadaki özel takipleri çeken fonksiyon
  _loadCustomTrackers() async {
    final prefs = await SharedPreferences.getInstance();
    String trackersStr = prefs.getString('ozel_takipler_listesi') ?? "[]";
    setState(() {
      customTrackers = List<Map<String, dynamic>>.from(jsonDecode(trackersStr));
    });
  }

  // Yeni Özelleştirilebilir Takip Kalemi Ekleme
  _addCustomTracker() async {
    String title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen takip etmek istediğiniz durumu yazın kanka!")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    Map<String, dynamic> newTracker = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'frequency': selectedFrequency, // Senin istediğin 1-7 gün arası sıklık kuralı
      'status': 'none', // 'tik', 'carpi' veya 'none' (seçilmemiş)
      'date': "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}"
    };

    setState(() {
      customTrackers.add(newTracker);
      titleController.clear();
      selectedFrequency = 1;
    });

    await prefs.setString('ozel_takipler_listesi', jsonEncode(customTrackers));
    Navigator.pop(context); // Dialog penceresini kapat kanka
  }

  // Durumu Tik veya Çarpı olarak güncelleme fonksiyonu
  _updateStatus(String id, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var tracker in customTrackers) {
        if (tracker['id'] == id) {
          tracker['status'] = newStatus;
        }
      }
    });

    await prefs.setString('ozel_takipler_listesi', jsonEncode(customTrackers));
    
    // Haftalık rapora gönderilecek log altyapısı kanka
    List<String> reportLogs = prefs.getStringList('ozel_takip_rapor_loglari') ?? [];
    reportLogs.add("ID: $id - Durum: $newStatus - Tarih: ${DateTime.now().day}.${DateTime.now().month}");
    await prefs.setStringList('ozel_takip_rapor_loglari', reportLogs);
  }

  // Takip kalemi silme (Testlerde kolaylık olsun diye)
  _deleteTracker(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      customTrackers.removeWhere((t) => t['id'] == id);
    });
    await prefs.setString('ozel_takipler_listesi', jsonEncode(customTrackers));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Özelleştirilebilir Takipler")),
      body: customTrackers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Önceki 13 kategorinin dışında takip etmek istediğin ne varsa alttaki butondan ekle kanka!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: customTrackers.length,
              itemBuilder: (context, index) {
                final tracker = customTrackers[index];
                String currentStatus = tracker['status'] ?? 'none';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Başlık ve Sıklık Bilgisi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tracker['title'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Hedef Sıklık: Haftada ${tracker['frequency']} Gün",
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        
                        // Tik ve Çarpı Seçim Alanı kanka
                        Row(
                          children: [
                            // ÇARPI BUTONU
                            IconButton(
                              icon: Icon(
                                currentStatus == 'carpi' ? Icons.cancel : Icons.cancel_outlined,
                                color: currentStatus == 'carpi' ? Colors.red : Colors.grey.shade400,
                                size: 28,
                              ),
                              onPressed: () => _updateStatus(tracker['id'], 'carpi'),
                            ),
                            // TİK BUTONU
                            IconButton(
                              icon: Icon(
                                currentStatus == 'tik' ? Icons.check_circle : Icons.check_circle_outline,
                                color: currentStatus == 'tik' ? Colors.green : Colors.grey.shade400,
                                size: 28,
                              ),
                              onPressed: () => _updateStatus(tracker['id'], 'tik'),
                            ),
                            // SİLME SEÇENEĞİ (Üzerine basılı tutunca veya küçük butonla kanka)
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey, size: 20),
                              onPressed: () => _deleteTracker(tracker['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        onPressed: () => _showAddTrackerDialog(),
        child: const Icon(Icons.playlist_add),
      ),
    );
  }

  // YENİ ÖZEL GÖREV EKLEME PENCERESİ (DIALOG)
  _showAddTrackerDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Dropdown güncellemesi dialog içinde çalışsın diye kanka
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Özel Takip Kalemi Oluştur"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Ne takip etmek istiyorsun?",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Takip Sıklığı (Haftada Kaç Gün?)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 5),
              DropdownButton<int>(
                value: selectedFrequency,
                isExpanded: true,
                items: [1, 2, 3, 4, 5, 6, 7].map((int val) {
                  return DropdownMenuItem<int>(
                    value: val,
                    child: Text("Haftada $val Gün"),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setDialogState(() {
                    selectedFrequency = newValue!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
              onPressed: _addCustomTracker,
              child: const Text("Takibi Başlat"),
            ),
          ],
        ),
      ),
    );
  }
}