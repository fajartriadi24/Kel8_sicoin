import 'dart:ui'; // Diperlukan untuk ImageFilter (efek blur glassmorphism)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:sicoin/services/database_service.dart';

class DailyChecklistItem {
  final DateTime date;
  bool isChecked;
  final bool isInitiallyChecked;

  DailyChecklistItem({
    required this.date,
    this.isChecked = false,
    this.isInitiallyChecked = false,
  });
}

class MonitoringTargetPage extends StatefulWidget {
  final TargetModel target;
  const MonitoringTargetPage({super.key, required this.target});

  @override
  State<MonitoringTargetPage> createState() => _MonitoringTargetPageState();
}

class _MonitoringTargetPageState extends State<MonitoringTargetPage> {
  late TargetModel _currentTarget;
  late double _itemSavingTarget; // Nominal per satu kotak checklist
  List<DailyChecklistItem> _checklistItems = [];
  List<DailyChecklistItem> _upcomingListForDisplay = [];
  List<DailyChecklistItem> _completedListForDisplay = [];

  // Palet Warna Mewah
  final Color deepNavy = const Color(0xFF0D1B2A);
  final Color electricBlue = const Color(0xFF2979FF);

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _currentTarget = widget.target.copyWith();
    _initializeDailyChecklist();
    _refreshDisplayLists(); // Memisahkan daftar hanya saat halaman pertama kali dibuka
  }

  void _initializeDailyChecklist() {
    final int totalDiffDays = _currentTarget.endDate.difference(_currentTarget.startDate).inDays + 1;
    List<DateTime> allDates = [];

    // LOGIKA BARU: Generate tanggal berdasarkan savingPlan
    if (_currentTarget.savingPlan == 'weekly') {
      for (int i = 0; i < totalDiffDays; i += 7) {
        allDates.add(_currentTarget.startDate.add(Duration(days: i)));
      }
    } else if (_currentTarget.savingPlan == 'monthly') {
      for (int i = 0; i < totalDiffDays; i += 30) {
        allDates.add(_currentTarget.startDate.add(Duration(days: i)));
      }
    } else {
      // Default: Daily
      allDates = List.generate(totalDiffDays, (i) => _currentTarget.startDate.add(Duration(days: i)));
    }

    // Hitung nominal per kotak checklist
    _itemSavingTarget = allDates.isNotEmpty
        ? _currentTarget.targetAmount / allDates.length
        : _currentTarget.targetAmount;

    // Hitung berapa banyak yang sudah dicentang berdasarkan currentAmount
    int checkedCount = _itemSavingTarget > 0
        ? (_currentTarget.currentAmount / _itemSavingTarget).round()
        : 0;

    _checklistItems = allDates.asMap().entries.map((entry) {
      bool isChecked = entry.key < checkedCount;
      return DailyChecklistItem(
          date: entry.value,
          isChecked: isChecked,
          isInitiallyChecked: isChecked
      );
    }).toList();
  }

  // Fungsi ini menentukan posisi item (Atas/Bawah)
  void _refreshDisplayLists() {
    _upcomingListForDisplay = _checklistItems.where((item) => !item.isChecked).toList();
    _completedListForDisplay = _checklistItems.where((item) => item.isChecked).toList();
  }

  void _onChecklistTapped(DailyChecklistItem item) {
    final bool wasCompletedBefore = _currentTarget.currentAmount >= _currentTarget.targetAmount;

    setState(() {
      item.isChecked = !item.isChecked;

      // Update perhitungan jumlah tabungan (Real-time)
      int totalChecked = _checklistItems.where((i) => i.isChecked).length;
      _currentTarget.currentAmount = (totalChecked * _itemSavingTarget).clamp(0, _currentTarget.targetAmount);
    });

    if (_currentTarget.currentAmount >= _currentTarget.targetAmount && !wasCompletedBefore) {
      _showCompletionVideoDialog();
    }
  }

  void _showCompletionVideoDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (_) => CelebrationVideoDialog(targetName: _currentTarget.name));
  }

  void _navigateBack() {
    Navigator.of(context).pop({'action': 'update', 'target': _currentTarget});
  }

  void _deleteTarget() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Hapus Target', style: TextStyle(fontWeight: FontWeight.w900, color: deepNavy)),
        content: Text('Hapus target "${_currentTarget.name}"?\nTindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {'action': 'delete', 'target': _currentTarget});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String planText = "Harian";
    if(_currentTarget.savingPlan == 'weekly') planText = "Mingguan";
    if(_currentTarget.savingPlan == 'monthly') planText = "Bulanan";

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) { if (!didPop) _navigateBack(); },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: deepNavy, size: 20),
              onPressed: _navigateBack
          ),
          title: Text('Monitoring', style: TextStyle(color: deepNavy, fontWeight: FontWeight.w900, fontSize: 22)),
          actions: [
            IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: _deleteTarget),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _buildGlassProgressCard(),
            const SizedBox(height: 32),
            Text('Rencana $planText', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: deepNavy, letterSpacing: -0.5)),
            Text('Ketuk untuk mencatat tabungan $planText-mu.', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
            const SizedBox(height: 20),

            ..._upcomingListForDisplay.map((item) => _buildChecklistItem(item)),

            if (_completedListForDisplay.isNotEmpty) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('RIWAYAT SELESAI', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              ..._completedListForDisplay.reversed.map((item) => _buildChecklistItem(item)),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassProgressCard() {
    bool isDone = _currentTarget.currentAmount >= _currentTarget.targetAmount;

    // Hitung sisa item/hari/minggu/bulan
    final int totalItems = _checklistItems.length;
    final int checkedItems = _checklistItems.where((i) => i.isChecked).length;
    final int remaining = (totalItems - checkedItems).clamp(0, totalItems);

    String unit = "Item";
    if(_currentTarget.savingPlan == 'daily') unit = "Hari";
    if(_currentTarget.savingPlan == 'weekly') unit = "Minggu";
    if(_currentTarget.savingPlan == 'monthly') unit = "Bulan";

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepNavy,
            deepNavy.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: deepNavy.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(_currentTarget.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)
                      ),
                    ),
                    if (!isDone) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: electricBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: electricBlue.withValues(alpha: 0.5))),
                      child: Text('$remaining $unit Lagi', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text('Terkumpul saat ini', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(currencyFormatter.format(_currentTarget.currentAmount),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: _currentTarget.progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(isDone ? const Color(0xFF00C853) : electricBlue),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(_currentTarget.progress * 100).toInt()}% Progres', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    Text('Target: ${currencyFormatter.format(_currentTarget.targetAmount)}', style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(DailyChecklistItem item) {
    bool isChecked = item.isChecked;
    String label = "Simpan";
    if(_currentTarget.savingPlan == 'weekly') label = "Setoran Minggu Ini";
    if(_currentTarget.savingPlan == 'monthly') label = "Setoran Bulan Ini";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isChecked ? electricBlue.withValues(alpha: 0.3) : Colors.transparent,
            width: 2
        ),
        boxShadow: [
          BoxShadow(
              color: isChecked ? electricBlue.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 6)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _onChecklistTapped(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isChecked ? electricBlue : Colors.transparent,
                    border: Border.all(color: isChecked ? electricBlue : Colors.grey.shade300, width: 2),
                  ),
                  child: Icon(
                    isChecked ? Icons.check_rounded : Icons.radio_button_off_rounded,
                    color: isChecked ? Colors.white : Colors.grey.shade300,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateFormatter.format(item.date),
                          style: TextStyle(fontWeight: FontWeight.w800, color: isChecked ? deepNavy : const Color(0xFF1A1A1A), fontSize: 15)
                      ),
                      const SizedBox(height: 2),
                      Text('$label ${currencyFormatter.format(_itemSavingTarget)}',
                          style: TextStyle(fontSize: 12, color: isChecked ? electricBlue : Colors.blueGrey, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CelebrationVideoDialog extends StatefulWidget {
  final String targetName;
  const CelebrationVideoDialog({super.key, required this.targetName});

  @override
  State<CelebrationVideoDialog> createState() => _CelebrationVideoDialogState();
}

class _CelebrationVideoDialogState extends State<CelebrationVideoDialog> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/celebration_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: 1,
              child: _controller.value.isInitialized ? VideoPlayer(_controller) : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Kamu Hebat!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), letterSpacing: -1)),
          const SizedBox(height: 10),
          Text('Target "${widget.targetName}"\nberhasil kamu capai!', textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B2A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              child: const Text('Lihat Pencapaian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
