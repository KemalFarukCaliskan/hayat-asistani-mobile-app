class KitapModel {
  final String id;
  final String ad;
  final int toplamSayfa;
  int okunanSayfa;
  final String baslamaTarihi;
  String bitmeTarihi;
  bool bittiMi;

  KitapModel({
    required this.id,
    required this.ad,
    required this.toplamSayfa,
    required this.okunanSayfa,
    required this.baslamaTarihi,
    this.bitmeTarihi = "",
    this.bittiMi = false,
  });

  // Şimdilik listeleri SharedPreferences'ta saklamak için hızlıca JSON dönüşüm altyapısı kuruyoruz
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad': ad,
      'toplamSayfa': toplamSayfa,
      'okunanSayfa': okunanSayfa,
      'baslamaTarihi': baslamaTarihi,
      'bitmeTarihi': bitmeTarihi,
      'bittiMi': bittiMi ? 1 : 0,
    };
  }

  factory KitapModel.fromMap(Map<String, dynamic> map) {
    return KitapModel(
      id: map['id'],
      ad: map['ad'],
      toplamSayfa: map['toplamSayfa'],
      okunanSayfa: map['okunanSayfa'],
      baslamaTarihi: map['baslamaTarihi'],
      bitmeTarihi: map['bitmeTarihi'],
      bittiMi: map['bittiMi'] == 1,
    );
  }
}