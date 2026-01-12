class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.noiDung,
    required this.createdAt,
  });

  final int id;
  final int chatId;
  final int senderId;
  final String noiDung;
  final DateTime createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: (data['ID'] as num).toInt(),
      chatId: (data['ID_Chat'] as num).toInt(),
      senderId: (data['ID_NguoiGui'] as num).toInt(),
      noiDung: data['NoiDung']?.toString() ?? '',
      createdAt: DateTime.tryParse(data['CreatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

