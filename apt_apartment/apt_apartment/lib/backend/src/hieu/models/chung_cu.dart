/// Represents a row from the `ChungCus` table together with its images.
class ChungCu {
  final int id;
  final String ten;
  final String diaChi;
  final String? chuDauTu;
  final int? namXayDung;
  final int? soTang;
  final String? moTa;
  final List<String> hinhAnhs;

  const ChungCu({
    required this.id,
    required this.ten,
    required this.diaChi,
    this.chuDauTu,
    this.namXayDung,
    this.soTang,
    this.moTa,
    this.hinhAnhs = const [],
  });

  factory ChungCu.fromMap(Map<String, dynamic> data) {
    final images = <String>[];
    final dynamic nestedImages = data['HinhAnhChungCus'];
    if (nestedImages is List) {
      for (final dynamic img in nestedImages) {
        final url = img is Map<String, dynamic> ? img['DuongDan'] : null;
        if (url is String && url.isNotEmpty) {
          images.add(url);
        }
      }
    }

    return ChungCu(
      id: data['ID'] as int,
      ten: data['Ten']?.toString() ?? '',
      diaChi: data['DiaChi']?.toString() ?? '',
      chuDauTu: data['ChuDauTu']?.toString(),
      namXayDung: (data['NamXayDung'] as num?)?.toInt(),
      soTang: (data['SoTang'] as num?)?.toInt(),
      moTa: data['MoTa']?.toString(),
      hinhAnhs: images,
    );
  }
}
