import 'dart:convert';

/// Data model that represents a single apartment (CanHo) row.
class CanHo {
  final int id;
  final int? chungCuId;
  final String maCan;
  final double? dienTich;
  final int? soPhong;
  final double? gia;
  final String trangThai;
  final String? moTa;
  final String? tenChungCu;
  final List<String> model3DUrls;
  final List<String> mediaUrls;

  const CanHo({
    required this.id,
    this.chungCuId,
    required this.maCan,
    required this.trangThai,
    this.dienTich,
    this.soPhong,
    this.gia,
    this.moTa,
    this.tenChungCu,
    this.model3DUrls = const [],
    this.mediaUrls = const [],
  });

  factory CanHo.fromMap(Map<String, dynamic> data) {
    final rawUrls = data['URLs'];
    final media = <String>[];
    final model3d = <String>[];

    void collect(dynamic value) {
      final url = value?.toString();
      if (url == null || url.isEmpty) return;
      if (_looksLikeImage(url)) {
        media.add(url);
        return;
      }
      final normalized = _normalizeLink(url);
      if (!model3d.contains(normalized)) {
        model3d.add(normalized);
      }
    }

    if (rawUrls is List) {
      for (final dynamic entry in rawUrls) {
        collect(entry);
      }
    } else if (rawUrls is String && rawUrls.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawUrls);
        if (decoded is List) {
          for (final dynamic entry in decoded) {
            collect(entry);
          }
        } else {
          collect(rawUrls);
        }
      } catch (_) {
        collect(rawUrls);
      }
    }

    final dynamic relationImages = data['HinhAnhCanHos'];
    collect(data['Model3DUrl']);
    if (relationImages is List) {
      for (final dynamic image in relationImages) {
        final url = image is Map<String, dynamic>
            ? image['DuongDan']?.toString()
            : null;
        collect(url);
      }
    }

    String? tenChungCu;
    final nestedChungCu = data['ChungCus'];
    if (nestedChungCu is Map<String, dynamic>) {
      tenChungCu = nestedChungCu['Ten']?.toString();
    }
    tenChungCu ??= data['TenChungCu']?.toString();

    return CanHo(
      id: data['ID'] as int,
      chungCuId: (data['ID_ChungCu'] as num?)?.toInt(),
      maCan: data['MaCan'] as String,
      trangThai: data['TrangThai']?.toString() ?? 'Dang ban',
      dienTich: (data['DienTich'] as num?)?.toDouble(),
      soPhong: (data['SoPhong'] as num?)?.toInt(),
      gia: (data['Gia'] as num?)?.toDouble(),
      moTa: data['MoTa']?.toString(),
      tenChungCu: tenChungCu,
      model3DUrls:
          model3d.isEmpty ? const [] : List.unmodifiable(model3d),
      mediaUrls: media.isEmpty ? const [] : List.unmodifiable(media),
    );
  }

  static String _normalizeLink(String url) {
    return url.trim();
  }

  static bool _looksLikeImage(String url) {
    final lower = url.toLowerCase();
    if (lower.startsWith('data:image')) return true;
    final base = lower.split('?').first;
    return base.endsWith('.jpg') ||
        base.endsWith('.jpeg') ||
        base.endsWith('.png') ||
        base.endsWith('.webp') ||
        base.endsWith('.gif');
  }
}
