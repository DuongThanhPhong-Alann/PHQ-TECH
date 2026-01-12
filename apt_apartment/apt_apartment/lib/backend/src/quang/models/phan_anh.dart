class PhanAnh {
  const PhanAnh({
    required this.id,
    required this.idNguoiDung,
    required this.noiDung,
    required this.trangThai,
    required this.ngayGui,
    this.phanHoi,
    this.hinhAnh,
  });

  final int id;
  final int idNguoiDung;
  final String noiDung;
  final String trangThai;
  final DateTime ngayGui;
  final String? phanHoi;
  final String? hinhAnh;

  factory PhanAnh.fromMap(Map<String, dynamic> data) {
    return PhanAnh(
      id: data['ID'] as int,
      idNguoiDung: data['ID_NguoiDung'] as int,
      noiDung: data['NoiDung']?.toString() ?? '',
      trangThai: data['TrangThai']?.toString() ?? 'Chua xu ly',
      ngayGui: DateTime.parse(data['NgayGui'] as String),
      phanHoi: data['PhanHoi']?.toString(),
      hinhAnh: data['HinhAnh']?.toString(),
    );
  }
}
