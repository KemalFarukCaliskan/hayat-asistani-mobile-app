import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/vucut_detay_screen.dart';
import 'screens/diyet_screen.dart';
import 'screens/antrenman_screen.dart';
import 'screens/su_screen.dart';
import 'screens/kitap_screen.dart';
import 'screens/ders_screen.dart';
import 'screens/meditasyon_screen.dart';
import 'screens/birakma_screen.dart';
import 'screens/finans_screen.dart';
import 'screens/regl_screen.dart';
import 'screens/uyku_screen.dart';
import 'screens/dizi_film_screen.dart';
import 'screens/gunluk_screen.dart';
import 'screens/ozel_takip_screen.dart';
import 'screens/rapor_screen.dart';

void main() {
  runApp(const HayatAsistaniApp());
}

class HayatAsistaniApp extends StatelessWidget {
  const HayatAsistaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hayat Asistanı',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "";
  double userBmi = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Ekran açılırken verileri yükle
  }

  // Hafızadaki verileri çekme fonksiyonu
  _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? "Kullanıcı";
      double weight = prefs.getDouble('user_weight') ?? 0.0;
      double height = prefs.getDouble('user_height') ?? 1.0;
      
      if (height > 0) {
        userBmi = weight / ((height / 100) * (height / 100));
      }
    });
  }

  final List<String> categories = const [
    'Diyet', 'Antrenman', 'Su', 'Kitap', 'Ders', 'Meditasyon',
    'Vücut', 'Bırakma', 'Finans', 'Regl', 'Uyku', 'Dizi/Film', 'Günlük', 'Özel'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Hayat Asistanı"),
  actions: [
    IconButton(
      icon: const Icon(Icons.bar_chart, size: 28, color: Colors.blue),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RaporScreen()),
        );
      },
    ),
  ],
),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return GestureDetector(
    onTap: () {
  if (categories[index] == 'Vücut') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VucutDetayScreen()),
    );
  } 
  else if (categories[index] == 'Diyet') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiyetScreen()),
    );
  } 
  else if (categories[index] == 'Antrenman') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AntrenmanScreen()),
    );
  }
  else if (categories[index] == 'Su') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SuScreen()),
    );
  }else if (categories[index] == 'Kitap') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KitapScreen()),
    );
  }else if (categories[index] == 'Ders') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DersScreen()),
    );
  }else if (categories[index] == 'Meditasyon') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MeditasyonScreen()),
    );
  }else if (categories[index] == 'Bırakma') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BirakmaScreen()),
    );
  }else if (categories[index] == 'Finans') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FinansScreen()),
    );
  }else if (categories[index] == 'Regl Döngüsü') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReglScreen()),
    );
  }else if (categories[index] == 'Uyku') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UykuScreen()),
    );
  }else if (categories[index] == 'Dizi/Film') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiziFilmScreen()),
    );
  }else if (categories[index] == 'Sanal Günlük') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GunlukScreen()),
    );
  }else if (categories[index] == 'Özelleştirilebilir Takipler') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OzelTakipScreen()),
    );
  }
  else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${categories[index]} sayfası yakında eklenecek!")),
    );
  }
},
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Center(
        child: Text(
          categories[index],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
      ),
    ),
  );
        },
      ),
    );
  }
}