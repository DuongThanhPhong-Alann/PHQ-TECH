import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apt_apartment/backend/src/phong/models/nguoi_dung.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AppAuthState {
  const AppAuthState({
    required this.status,
    this.profile,
  });

  final AuthStatus status;
  final NguoiDung? profile;

  static const AppAuthState unauthenticated =
      AppAuthState(status: AuthStatus.unauthenticated);
  static const AppAuthState loading = AppAuthState(status: AuthStatus.loading);
}

class AuthController extends ValueNotifier<AppAuthState> {
  AuthController()
      : _repository = AptConnectRepository(),
        super(AppAuthState.unauthenticated);

  final AptConnectRepository _repository;
  static const String _kSignedInUserId = 'aptconnect.signed_in_user_id';

  Future<void> restoreSession() async {
    value = AppAuthState.loading;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_kSignedInUserId);
      if (userId == null) {
        value = AppAuthState.unauthenticated;
        return;
      }
      final user = await _repository.fetchNguoiDungById(userId);
      if (user == null) {
        await prefs.remove(_kSignedInUserId);
        value = AppAuthState.unauthenticated;
        return;
      }
      value = AppAuthState(status: AuthStatus.authenticated, profile: user);
    } catch (_) {
      value = AppAuthState.unauthenticated;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final user = await _repository.fetchNguoiDungByEmail(email);
      if (user == null) {
        return 'Tai khoan khong ton tai.';
      }
      final storedHash = user.matKhauHash;
      if (storedHash == null) {
        return 'Mat khau khong chinh xac.';
      }
      final isBcrypt = _isBcryptHash(storedHash);
      final matches = _verifyPassword(password, storedHash);
      if (!matches) {
        return 'Mat khau khong chinh xac.';
      }

      if (!isBcrypt) {
        final upgradedHash = _hashPassword(password);
        await _repository.updateNguoiDungMatKhau(
          nguoiDungId: user.id,
          matKhauHash: upgradedHash,
        );
      }

      value = AppAuthState(
        status: AuthStatus.authenticated,
        profile: user,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kSignedInUserId, user.id);
      return null;
    } catch (error) {
      return 'Da co loi xay ra: $error';
    }
  }

  Future<String?> signUp({
    required String hoTen,
    required String email,
    required String password,
    String? soDienThoai,
  }) async {
    try {
      final existing = await _repository.fetchNguoiDungByEmail(email);
      if (existing != null) {
        return 'Email da duoc dang ky.';
      }
      await _repository.upsertNguoiDung(
        hoTen: hoTen,
        email: email,
        matKhauHash: _hashPassword(password),
        soDienThoai: soDienThoai,
      );
      return null;
    } catch (error) {
      return 'Da co loi xay ra: $error';
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSignedInUserId);
    } catch (_) {}
    value = AppAuthState.unauthenticated;
  }

  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  bool _verifyPassword(String password, String storedHash) {
    if (_isBcryptHash(storedHash)) {
      return BCrypt.checkpw(password, storedHash);
    }
    return _legacyHash(password) == storedHash;
  }

  bool _isBcryptHash(String hash) {
    return hash.startsWith(r'$2');
  }

  String _legacyHash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
