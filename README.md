# APT-CONNECT: Hệ Thống Quản Lý và Trải Nghiệm Chung Cư

**Giảng viên hướng dẫn:** Trần Đăng Khoa  
**Ngành:** Công Nghệ Thông Tin — **Chuyên ngành:** Công Nghệ Phần Mềm

**Sinh viên/nhóm thực hiện**
- Dương Thanh Phong — 2280602345 — 22DTHD4
- Lê Minh Hiếu — 2280600947 — 22DTHD4
- Trương Vệ Quang — 2280602568 — 22DTHD4

## 1) Giới thiệu
APT-CONNECT là giải pháp hỗ trợ **quản lý chung cư** và **tương tác cư dân** theo hướng số hóa, minh bạch, dễ theo dõi.

Repo hiện có 2 phần chính:
- **Web quản trị/tra cứu (ASP.NET Core MVC)**: phục vụ vận hành, quản trị dữ liệu, xử lý nghiệp vụ quản lý chung cư.
- **Mobile (Flutter)**: tập trung trải nghiệm người dùng trên điện thoại (tra cứu, dịch vụ, hóa đơn, phản ánh, chat), sử dụng Supabase làm backend (PostgreSQL + Storage + Realtime).

## 2) Bối cảnh & mục tiêu
Xuất phát từ nhu cầu thực tế về nền tảng quản lý chung cư hiệu quả, APT-CONNECT hướng tới:
- Tăng hiệu quả giao tiếp giữa ban quản lý và cư dân
- Quản lý thông tin chung cư/căn hộ/dịch vụ tập trung
- Theo dõi dịch vụ, hóa đơn, phản ánh minh bạch theo trạng thái
- Cải thiện trải nghiệm người dùng với các tính năng hiện đại: 3D, chatbot, thông báo/email, chat nội khu

## 3) Kiến trúc kỹ thuật (tổng quan)
### 3.1 Web (ASP.NET Core MVC)
- Nền tảng: ASP.NET Core MVC (`.NET 9`)
- ORM: Entity Framework Core
- Database: SQL Server (script khởi tạo: `APT/QLCC.sql`)
- Xác thực: Cookie Authentication
- Tích hợp:
  - **Email SMTP** (gửi thông báo/xác nhận/khôi phục)
  - **Chatbot** qua Google Dialogflow (API `api/ChatBot`)

### 3.2 Mobile (Flutter)
- Nền tảng: Flutter (Dart SDK theo `apt_apartment/apt_apartment/pubspec.yaml`)
- Backend-as-a-Service: **Supabase** (PostgreSQL + Storage + stream/realtime)
- Một số package chính: `supabase_flutter`, `shared_preferences`, `file_picker`, `webview_flutter`, `cached_network_image`, `intl`...
- 3D: mở URL mô hình 3D bằng WebView

## 4) Phân quyền người dùng (nghiệp vụ)
### A. Khách hàng (truy cập cơ bản)
- Tra cứu thông tin chung cư
- Xem danh sách/chi tiết căn hộ
- Xem dịch vụ
- Đọc tin tức/sự kiện

### B. Cư dân (quyền nâng cao)
- Toàn bộ chức năng của khách hàng
- Đăng ký dịch vụ
- Theo dõi hóa đơn
- Gửi phản ánh (có thể kèm hình ảnh)
- Cập nhật thông tin cá nhân
- Tham gia chat (chat chung chung cư và chat riêng cư dân)

### C. Quản trị viên / Ban quản lý (admin)
- Quản lý hệ thống toàn diện
- Thêm/sửa/xóa dữ liệu: chung cư, căn hộ, dịch vụ, tin tức, người dùng...
- Duyệt/đối soát hóa đơn, xử lý phản ánh
- Quản lý chủ hộ/cư dân theo căn hộ

## 5) Tính năng nổi bật
### 5.1 Email tự động (Web)
- Thông báo phản ánh
- Xác nhận đăng ký dịch vụ
- Khôi phục mật khẩu

### 5.2 Mô hình 3D căn hộ (Web + Mobile)
- Dữ liệu mô hình 3D được tạo từ SketchUp và lưu dưới dạng URL (hoặc tài nguyên liên kết)
- Mobile hỗ trợ mở mô hình qua WebView (màn hình xem 3D)

### 5.3 Chatbot hỗ trợ trực tuyến (Web)
- Tích hợp Dialogflow để trả lời câu hỏi/định hướng thao tác
- Có thể cấu hình chế độ bypass để phát triển/thử nghiệm

### 5.4 Mobile app (Flutter) – phần mới bổ sung
Các nhóm màn hình chính trong app (tham khảo code tại `apt_apartment/apt_apartment/lib/frontend/src/...`):
- **Xác thực & hồ sơ**: đăng nhập/đăng ký, xem/cập nhật thông tin cá nhân
- **Trang chủ**: điều hướng nhanh tới các phân hệ
- **Chung cư & căn hộ**: xem danh sách, xem chi tiết, ảnh minh họa
- **3D Viewer**: mở mô hình 3D căn hộ bằng URL
- **Dịch vụ**: xem dịch vụ, cư dân có thể đăng ký dịch vụ (tạo hóa đơn dịch vụ)
- **Hóa đơn**: xem danh sách hóa đơn theo cư dân/căn hộ, cập nhật theo luồng dữ liệu
- **Phản ánh**: tạo phản ánh, theo dõi trạng thái, xem phản hồi (có thể đính kèm ảnh)
- **Chat**:
  - Chat chung theo chung cư
  - Chat riêng giữa cư dân
  - Theo dõi tin nhắn theo dạng stream (realtime)

## 6) Cấu trúc thư mục trong repo
- `APT/`: Web ASP.NET Core MVC + SQL Server
  - `APT/APT/`: source chính của web app (`Program.cs`, `Controllers/`, `Views/`, ...)
  - `APT/QLCC.sql`: script tạo database SQL Server
- `apt_apartment/`: Mobile Flutter + Supabase
  - `apt_apartment/apt_apartment/`: source Flutter app
  - `apt_apartment/sql`: schema & seed data cho Supabase

## 7) Hướng dẫn chạy dự án
### 7.1 Chạy Web (ASP.NET Core MVC)
**Yêu cầu**
- .NET SDK 9.x
- SQL Server

**Bước chạy nhanh**
1. Tạo database bằng script: `APT/QLCC.sql`
2. Cập nhật connection string trong `APT/APT/appsettings.json` (mục `ConnectionStrings:DefaultConnection`)
3. Chạy project:
   - `cd APT/APT`
   - `dotnet restore`
   - `dotnet run`

### 7.2 Chạy Mobile (Flutter)
**Yêu cầu**
- Flutter SDK
- Android Studio (hoặc Xcode nếu chạy iOS)
- Một project Supabase (URL + anon key)

**Thiết lập Supabase**
1. Tạo project trên Supabase
2. Chạy schema & seed: `apt_apartment/sql` (Supabase SQL editor)
3. (Tuỳ chọn) Tạo bucket Storage tên `apt-assets` và cấu hình policy phù hợp cho upload/đọc ảnh

**Chạy ứng dụng**
1. Cập nhật `apt_apartment/apt_apartment/lib/supabase_options.dart` theo Supabase của bạn
2. Chạy:
   - `cd apt_apartment/apt_apartment`
   - `flutter pub get`
   - `flutter run`

## 8) Thách thức & hướng phát triển
- Bảo mật thông tin (quản lý secrets cấu hình, phân quyền dữ liệu, audit)
- Tối ưu trải nghiệm người dùng (độ mượt UI, offline-first, tối ưu tải ảnh)
- Mở rộng tích hợp dịch vụ thông minh (IoT, thanh toán, thông báo đẩy, v.v.)
