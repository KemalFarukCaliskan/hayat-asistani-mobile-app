import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../main.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controller'larımızı burada tanımlıyoruz
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  
  // 1. Adım: Cinsiyet değişkenimiz
  String secilenCinsiyet = "Erkek"; 

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Oluştur")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'İsim'),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: ageController,
              decoration: const InputDecoration(labelText: 'Yaş'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: heightController,
              decoration: const InputDecoration(labelText: 'Boy (cm)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Kilo (kg)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),

            // 2. Adım: Cinsiyet Seçim Alanı (Arayüz)
            const Text("Cinsiyetiniz", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: secilenCinsiyet,
              isExpanded: true,
              items: ["Erkek", "Kadın"].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  secilenCinsiyet = newValue!;
                });
              },
            ),
            const SizedBox(height: 35),

            // 3. Adım: Kaydetme Butonu 
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      ageController.text.isEmpty ||
                      weightController.text.isEmpty ||
                      heightController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
                    );
                    return;
                  }

                  // Modeli oluşturuyoruz
                  final user = UserModel(
                    name: nameController.text,
                    age: int.parse(ageController.text),
                    weight: double.parse(weightController.text),
                    height: double.parse(heightController.text),
                    gender: secilenCinsiyet,
                  );

                  // Telefona kalıcı hafızaya yazıyoruz
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_name', user.name);
                  await prefs.setInt('user_age', user.age);
                  await prefs.setDouble('user_weight', user.weight);
                  await prefs.setDouble('user_height', user.height);
                  await prefs.setString('user_gender', user.gender);

                  // Kayıt başarılı mesajı verip Dashboard'a paslıyoruz
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bilgileriniz başarıyla kaydedildi!")),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}