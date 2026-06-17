import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiziFilmScreen extends StatefulWidget {
  const DiziFilmScreen({super.key});

  @override
  State<DiziFilmScreen> createState() => _DiziFilmScreenState();
}

class _DiziFilmScreenState extends State<DiziFilmScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Film Form Controller'ları
  final filmNameController = TextEditingController();
  final filmHourController = TextEditingController();
  final filmMinuteController = TextEditingController();

  // Dizi Form Controller'ları
  final diziNameController = TextEditingController();
  final diziSeasonController = TextEditingController();
  final diziEpisodeController = TextEditingController();

  List<Map<String, dynamic>> filmList = [];
  List<Map<String, dynamic>> diziList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMediaData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    filmNameController.dispose();
    filmHourController.dispose();
    filmMinuteController.dispose();
    diziNameController.dispose();
    diziSeasonController.dispose();
    diziEpisodeController.dispose();
    super.dispose();
  }

  // Hafızadan film ve dizi listelerini çeken fonksiyon
  _loadMediaData() async {
    final prefs = await SharedPreferences.getInstance();
    
    String filmsStr = prefs.getString('finans_film_listesi') ?? "[]"; // SharedPreferences key'leri İngilizce pürüzsüz kanka
    String dizisStr = prefs.getString('finans_dizi_listesi') ?? "[]";

    setState(() {
      filmList = List<Map<String, dynamic>>.from(jsonDecode(filmsStr));
      diziList = List<Map<String, dynamic>>.from(jsonDecode(dizisStr));
    });
  }

  // Yeni Film Ekleme Fonksiyonu
  _addFilm() async {
    String name = filmNameController.text.trim();
    int hour = int.tryParse(filmHourController.text) ?? 0;
    int minute = int.tryParse(filmMinuteController.text) ?? 0;

    if (name.isEmpty || (hour == 0 && minute == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen film adını ve süresini geçerli girin kanka!")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    Map<String, dynamic> newFilm = {
      'id': now.millisecondsSinceEpoch.toString(),
      'name': name,
      'duration': "$hour sa $minute dk",
      'date': "${now.day}.${now.month}.${now.year}",
    };

    setState(() {
      filmList.add(newFilm);
      filmNameController.clear();
      filmHourController.clear();
      filmMinuteController.clear();
    });

    await prefs.setString('finans_film_listesi', jsonEncode(filmList));
  }

  // Yeni Dizi Takibi Başlatma
  _startDizi() async {
    String name = diziNameController.text.trim();
    int totalSeasons = int.tryParse(diziSeasonController.text) ?? 1;
    int totalEpisodes = int.tryParse(diziEpisodeController.text) ?? 0;

    if (name.isEmpty || totalEpisodes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen dizi adını ve toplam bölüm sayısını girin kanka!")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    Map<String, dynamic> newDizi = {
      'id': now.millisecondsSinceEpoch.toString(),
      'name': name,
      'totalSeasons': totalSeasons,
      'totalEpisodes': totalEpisodes,
      'currentEpisode': 0,
      'startDate': "${now.day}.${now.month}.${now.year}",
      'endDate': "",
      'isCompleted': false,
    };

    setState(() {
      diziList.add(newDizi);
      diziNameController.clear();
      diziSeasonController.clear();
      diziEpisodeController.clear();
    });

    await prefs.setString('finans_dizi_listesi', jsonEncode(diziList));
  }

  // Dizide yeni bölüm izlendiğinde ilerleme kaydetme (Aynı kitap mantığı kanka)
  _incrementEpisode(String id) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    setState(() {
      for (var dizi in diziList) {
        if (dizi['id'] == id) {
          if (dizi['currentEpisode'] < dizi['totalEpisodes']) {
            dizi['currentEpisode'] += 1;
            
            // Eğer son bölüm de izlendiyse diziyi tamamlandı olarak işaretle ve bitiş tarihini yaz
            if (dizi['currentEpisode'] == dizi['totalEpisodes']) {
              dizi['isCompleted'] = true;
              dizi['endDate'] = "${now.day}.${now.month}.${now.year}";
            }
          }
        }
      }
    });

    await prefs.setString('finans_dizi_listesi', jsonEncode(diziList));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dizi & Film Kütüphanesi"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.movie), text: "Filmler"),
            Tab(icon: Icon(Icons.tv), text: "Diziler"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ================= FILM SEKMESİ =================
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                TextField(
                  controller: filmNameController,
                  decoration: const InputDecoration(labelText: "Film Adı", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: filmHourController,
                        decoration: const InputDecoration(labelText: "Saat", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: filmMinuteController,
                        decoration: const InputDecoration(labelText: "Dakika", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)),
                      onPressed: _addFilm,
                      child: const Text("Ekle"),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Expanded(
                  child: filmList.isEmpty
                      ? const Center(child: Text("Henüz film kütüphanen boş kanka."))
                      : ListView.builder(
                          itemCount: filmList.length,
                          itemBuilder: (context, index) {
                            final film = filmList[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.local_movies, color: Colors.red),
                                title: Text(film['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("İzlenme Tarihi: ${film['date']}"),
                                trailing: Text(film['duration'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // ================= DIZI SEKMESİ =================
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                TextField(
                  controller: diziNameController,
                  decoration: const InputDecoration(labelText: "Dizi Adı", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: diziSeasonController,
                        decoration: const InputDecoration(labelText: "Total Sezon", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: diziEpisodeController,
                        decoration: const InputDecoration(labelText: "Total Bölüm", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)),
                      onPressed: _startDizi,
                      child: const Text("Başlat"),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Expanded(
                  child: diziList.isEmpty
                      ? const Center(child: Text("Henüz takip edilen bir dizi yok kanka."))
                      : ListView.builder(
                          itemCount: diziList.length,
                          itemBuilder: (context, index) {
                            final dizi = diziList[index];
                            bool done = dizi['isCompleted'];

                            return Card(
                              color: done ? Colors.green.shade50 : Colors.white,
                              child: ListTile(
                                leading: Icon(Icons.tv, color: done ? Colors.green : Colors.blue),
                                title: Text(dizi['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: done 
                                    ? Text("Bitti! 🎉 (${dizi['startDate']} - ${dizi['endDate']})")
                                    : Text("Başlangıç: ${dizi['startDate']}\nSezon: ${dizi['totalSeasons']}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${dizi['currentEpisode']} / ${dizi['totalEpisodes']}",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: done ? Colors.green.shade800 : Colors.black87),
                                    ),
                                    if (!done)
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                                        onPressed: () => _incrementEpisode(dizi['id']),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}