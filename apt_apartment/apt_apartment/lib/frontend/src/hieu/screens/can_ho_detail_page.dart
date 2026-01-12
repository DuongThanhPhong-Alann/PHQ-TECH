import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:apt_apartment/backend/src/hieu/models/can_ho.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/frontend/src/hieu/screens/three_d_viewer_page.dart';
import 'package:apt_apartment/frontend/src/quang/constants/media_assets.dart';

class CanHoDetailPage extends StatefulWidget {
  const CanHoDetailPage({super.key, required this.canHoId});

  final int canHoId;

  @override
  State<CanHoDetailPage> createState() => _CanHoDetailPageState();
}

class _CanHoDetailPageState extends State<CanHoDetailPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  late Future<CanHo?> _future;
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchCanHoById(widget.canHoId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết căn hộ')),
      body: FutureBuilder<CanHo?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            );
          }
          final canHo = snapshot.data;
          if (canHo == null) {
            return const Center(child: Text('Không tìm thấy căn hộ.'));
          }

          final images = canHo.mediaUrls.isNotEmpty
              ? canHo.mediaUrls
              : [MediaAssets.canHoImage];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 240,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => Center(
                            child: Icon(
                              Icons.home_work_outlined,
                              size: 72,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                canHo.maCan,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (canHo.dienTich != null)
                    _InfoChip(
                      icon: Icons.square_foot,
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
                      text: _currency.format(canHo.gia),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (canHo.moTa != null && canHo.moTa!.isNotEmpty)
                Text(
                  canHo.moTa!,
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              else
                Text(
                  'Chưa có mô tả.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                ),
              const SizedBox(height: 16),
              if (canHo.model3DUrls.isEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => _openModel(null, canHo.maCan),
                  icon: const Icon(Icons.public_rounded),
                  label: const Text('Xem mô hình 3D'),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < canHo.model3DUrls.length; i++)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                        child: FilledButton.tonalIcon(
                          onPressed: () => _openModel(
                            canHo.model3DUrls[i],
                            '${canHo.maCan} - ${i + 1}',
                          ),
                          icon: const Icon(Icons.public_rounded),
                          label: Text(
                            canHo.model3DUrls.length == 1
                                ? 'Xem mô hình 3D'
                                : 'Xem mô hình 3D ${i + 1}',
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  void _openModel(String? url, String title) {
    final target = url?.isNotEmpty == true ? url! : MediaAssets.canHo360;
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThreeDViewerPage(
          title: title,
          url: uri.toString(),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
  });

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
