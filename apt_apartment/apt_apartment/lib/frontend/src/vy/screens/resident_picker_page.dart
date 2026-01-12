import 'package:flutter/material.dart';

import 'package:apt_apartment/backend/src/phong/models/nguoi_dung.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';

class ResidentPickerPage extends StatefulWidget {
  const ResidentPickerPage({
    super.key,
    required this.currentUserId,
    required this.chungCuId,
  });

  final int currentUserId;
  final int chungCuId;

  @override
  State<ResidentPickerPage> createState() => _ResidentPickerPageState();
}

class _ResidentPickerPageState extends State<ResidentPickerPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  final TextEditingController _search = TextEditingController();
  Future<List<NguoiDung>>? _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.toLowerCase().trim());
    });
    _future = _repository.fetchResidentsInBuilding(
      chungCuId: widget.chungCuId,
      excludeUserId: widget.currentUserId,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chon cu dan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              elevation: 0,
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Tim theo ten...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<NguoiDung>>(
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
                      ),
                    ),
                  );
                }
                final residents = snapshot.data ?? const <NguoiDung>[];
                final filtered = _query.isEmpty
                    ? residents
                    : residents
                        .where((u) => u.hoTen.toLowerCase().contains(_query))
                        .toList(growable: false);
                if (filtered.isEmpty) {
                  return const _EmptyResidents();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return Material(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(user),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    colorScheme.primary.withValues(alpha: 0.12),
                                child: Text(
                                  user.hoTen.isNotEmpty
                                      ? user.hoTen
                                          .trim()
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.hoTen,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
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
  }
}

class _EmptyResidents extends StatelessWidget {
  const _EmptyResidents();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.person_search, color: colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Khong tim thay cu dan',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Thu doi tu khoa khac.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
