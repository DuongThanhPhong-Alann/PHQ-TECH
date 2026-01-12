class HinhAnhDichVu {
  const HinhAnhDichVu({
    required this.id,
    required this.idDichVu,
    required this.duongDan,
  });

  final int id;
  final int idDichVu;
  final String duongDan;

  factory HinhAnhDichVu.fromMap(Map<String, dynamic> data) {
    return HinhAnhDichVu(
      id: data['ID'] as int,
      idDichVu: data['ID_DichVu'] as int,
      duongDan: data['DuongDan']?.toString() ?? '',
    );
  }
}
