import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinansScreen extends StatefulWidget {
  const FinansScreen({super.key});

  @override
  State<FinansScreen> createState() => _FinansScreenState();
}

class _FinansScreenState extends State<FinansScreen> {
  // Form Elemanları
  final amountController = TextEditingController();
  final nameController = TextEditingController();
  String transactionType = "Gelir"; // Gelir veya Gider
  DateTime selectedDate = DateTime.now();

  // Finansal Veri Listesi
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  // Filtreleme Durumları: 'all', 'weekly', 'monthly', 'yearly', 'custom'
  String currentFilter = "all"; 
  DateTimeRange? customDateRange;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  @override
  void dispose() {
    amountController.dispose();
    nameController.dispose();
    super.dispose();
  }

  // Verileri SharedPreferences'tan yükleme
  _loadFinanceData() async {
    final prefs = await SharedPreferences.getInstance();
    String historyStr = prefs.getString('finans_islemleri_listesi') ?? "[]";
    List<dynamic> decoded = jsonDecode(historyStr);
    
    setState(() {
      allTransactions = List<Map<String, dynamic>>.from(decoded);
      _applyFilter("all"); // Varsayılan olarak hepsini göster
    });
  }

  // Yeni Gelir/Gider Kaydetme
  _addTransaction() async {
    double amount = double.tryParse(amountController.text) ?? 0.0;
    String name = nameController.text.trim();

    if (amount <= 0 || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen geçerli bir miktar ve isim girin!")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> newTx = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'amount': amount,
      'type': transactionType, // "Gelir" veya "Gider"
      'date': selectedDate.toIso8601String(),
    };

    setState(() {
      allTransactions.add(newTx);
      amountController.clear();
      nameController.clear();
      selectedDate = DateTime.now();
      _applyFilter(currentFilter); // Mevcut filtreyi koru ve listeyi yenile
    });

    await prefs.setString('finans_islemleri_listesi', jsonEncode(allTransactions));
  }

  // İşlem Silme Altyapısı (Testlerde kolaylık olsun diye kanka)
  _deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      allTransactions.removeWhere((tx) => tx['id'] == id);
      _applyFilter(currentFilter);
    });
    await prefs.setString('finans_islemleri_listesi', jsonEncode(allTransactions));
  }

  // Tarih Seçici (showDatePicker)
  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Takvimden İki Tarih Arası Seçici (showDateRangePicker)
  _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() {
        customDateRange = picked;
        _applyFilter("custom");
      });
    }
  }

  // Senin istediğin o detaylı Haftalık, Aylık, Yıllık ve Özel Tarih Filtreleme Motoru
  _applyFilter(String filterType) {
    currentFilter = filterType;
    DateTime now = DateTime.now();

    setState(() {
      filteredTransactions = allTransactions.where((tx) {
        DateTime txDate = DateTime.parse(tx['date']);

        if (filterType == "weekly") {
          // Son 7 gün
          return now.difference(txDate).inDays <= 7;
        } else if (filterType == "monthly") {
          // Aynı ay ve aynı yıl
          return txDate.month == now.month && txDate.year == now.year;
        } else if (filterType == "yearly") {
          // Aynı yıl
          return txDate.year == now.year;
        } else if (filterType == "custom" && customDateRange != null) {
          // İki tarih arasında mı? (Gün bazında hassasiyet için başlangıç ve bitiş sınırları ayarı)
          return txDate.isAfter(customDateRange!.start.subtract(const Duration(days: 1))) &&
                 txDate.isBefore(customDateRange!.end.add(const Duration(days: 1)));
        }
        return true; // "all" ise hepsini döndür
      }).toList();
      
      // Tarihe göre en güncelden eskiye doğru sırala
      filteredTransactions.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    });
  }

  // Mali Durum Özeti Hesaplama (Gelir - Gider)
  Map<String, double> _calculateSummary() {
    double totalGelir = 0;
    double totalGider = 0;

    for (var tx in filteredTransactions) {
      double amt = tx['amount'];
      if (tx['type'] == "Gelir") {
        totalGelir += amt;
      } else {
        totalGider += amt;
      }
    }
    return {
      'gelir': totalGelir,
      'gider': totalGider,
      'denge': totalGelir - totalGider,
    };
  }

  @override
  Widget build(BuildContext context) {
    var summary = _calculateSummary();
    String formattedDate = "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}";

    return Scaffold(
      appBar: AppBar(title: const Text("Finans Dengesi")),
      body: Column(
        children: [
          // 1. ÜST BÖLÜM: GELİR/GİDER EKLEME FORMU
          ExpansionTile(
            title: const Text("Yeni Gelir / Gider Ekle", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: "İsim (Örn: Maaş, Kira, Market)", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: amountController,
                            decoration: const InputDecoration(labelText: "Miktar (TL)", border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tür Seçimi (Dropdown)
                        DropdownButton<String>(
                          value: transactionType,
                          items: ["Gelir", "Gider"].map((String val) {
                            return DropdownMenuItem<String>(value: val, child: Text(val));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              transactionType = value!;
                            });
                          },
                        ),
                        // Tarih Seçim Butonu
                        OutlinedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text("Tarih: $formattedDate"),
                        ),
                        // Ekleme Butonu
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          onPressed: _addTransaction,
                          child: const Text("Ekle"),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),

          // 2. ORTA BÖLÜM: FİLTRELEME BUTONLARI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              children: [
                _filterButton("Tümü", "all"),
                _filterButton("Haftalık", "weekly"),
                _filterButton("Aylık", "monthly"),
                _filterButton("Yıllık", "yearly"),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentFilter == "custom" ? Colors.blue : Colors.grey.shade200,
                    foregroundColor: currentFilter == "custom" ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => _selectDateRange(context),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(currentFilter == "custom" && customDateRange != null
                      ? "${customDateRange!.start.day}.${customDateRange!.start.month} - ${customDateRange!.end.day}.${customDateRange!.end.month}"
                      : "Takvimden Seç"),
                ),
              ],
            ),
          ),

          // 3. MALİ DURUM GÖSTERGE PANELI (ÖZET KAPANI)
          Card(
            margin: const EdgeInsets.all(12),
            color: Colors.blueGrey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _summaryColumn("Toplam Gelir", "${summary['gelir']!.toStringAsFixed(0)} TL", Colors.green),
                  const VerticalDivider(thickness: 2),
                  _summaryColumn("Toplam Gider", "${summary['gider']!.toStringAsFixed(0)} TL", Colors.red),
                  const VerticalDivider(thickness: 2),
                  _summaryColumn("Güncel Durum", "${summary['denge']!.toStringAsFixed(0)} TL", 
                      summary['denge']! >= 0 ? Colors.blue.shade900 : Colors.red.shade900),
                ],
              ),
            ),
          ),

          // 4. ALT BÖLÜM: FİLTRELENMİŞ İŞLEM LİSTESİ
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(child: Text("Bu filtreye uygun harcama veya gelir kaydı bulunamadı."))
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      DateTime txDate = DateTime.parse(tx['date']);
                      bool isGelir = tx['type'] == "Gelir";

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isGelir ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(isGelir ? Icons.arrow_upward : Icons.arrow_downward, color: isGelir ? Colors.green : Colors.red),
                        ),
                        title: Text(tx['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${txDate.day}.${txDate.month}.${txDate.year}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${isGelir ? '+' : '-'} ${tx['amount']} TL",
                              style: TextStyle(color: isGelir ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () => _deleteTransaction(tx['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, String filterType) {
    bool isActive = currentFilter == filterType;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.blue : Colors.grey.shade200,
          foregroundColor: isActive ? Colors.white : Colors.black87,
        ),
        onPressed: () => _applyFilter(filterType), // Başına alt çizgiyi ekledik kanka
        child: Text(label),
      ),
    );
  }

  Widget _summaryColumn(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
} // Sınıfın en sonundaki süslü parantez