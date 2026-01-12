# APT-CONNECT (PHQ-TECH): Hệ Thống Quản Lý và Trải Nghiệm Chung Cư

**Giảng viên hướng dẫn:** Trần Đăng Khoa  
**Ngành:** Công Nghệ Thông Tin — **Chuyên ngành:** Công Nghệ Phần Mềm

**Sinh viên/nhóm thực hiện**
- Dương Thanh Phong — 2280602345 — 22DTHD4
- Lê Minh Hiếu — 2280600947 — 22DTHD4
- Trương Vệ Quang — 2280602568 — 22DTHD4

## 1) Tổng quan
APT-CONNECT là giải pháp số hóa việc **quản lý chung cư** và **tương tác cư dân** (thông tin căn hộ, dịch vụ, hóa đơn, phản ánh, tin tức, chat, 3D…).

Repo hiện gồm **3 phần** tương ứng 3 thư mục:
- `APT/`: **Web version 1** (ASP.NET Core MVC + SQL Server)
- `apt_apartment/`: **App mobile** (Flutter + Supabase)
- `APT_DACN/`: **Web version 2** (Node.js/TypeScript + React + Supabase)

## 2) Phân quyền người dùng (nghiệp vụ)
### 2.1 Khách (truy cập cơ bản)
- Tra cứu thông tin chung cư
- Xem danh sách/chi tiết căn hộ
- Xem dịch vụ
- Đọc tin tức/sự kiện

### 2.2 Cư dân (quyền nâng cao)
- Toàn bộ chức năng của khách
- Đăng ký dịch vụ
- Theo dõi hóa đơn
- Gửi phản ánh (có thể kèm hình ảnh)
- Cập nhật thông tin cá nhân
- Tham gia chat (tuỳ phiên bản)

### 2.3 Ban quản lý / Admin
- Quản lý dữ liệu: chung cư, căn hộ, dịch vụ, tin tức, người dùng…
- Duyệt/đối soát hóa đơn, xử lý phản ánh
- Quản lý cư dân/chủ hộ theo căn hộ

## 3) `APT/` — Web version 1 (ASP.NET Core MVC + SQL Server)
### 3.1 Công nghệ
- ASP.NET Core MVC (`.NET 9`), Entity Framework Core
- SQL Server (script: `APT/QLCC.sql`)
- Cookie Authentication
- Tích hợp: Email SMTP, Chatbot Dialogflow (tuỳ cấu hình)

### 3.2 Cấu trúc liên quan
- Source web: `APT/APT/`
- Cấu hình: `APT/APT/appsettings.json`
- Script DB: `APT/QLCC.sql`

### 3.3 Chạy Web v1
**Yêu cầu:** .NET SDK 9.x, SQL Server
```bash
cd APT/APT
dotnet restore
dotnet run
```
Gợi ý: tạo DB bằng `APT/QLCC.sql` và cập nhật `ConnectionStrings:DefaultConnection` trong `APT/APT/appsettings.json`.

## 4) `apt_apartment/` — App mobile (Flutter + Supabase)
### 4.1 Công nghệ
- Flutter (Dart)
- Supabase (PostgreSQL + Storage + Realtime/stream)
- 3D viewer: mở URL mô hình 3D bằng WebView

### 4.2 Tính năng chính (mobile)
- Đăng nhập/đăng ký, quản lý phiên (local)
- Xem chung cư, căn hộ, chi tiết căn hộ + media
- Xem mô hình 3D căn hộ (WebView)
- Xem dịch vụ, cư dân đăng ký dịch vụ
- Xem hóa đơn theo cư dân/căn hộ
- Gửi phản ánh (có thể đính kèm ảnh), theo dõi trạng thái/phản hồi
- Chat (chat chung chung cư + chat riêng), nhận tin nhắn theo stream

### 4.3 Cấu trúc liên quan
- Source Flutter: `apt_apartment/apt_apartment/`
- Schema Supabase: `apt_apartment/sql`
- Cấu hình Supabase: `apt_apartment/apt_apartment/lib/supabase_options.dart`

### 4.4 Chạy mobile
**Yêu cầu:** Flutter SDK, Android Studio (hoặc Xcode nếu chạy iOS), 01 project Supabase
```bash
cd apt_apartment/apt_apartment
flutter pub get
flutter run
```
Gợi ý: chạy schema/seed trong `apt_apartment/sql` trên Supabase SQL Editor và cập nhật `supabase_options.dart` (URL + anon key).

## 5) `APT_DACN/` — Web version 2 (Node.js/TypeScript + React + Supabase)
Web v2 là bản rewrite theo hướng tách **backend API** và **frontend SPA**:
- Backend: `APT_DACN/src/` (Express + TypeScript) — API prefix `/api`
- Frontend: `APT_DACN/client/` (Vite + React + TypeScript)
- Database/Storage: Supabase (Postgres + Storage)

### 5.1 Chạy backend (API)
**Yêu cầu:** Node.js (khuyến nghị 18+/20+)
```bash
cd APT_DACN
copy .env.example .env
npm install
npm run dev
```
- Port mặc định: `4000` (theo `APT_DACN/.env.example`)
- Cần điền các biến Supabase/JWT trong `.env` (ví dụ: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `JWT_SECRET`, …)

### 5.2 Chạy frontend (UI)
```bash
cd APT_DACN/client
npm install
npm run dev
```
- UI mặc định chạy tại `http://localhost:5173`

### 5.3 Gợi ý cấu hình Supabase cho web v2
- Tạo bucket Storage (ví dụ `apt-assets`) theo biến `SUPABASE_STORAGE_BUCKET`
- Backend hỗ trợ upload ảnh lên Supabase Storage và lưu **public URL** vào DB

## 6) Thách thức & hướng phát triển
- Bảo mật thông tin (quản lý secrets `.env`/`appsettings.json`, phân quyền dữ liệu)
- Tối ưu UX/UI (mobile + web), tối ưu tải ảnh/media
- Mở rộng tích hợp dịch vụ thông minh (IoT, thanh toán, thông báo đẩy, v.v.)
