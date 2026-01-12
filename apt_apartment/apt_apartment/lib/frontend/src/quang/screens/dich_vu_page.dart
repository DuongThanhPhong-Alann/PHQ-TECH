import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:apt_apartment/backend/src/quang/models/dich_vu.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/frontend/src/quang/constants/media_assets.dart';
import 'package:apt_apartment/frontend/src/quang/widgets/app_states.dart';

class DichVuPage extends StatefulWidget {
  const DichVuPage({super.key, this.userId});

  final int? userId;

  @override
  State<DichVuPage> createState() => _DichVuPageState();
}

class _DichVuPageState extends State<DichVuPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  Future<List<DichVu>>? _future;
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
  final Set<int> _pendingRegistrations = <int>{};

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchDichVus();
  }

  Future<void> _refresh() async {
    final result = await _repository.fetchDichVus();
    if (!mounted) return;
    setState(() => _future = Future.value(result));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DichVu>>(
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
        final services = snapshot.data ?? const [];
        if (services.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                SizedBox(height: 80),
                AppEmptyState(
                  icon: Icons.design_services_outlined,
                  title: 'Chưa có dịch vụ',
                  subtitle: 'Hiện chưa có dịch vụ nào được đăng.',
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final service = services[index];
              final isRegistering = _pendingRegistrations.contains(service.id);
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ServiceImage(hinhAnh: service.hinhAnh),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service.ten,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                _currency.format(service.gia),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service.moTa,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: isRegistering
                                  ? null
                                  : () => _confirmRegister(service),
                              icon: isRegistering
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.assignment_turned_in_outlined,
                                    ),
                              label: Text(
                                isRegistering
                                    ? 'Dang xu ly...'
                                    : 'Dang ky dich vu',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmRegister(DichVu service) async {
    final userId = widget.userId;
    if (userId == null) {
      _showMessage('Vui long dang nhap de dang ky dich vu.');
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xac nhan dang ky'),
            content: Text('Ban co chac muon dang ky dich vu "${service.ten}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Huy'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Dong y'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    setState(() => _pendingRegistrations.add(service.id));
    try {
      await _repository.registerDichVu(
        dichVuId: service.id,
        nguoiDungId: userId,
        soTien: service.gia,
      );
      if (!mounted) return;
      _showMessage('Da gui yeu cau dang ky dich vu.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Khong the dang ky: $error');
    } finally {
      if (mounted) {
        setState(() => _pendingRegistrations.remove(service.id));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({this.hinhAnh});

  final String? hinhAnh;

  @override
  Widget build(BuildContext context) {
    final borderRadius = const BorderRadius.vertical(top: Radius.circular(20));
    final colorScheme = Theme.of(context).colorScheme;

    if (hinhAnh != null && hinhAnh!.startsWith('data:image')) {
      final bytes = _decodeBase64(hinhAnh!);
      if (bytes != null) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(
            bytes,
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    final imageUrl =
        hinhAnh?.isNotEmpty == true ? hinhAnh! : MediaAssets.chungCuImage;

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          height: 170,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => SizedBox(
          height: 170,
          child: ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Icons.design_services_rounded,
                size: 54,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Uint8List? _decodeBase64(String dataUrl) {
    try {
      final base64String = dataUrl.split(',').last;
      return base64.decode(base64String);
    } catch (_) {
      return null;
    }
  }
}
