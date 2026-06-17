class UserModel {
  final String name;
  final int age;
  final double weight;
  final double height;
  final String gender; // Yeni eklediğimiz cinsiyet alanı

  UserModel({
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender, // Constructor'a da ekledik
  });

  // Senin yazdığın mevcut VKİ fonksiyonları aynen kalıyor
  double get bmi => weight / ((height / 100) * (height / 100));

  double get waterGoal => weight * 35;

  String get bmiStatus {
    if (bmi < 18.5) return "Zayıf";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Fazla Kilolu";
    return "Obez";
  }

  // --- DİYET MODÜLÜ İÇİN YENİ MATEMATİK MOTORU ---

  // Bazal Metabolizma Hızı (BMR) Hesaplama (Harris-Benedict Formülü)
  double calculateBMR() {
    if (gender == "Erkek") {
      return 66.47 + (13.75 * weight) + (5.003 * height) - (6.755 * age);
    } else {
      return 655.1 + (9.563 * weight) + (1.85 * height) - (4.676 * age);
    }
  }

  // Kullanıcının seçtiği hareket sıklığı ve diyete göre günlük kalori ihtiyacı
  double calculateDailyCalories(double activityMultiplier, String target) {
    double bmr = calculateBMR();
    double tdee = bmr * activityMultiplier; // Toplam Günlük Enerji Harcaması

    switch (target) {
      case "Kilo Vermek": 
        return tdee - 500; // Kalori açığı
      case "Hızlı Kilo Almak (Dirty Bulk)": 
        return tdee + 700; // Yüksek kalori fazlası
      case "Kilo Almak / Kas Kazanmak": 
        return tdee + 300; // Temiz kalori fazlası
      case "Kilosunu Korumak":
      default: 
        return tdee; // Sabit kalori
    }
  }
}