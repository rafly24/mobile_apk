import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';

class ReviewController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  final Rx<XFile?> selectedVideo = Rx<XFile?>(null);

  final storage = GetStorage();

  // Ambil Foto
  Future<void> pickPhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      selectedImage.value = photo;
      storage.write('selectedImage', photo.path);
    }
  }

  // Ambil Video
  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      selectedVideo.value = video;
      storage.write('selectedVideo', video.path);
    }
  }

  @override
  void onInit() {
    // Load data dari GetStorage jika tersedia
    String? savedImagePath = storage.read('selectedImage');
    if (savedImagePath != null) {
      selectedImage.value = XFile(savedImagePath);
    }

    String? savedVideoPath = storage.read('selectedVideo');
    if (savedVideoPath != null) {
      selectedVideo.value = XFile(savedVideoPath);
    }
    super.onInit();
  }
}
