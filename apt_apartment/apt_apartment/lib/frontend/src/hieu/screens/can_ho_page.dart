import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:apt_apartment/backend/src/hieu/models/can_ho.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/frontend/src/hieu/screens/can_ho_detail_page.dart';
import 'package:apt_apartment/frontend/src/quang/constants/media_assets.dart';
import 'package:apt_apartment/frontend/src/quang/widgets/app_states.dart';

class CanHoPage extends StatefulWidget {
  const CanHoPage({super.key});

  @override
  State<CanHoPage> createState() => _CanHoPageState();
}

class _CanHoPageState extends State<CanHoPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  Future<List<CanHo>>? _future;
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchAllCanHos();
  }

  Future<void> _refresh() async {
    final result = await _repository.fetchAllCanHos();
    if (!mounted) return;
    setState(() => _future = Future.value(result));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CanHo>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AppErrorState(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }
        final apartments = snapshot.data ?? const [];
        if (apartments.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                SizedBox(height: 80),
                AppEmptyState(
                  icon: Icons.home_work_rounded,
                  title: 'Chưa có căn hộ',
                  subtitle: 'Hiện chưa có căn hộ nào được đăng.',
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: apartments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final canHo = apartments[index];
              return _ApartmentCard(
                canHo: canHo,
                currency: _currency,
                onTap: () => _openDetail(canHo),
              );
            },
          ),
        );
      },
    );
  }

  void _openDetail(CanHo canHo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CanHoDetailPage(canHoId: canHo.id),
      ),
    );
  }
}

class _ApartmentCard extends StatelessWidget {
  const _ApartmentCard({
    required this.canHo,
    required this.currency,
    required this.onTap,
  });

  final CanHo canHo;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = canHo.mediaUrls.isNotEmpty ? canHo.mediaUrls.first : null;
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
                imageUrl: imageUrl ?? MediaAssets.canHoImage,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.home_work_outlined,
                      size: 54,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          canHo.maCan,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _StatusChip(status: canHo.trangThai),
                    ],
                  ),
                  if (canHo.tenChungCu != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            canHo.tenChungCu!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.75),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (canHo.dienTich != null)
                        _InfoChip(
                          icon: Icons.square_foot_rounded,
                          text: '${canHo.dienTich} m²',
                        ),
                      if (canHo.soPhong != null)
                        _InfoChip(
                          icon: Icons.king_bed_outlined,
                          text: '${canHo.soPhong} phòng',
                        ),
                      if (canHo.gia != null)
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          text: currency.format(canHo.gia),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _QuickInfo(canHo: canHo),
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
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
    );
  }
}

class _QuickInfo extends StatelessWidget {
  const _QuickInfo({required this.canHo});

  final CanHo canHo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (canHo.moTa != null && canHo.moTa!.isNotEmpty) {
      return Text(
        canHo.moTa!,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(
      'Chưa có mô tả chi tiết.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.75),
          ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      'Dang ban' || 'Đang bán' => (scheme.primary.withValues(alpha: 0.16), scheme.primary),
      'Da ban' || 'Đã bán' => (scheme.tertiary.withValues(alpha: 0.16), scheme.tertiary),
      'Cho thue' || 'Cho thuê' => (scheme.secondary.withValues(alpha: 0.16), scheme.secondary),
      'Da thue' || 'Đã thuê' => (scheme.error.withValues(alpha: 0.14), scheme.error),
      _ => (scheme.primary.withValues(alpha: 0.16), scheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.30)),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
