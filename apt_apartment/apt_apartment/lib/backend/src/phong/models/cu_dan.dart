class CuDan {
  const CuDan({
    required this.id,
    required this.idNguoiDung,
    required this.idCanHo,
    required this.idChungCu,
    required this.laChuHo,
  });

  final int id;
  final int idNguoiDung;
  final int idCanHo;
  final int idChungCu;
  final bool laChuHo;

  factory CuDan.fromMap(Map<String, dynamic> data) {
    return CuDan(
      id: data['ID'] as int,
      idNguoiDung: data['ID_NguoiDung'] as int,
      idCanHo: data['ID_CanHo'] as int,
      idChungCu: data['ID_ChungCu'] as int,
      laChuHo: data['LaChuHo'] as bool? ?? false,
    );
  }
}
