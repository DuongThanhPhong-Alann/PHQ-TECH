enum ChatLoai { building, private }

class Chat {
  const Chat({
    required this.id,
    required this.loai,
    required this.createdAt,
    this.idChungCu,
    this.privateKey,
  });

  final int id;
  final ChatLoai loai;
  final int? idChungCu;
  final String? privateKey;
  final DateTime createdAt;

  factory Chat.fromMap(Map<String, dynamic> data) {
    final loaiRaw = data['Loai']?.toString() ?? 'private';
    return Chat(
      id: (data['ID'] as num).toInt(),
      loai: loaiRaw == 'building' ? ChatLoai.building : ChatLoai.private,
      idChungCu: (data['ID_ChungCu'] as num?)?.toInt(),
      privateKey: data['PrivateKey']?.toString(),
      createdAt: DateTime.tryParse(data['CreatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

