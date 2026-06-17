import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirakmaScreen extends StatefulWidget {
  const BirakmaScreen({super.key});

  @override
  State<BirakmaScreen> createState() => _BirakmaScreenState();
}

class _BirakmaScreenState extends State<BirakmaScreen> {
  String selectedHabit = "Sigara";
  int streakDays = 0;
  String startDateStr = "";

  final List<String> habits = ["Sigara", "Alkol", "Sosyal Medya", "Abur Cubur", "Kafein"];

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  // Hafızadan seriyi ve başlangıç tarihini yükler
  _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      startDateStr = prefs.getString('${selectedHabit}_baslangic_tarihi') ?? "";
      
      if (startDateStr.isNotEmpty) {
        DateTime startDate = DateTime.parse(startDateStr);
        DateTime today = DateTime.now();
        
        // İki tarih arasındaki net gün farkını hesaplar
        int difference = today.difference(startDate).inDays;
        streakDays = difference >= 0 ? difference : 0;
      } else {
        streakDays = 0;
      }
    });
  }

  // Yeni bırakma serisi başlatır
  _startNewStreak() async {
    final prefs = await SharedPreferences.getInstance();
    String nowStr = DateTime.now().toIso8601String();
    
    await prefs.setString('${selectedHabit}_baslangic_tarihi', nowStr);
    
    // Haftalık rapora veri göndermek için log tutuyoruz kanka
    List<String> logs = prefs.getStringList('birakma_kayitlari') ?? [];
    logs.add("$selectedHabit - Basladi - ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}");
    await prefs.setStringList('birakma_kayitlari', logs);

    _loadStreakData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$selectedHabit bırakma serin başarıyla başladı. Sonuna kadar arkandayım! 🔥")),
      );
    }
  }

  // Seri bozulduğunda zinciri kırar ve sıfırlar
  _resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Haftalık raporlama sistemine serinin bozulduğu tarih bilgisini logluyoruz
    List<String> logs = prefs.getStringList('birakma_kayitlari') ?? [];
    logs.add("$selectedHabit - Bozuldu - ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}");
    await prefs.setStringList('birakma_kayitlari', logs);

    // Başlangıç tarihini silerek seriyi sıfırlıyoruz
    await prefs.remove('${selectedHabit}_baslangic_tarihi');
    _loadStreakData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seri bozuldu. Sağlık olsun kanka, pes etmek yok yeniden başlayacağız! 💪")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kötü Alışkanlıkları Bırakma")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Kurtulmak İstediğin Alışkanlık", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            DropdownButton<String>(
              value: selectedHabit,
              isExpanded: true,
              items: habits.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedHabit = newValue!;
                  _loadStreakData();
                });
              },
            ),
            const SizedBox(height: 40),

            // CANLI SERİ GÖSTERGESİ
            Center(
              child: Column(
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: streakDays > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: streakDays > 0 ? Colors.green : Colors.grey, width: 4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$streakDays",
                          style: TextStyle(
                            fontSize: 48, 
                            fontWeight: FontWeight.bold, 
                            color: streakDays > 0 ? Colors.green.shade900 : Colors.grey
                          ),
                        ),
                        const Text("GÜN", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    streakDays > 0 
                        ? "Tebrikler! $streakDays gündür $selectedHabit kullanmıyorsun. 🎉" 
                        : "Henüz bir seri başlatılmadı kanka.",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Divider(height: 60),

            // AKSİYON BUTONLARI
            if (startDateStr.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  onPressed: _startNewStreak,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Seriyi Başlat", style: TextStyle(fontSize: 16)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red, 
                    side: const BorderSide(color: Colors.red), 
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Seriyi Bozdun mu?"),
                        content: const Text("Eğer seriyi bozduysan gün sayacın sıfırlanacaktır. Emin misin?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                              _resetStreak();
                            },
                            child: const Text("Evet, Sıfırla"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("Seriyi Bozdum (Zinciri Kır)"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}