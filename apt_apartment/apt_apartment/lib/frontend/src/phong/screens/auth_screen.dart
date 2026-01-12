import 'package:flutter/material.dart';

import 'package:apt_apartment/backend/src/phong/services/auth_controller.dart';
import 'package:apt_apartment/frontend/src/phong/screens/dang_ky_page.dart';
import 'package:apt_apartment/frontend/src/phong/screens/dang_nhap_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showRegister = false;

  void _toggle() {
    setState(() => _showRegister = !_showRegister);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.12),
                            child: Icon(
                              Icons.apartment_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'APT-CONNECT',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  _showRegister
                                      ? 'Tao tai khoan moi'
                                      : 'Dang nhap de tiep tuc',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.75),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _toggle,
                            icon: Icon(
                              _showRegister
                                  ? Icons.login_rounded
                                  : Icons.person_add_alt_1_rounded,
                            ),
                            label: Text(_showRegister ? 'Dang nhap' : 'Dang ky'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _showRegister
                            ? DangKyPage(
                                key: const ValueKey('register'),
                                controller: widget.controller,
                                onLoginTap: _toggle,
                              )
                            : DangNhapPage(
                                key: const ValueKey('login'),
                                controller: widget.controller,
                                onRegisterTap: _toggle,
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bang viec dang nhap/tao tai khoan, ban dong y voi cac quy dinh su dung.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
