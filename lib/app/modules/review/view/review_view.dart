import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class ReviewView extends StatefulWidget {
  const ReviewView({super.key});

  @override
  _ReviewViewState createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  XFile? _selectedVideo;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  final List<int> ratings = List.generate(5, (_) => 0);

  @override
  void dispose() {
    if (_isVideoInitialized) {
      _videoController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera); // Ganti dari galeri ke kamera
    if (photo != null) {
      setState(() {
        _selectedImage = photo;
      });
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.camera); // Ganti dari galeri ke kamera
    if (video != null) {
      setState(() {
        _selectedVideo = video;
        _videoController = VideoPlayerController.file(File(video.path))
          ..initialize().then((_) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController.play();
          });
      });
    }
  }

  Widget _buildRatingRow(String title, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Row(
          children: List.generate(
            5,
            (i) => IconButton(
              onPressed: () {
                setState(() {
                  ratings[index] = i + 1;
                });
              },
              icon: Icon(
                Icons.star,
                color: i < ratings[index] ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Give a review of the Dormitory you rented to help make it better",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/kamar3.jpeg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kos dekat UMM",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Jl. Raya Jetis", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Rating Rows
            _buildRatingRow("Security", 0),
            _buildRatingRow("Cleanliness", 1),
            _buildRatingRow("Comfort", 2),
            _buildRatingRow("Room Facilities", 3),
            _buildRatingRow("Price Match", 4),
            const SizedBox(height: 16),

            // Add Photo and Video Section
            Row(
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage == null
                        ? const Icon(Icons.add_a_photo,
                            size: 40, color: Colors.grey)
                        : Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedVideo == null
                        ? const Icon(Icons.videocam,
                            size: 40, color: Colors.grey)
                        : const Icon(Icons.play_circle_fill,
                            size: 40, color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Video Player
            if (_isVideoInitialized)
              AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            if (_isVideoInitialized) const SizedBox(height: 16),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                // Validasi: Jika tidak ada gambar atau video yang dipilih
                if (_selectedImage == null && _selectedVideo == null) {
                  Get.snackbar(
                    'Error', 
                    'Please select at least a photo or a video to upload!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                // Menampilkan notifikasi sukses
                Get.snackbar(
                  'Review Submitted', 
                  'Your review has been saved!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Send",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}