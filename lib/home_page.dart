import 'package:flutter/material.dart';
import 'package:intl/intl.dart';import 'package:sicoin/services/database_service.dart';
import 'package:sicoin/add_target_page.dart';
import 'package:sicoin/login_page.dart';
import 'package:sicoin/monitoring_target_page.dart';
import 'package:sicoin/settings_page.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final int userId;

  const HomePage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _currentUserName;
  List<TargetModel> _targetList = [];
  bool _isLoading = true;

  final currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName;
    _loadTargetsForCurrentUser();
  }

  Future<void> _loadTargetsForCurrentUser() async {
    setState(() => _isLoading = true);
    final targets = await DatabaseService.instance.getTargets(widget.userId);

    // Pengurutan: Aktif di atas, Selesai di bawah
    targets.sort((a, b) {
      final bool aIsCompleted = a.currentAmount >= a.targetAmount;
      final bool bIsCompleted = b.currentAmount >= b.targetAmount;

      if (aIsCompleted && !bIsCompleted) return 1;
      if (!aIsCompleted && bIsCompleted) return -1;
      return b.id.compareTo(a.id); // Urutan terbaru jika status sama
    });

    if (mounted) {
      setState(() {
        _targetList = targets;
        _isLoading = false;
      });
    }
  }

  Future<void> _addTarget(TargetModel newTarget) async {
    await DatabaseService.instance.insertTarget(widget.userId, newTarget);
    _loadTargetsForCurrentUser();
  }

  Future<void> _updateTarget(TargetModel updatedTarget) async {
    await DatabaseService.instance.updateTarget(widget.userId, updatedTarget);
    _loadTargetsForCurrentUser();
  }

  Future<void> _deleteTarget(TargetModel targetToDelete) async {
    await DatabaseService.instance.deleteTarget(widget.userId, targetToDelete.id);
    _loadTargetsForCurrentUser();
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  void _navigateToAddTarget() async {
    final newTarget = await Navigator.of(context).push<TargetModel>(
      MaterialPageRoute(builder: (context) => const AddTargetPage()),
    );
    if (newTarget != null) {
      _addTarget(newTarget);
    }
  }

  void _navigateToSettings() async {
    final newUserName = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => SettingsPage(userId: widget.userId)),
    );

    if (newUserName != null && mounted) {
      setState(() => _currentUserName = newUserName);
    }
  }

  void _navigateToMonitoring(TargetModel target) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => MonitoringTargetPage(target: target)),
    );

    if (result != null && result is Map<String, dynamic>) {
      final action = result['action'];
      final returnedTarget = result['target'] as TargetModel;
      if (action == 'delete') _deleteTarget(returnedTarget);
      else if (action == 'update') _updateTarget(returnedTarget);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF7FF), // Background biru muda estetik
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 85,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'siCoin',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Halo, $_currentUserName 👋',
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _navigateToSettings,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.settings_rounded, color: Colors.black87, size: 20),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: IconButton(
            onPressed: _logout,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final int completedCount = _targetList.where((t) => t.currentAmount >= t.targetAmount).length;
    final int activeCount = _targetList.length - completedCount;

    return RefreshIndicator(
      onRefresh: _loadTargetsForCurrentUser,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummarySection(completedCount, activeCount),
            const SizedBox(height: 32),
            _buildActionCard(),
            const SizedBox(height: 32),
            const Text(
              'Daftar Tabungan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            _targetList.isEmpty ? _buildEmptyState() : _buildTargetList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(int completed, int active) {
    return Row(
      children: [
        _buildSummaryCard(
          label: 'Selesai',
          value: completed.toString(),
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF00C853),
        ),
        const SizedBox(width: 16),
        _buildSummaryCard(
          label: 'Berjalan',
          value: active.toString(),
          icon: Icons.auto_graph_rounded,
          color: const Color(0xFF2979FF),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String label, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B2A).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/images/koin.png', width: 130),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wujudkan Impianmu',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tambah target baru untuk mulai menabung secara teratur.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _navigateToAddTarget,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Buat Target Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D1B2A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _targetList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildTargetItem(_targetList[index]),
    );
  }

  Widget _buildTargetItem(TargetModel target) {
    final bool isDone = target.currentAmount >= target.targetAmount;
    final progress = target.progress;

    return GestureDetector(
      onTap: () => _navigateToMonitoring(target),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDone ? Colors.green.withValues(alpha: 0.1) : Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(target.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Color(0xFF1A1A1A))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    isDone ? 'Selesai' : 'Aktif',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDone ? const Color(0xFF2E7D32) : const Color(0xFF1976D2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progres Tabungan', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF0F4F8),
                valueColor: AlwaysStoppedAnimation<Color>(isDone ? const Color(0xFF00C853) : const Color(0xFF2979FF)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(currencyFormatter.format(target.currentAmount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                Text('dari ${currencyFormatter.format(target.targetAmount)}', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(Icons.auto_graph_rounded, size: 70, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('Mulai Nabung Yuk!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
          const SizedBox(height: 4),
          Text('Belum ada target yang dibuat.', style: TextStyle(color: Colors.blueGrey.shade400)),
        ],
      ),
    );
  }
}
