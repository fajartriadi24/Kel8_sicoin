// File: lib/add_target_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sicoin/services/database_service.dart';
import 'package:uuid/uuid.dart';

class AddTargetPage extends StatefulWidget {
  const AddTargetPage({super.key});

  @override
  State<AddTargetPage> createState() => _AddTargetPageState();
}

class _AddTargetPageState extends State<AddTargetPage> {
  final _formKey = GlobalKey<FormState>();
  final _targetNameController = TextEditingController();
  final _targetAmountController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  // Variabel untuk menyimpan hasil perhitungan
  double _dailySaving = 0.0;
  double _weeklySaving = 0.0;
  double _monthlySaving = 0.0;

  // Variabel pilihan plan (Default: daily)
  String _selectedPlan = 'daily';

  final Color deepNavy = const Color(0xFF0D1B2A);
  final Color electricBlue = const Color(0xFF2979FF);

  final currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _targetAmountController.addListener(_calculateSavings);
  }

  @override
  void dispose() {
    _targetNameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  void _calculateSavings() {
    final double amount =
        double.tryParse(_targetAmountController.text.replaceAll('.', '')) ?? 0;

    if (amount > 0 && _startDate != null && _endDate != null) {
      if (_endDate!.isAfter(_startDate!)) {
        final int diffDays = _endDate!.difference(_startDate!).inDays + 1;

        setState(() {
          _dailySaving = amount / diffDays;
          // Perhitungan Mingguan (Jika rentang >= 7 hari)
          _weeklySaving = diffDays >= 7 ? (amount / (diffDays / 7)) : 0;
          // Perhitungan Bulanan (Jika rentang >= 30 hari)
          _monthlySaving = diffDays >= 30 ? (amount / (diffDays / 30)) : 0;
        });
        return;
      }
    }
    setState(() {
      _dailySaving = 0.0;
      _weeklySaving = 0.0;
      _monthlySaving = 0.0;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime currentStartDate = _startDate ?? DateTime.now();
    final DateTime firstSelectableDate =
    isStartDate ? DateTime.now() : currentStartDate.add(const Duration(days: 1));

    DateTime initialCalendarDate =
    isStartDate ? currentStartDate : (_endDate ?? firstSelectableDate);
    if (initialCalendarDate.isBefore(firstSelectableDate)) {
      initialCalendarDate = firstSelectableDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialCalendarDate,
      firstDate: firstSelectableDate,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: deepNavy,
              onPrimary: Colors.white,
              onSurface: deepNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
        _calculateSavings();
      });
    }
  }

  void _submitTarget() {
    if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
      final newTarget = TargetModel(
        id: const Uuid().v4(),
        name: _targetNameController.text,
        targetAmount: double.parse(_targetAmountController.text.replaceAll('.', '')),
        startDate: _startDate!,
        endDate: _endDate!,
        savingPlan: _selectedPlan, // Mengirimkan plan yang dipilih (daily/weekly/monthly)
      );
      Navigator.of(context).pop(newTarget);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data dengan benar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: deepNavy, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Target Baru',
          style: TextStyle(color: deepNavy, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormCard(),
                    if (_dailySaving > 0) ...[
                      const SizedBox(height: 32),
                      _buildRecommendationSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Nama Target'),
          _buildModernField(
            controller: _targetNameController,
            hint: 'Contoh: Laptop Gaming',
            icon: Icons.track_changes_rounded,
            validator: (value) => (value == null || value.isEmpty) ? 'Nama harus diisi' : null,
          ),
          const SizedBox(height: 24),
          _buildInputLabel('Jumlah Target'),
          _buildModernField(
            controller: _targetAmountController,
            hint: 'Contoh: 5.000.000',
            icon: Icons.account_balance_wallet_rounded,
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsSeparatorInputFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Jumlah harus diisi';
              final number = double.tryParse(value.replaceAll('.', '')) ?? 0;
              if (number <= 0) return 'Harus lebih dari 0';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildInputLabel('Periode Tabungan'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  date: _startDate,
                  label: 'Mulai',
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  date: _endDate,
                  label: 'Target Selesai',
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Pilih Rencana Menabung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: deepNavy,
              letterSpacing: -0.5,
            ),
          ),
        ),
        _buildSavingOptionCard(
          title: 'Nabung Harian',
          amount: _dailySaving,
          subtitle: 'Paling konsisten untuk target cepat',
          icon: Icons.wb_sunny_rounded,
          color: electricBlue,
          planType: 'daily',
        ),
        const SizedBox(height: 12),
        if (_weeklySaving > 0)
          _buildSavingOptionCard(
            title: 'Nabung Mingguan',
            amount: _weeklySaving,
            subtitle: 'Cocok untuk disisihkan tiap akhir pekan',
            icon: Icons.calendar_view_week_rounded,
            color: Colors.orangeAccent,
            planType: 'weekly',
          ),
        const SizedBox(height: 12),
        if (_monthlySaving > 0)
          _buildSavingOptionCard(
            title: 'Nabung Bulanan',
            amount: _monthlySaving,
            subtitle: 'Ideal setelah menerima gaji',
            icon: Icons.account_balance_rounded,
            color: Colors.greenAccent.shade700,
            planType: 'monthly',
          ),
      ],
    );
  }

  Widget _buildSavingOptionCard({
    required String title,
    required double amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String planType,
  }) {
    bool isSelected = _selectedPlan == planType;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? electricBlue : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? electricBlue.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? electricBlue : Colors.blueGrey.shade400,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: deepNavy,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey.shade300,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: electricBlue, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: deepNavy.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: electricBlue, size: 20),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: electricBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateButton({required DateTime? date, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: electricBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? dateFormatter.format(date) : 'Pilih',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: date == null ? Colors.grey : deepNavy,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitTarget,
        style: ElevatedButton.styleFrom(
          backgroundColor: deepNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('Buat Target Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    String newText = newValue.text.replaceAll('.', '');
    if (newText.isEmpty) {
      return const TextEditingValue();
    }
    try {
      final formatter = NumberFormat('#,###', 'id_ID');
      String formattedText = formatter.format(int.parse(newText));
      formattedText = formattedText.replaceAll(',', '.');

      return newValue.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}
