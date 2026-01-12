import 'package:flutter/material.dart';

import 'package:apt_apartment/backend/src/phong/services/auth_controller.dart';

class DangNhapPage extends StatefulWidget {
  const DangNhapPage({
    super.key,
    required this.controller,
    required this.onRegisterTap,
  });

  final AuthController controller;
  final VoidCallback onRegisterTap;

  @override
  State<DangNhapPage> createState() => _DangNhapPageState();
}

class _DangNhapPageState extends State<DangNhapPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final error = await widget.controller
        .signIn(_emailController.text.trim(), _passwordController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
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
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.password],
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
                : const Icon(Icons.login_rounded),
            label: const Text('Dang nhap'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onRegisterTap,
            child: const Text('Chua co tai khoan? Dang ky'),
          ),
        ],
      ),
    );
  }
}
