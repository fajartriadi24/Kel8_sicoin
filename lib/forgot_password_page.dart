import 'package:flutter/material.dart';
import 'package:sicoin/services/database_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum ResetStep { enterEmail, enterCode }

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  ResetStep _currentStep = ResetStep.enterEmail;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Palet Warna Profesional
  final Color deepNavy = const Color(0xFF0D1B2A);
  final Color electricBlue = const Color(0xFF2979FF);
  final Color backgroundColor = const Color(0xFFEEF7FF);

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Harap masukkan email Anda', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final code = await DatabaseService.instance.generateAndSaveResetCode(_emailController.text);

    if (!mounted) return;

    if (code != null) {
      _showSnackBar('Kode verifikasi telah dikirim ke konsol debug', Colors.blue);
      setState(() {
        _currentStep = ResetStep.enterCode;
        _isLoading = false;
      });
    } else {
      _showSnackBar('Email tidak terdaftar', Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCodeAndReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await DatabaseService.instance.verifyCodeAndResetPassword(
      _emailController.text,
      _codeController.text,
      _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar('Password berhasil diubah!', Colors.green);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      _showSnackBar('Kode verifikasi salah atau kadaluarsa', Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: deepNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      // PERBAIKAN 1: Menggunakan .withValues
                      color: electricBlue.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Icon(
                  _currentStep == ResetStep.enterEmail
                      ? Icons.lock_reset_rounded
                      : Icons.verified_user_rounded,
                  size: 56,
                  color: electricBlue,
                ),
              ),

              const SizedBox(height: 40),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _currentStep == ResetStep.enterEmail
                    ? _buildEnterEmailStep()
                    : _buildEnterCodeStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnterEmailStep() {
    return Container(
      key: const ValueKey('enterEmail'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            // PERBAIKAN 2: Menggunakan .withValues
            color: deepNavy.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Lupa Password?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: deepNavy)),
          const SizedBox(height: 12),
          const Text(
            'Jangan khawatir! Masukkan email Anda untuk menerima kode verifikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _emailController,
            hint: 'Email Anda',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _sendResetCode,
            style: _buttonStyle(deepNavy),
            child: const Text('Kirim Kode Verifikasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterCodeStep() {
    return Container(
      key: const ValueKey('enterCode'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            // PERBAIKAN 3: Menggunakan .withValues
            color: deepNavy.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Verifikasi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: deepNavy)),
            const SizedBox(height: 8),
            Text(
              'Email: ${_emailController.text}',
              textAlign: TextAlign.center,
              style: TextStyle(color: electricBlue, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _codeController,
              hint: 'Kode 6-Digit',
              icon: Icons.pin_rounded,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Kode tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _newPasswordController,
              hint: 'Password Baru',
              icon: Icons.vpn_key_outlined,
              isPassword: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                if (v.length < 6) return 'Minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _verifyCodeAndReset,
              style: _buttonStyle(electricBlue),
              child: const Text('Reset Password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _currentStep = ResetStep.enterEmail),
              child: Text('Bukan email Anda? Kembali',
                  style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w600)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: electricBlue, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          // PERBAIKAN 4: Menggunakan .withValues
          borderSide: BorderSide(color: electricBlue.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
