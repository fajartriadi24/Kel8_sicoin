import 'package:flutter/material.dart';
// 1. Import tambahan WAJIB agar Web tidak Error
import 'package:flutter/foundation.dart'; // Untuk cek kIsWeb
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Paket Web Database
import 'package:sqflite/sqflite.dart'; // Paket Database utama

import 'package:intl/date_symbol_data_local.dart';
import 'package:sicoin/welcome_page.dart';

void main() async {
  // Wajib ada di baris pertama
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Format Tanggal (Indonesia)
  await initializeDateFormatting('id_ID', null);

  // 3. LOGIKA PERBAIKAN ERROR WEB (PENTING!)
  // Cek: Jika aplikasi dijalankan di browser (Web)
  if (kIsWeb) {
    // Gunakan factory database khusus Web
    databaseFactory = databaseFactoryFfiWeb;
  }

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
        fontFamily: 'Poppins', 
      ),
      debugShowCheckedModeBanner: false, 
      home: const WelcomePage(),
    );
  }
}
