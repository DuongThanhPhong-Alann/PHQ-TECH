import 'package:flutter/material.dart';

import 'package:apt_apartment/backend/src/phong/models/nguoi_dung.dart';
import 'package:apt_apartment/frontend/src/quang/widgets/app_states.dart';

class ThongTinPage extends StatelessWidget {
  const ThongTinPage({super.key, required this.profile});

  final NguoiDung? profile;

  @override
  Widget build(BuildContext context) {
    final user = profile;
    if (user == null) {
      return const AppEmptyState(
        icon: Icons.info_outline_rounded,
        title: 'Không tìm thấy tài khoản',
        subtitle: 'Vui lòng đăng nhập lại.',
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initial =
        user.hoTen.isNotEmpty ? user.hoTen.trim().substring(0, 1) : '?';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    initial.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.hoTen,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.loaiNguoiDung,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      if (user.isCuDan &&
                          (user.tenChungCu != null || user.tenCanHo != null))
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (user.tenChungCu != null)
                                Chip(
                                  avatar: const Icon(Icons.apartment_rounded,
                                      size: 16),
                                  label: Text(user.tenChungCu!),
                                ),
                              if (user.tenCanHo != null)
                                Chip(
                                  avatar: const Icon(Icons.home_work_rounded,
                                      size: 16),
                                  label: Text(user.tenCanHo!),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                value: user.email,
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.phone_iphone_rounded,
                title: 'Số điện thoại',
                value: user.soDienThoai ?? 'Chưa cập nhật',
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.badge_outlined,
                title: 'Loại tài khoản',
                value: user.loaiNguoiDung,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.apartment_rounded, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Về APT-CONNECT',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Ứng dụng hỗ trợ cư dân xem tin tức, hóa đơn, đăng ký dịch vụ, gửi phản ánh và trò chuyện trực tiếp trong cùng một nền tảng.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: colorScheme.primary),
      ),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
