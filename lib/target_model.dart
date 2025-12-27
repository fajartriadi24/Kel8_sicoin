// lib/target_model.dart

class TargetModel {  // ==================== PERUBAHAN 1: Tambahkan ID ====================
  // ID ini akan menjadi primary key di database. Boleh null saat pertama kali dibuat.
  final int? id;

  // Properti yang sudah ada (dibuat 'final' untuk konsistensi, kecuali 'currentAmount')
  final String name;
  final double targetAmount;
  final DateTime startDate;
  final DateTime endDate;

  double currentAmount;

  // ==================== PERUBAHAN 2: Perbarui Constructor ====================
  // Tambahkan 'this.id' di constructor agar bisa menerima ID.
  TargetModel({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.startDate,
    required this.endDate,
    this.currentAmount = 0.0,
  });

  // Getter 'progress' tidak berubah, sudah bagus.
  double get progress {
    if (targetAmount <= 0) {
      return 0.0;
    }
    final calculatedProgress = currentAmount / targetAmount;
    return calculatedProgress.clamp(0.0, 1.0);
  }

  // =========================================================================
  // === PERUBAHAN 3: Tambahkan metode untuk konversi ke/dari database ===
  // =========================================================================

  // Metode 'copyWith' untuk membuat salinan objek dengan nilai yang diperbarui.
  // Sangat berguna saat Anda ingin meng-update sebagian data target.
  TargetModel copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TargetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  // Metode 'toMap' untuk mengubah objek TargetModel menjadi Map.
  // Format Map inilah yang akan disimpan oleh sqflite ke dalam database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      // Simpan tanggal sebagai String dengan format ISO 8601, ini adalah standar terbaik.
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  // Factory constructor 'fromMap' untuk membuat objek TargetModel dari Map.
  // Ini digunakan saat Anda membaca data dari database.
  factory TargetModel.fromMap(Map<String, dynamic> map) {
    return TargetModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(), // Konversi aman dari num
      currentAmount: (map['currentAmount'] as num).toDouble(), // Konversi aman dari num
      // Ubah kembali String dari database menjadi objek DateTime.
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
    );
  }
}
