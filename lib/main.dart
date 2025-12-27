import 'package:flutter/material.dart';
// 1. IMPOR PACKAGE UNTUK INISIALISASI
import 'package:intl/date_symbol_data_local.dart';
import 'package:sicoin/welcome_page.dart';

// 2. UBAH main() MENJADI async dan TAMBAHKAN KODE INISIALISASI
void main() async {
  // Baris ini wajib ada di dalam main() yang async sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // **PERBAIKAN UTAMA ADA DI SINI**
  // Inisialisasi data lokalisasi untuk bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'siCoin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Poppins', // Jika Anda menggunakan font custom
      ),
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      home: const WelcomePage(),
    );
  }
}
