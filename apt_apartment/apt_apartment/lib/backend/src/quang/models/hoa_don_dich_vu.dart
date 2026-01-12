class HoaDonDichVuModel {
  const HoaDonDichVuModel({
    required this.id,
    required this.canHoId,
    required this.chungCuId,
    required this.soTien,
    required this.ngayLap,
    required this.trangThai,
    required this.dichVus,
  });

  final int id;
  final int canHoId;
  final int chungCuId;
  final double soTien;
  final DateTime ngayLap;
  final String trangThai;
  final List<DichVuHoaDon> dichVus;

  factory HoaDonDichVuModel.fromMap(Map<String, dynamic> data) {
    final list = <DichVuHoaDon>[];
    final dynamic nested = data['HoaDonDichVu_DichVus'];
    if (nested is List) {
      for (final dynamic entry in nested) {
        if (entry is Map<String, dynamic>) {
          final dichVu = entry['DichVus'];
          if (dichVu is Map<String, dynamic>) {
            list.add(DichVuHoaDon.fromMap(dichVu));
          }
        }
      }
    }

    return HoaDonDichVuModel(
      id: data['ID'] as int,
      canHoId: data['ID_CanHo'] as int,
      chungCuId: data['ID_ChungCu'] as int,
      soTien: (data['SoTien'] as num).toDouble(),
      ngayLap: DateTime.parse(data['NgayLap'] as String),
      trangThai: data['TrangThai']?.toString() ?? 'Chua thanh toan',
      dichVus: list,
    );
  }
}

class DichVuHoaDon {
  const DichVuHoaDon({required this.id, required this.ten, required this.gia});

  final int id;
  final String ten;
  final double gia;

  factory DichVuHoaDon.fromMap(Map<String, dynamic> data) {
    return DichVuHoaDon(
      id: data['ID'] as int,
      ten: data['TenDichVu']?.toString() ?? '',
      gia: (data['Gia'] as num?)?.toDouble() ?? 0,
    );
  }
}
