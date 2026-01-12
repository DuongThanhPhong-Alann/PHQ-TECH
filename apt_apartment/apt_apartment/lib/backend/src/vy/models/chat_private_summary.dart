import 'package:apt_apartment/backend/src/phong/models/nguoi_dung.dart';

class ChatPrivateSummary {
  const ChatPrivateSummary({
    required this.chatId,
    required this.otherUser,
    this.lastMessage,
    this.lastAt,
  });

  final int chatId;
  final NguoiDung otherUser;
  final String? lastMessage;
  final DateTime? lastAt;
}
