import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VucutDetayScreen extends StatefulWidget {
  const VucutDetayScreen({super.key});

  @override
  State<VucutDetayScreen> createState() => _VucutDetayScreenState();
}

class _VucutDetayScreenState extends State<VucutDetayScreen> {
  UserModel? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

    _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      user = UserModel(
        name: prefs.getString('user_name') ?? "",
        age: prefs.getInt('user_age') ?? 0,
        weight: prefs.getDouble('user_weight') ?? 0.0,
        height: prefs.getDouble('user_height') ?? 0.0,
        gender: prefs.getString('user_gender') ?? "Erkek", // İŞTE BURASI! Hafızadan cinsiyeti çekiyoruz
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Vücut Analizi")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _bilgiKarti("Vücut Kitle İndeksi (VKİ)", user!.bmi.toStringAsFixed(1)),
            _bilgiKarti("Günlük Su İhtiyacı", "${user!.waterGoal.toInt()} ml"),
            const Divider(height: 40),
            Text(
              "Durum: ${user!.bmiStatus}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bilgiKarti(String baslik, String deger) {
    return Card(
      child: ListTile(
        title: Text(baslik),
        trailing: Text(deger, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}