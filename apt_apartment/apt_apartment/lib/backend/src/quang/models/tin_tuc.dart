class TinTuc {
  const TinTuc({
    required this.id,
    required this.tieuDe,
    required this.noiDung,
    required this.ngayDang,
    this.hinhAnh,
  });

  final int id;
  final String tieuDe;
  final String noiDung;
  final DateTime ngayDang;
  final String? hinhAnh;

  factory TinTuc.fromMap(Map<String, dynamic> data) {
    return TinTuc(
      id: data['ID'] as int,
      tieuDe: data['TieuDe']?.toString() ?? '',
      noiDung: data['NoiDung']?.toString() ?? '',
      ngayDang: DateTime.parse(data['NgayDang'] as String),
      hinhAnh: data['HinhAnh']?.toString(),
    );
  }
}
