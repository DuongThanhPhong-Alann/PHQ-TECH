import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:apt_apartment/backend/src/quang/models/phan_anh.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/frontend/src/quang/widgets/app_states.dart';

class PhanAnhPage extends StatefulWidget {
  const PhanAnhPage({super.key, required this.userId});

  final int? userId;

  @override
  State<PhanAnhPage> createState() => _PhanAnhPageState();
}

class _PhanAnhPageState extends State<PhanAnhPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  Future<List<PhanAnh>>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _future = _repository.fetchPhanAnhs(nguoiDungId: widget.userId!);
    }
  }

  Future<void> _refresh() async {
    if (widget.userId == null) return;
    final data = await _repository.fetchPhanAnhs(nguoiDungId: widget.userId!);
    if (!mounted) return;
    setState(() => _future = Future.value(data));
  }

  Future<void> _openCreateDialog() async {
    if (widget.userId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Uint8List? pickedBytes;
    String? pickedName;
    String? pickedMime;

    final success = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Gửi phản ánh'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controller,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập nội dung';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  withData: true,
                                );
                                if (result != null &&
                                    result.files.single.bytes != null) {
                                  final file = result.files.single;
                                  setStateDialog(() {
                                    pickedBytes = file.bytes;
                                    pickedName = file.name;
                                    final ext = file.extension?.toLowerCase();
                                    pickedMime = ext != null
                                        ? 'image/$ext'
                                        : 'image/jpeg';
                                  });
                                }
                              },
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          pickedName ?? 'Đính kèm hình ảnh (tùy chọn)',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setStateDialog(() => isSubmitting = true);
                          try {
                            String? imageUrl;
                            if (pickedBytes != null) {
                              final fileName =
                                  '${DateTime.now().millisecondsSinceEpoch}_${pickedName ?? 'complaint.jpg'}';
                              imageUrl = await _repository.uploadComplaintImage(
                                fileName: fileName,
                                bytes: pickedBytes!,
                                contentType: pickedMime,
                              );
                            }
                            await _repository.createPhanAnh(
                              nguoiDungId: widget.userId!,
                              noiDung: controller.text.trim(),
                              hinhAnh: imageUrl,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop(true);
                          } catch (error) {
                            setStateDialog(() => isSubmitting = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Gửi phản ánh thất bại: $error'),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (success == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã gửi phản ánh thành công.')),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    if (userId == null) {
      return const AppEmptyState(
        icon: Icons.report_outlined,
        title: 'Chưa đăng nhập',
        subtitle: 'Vui lòng đăng nhập để gửi và theo dõi phản ánh.',
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Gửi phản ánh'),
      ),
      body: FutureBuilder<List<PhanAnh>>(
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
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    icon: Icons.report_outlined,
                    title: 'Chưa có phản ánh',
                    subtitle: 'Nhấn "Gửi phản ánh" để tạo phản ánh mới.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ComplaintCard(item: items[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.item});

  final PhanAnh item;

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
                    'Mã phản ánh #${item.id}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusChip(status: item.trangThai),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(DateFormat('dd/MM/yyyy').format(item.ngayGui)),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.noiDung),
            if (item.phanHoi != null && item.phanHoi!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Phản hồi',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.phanHoi!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.80),
                ),
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
      'Da xu ly' || 'Đã xử lý' =>
        (scheme.primary.withValues(alpha: 0.16), scheme.primary),
      'Dang xu ly' || 'Đang xử lý' =>
        (scheme.tertiary.withValues(alpha: 0.16), scheme.tertiary),
      _ => (scheme.error.withValues(alpha: 0.12), scheme.error),
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
