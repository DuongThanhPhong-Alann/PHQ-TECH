class HinhAnhChungCu {
  const HinhAnhChungCu({
    required this.id,
    required this.idChungCu,
    required this.duongDan,
  });

  final int id;
  final int idChungCu;
  final String duongDan;

  factory HinhAnhChungCu.fromMap(Map<String, dynamic> data) {
    return HinhAnhChungCu(
      id: data['ID'] as int,
      idChungCu: data['ID_ChungCu'] as int,
      duongDan: data['DuongDan']?.toString() ?? '',
    );
  }
}
