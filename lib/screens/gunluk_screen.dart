import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GunlukScreen extends StatefulWidget {
  const GunlukScreen({super.key});

  @override
  State<GunlukScreen> createState() => _GunlukScreenState();
}

class _GunlukScreenState extends State<GunlukScreen> {
  // Kilit ve Güvenlik Durumları
  bool isLocked = true;
  bool hasPassword = false;
  String savedPassword = "";
  String recoveryEmail = "";

  final passwordController = TextEditingController();
  final emailController = TextEditingController();

  // Günlük İçerik Controller'ları
  final diaryTextController = TextEditingController();
  final tagsController = TextEditingController();
  String searchQuery = "";

  List<Map<String, dynamic>> allNotes = [];
  List<Map<String, dynamic>> filteredNotes = [];

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
  }

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    diaryTextController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  // 1. GÜVENLİK KONTROLÜ: Şifre var mı, kilitli mi?
  _checkSecurityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedPassword = prefs.getString('gunluk_sifre') ?? "";
      recoveryEmail = prefs.getString('gunluk_eposta') ?? "kemal@example.com"; // Varsayılan kurtarma maili
      hasPassword = savedPassword.isNotEmpty;
      isLocked = hasPassword; // Eğer şifre varsa ekran kilitli başlar kanka
    });
    if (!isLocked) {
      _loadDiaryNotes();
    }
  }

  // İlk Kez Şifre Oluşturma
  _setupInitialPassword() async {
    if (passwordController.text.length < 4 || emailController.text.isEmpty) {
      _showSnackBar("Lütfen en az 4 haneli şifre ve geçerli bir e-posta girin!");
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gunluk_sifre', passwordController.text);
    await prefs.setString('gunluk_eposta', emailController.text);
    
    _showSnackBar("Şifreniz başarıyla oluşturuldu! 🎉");
    passwordController.clear();
    _checkSecurityStatus();
  }

  // Şifre Doğrulama (Giriş)
  _verifyPassword() {
    if (passwordController.text == savedPassword) {
      setState(() {
        isLocked = false;
      });
      passwordController.clear();
      _loadDiaryNotes();
    } else {
      _showSnackBar("🚨 Hatalı şifre! Lütfen tekrar deneyin.");
    }
  }

  // Senin İstediğin E-posta ile Şifre Yenileme / Sıfırlama
  _resetPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Şifremi Unuttum"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Şifrenizi sıfırlamak için kayıtlı e-posta adresinizi girin:"),
            const SizedBox(height: 10),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text == recoveryEmail) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('gunluk_sifre'); // Şifreyi siliyoruz ki yeniden kursun kanka
                Navigator.pop(context);
                _showSnackBar("Şifreniz sıfırlandı! Yeni bir şifre belirleyebilirsiniz.");
                _checkSecurityStatus();
              } else {
                _showSnackBar("Girdiğiniz e-posta kayıtlı adresle eşleşmedi!");
              }
            },
            child: const Text("Şifreyi Sıfırla"),
          )
        ],
      ),
    );
  }

  // 2. GÜNLÜK VERİ TABANI ALTYAPISI (SharedPreferences Üzerinden JSON)
  _loadDiaryNotes() async {
    final prefs = await SharedPreferences.getInstance();
    String notesStr = prefs.getString('gunluk_notlari_listesi') ?? "[]";
    List<dynamic> decoded = jsonDecode(notesStr);
    
    setState(() {
      allNotes = List<Map<String, dynamic>>.from(decoded);
      _filterNotes(""); // Başlangıçta hepsini göster kanka
    });
  }

  // Günlük Notu Ekleme (Metin + Tarih + Anahtar Kelimeler)
  _addDiaryNote() async {
    if (diaryTextController.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    Map<String, dynamic> newNote = {
      'id': now.millisecondsSinceEpoch.toString(),
      'text': diaryTextController.text,
      'tags': tagsController.text.toLowerCase(), // Arama kolaylığı için küçük harf
      'date': "${now.day}.${now.month}.${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}",
    };

    setState(() {
      allNotes.add(newNote);
      diaryTextController.clear();
      tagsController.clear();
      _filterNotes(searchQuery);
    });

    await prefs.setString('gunluk_notlari_listesi', jsonEncode(allNotes));
    Navigator.pop(context); // Ekleme sayfasından geri çık kanka
  }

  // Senin İstediğin Anahtar Kelime ve Metin Arama Motoru
  _filterNotes(String query) {
    searchQuery = query.toLowerCase();
    setState(() {
      filteredNotes = allNotes.where((note) {
        String noteText = note['text'].toString().toLowerCase();
        String noteTags = note['tags'].toString().toLowerCase();
        String noteDate = note['date'].toString().toLowerCase();
        
        // Arama çubuğuna yazılan kelime metinde, etiketlerde veya tarihte geçiyor mu?
        return noteText.contains(searchQuery) || noteTags.contains(searchQuery) || noteDate.contains(searchQuery);
      }).toList();
      
      // En yeni notu en üstte gösterelim
      filteredNotes.sort((a, b) => b['id'].compareTo(a['id']));
    });
  }

  _showSnackBar(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // A- EKRAN KİLİTLİYSE: ŞİFRE GİRİŞ VEYA KAYIT EKRANI AÇILIR kanka
    if (isLocked) {
      return Scaffold(
        appBar: AppBar(title: const Text("Güvenli Günlük Girişi")),
        body: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.indigo.shade700),
                  const SizedBox(height: 20),
                  if (!hasPassword) ...[
                    // İLK KEZ GİREN KULLANICI İÇİN KURULUM FORMU
                    const Text("Günlüğünüz için bir giriş şifresi ve kurtarma e-postası belirleyin.", textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: "4 Haneli Şifre", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "Kurtarma E-postası", border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      onPressed: _setupInitialPassword,
                      child: const Text("Şifreyi ve Günlüğü Oluştur"),
                    ),
                  ] else ...[
                    // ŞİFRE GİRİŞ ALANI
                    const Text("Bu alan şifre ile korunmaktadır.", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: "Şifrenizi Girin", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                      onPressed: _verifyPassword,
                      child: const Text("Giriş Yap"),
                    ),
                    TextButton(
                      onPressed: _resetPasswordDialog,
                      child: const Text("Şifremi Unuttum (E-posta ile Sıfırla)", style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // B- EKRAN AÇIKSA: GÜNLÜK LİSTESİ VE ARAMA MOTORU EKRANI kanka
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sanal Günlük Defterim"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => setState(() => isLocked = true), // Çıkış yapınca otomatik geri kilitle kanka
          )
        ],
      ),
      body: Column(
        children: [
          // AKILLI ANAHTAR KELİME ARAMA ÇUBUĞU
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => _filterNotes(value),
              decoration: const InputDecoration(
                labelText: "Kelime, Anahtar Kelime veya Tarih Ara...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          // GÜNLÜK NOTLARI LİSTESİ
          Expanded(
            child: filteredNotes.isEmpty
                ? const Center(child: Text("Yazılmış anı veya aradığın kelimeye uygun günlük bulunamadı kanka."))
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(note['date'], style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                  if (note['tags'].toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text("#${note['tags']}", style: const TextStyle(fontSize: 11, color: Colors.indigo)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(note['text'], style: const TextStyle(fontSize: 15, height: 1.4)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => _showWriteDiaryBottomSheet(),
        child: const Icon(Icons.edit_note),
      ),
    );
  }

  // YENİ GÜNLÜK YAZMA PANELİ (BOTTOM SHEET)
  _showWriteDiaryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Klavye açılınca yukarı kaysın kanka
          top: 20, left: 20, right: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bugün Neler Yaşandı Kemal?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: diaryTextController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: "Sevgili günlük, bugün...", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(hintText: "Anahtar kelimeler (Örn: sinema, sinav, besiktas)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            
            // SENİN İSTEDİĞİN MULTİMEDYA BUTONLARI (İleride içlerini dolduracağımız alan)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.camera_alt, color: Colors.blue), onPressed: () => _showSnackBar("Fotoğraf ekleme kütüphanesi bir sonraki aşamada entegre edilecek kanka.")),
                IconButton(icon: const Icon(Icons.videocam, color: Colors.red), onPressed: () => _showSnackBar("Video ekleme kütüphanesi bir sonraki aşamada entegre edilecek kanka.")),
                IconButton(icon: const Icon(Icons.mic, color: Colors.green), onPressed: () => _showSnackBar("Ses kaydetme kütüphanesi bir sonraki aşamada entegre edilecek kanka.")),
              ],
            ),
            const SizedBox(height: 15),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: _addDiaryNote,
                child: const Text("Anıyı Deftere Kaydet"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}