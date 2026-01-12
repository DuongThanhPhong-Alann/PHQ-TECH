import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:apt_apartment/backend/src/hieu/models/can_ho.dart';
import 'package:apt_apartment/backend/src/hieu/models/chung_cu.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/frontend/src/hieu/screens/can_ho_detail_page.dart';
import 'package:apt_apartment/frontend/src/quang/constants/media_assets.dart';
import 'package:apt_apartment/frontend/src/quang/widgets/app_states.dart';

class ChungCuDetailPage extends StatefulWidget {
  const ChungCuDetailPage({super.key, required this.chungCu});

  final ChungCu chungCu;

  @override
  State<ChungCuDetailPage> createState() => _ChungCuDetailPageState();
}

class _ChungCuDetailPageState extends State<ChungCuDetailPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  Future<List<CanHo>>? _apartmentsFuture;
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

  @override
  void initState() {
    super.initState();
    _apartmentsFuture = _repository.fetchCanHos(chungCuId: widget.chungCu.id);
  }

  Future<void> _reloadApartments() async {
    setState(() {
      _apartmentsFuture = _repository.fetchCanHos(chungCuId: widget.chungCu.id);
    });
    await _apartmentsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final chungCu = widget.chungCu;
    final image = chungCu.hinhAnhs.isNotEmpty
        ? chungCu.hinhAnhs.first
        : MediaAssets.chungCuImage;

    return Scaffold(
      appBar: AppBar(title: Text(chungCu.ten)),
      body: RefreshIndicator(
        onRefresh: _reloadApartments,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) =>
                              const _HeroImageFallback(),
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
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(chungCu.diaChi)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                if (chungCu.chuDauTu != null &&
                                    chungCu.chuDauTu!.isNotEmpty)
                                  _InfoChip(
                                    icon: Icons.badge_outlined,
                                    label: 'Chủ đầu tư: ${chungCu.chuDauTu}',
                                  ),
                                if (chungCu.namXayDung != null)
                                  _InfoChip(
                                    icon: Icons.calendar_month_rounded,
                                    label: 'Năm: ${chungCu.namXayDung}',
                                  ),
                                if (chungCu.soTang != null)
                                  _InfoChip(
                                    icon: Icons.layers_rounded,
                                    label: '${chungCu.soTang} tầng',
                                  ),
                              ],
                            ),
                            if (chungCu.moTa != null &&
                                chungCu.moTa!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                chungCu.moTa!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Danh sách căn hộ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: 'Tải lại',
                      onPressed: _reloadApartments,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: FutureBuilder<List<CanHo>>(
                future: _apartmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppErrorState(
                        message: snapshot.error.toString(),
                        onRetry: _reloadApartments,
                      ),
                    );
                  }
                  final list = snapshot.data ?? const [];
                  if (list.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: Icons.home_work_outlined,
                        title: 'Chưa có căn hộ',
                        subtitle: 'Chung cư này chưa có căn hộ nào được đăng.',
                      ),
                    );
                  }
                  return SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final canHo = list[index];
                      return _ApartmentTile(
                        canHo: canHo,
                        currency: _currency,
                        onTap: () => _openCanHo(canHo),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCanHo(CanHo canHo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CanHoDetailPage(canHoId: canHo.id),
      ),
    );
  }
}

class _ApartmentTile extends StatelessWidget {
  const _ApartmentTile({
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
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(canHo.maCan),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canHo.dienTich != null)
              Text('Diện tích: ${canHo.dienTich} m²'),
            if (canHo.soPhong != null) Text('Số phòng: ${canHo.soPhong}'),
            if (canHo.gia != null) Text('Giá: ${currency.format(canHo.gia)}'),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
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

class _HeroImageFallback extends StatelessWidget {
  const _HeroImageFallback();

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
