class NguoiDung {
  const NguoiDung({
    required this.id,
    required this.hoTen,
    required this.email,
    required this.loaiNguoiDung,
    this.soDienThoai,
    this.matKhauHash,
    this.tenCanHo,
    this.tenChungCu,
  });

  final int id;
  final String hoTen;
  final String email;
  final String loaiNguoiDung;
  final String? soDienThoai;
  final String? matKhauHash;
  final String? tenCanHo;
  final String? tenChungCu;

  factory NguoiDung.fromMap(Map<String, dynamic> data) {
    return NguoiDung(
      id: data['ID'] as int,
      hoTen: data['HoTen']?.toString() ?? '',
      email: data['Email']?.toString() ?? '',
      loaiNguoiDung: data['LoaiNguoiDung']?.toString() ?? 'Khach',
      soDienThoai: data['SoDienThoai']?.toString(),
      matKhauHash: data['MatKhau']?.toString(),
      tenCanHo: data['TenCanHo']?.toString(),
      tenChungCu: data['TenChungCu']?.toString(),
    );
  }

  NguoiDung copyWith({
    String? hoTen,
    String? email,
    String? loaiNguoiDung,
    String? soDienThoai,
    String? matKhauHash,
    String? tenCanHo,
    String? tenChungCu,
  }) {
    return NguoiDung(
      id: id,
      hoTen: hoTen ?? this.hoTen,
      email: email ?? this.email,
      loaiNguoiDung: loaiNguoiDung ?? this.loaiNguoiDung,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      matKhauHash: matKhauHash ?? this.matKhauHash,
      tenCanHo: tenCanHo ?? this.tenCanHo,
      tenChungCu: tenChungCu ?? this.tenChungCu,
    );
  }

  bool get isCuDan {
    final normalized = loaiNguoiDung.toLowerCase().replaceAll(' ', '');
    return normalized == 'cudan';
  }
}
