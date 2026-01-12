# APT-CONNECT Mobile (Flutter)

Mobile app của dự án APT-CONNECT (tra cứu chung cư/căn hộ, dịch vụ, hóa đơn, phản ánh, chat) được xây bằng Flutter và sử dụng Supabase làm backend.

## Thư mục
- Source Flutter: `apt_apartment/apt_apartment`
- Schema Supabase: `apt_apartment/sql`

## Yêu cầu
- Flutter SDK
- Android Studio (hoặc Xcode nếu chạy iOS)
- 01 project Supabase (URL + anon key)

## Thiết lập Supabase
1. Tạo project trên Supabase
2. Mở SQL Editor và chạy file: `apt_apartment/sql`
3. (Tuỳ chọn) Tạo bucket Storage tên `apt-assets` để upload/đọc ảnh

## Cấu hình app
Sửa file `apt_apartment/apt_apartment/lib/supabase_options.dart` để trỏ tới Supabase của bạn (URL + anon key).

## Chạy ứng dụng
```bash
cd apt_apartment/apt_apartment
flutter pub get
flutter run
```

## Tài liệu tổng quan
Xem `README.md` ở root repo để biết kiến trúc tổng thể (Web + Mobile) và hướng dẫn chạy Web.
