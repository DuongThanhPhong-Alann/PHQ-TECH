class DichVu {
  const DichVu({
    required this.id,
    required this.ten,
    required this.moTa,
    required this.gia,
    this.hinhAnh,
  });

  final int id;
  final String ten;
  final String moTa;
  final double gia;
  final String? hinhAnh;

  factory DichVu.fromMap(Map<String, dynamic> data) {
    return DichVu(
      id: data['ID'] as int,
      ten: data['TenDichVu']?.toString() ?? '',
      moTa: data['MoTa']?.toString() ?? '',
      gia: (data['Gia'] as num?)?.toDouble() ?? 0,
      hinhAnh: data['HinhAnh']?.toString(),
    );
  }
}
