import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apt_apartment/backend/src/hieu/models/can_ho.dart';
import 'package:apt_apartment/backend/src/hieu/models/chung_cu.dart';
import 'package:apt_apartment/backend/src/phong/models/nguoi_dung.dart';
import 'package:apt_apartment/backend/src/quang/models/dich_vu.dart';
import 'package:apt_apartment/backend/src/quang/models/hoa_don_dich_vu.dart';
import 'package:apt_apartment/backend/src/quang/models/phan_anh.dart';
import 'package:apt_apartment/backend/src/quang/models/tin_tuc.dart';
import 'package:apt_apartment/backend/src/vy/models/chat.dart';
import 'package:apt_apartment/backend/src/vy/models/chat_message.dart';
import 'package:apt_apartment/backend/src/vy/models/chat_private_summary.dart';
import 'package:apt_apartment/supabase_options.dart';

class AptConnectRepository {
  AptConnectRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _bucketAssets = 'apt-assets';
  static const String _chatBackgroundFolder = 'NEN';
  static final StreamController<void> _hoaDonUpdates =
      StreamController<void>.broadcast();

  static Stream<void> get hoaDonUpdates => _hoaDonUpdates.stream;

  Future<List<ChungCu>> fetchChungCus({int limit = 50}) async {
    try {
      final List<dynamic> data = await _client
          .from('ChungCus')
          .select(
            'ID,Ten,DiaChi,ChuDauTu,NamXayDung,SoTang,MoTa,HinhAnhChungCus(DuongDan)',
          )
          .order('CreatedAt', ascending: false)
          .limit(limit);

      return data
          .whereType<Map<String, dynamic>>()
          .map(ChungCu.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw Exception('Không thể tải danh sách chung cư: ${error.message}');
    } catch (error) {
      throw Exception('Đã có lỗi xảy ra khi tải chung cư: $error');
    }
  }

  Future<List<CanHo>> fetchCanHos({required int chungCuId}) async {
    try {
      final List<dynamic> data = await _client
          .from('CanHos')
          .select(
            'ID,ID_ChungCu,MaCan,DienTich,SoPhong,Gia,TrangThai,MoTa,URLs,HinhAnhCanHos(DuongDan),ChungCus(Ten)',
          )
          .eq('ID_ChungCu', chungCuId)
          .order('Gia');

      return data
          .whereType<Map<String, dynamic>>()
          .map(CanHo.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw Exception('Không thể tải căn hộ: ${error.message}');
    } catch (error) {
      throw Exception('Đã có lỗi xảy ra khi tải căn hộ: $error');
    }
  }

  Future<List<CanHo>> fetchFeaturedCanHos({int limit = 10}) async {
    try {
      final List<dynamic> data = await _client
          .from('CanHos')
          .select(
            'ID,ID_ChungCu,MaCan,DienTich,SoPhong,Gia,TrangThai,MoTa,URLs,HinhAnhCanHos(DuongDan),ChungCus(Ten)',
          )
          .order('CreatedAt', ascending: false)
          .limit(limit);
      return data
          .whereType<Map<String, dynamic>>()
          .map(CanHo.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw Exception('Không thể tải căn hộ nổi bật: ${error.message}');
    } catch (error) {
      throw Exception('Lỗi tải căn hộ nổi bật: $error');
    }
  }

  Future<List<CanHo>> fetchAllCanHos({int limit = 500}) async {
    try {
      final List<dynamic> data = await _client
          .from('CanHos')
          .select(
            'ID,ID_ChungCu,MaCan,DienTich,SoPhong,Gia,TrangThai,MoTa,URLs,HinhAnhCanHos(DuongDan),ChungCus(Ten)',
          )
          .order('CreatedAt', ascending: false)
          .limit(limit);
      return data
          .whereType<Map<String, dynamic>>()
          .map(CanHo.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw Exception('Không thể tải danh sách căn hộ: ${error.message}');
    } catch (error) {
      throw Exception('Đã có lỗi khi tải căn hộ: $error');
    }
  }

  Future<List<DichVu>> fetchDichVus() async {
    try {
      final List<dynamic> data = await _client
          .from('DichVus')
          .select('ID,TenDichVu,MoTa,Gia,HinhAnh')
          .order('CreatedAt', ascending: false);
      return data
          .whereType<Map<String, dynamic>>()
          .map(DichVu.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw Exception('Không thể tải dịch vụ: ${error.message}');
    } catch (error) {
      throw Exception('Đã có lỗi khi tải dịch vụ: $error');
    }
  }



  Future<void> registerDichVu({
    required int dichVuId,
    required int nguoiDungId,
    required double soTien,
    String trangThai = 'Chua thanh toan',
  }) async {
    final cuDanInfo = await _fetchCuDanResidencyInfo(nguoiDungId);
    final canHoId = (cuDanInfo?['ID_CanHo'] as int?);
    final chungCuId = (cuDanInfo?['ID_ChungCu'] as int?);

    if (canHoId == null || chungCuId == null) {
      throw Exception('Chi cu dan moi co the dang ky dich vu.');
    }

    try {
      final inserted = await _client
          .from('HoaDonDichVus')
          .insert({
            'ID_CanHo': canHoId,
            'ID_ChungCu': chungCuId,
            'SoTien': soTien,
            'NgayLap': DateTime.now().toIso8601String(),
            'TrangThai': trangThai,
          })
          .select('ID')
          .single();

      final hoaDonId = (inserted['ID'] as num).toInt();

      await _client.from('HoaDonDichVu_DichVus').insert({
        'ID_HoaDon': hoaDonId,
        'ID_DichVu': dichVuId,
      });
      _emitHoaDonUpdate();
    } on PostgrestException catch (error) {
      throw Exception('Khong the dang ky dich vu: ${error.message}');
    } catch (error) {
      throw Exception('Da co loi khi dang ky dich vu: $error');
    }
  }

  Future<List<HoaDonDichVuModel>> fetchHoaDonDichVus({
    required int nguoiDungId,
    int limit = 20,
  }) async {
    try {
      final canHoIds = await _fetchCanHoIdsByNguoiDung(nguoiDungId);
      if (canHoIds.isEmpty) {
        return const [];
      }

      final List<dynamic> data = await _client
          .from('HoaDonDichVus')
          .select(
            'ID,ID_CanHo,ID_ChungCu,SoTien,NgayLap,TrangThai,'
            'HoaDonDichVu_DichVus(DichVus(ID,TenDichVu,Gia))',
          )
          .filter('ID_CanHo', 'in', '(${canHoIds.join(',')})')
          .order('NgayLap', ascending: false)
          .limit(limit);
      return data
          .whereType<Map<String, dynamic>>()
          .map(HoaDonDichVuModel.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw Exception('Không thể tải hóa đơn dịch vụ: ${error.message}');
    } catch (error) {
      throw Exception('Đã có lỗi khi tải hóa đơn: $error');
    }
  }

  Future<List<TinTuc>> fetchTinTucs({int limit = 10}) async {
    try {
      final List<dynamic> data = await _client
          .from('TinTucs')
          .select('ID,TieuDe,NoiDung,NgayDang,HinhAnh')
          .order('NgayDang', ascending: false)
          .limit(limit);
      return data
          .whereType<Map<String, dynamic>>()
          .map(TinTuc.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw Exception('Không thể tải tin tức: ${error.message}');
    } catch (error) {
      throw Exception('Đã có lỗi khi tải tin tức: $error');
    }
  }

  Future<NguoiDung?> fetchNguoiDungByEmail(String email) async {
    try {
      final data = await _client
          .from('NguoiDungs')
          .select('ID,HoTen,Email,SoDienThoai,LoaiNguoiDung,MatKhau')
          .eq('Email', email)
          .maybeSingle();
      if (data is Map<String, dynamic>) {
        var nguoiDung = NguoiDung.fromMap(data);
        if (nguoiDung.isCuDan) {
          final info = await _fetchCuDanResidencyInfo(nguoiDung.id);
          if (info != null) {
            nguoiDung = nguoiDung.copyWith(
              tenCanHo: info['TenCanHo'],
              tenChungCu: info['TenChungCu'],
            );
          }
        }
        return nguoiDung;
      }
      return null;
    } on PostgrestException catch (error) {
      throw Exception('Khong the tai nguoi dung: ${error.message}');
    } catch (error) {
      throw Exception('Da co loi khi tai nguoi dung: $error');
    }
  }

  Future<NguoiDung?> fetchNguoiDungById(int nguoiDungId) async {
    try {
      final data = await _client
          .from('NguoiDungs')
          .select('ID,HoTen,Email,SoDienThoai,LoaiNguoiDung,MatKhau')
          .eq('ID', nguoiDungId)
          .maybeSingle();
      if (data is Map<String, dynamic>) {
        var nguoiDung = NguoiDung.fromMap(data);
        if (nguoiDung.isCuDan) {
          final info = await _fetchCuDanResidencyInfo(nguoiDung.id);
          if (info != null) {
            nguoiDung = nguoiDung.copyWith(
              tenCanHo: info['TenCanHo'],
              tenChungCu: info['TenChungCu'],
            );
          }
        }
        return nguoiDung;
      }
      return null;
    } on PostgrestException catch (error) {
      throw Exception('Khong the tai nguoi dung: ${error.message}');
    } catch (error) {
      throw Exception('Da co loi khi tai nguoi dung: $error');
    }
  }

  Future<void> upsertNguoiDung({
    required String hoTen,
    required String email,
    required String matKhauHash,
    String? soDienThoai,
    String loaiNguoiDung = 'Khach',
  }) async {
    try {
      await _client.from('NguoiDungs').upsert(
        {
          'HoTen': hoTen,
          'Email': email,
          'MatKhau': matKhauHash,
          'SoDienThoai': soDienThoai,
          'LoaiNguoiDung': loaiNguoiDung,
        },
        onConflict: 'Email',
      );
    } on PostgrestException catch (error) {
      throw Exception('Không thể cập nhật người dùng: ${error.message}');
    } catch (error) {
      throw Exception('Đã có lỗi khi ghi người dùng: $error');
    }
  }

  Future<void> updateNguoiDungMatKhau({

    required int nguoiDungId,

    required String matKhauHash,

  }) async {

    try {

      await _client

          .from('NguoiDungs')

          .update({'MatKhau': matKhauHash}).eq('ID', nguoiDungId);

    } on PostgrestException catch (error) {

      throw Exception('Khong the cap nhat mat khau: ${error.message}');

    } catch (error) {

      throw Exception('Da co loi khi cap nhat mat khau: $error');

    }

  }



  Future<CanHo?> fetchCanHoById(int canHoId) async {
    try {
      final data = await _client
          .from('CanHos')
          .select(
            'ID,ID_ChungCu,MaCan,DienTich,SoPhong,Gia,TrangThai,MoTa,URLs,HinhAnhCanHos(DuongDan),ChungCus(Ten)',
          )
          .eq('ID', canHoId)
          .maybeSingle();
      if (data is Map<String, dynamic>) {
        return CanHo.fromMap(data);
      }
      return null;
    } on PostgrestException catch (error) {
      throw Exception('Khong the tai chi tiet can ho: ${error.message}');
    } catch (error) {
      throw Exception('Da co loi khi tai chi tiet can ho: $error');
    }
  }

  Future<List<PhanAnh>> fetchPhanAnhs({
    required int nguoiDungId,
    int limit = 50,
  }) async {
    try {
      final List<dynamic> data = await _client
          .from('PhanAnhs')
          .select('ID,ID_NguoiDung,NoiDung,TrangThai,NgayGui,PhanHoi,HinhAnh')
          .eq('ID_NguoiDung', nguoiDungId)
          .order('NgayGui', ascending: false)
          .limit(limit);
      return data
          .whereType<Map<String, dynamic>>()
          .map(PhanAnh.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw Exception('Khong the tai phan anh: ${error.message}');
    } catch (error) {
      throw Exception('Da co loi khi tai phan anh: $error');
    }
  }

  Future<Map<String, dynamic>?> _fetchCuDanResidencyInfo(int nguoiDungId) async {
    final record = await _client
        .from('CuDans')
        .select('ID_CanHo,ID_ChungCu,CanHos(MaCan),ChungCus(Ten)')
        .eq('ID_NguoiDung', nguoiDungId)
        .maybeSingle();
    if (record is! Map<String, dynamic>) {
      return null;
    }
    final canHoId = (record['ID_CanHo'] as num?)?.toInt();
    final chungCuId = (record['ID_ChungCu'] as num?)?.toInt();
    final canHo = record['CanHos'] as Map<String, dynamic>?;
    final chungCu = record['ChungCus'] as Map<String, dynamic>?;
    if (canHoId == null && chungCuId == null && canHo == null && chungCu == null) {
      return null;
    }
    return {
      'ID_CanHo': canHoId,
      'ID_ChungCu': chungCuId,
      'TenCanHo': canHo?['MaCan']?.toString(),
      'TenChungCu': chungCu?['Ten']?.toString(),
    };
  }

  static void _emitHoaDonUpdate() {
    if (!_hoaDonUpdates.isClosed) {
      _hoaDonUpdates.add(null);
    }
  }

  Future<List<int>> _fetchCanHoIdsByNguoiDung(int nguoiDungId) async {
    final List<dynamic> data = await _client
        .from('CuDans')
        .select('ID_CanHo')
        .eq('ID_NguoiDung', nguoiDungId);
    return data
        .whereType<Map<String, dynamic>>()
        .map((row) => (row['ID_CanHo'] as num?)?.toInt())
        .whereType<int>()
        .toList(growable: false);
  }

  Future<void> createPhanAnh({
    required int nguoiDungId,
    required String noiDung,
    String? hinhAnh,
  }) async {
    try {
      await _client.from('PhanAnhs').insert({
        'ID_NguoiDung': nguoiDungId,
        'NoiDung': noiDung,
        'TrangThai': 'Dang xu ly',
        'NgayGui': DateTime.now().toIso8601String(),
        'HinhAnh': hinhAnh,
      });
    } on PostgrestException catch (error) {
      throw Exception('Khong the gui phan anh: ${error.message}');
    } catch (error) {
      throw Exception('Da co loi khi gui phan anh: $error');
    }
  }

  Future<String> uploadComplaintImage({
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final storage = _client.storage.from(_bucketAssets);
    final path = 'complaints/$fileName';
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        cacheControl: '3600',
        upsert: true,
        contentType: contentType ?? 'image/jpeg',
      ),
    );
    return '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$path';
  }

  Future<Map<String, dynamic>?> fetchCuDanResidencyInfo(int nguoiDungId) {
    return _fetchCuDanResidencyInfo(nguoiDungId);
  }

  Future<List<String>> fetchChatBackgroundUrls() async {
    final hardcoded = <String>[
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/generated_video%20(1)%20(1).mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/generated_video%20(1).mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/generated_video%20(2)%20(1).mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/generated_video%20(2).mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/generated_video%20(3).mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/generated_video%20(4).mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/generated_video.mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/view.mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/view1.mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/view2.mp4',
      '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$_chatBackgroundFolder/view3.mp4',
    ];

    try {
      final files = await _client.storage.from(_bucketAssets).list(
            path: _chatBackgroundFolder,
          );
      final urls = files
          .map((file) => (file as dynamic).name?.toString() ?? '')
          .where((name) => name.isNotEmpty && name.toLowerCase().endsWith('.mp4'))
          .map((name) {
            final objectPath = '$_chatBackgroundFolder/$name';
            final encoded = Uri.encodeFull(objectPath);
            return '${SupabaseOptions.url}/storage/v1/object/public/$_bucketAssets/$encoded';
          })
          .toSet()
          .toList(growable: false)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return urls.isEmpty ? hardcoded : urls;
    } catch (_) {
      return hardcoded;
    }
  }

  Future<void> ensureChatMember({
    required int chatId,
    required int nguoiDungId,
  }) async {
    await _client.from('ChatMembers').upsert(
      {'ID_Chat': chatId, 'ID_NguoiDung': nguoiDungId},
      onConflict: 'ID_Chat,ID_NguoiDung',
    );
  }

  Future<Chat> getOrCreateBuildingChat({
    required int chungCuId,
    required int nguoiDungId,
  }) async {
    try {
      final existing = await _client
          .from('Chats')
          .select('ID,Loai,ID_ChungCu,PrivateKey,CreatedAt')
          .eq('Loai', 'building')
          .eq('ID_ChungCu', chungCuId)
          .maybeSingle();

      final chatMap = existing is Map<String, dynamic>
          ? existing
          : await _client
              .from('Chats')
              .insert({'Loai': 'building', 'ID_ChungCu': chungCuId})
              .select('ID,Loai,ID_ChungCu,PrivateKey,CreatedAt')
              .single();

      final chat = Chat.fromMap(chatMap);
      await ensureChatMember(chatId: chat.id, nguoiDungId: nguoiDungId);
      return chat;
    } on PostgrestException catch (error) {
      throw Exception('Khong the tao/tai chat chung cu: ${error.message}');
    } catch (error) {
      throw Exception('Da co loi khi tao/tai chat chung cu: $error');
    }
  }

  Future<Chat> getOrCreatePrivateChat({
    required int nguoiDungId,
    required int otherUserId,
  }) async {
    final a = nguoiDungId < otherUserId ? nguoiDungId : otherUserId;
    final b = nguoiDungId < otherUserId ? otherUserId : nguoiDungId;
    final privateKey = '${a}_$b';

    try {
      final existing = await _client
          .from('Chats')
          .select('ID,Loai,ID_ChungCu,PrivateKey,CreatedAt')
          .eq('Loai', 'private')
          .eq('PrivateKey', privateKey)
          .maybeSingle();

      final chatMap = existing is Map<String, dynamic>
          ? existing
          : await _client
              .from('Chats')
              .insert({'Loai': 'private', 'PrivateKey': privateKey})
              .select('ID,Loai,ID_ChungCu,PrivateKey,CreatedAt')
              .single();

      final chat = Chat.fromMap(chatMap);
      await ensureChatMember(chatId: chat.id, nguoiDungId: nguoiDungId);
      await ensureChatMember(chatId: chat.id, nguoiDungId: otherUserId);
      return chat;
    } on PostgrestException catch (error) {
      throw Exception('Khong the tao/tai chat rieng: ${error.message}');
    } catch (error) {
      throw Exception('Da co loi khi tao/tai chat rieng: $error');
    }
  }

  Future<Map<int, NguoiDung>> fetchChatMembers(int chatId) async {
    final List<dynamic> rows = await _client
        .from('ChatMembers')
        .select(
          'ID_NguoiDung,'
          'NguoiDungs(ID,HoTen,Email,SoDienThoai,LoaiNguoiDung)',
        )
        .eq('ID_Chat', chatId);

    final members = <int, NguoiDung>{};
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final userMap = row['NguoiDungs'];
      if (userMap is Map<String, dynamic>) {
        final user = NguoiDung.fromMap(userMap);
        members[user.id] = user;
      }
    }
    return members;
  }

  Stream<List<ChatMessage>> watchChatMessages({
    required int chatId,
    int limit = 200,
  }) {
    return _client
        .from('ChatMessages')
        .stream(primaryKey: ['ID'])
        .eq('ID_Chat', chatId)
        .order('CreatedAt', ascending: false)
        .limit(limit)
        .map((rows) => rows
            .whereType<Map<String, dynamic>>()
            .map(ChatMessage.fromMap)
            .toList(growable: false));
  }

  Future<List<ChatMessage>> fetchChatMessages({
    required int chatId,
    int limit = 200,
  }) async {
    final List<dynamic> rows = await _client
        .from('ChatMessages')
        .select('ID,ID_Chat,ID_NguoiGui,NoiDung,CreatedAt')
        .eq('ID_Chat', chatId)
        .order('CreatedAt', ascending: false)
        .limit(limit);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromMap)
        .toList(growable: false);
  }

  Future<void> sendChatMessage({
    required int chatId,
    required int senderId,
    required String noiDung,
  }) async {
    final content = noiDung.trim();
    if (content.isEmpty) return;

    try {
      await _client.from('ChatMessages').insert({
        'ID_Chat': chatId,
        'ID_NguoiGui': senderId,
        'NoiDung': content,
        'CreatedAt': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (error) {
      throw Exception('Khong the gui tin nhan: ${error.message}');
    } catch (error) {
      throw Exception('Da co loi khi gui tin nhan: $error');
    }
  }

  Future<List<NguoiDung>> fetchResidentsInBuilding({
    required int chungCuId,
    int? excludeUserId,
  }) async {
    final List<dynamic> rows = await _client
        .from('CuDans')
        .select(
          'ID_NguoiDung,'
          'NguoiDungs(ID,HoTen,Email,SoDienThoai,LoaiNguoiDung)',
        )
        .eq('ID_ChungCu', chungCuId);

    final users = <NguoiDung>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final userMap = row['NguoiDungs'];
      if (userMap is! Map<String, dynamic>) continue;
      final user = NguoiDung.fromMap(userMap);
      if (excludeUserId != null && user.id == excludeUserId) continue;
      users.add(user);
    }
    users.sort((a, b) => a.hoTen.toLowerCase().compareTo(b.hoTen.toLowerCase()));
    return users;
  }

  Future<List<ChatPrivateSummary>> fetchPrivateChatsForUser({
    required int nguoiDungId,
  }) async {
    final List<dynamic> memberships = await _client
        .from('ChatMembers')
        .select('ID_Chat,Chats(ID,Loai,CreatedAt)')
        .eq('ID_NguoiDung', nguoiDungId);

    final chatIds = memberships
        .whereType<Map<String, dynamic>>()
        .map((row) => row['Chats'])
        .whereType<Map<String, dynamic>>()
        .where((chat) => chat['Loai']?.toString() == 'private')
        .map((chat) => (chat['ID'] as num).toInt())
        .toList(growable: false);

    final summaries = <ChatPrivateSummary>[];
    for (final chatId in chatIds) {
      final otherMember = await _client
          .from('ChatMembers')
          .select(
            'ID_NguoiDung,'
            'NguoiDungs(ID,HoTen,Email,SoDienThoai,LoaiNguoiDung)',
          )
          .eq('ID_Chat', chatId)
          .neq('ID_NguoiDung', nguoiDungId)
          .maybeSingle();

      if (otherMember is! Map<String, dynamic>) continue;
      final otherUserMap = otherMember['NguoiDungs'];
      if (otherUserMap is! Map<String, dynamic>) continue;
      final otherUser = NguoiDung.fromMap(otherUserMap);

      final lastMsg = await _client
          .from('ChatMessages')
          .select('NoiDung,CreatedAt')
          .eq('ID_Chat', chatId)
          .order('CreatedAt', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastMessage = lastMsg is Map<String, dynamic>
          ? lastMsg['NoiDung']?.toString()
          : null;
      final lastAtRaw = lastMsg is Map<String, dynamic>
          ? lastMsg['CreatedAt']?.toString()
          : null;
      final lastAt = lastAtRaw != null ? DateTime.tryParse(lastAtRaw) : null;

      summaries.add(
        ChatPrivateSummary(
          chatId: chatId,
          otherUser: otherUser,
          lastMessage: lastMessage,
          lastAt: lastAt,
        ),
      );
    }

    summaries.sort((a, b) {
      final atA = a.lastAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final atB = b.lastAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return atB.compareTo(atA);
    });
    return summaries;
  }
}
