/// Chứa các hằng số là tên của các routes trong ứng dụng.
/// Việc sử dụng hằng số giúp tránh lỗi chính tả và dễ dàng tìm kiếm, thay thế.
class AppRoutes {
  // Route ban đầu khi mở ứng dụng
  static const String splash = '/';

  // Route chính, chứa Bottom Navigation Bar
  static const String main = '/main';

  // Route cho các màn hình chức năng
  static const String camera = '/camera';
  static const String history = '/history';
  static const String reports = '/reports';
  static const String settings = '/settings';

  // Route cho luồng thiết lập tài khoản
  static const String accountSetup = '/account-setup';

  // THÊM: Route cho màn hình đăng nhập
  static const String login = '/login';
}