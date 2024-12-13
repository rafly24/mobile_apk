import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart'; // Tambahkan ini

class ChatPemilikController extends GetxController {
  var messages = <ChatMessage>[].obs;
  var voiceNotes = <VoiceNote>[].obs;

  late FlutterSoundRecorder _recorder;
  late AudioPlayer _player; // Ganti FlutterSoundPlayer dengan AudioPlayer
  RxBool isRecording = false.obs;
  RxBool isPlaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    requestPermissions();
    _recorder = FlutterSoundRecorder();
    _player = AudioPlayer(); // Inisialisasi AudioPlayer
    initRecorder();
    messages.add(ChatMessage(
      text: "Hi, saya tertarik dengan kos anda",
      isMe: true,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> startRecording() async {
    if (isRecording.value) return;
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(toFile: filePath);
    isRecording.value = true;
  }

  Future<void> stopRecording() async {
    if (!isRecording.value) return;

    try {
      final filePath = await _recorder.stopRecorder();
      if (filePath != null) {
        print('Rekaman disimpan di: $filePath');
        voiceNotes.add(VoiceNote(filePath: filePath, timestamp: DateTime.now()));
      } else {
        print('Gagal mendapatkan path rekaman');
      }
    } catch (e) {
      print('Error saat menghentikan rekaman: $e');
    } finally {
      isRecording.value = false;
    }
  }

  Future<void> playVoiceNote(String filePath) async {
    if (isPlaying.value) {
      await _player.stop(); // Menghentikan pemutaran
      isPlaying.value = false;
    } else {
      try {
        await _player.setFilePath(filePath); // Mengatur file untuk diputar
        await _player.play(); // Memulai pemutaran
        isPlaying.value = true;

        // Mengatur status pemutaran saat selesai
        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            isPlaying.value = false;
          }
        });
      } catch (e) {
        print('Error saat memutar voice note: $e');
      }
    }
  }

  void sendMessage(String text) {
    messages.add(ChatMessage(
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void onClose() {
    _recorder.closeRecorder();
    _player.dispose(); // Pastikan untuk membebaskan AudioPlayer
    super.onClose();
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class VoiceNote {
  final String filePath;
  final DateTime timestamp;

  VoiceNote({
    required this.filePath,
    required this.timestamp,
  });
}