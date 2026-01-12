import 'package:flutter/material.dart';

import 'package:apt_apartment/backend/src/phong/services/auth_controller.dart';

class DangKyPage extends StatefulWidget {
  const DangKyPage({
    super.key,
    required this.controller,
    required this.onLoginTap,
  });

  final AuthController controller;
  final VoidCallback onLoginTap;

  @override
  State<DangKyPage> createState() => _DangKyPageState();
}

class _DangKyPageState extends State<DangKyPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final error = await widget.controller.signUp(
      hoTen: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      soDienThoai:
          _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dang ky thanh cong, vui long dang nhap.'),
      ),
    );
    widget.onLoginTap();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ho ten',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Vui long nhap ho ten';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Vui long nhap email';
                    if (!email.contains('@')) return 'Email khong hop le';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'So dien thoai (tuy chon)',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.newPassword],
                  obscureText: _obscureText,
                  textInputAction: TextInputAction.send,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mat khau',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscureText ? 'Hien' : 'An',
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                  validator: (value) {
                    final pw = value?.trim() ?? '';
                    if (pw.isEmpty) return 'Vui long nhap mat khau';
                    if (pw.length < 6) return 'Mat khau toi thieu 6 ky tu';
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Dang ky'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onLoginTap,
            child: const Text('Da co tai khoan? Dang nhap'),
          ),
        ],
      ),
    );
  }
}
