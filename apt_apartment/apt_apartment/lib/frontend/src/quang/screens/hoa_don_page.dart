import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:apt_apartment/backend/src/quang/models/hoa_don_dich_vu.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/frontend/src/quang/widgets/app_states.dart';

class HoaDonPage extends StatefulWidget {
  const HoaDonPage({super.key, required this.userId});

  final int? userId;

  @override
  State<HoaDonPage> createState() => _HoaDonPageState();
}

class _HoaDonPageState extends State<HoaDonPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  Future<List<HoaDonDichVuModel>>? _future;
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
  StreamSubscription<void>? _hoaDonSubscription;

  @override
  void initState() {
    super.initState();
    final userId = widget.userId;
    if (userId != null) {
      _future = _repository.fetchHoaDonDichVus(nguoiDungId: userId);
      _hoaDonSubscription =
          AptConnectRepository.hoaDonUpdates.listen((_) => _refresh());
    }
  }

  @override
  void dispose() {
    _hoaDonSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (widget.userId == null) return;
    final result =
        await _repository.fetchHoaDonDichVus(nguoiDungId: widget.userId!);
    if (!mounted) return;
    setState(() => _future = Future.value(result));
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    if (userId == null) {
      return const AppEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'Chưa đăng nhập',
        subtitle: 'Vui lòng đăng nhập để xem hóa đơn.',
      );
    }

    return FutureBuilder<List<HoaDonDichVuModel>>(
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
        final bills = snapshot.data ?? const [];
        if (bills.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                SizedBox(height: 80),
                AppEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Chưa có hóa đơn',
                  subtitle: 'Khi có hóa đơn dịch vụ, chúng sẽ hiển thị ở đây.',
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bill = bills[index];
              return _BillCard(
                bill: bill,
                currency: _currency,
              );
            },
          ),
        );
      },
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.bill,
    required this.currency,
  });

  final HoaDonDichVuModel bill;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Căn hộ #${bill.canHoId}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusChip(status: bill.trangThai),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Ngày lập: ${DateFormat('dd/MM/yyyy').format(bill.ngayLap)}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.payments_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tổng tiền: ${currency.format(bill.soTien)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (bill.dichVus.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Dịch vụ bao gồm',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bill.dichVus
                    .map(
                      (dv) => Chip(
                        avatar: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text('${dv.ten} (${currency.format(dv.gia)})'),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
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
      'Da thanh toan' || 'Đã thanh toán' =>
        (scheme.primary.withValues(alpha: 0.16), scheme.primary),
      _ => (scheme.tertiary.withValues(alpha: 0.16), scheme.tertiary),
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
