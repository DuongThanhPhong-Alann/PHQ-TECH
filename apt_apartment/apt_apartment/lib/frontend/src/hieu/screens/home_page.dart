import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:apt_apartment/backend/src/hieu/models/chung_cu.dart';
import 'package:apt_apartment/backend/src/phong/services/auth_controller.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/frontend/src/hieu/screens/can_ho_page.dart';
import 'package:apt_apartment/frontend/src/hieu/screens/chung_cu_detail_page.dart';
import 'package:apt_apartment/frontend/src/phong/screens/thong_tin_page.dart';
import 'package:apt_apartment/frontend/src/quang/constants/media_assets.dart';
import 'package:apt_apartment/frontend/src/quang/screens/dich_vu_page.dart';
import 'package:apt_apartment/frontend/src/quang/screens/hoa_don_page.dart';
import 'package:apt_apartment/frontend/src/quang/screens/phan_anh_page.dart';
import 'package:apt_apartment/frontend/src/quang/screens/tin_tuc_page.dart';
import 'package:apt_apartment/frontend/src/quang/widgets/app_states.dart';
import 'package:apt_apartment/frontend/src/vy/screens/chat_page.dart';

class AptConnectHomePage extends StatefulWidget {
  const AptConnectHomePage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AptConnectHomePage> createState() => _AptConnectHomePageState();
}

class _AptConnectHomePageState extends State<AptConnectHomePage> {
  int _currentIndex = 0;
  late final List<_NavItem> _items;

  @override
  void initState() {
    super.initState();
    final profile = widget.authController.value.profile;
    _items = [
      const _NavItem(
        title: 'Chung cư',
        icon: Icons.apartment_rounded,
        page: ChungCuTab(),
      ),
      const _NavItem(
        title: 'Căn hộ',
        icon: Icons.home_work_rounded,
        page: CanHoPage(),
      ),
      _NavItem(
        title: 'Dịch vụ',
        icon: Icons.design_services_rounded,
        page: DichVuPage(userId: profile?.id),
      ),
      const _NavItem(
        title: 'Tin tức',
        icon: Icons.article_outlined,
        page: TinTucPage(),
      ),
      _NavItem(
        title: 'Hóa đơn',
        icon: Icons.receipt_long_rounded,
        page: HoaDonPage(userId: profile?.id),
      ),
      _NavItem(
        title: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        page: ChatPage(profile: profile),
      ),
      _NavItem(
        title: 'Phản ánh',
        icon: Icons.report_outlined,
        page: PhanAnhPage(userId: profile?.id),
      ),
      _NavItem(
        title: 'Thông tin',
        icon: Icons.info_outline_rounded,
        page: ThongTinPage(profile: profile),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _items[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.title),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: widget.authController.signOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _items.map((item) => item.page).toList(growable: false),
      ),
      bottomNavigationBar: _ScrollableBottomNav(
        items: _items,
        currentIndex: _currentIndex,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _ScrollableBottomNav extends StatelessWidget {
  const _ScrollableBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.78),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final selected = index == currentIndex;
                    final textColor =
                        selected ? colorScheme.primary : colorScheme.onSurface;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => onSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? colorScheme.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.icon, color: textColor),
                              const SizedBox(width: 8),
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: selected
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.title,
    required this.icon,
    required this.page,
  });

  final String title;
  final IconData icon;
  final Widget page;
}

class ChungCuTab extends StatefulWidget {
  const ChungCuTab({super.key});

  @override
  State<ChungCuTab> createState() => _ChungCuTabState();
}

class _ChungCuTabState extends State<ChungCuTab> {
  final AptConnectRepository _repository = AptConnectRepository();
  final TextEditingController _searchController = TextEditingController();

  Future<List<ChungCu>>? _future;
  List<ChungCu> _cachedChungCus = const [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _future = _loadChungCus();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<List<ChungCu>> _loadChungCus() async {
    final results = await _repository.fetchChungCus();
    if (mounted) {
      setState(() {
        _cachedChungCus = results;
      });
    }
    return results;
  }

  void _handleSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }

  Future<void> _refresh() async {
    final data = await _repository.fetchChungCus();
    if (!mounted) return;
    setState(() {
      _cachedChungCus = data;
      _future = Future.value(data);
    });
  }

  List<ChungCu> get _filteredChungCus {
    if (_searchQuery.isEmpty) {
      return _cachedChungCus;
    }
    return _cachedChungCus.where((chungCu) {
      final name = chungCu.ten.toLowerCase();
      final address = chungCu.diaChi.toLowerCase();
      return name.contains(_searchQuery) || address.contains(_searchQuery);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChungCu>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedChungCus.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError && _cachedChungCus.isEmpty) {
          return AppErrorState(
            message: snapshot.error.toString(),
            onRetry: () async {
              setState(() => _future = _loadChungCus());
              await _future;
            },
          );
        }

        final chungCus = _filteredChungCus;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _SearchRow(
                    controller: _searchController,
                    onRefresh: _refresh,
                  ),
                ),
              ),
              if (chungCus.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.apartment_rounded,
                    title: 'Không có chung cư nào',
                    subtitle: 'Thử đổi từ khóa hoặc kéo xuống để tải lại.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList.separated(
                    itemCount: chungCus.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final chungCu = chungCus[index];
                      return _ChungCuCard(
                        chungCu: chungCu,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChungCuDetailPage(chungCu: chungCu),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm theo tên hoặc địa chỉ...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: 'Tải lại',
          onPressed: () => onRefresh(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _ChungCuCard extends StatelessWidget {
  const _ChungCuCard({required this.chungCu, required this.onTap});

  final ChungCu chungCu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = chungCu.hinhAnhs.isNotEmpty
        ? chungCu.hinhAnhs.first
        : MediaAssets.chungCuImage;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (context, _) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const _ImageFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chungCu.ten,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          chungCu.diaChi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.75),
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (chungCu.moTa != null && chungCu.moTa!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      chungCu.moTa!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (chungCu.soTang != null)
                        _InfoChip(
                          icon: Icons.apartment_rounded,
                          label: '${chungCu.soTang} tầng',
                        ),
                      if (chungCu.namXayDung != null)
                        _InfoChip(
                          icon: Icons.calendar_month_rounded,
                          label: 'Năm ${chungCu.namXayDung}',
                        ),
                      if (chungCu.chuDauTu != null &&
                          chungCu.chuDauTu!.isNotEmpty)
                        _InfoChip(
                          icon: Icons.badge_outlined,
                          label: chungCu.chuDauTu!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 54,
          color: colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
