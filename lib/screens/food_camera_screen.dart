import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/food_analysis_controller.dart';
import '../models/meal_analysis_result.dart';
import 'meal_result_screen.dart'; // Import màn hình mới

/// Màn hình chuyên dụng để chụp hoặc chọn ảnh món ăn để phân tích.
///
/// Bao gồm các chức năng:
/// - Hiển thị camera preview toàn màn hình với tỷ lệ 9:16.
/// - Nút chụp ảnh.
/// - Nút chọn ảnh từ thư viện.
/// - Điều hướng đến màn hình phân tích sau khi có ảnh.
class FoodCameraScreen extends StatefulWidget {
  const FoodCameraScreen({super.key});

  @override
  State<FoodCameraScreen> createState() => _FoodCameraScreenState();
}

class _FoodCameraScreenState extends State<FoodCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();

  // Cờ để kiểm soát việc resume camera, tránh xung đột khi đang xử lý ảnh
  bool _isProcessing = false;

  // Màu chủ đạo của ứng dụng (giả định)
  static const Color primaryColor = Color(0xFFA8D15D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // Xử lý khi app không active/inactive
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Tạm dừng camera thay vì hủy bỏ để tránh lỗi khi quay lại app
      cameraController.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      // Chỉ bật lại camera nếu không có tác vụ nặng (phân tích ảnh) đang chạy
      if (!_isProcessing) {
        cameraController.resumePreview();
      }
    }
  }

  /// Khởi tạo camera, chọn camera sau và đặt độ phân giải.
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      // Xử lý trường hợp không tìm thấy camera
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy camera trên thiết bị.')),
      );
      return;
    }
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium, //chất lượng
      enableAudio: false, // Không cần thu âm cho chức năng này
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  /// Xử lý logic chụp ảnh và điều hướng.
  Future<void> _takePicture() async {
    // Đảm bảo controller đã được khởi tạo
    await _initializeControllerFuture;

    if (_controller == null || !_controller!.value.isInitialized) {
      print('Lỗi: Camera controller chưa được khởi tạo.');
      return;
    }

    try {
      final XFile imageFile = await _controller!.takePicture();
      _navigateToScanScreen(imageFile);
    } catch (e) {
      print('Lỗi khi chụp ảnh: $e');
    }
  }

  /// Mở thư viện và chọn ảnh.
  Future<void> _pickImageFromGallery() async {
    // Tạm dừng camera trước khi mở thư viện để tránh xung đột tài nguyên.
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller?.pausePreview();
    }

    try {
      final XFile? imageFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (imageFile != null) {
        _navigateToScanScreen(imageFile);
      } else {
        // Nếu người dùng không chọn ảnh, bật lại camera preview.
        if (mounted && _controller != null) {
          await _controller?.resumePreview();
        }
      }
    } catch (e) {
      print('Lỗi khi chọn ảnh từ thư viện: $e');
      // Nếu có lỗi, cũng cố gắng bật lại camera.
      if (mounted && _controller != null) {
        await _controller?.resumePreview();
      }
    }
  }

  /// Điều hướng đến màn hình quét ảnh, thực thi quy trình phân tích và in kết quả.
  void _navigateToScanScreen(XFile imageFile) async {
    if (!mounted) return;

    // Đặt cờ để báo hiệu quá trình xử lý bắt đầu
    _isProcessing = true;

    // --- SỬA LỖI MÀN HÌNH ĐỎ ---
    // 1. Gỡ CameraPreview khỏi UI trước (setState)
    if (_controller != null) {
      final cameraToDispose = _controller; // Lưu vào biến tạm
      if (mounted) {
        setState(() {
          _controller = null; // Màn hình sẽ chuyển sang loading, không còn vẽ Camera nữa
        });
      }
      // 2. Sau đó mới tắt camera an toàn
      await cameraToDispose?.dispose();
    }
    // ----------------------------

    // Hiển thị dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      // Khởi tạo controller
      final controller = FoodAnalysisController();

      // Bắt đầu quy trình xử lý
      final MealAnalysisResult result = await controller.processMeal(imageFile);

      if (!mounted) return;

      // Tắt dialog loading
      Navigator.of(context, rootNavigator: true).pop();

      // --- XỬ LÝ KẾT QUẢ ---
      
      // TRƯỜNG HỢP 1: AI bảo không phải đồ ăn
      if (result.foodName == "Không phải đồ ăn") {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("⚠️ Ảnh không hợp lệ"),
            content: const Text("AI không nhận diện được món ăn nào. Vui lòng chụp lại hình ảnh thực phẩm rõ nét."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Đồng ý", style: TextStyle(color: primaryColor)),
              )
            ],
          ),
        );
      } 
      // TRƯỜNG HỢP 2: Lỗi phân tích (Rỗng)
      else if (result.ingredients.isEmpty) {
        print("Không thể phân tích món ăn từ ảnh này.");
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Không thể phân tích dinh dưỡng. Vui lòng thử lại!")),
        );
      } 
      // TRƯỜNG HỢP 3: Thành công
      else {
        // Điều hướng sang màn hình kết quả đẹp
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MealResultScreen(
              result: result,
              imageFile: imageFile,
            ),
          ),
        );
      }

    } catch (e) {
      print("Lỗi trong quá trình xử lý: $e");
      if (mounted) {
        // Tắt loading nếu còn
        Navigator.of(context, rootNavigator: true).pop();
      }
    } finally {
      
      if (mounted) {
        await _initializeCamera();
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước an toàn phía trên (tai thỏ/status bar)
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _controller != null && _controller!.value.isInitialized) {
            return Column(
              children: [
                // 1. Khoảng trống phía trên để tránh thanh trạng thái và AppBar
                SizedBox(height: topPadding + 80),

                // 2. Khung hình Camera (Preview)
                SizedBox(
                  width: double.infinity,
                  child: AspectRatio(
                    aspectRatio: 3 / 4, // Tỷ lệ
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize!.height,
                        height: _controller!.value.previewSize!.width,
                        child: ClipRect(child: CameraPreview(_controller!)),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // 4. Vùng điều khiển (Nút chụp + Thư viện)
                Container(
                  width: double.infinity,
                  color: Colors.black, // Nền đen cho vùng dưới giống hình mẫu
                  // Padding bottom: Đẩy nút chụp lên cao khỏi mép dưới màn hình
                  padding: const EdgeInsets.only(bottom: 50, top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Nút thư viện
                      IconButton(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(
                          Icons.image, // Icon hình ảnh giống mẫu hơn
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      // Nút chụp ảnh
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 80, // Tăng kích thước nút chụp to hơn chút
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 4,
                            ),
                          ),
                          // Tạo hiệu ứng vòng tròn nhỏ bên trong cho giống nút chụp thật
                          child: Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 32),
                    ],
                  ),
                ),
              ],
            );
          } else {
            
            if (_isProcessing) {
              return Container(color: Colors.black);
            }
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
        },
      ),
    );
  }
}
