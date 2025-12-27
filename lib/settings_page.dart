import 'package:flutter/material.dart';
import 'package:sicoin/login_page.dart';
import 'package:sicoin/services/database_service.dart';

class SettingsPage extends StatefulWidget {
  final int userId;const SettingsPage({
    super.key,
    required this.userId,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;

  User? _currentUser;
  String? _resultName;
  bool _isUserDataChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DatabaseService.instance.getUserById(widget.userId);
    if (mounted && user != null) {
      setState(() {
        _currentUser = user;
        _nameController.text = user.name;
        _emailController.text = user.email;
        _resultName = user.name;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    if (_currentUser == null || !mounted) return;
    final newEmail = _emailController.text;
    if (newEmail != _currentUser!.email) {
      final existingUser = await DatabaseService.instance.getUserByEmail(newEmail);
      if (existingUser != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Email sudah terdaftar!'),
              backgroundColor: Colors.redAccent));
        }
        return;
      }
    }
    final updatedUser = _currentUser!.copyWith(
        name: _nameController.text, email: _emailController.text);
    await DatabaseService.instance.updateUserProfile(updatedUser);

    setState(() {
      _resultName = _nameController.text;
      _isUserDataChanged = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: Colors.green));
    }
  }

  Future<void> _changePassword() async {
    if (!mounted) return;
    if (_currentUser?.password != null &&
        _currentUser!.password != _oldPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password lama salah!'),
          backgroundColor: Colors.redAccent));
      return;
    }
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password minimal 6 karakter!'),
          backgroundColor: Colors.orange));
      return;
    }
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Konfirmasi password tidak cocok!'),
          backgroundColor: Colors.orange));
      return;
    }
    await DatabaseService.instance
        .updateUserPassword(widget.userId, _newPasswordController.text);

    await _loadUserData();
    setState(() => _isUserDataChanged = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password berhasil diubah!'),
          backgroundColor: Colors.green));
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
      setState(() {
        _isOldPasswordVisible = false;
        _isNewPasswordVisible = false;
        _isConfirmNewPasswordVisible = false;
      });
    }
  }

  void _navigateBack() {
    if (mounted) {
      Navigator.of(context).pop(_isUserDataChanged ? _resultName : null);
    }
  }

  void _showDeleteAccountDialog() {
    if (_currentUser == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteAccountDialog(
        user: _currentUser!,
        onAccountDeleted: () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Akun dihapus secara permanen.'),
                  backgroundColor: Color(0xFF0D1B2A)),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _navigateBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF7FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text('Pengaturan',
              style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1A1A1A), size: 20),
            onPressed: _navigateBack,
          ),
        ),
        body: _currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Profil Pengguna', Icons.person_rounded),
              const SizedBox(height: 16),
              _buildProfileCard(),
              const SizedBox(height: 32),
              _buildSectionHeader('Keamanan', Icons.lock_rounded),
              const SizedBox(height: 16),
              _buildPasswordCard(),
              const SizedBox(height: 40),
              _buildDangerZone(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildModernField(
            controller: _nameController,
            labelText: 'Nama Lengkap',
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 20),
          _buildModernField(
            controller: _emailController,
            labelText: 'Email',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          _buildActionButton('Simpan Perubahan', _saveProfileChanges,
              const Color(0xFF0D1B2A)),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildModernField(
            controller: _oldPasswordController,
            labelText: 'Password Lama',
            prefixIcon: Icons.lock_open_rounded,
            isPassword: true,
            isPasswordVisible: _isOldPasswordVisible,
            onToggle: () =>
                setState(() => _isOldPasswordVisible = !_isOldPasswordVisible),
          ),
          const SizedBox(height: 20),
          _buildModernField(
            controller: _newPasswordController,
            labelText: 'Password Baru',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            isPasswordVisible: _isNewPasswordVisible,
            onToggle: () =>
                setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
          ),
          const SizedBox(height: 20),
          _buildModernField(
            controller: _confirmNewPasswordController,
            labelText: 'Konfirmasi Password',
            prefixIcon: Icons.check_circle_outline_rounded,
            isPassword: true,
            isPasswordVisible: _isConfirmNewPasswordVisible,
            onToggle: () => setState(() =>
            _isConfirmNewPasswordVisible = !_isConfirmNewPasswordVisible),
          ),
          const SizedBox(height: 24),
          // PERBAIKAN DI SINI: Colors.(...) diubah menjadi Color(...)
          _buildActionButton(
              'Ubah Password', _changePassword, const Color(0xFF0D1B2A)),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hapus Akun',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
              'Menghapus akun akan menghilangkan semua data tabungan secara permanen.',
              style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _showDeleteAccountDialog,
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            label: const Text('Hapus Akun Saya',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ],
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? !(isPasswordVisible ?? false) : false,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, color: Colors.blueAccent, size: 20),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                  (isPasswordVisible ?? false)
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 20,
                  color: Colors.grey),
              onPressed: onToggle,
            )
                : null,
            filled: true,
            fillColor: const Color(0xFFF0F4F8),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade100)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
    );
  }
}

enum _DeleteStep { confirmPassword, verifyCode, finalConfirm }

class _DeleteAccountDialog extends StatefulWidget {
  final User user;
  final VoidCallback onAccountDeleted;

  const _DeleteAccountDialog({
    required this.user,
    required this.onAccountDeleted,
  });

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  _DeleteStep _currentStep = _DeleteStep.confirmPassword;
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleNextStep() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    switch (_currentStep) {
      case _DeleteStep.confirmPassword:
        if (_passwordController.text == widget.user.password) {
          final code = await DatabaseService.instance
              .generateAndSaveResetCode(widget.user.email);
          if (code != null && mounted) {
            setState(() => _currentStep = _DeleteStep.verifyCode);
          }
        } else {
          setState(() => _errorMessage = 'Password salah!');
        }
        break;

      case _DeleteStep.verifyCode:
        final isValid = await DatabaseService.instance.verifyCodeAndResetPassword(
            widget.user.email, _codeController.text, widget.user.password);
        if (isValid) {
          setState(() => _currentStep = _DeleteStep.finalConfirm);
        } else {
          setState(() => _errorMessage = 'Kode salah!');
        }
        break;
      case _DeleteStep.finalConfirm:
        break;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Hapus Akun',
          style: TextStyle(fontWeight: FontWeight.w900)),
      content: _isLoading
          ? const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator()))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentStep == _DeleteStep.confirmPassword) ...[
            const Text('Masukkan password untuk konfirmasi.'),
            const SizedBox(height: 16),
            TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
          ] else if (_currentStep == _DeleteStep.verifyCode) ...[
            const Text('Masukkan kode verifikasi 6-digit.'),
            const SizedBox(height: 16),
            TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kode')),
          ] else ...[
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('Apakah Anda benar-benar yakin?',
                textAlign: TextAlign.center),
          ],
          if (_errorMessage != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red))),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        if (_currentStep != _DeleteStep.finalConfirm)
          ElevatedButton(onPressed: _handleNextStep, child: const Text('Lanjut'))
        else
          ElevatedButton(
              onPressed: () async {
                await DatabaseService.instance.deleteUserAccount(widget.user.id!);
                widget.onAccountDeleted();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus Permanen')),
      ],
    );
  }
}
