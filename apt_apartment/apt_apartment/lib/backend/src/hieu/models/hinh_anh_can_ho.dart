class HinhAnhCanHo {
  const HinhAnhCanHo({
    required this.id,
    required this.idCanHo,
    required this.duongDan,
  });

  final int id;
  final int idCanHo;
  final String duongDan;

  factory HinhAnhCanHo.fromMap(Map<String, dynamic> data) {
    return HinhAnhCanHo(
      id: data['ID'] as int,
      idCanHo: data['ID_CanHo'] as int,
      duongDan: data['DuongDan']?.toString() ?? '',
    );
  }
}
