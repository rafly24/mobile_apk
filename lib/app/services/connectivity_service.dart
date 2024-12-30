import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final GetStorage _storage = GetStorage();
  final RxBool isConnected = true.obs;
  final RxList<Map<String, dynamic>> pendingUploads = <Map<String, dynamic>>[].obs;
  final Logger logger = Logger();
  bool _isAppReady = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isAppReady = true;
      _initConnectivity();
      _setupConnectivityStream();
      _loadPendingUploads();
    });
  }

  Future<void> _loadPendingUploads() async {
    try {
      final savedUploads = _storage.read('pending_uploads');
      if (savedUploads != null) {
        pendingUploads.value = List<Map<String, dynamic>>.from(savedUploads);
      }
    } catch (e) {
      logger.e('Error loading pending uploads: $e');
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.isNotEmpty) {
        _updateConnectionStatus(connectivityResult.first);
      } else {
        _updateConnectionStatus(ConnectivityResult.none);
      }
    } catch (e) {
      logger.e('Error checking connectivity: $e');
      _updateConnectionStatus(ConnectivityResult.none);
    }
  }

  void _setupConnectivityStream() {
    try {
      _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          if (results.isNotEmpty) {
            _updateConnectionStatus(results.first);
          } else {
            _updateConnectionStatus(ConnectivityResult.none);
          }
        },
      );
    } catch (e) {
      logger.e('Error setting up connectivity stream: $e');
    }
  }

  void _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    SnackPosition snackPosition = SnackPosition.TOP,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_isAppReady && Get.context != null) {
      Get.snackbar(
        title,
        message,
        backgroundColor: backgroundColor,
        colorText: Colors.white,
        snackPosition: snackPosition,
        duration: duration,
      );
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    isConnected.value = result != ConnectivityResult.none;
    
    _showSnackbar(
      title: isConnected.value ? 'Terhubung' : 'Tidak Terhubung',
      message: isConnected.value 
          ? 'Anda terhubung ke internet' 
          : 'Tidak ada koneksi internet',
      backgroundColor: isConnected.value ? Colors.green : Colors.red,
    );

    if (isConnected.value && pendingUploads.isNotEmpty) {
      _processPendingUploads();
    }
  }

  Future<void> addPendingUpload(Map<String, dynamic> data, String collection) async {
    try {
      final uploadData = {
        ...data,
        'collection': collection,
        'timestamp': DateTime.now().toIso8601String(),
      };

      pendingUploads.add(uploadData);
      await _storage.write('pending_uploads', pendingUploads.toList());

      _showSnackbar(
        title: 'Pending Upload',
        message: 'Data akan disimpan ketika terhubung ke internet',
        backgroundColor: Colors.orange,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      logger.e('Error adding pending upload: $e');
      _showSnackbar(
        title: 'Error',
        message: 'Gagal menyimpan data untuk upload nanti',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _processPendingUploads() async {
    if (pendingUploads.isEmpty) return;

    final List<Map<String, dynamic>> failedUploads = [];

    for (final data in pendingUploads) {
      try {
        final collection = data['collection'] as String;
        final uploadData = Map<String, dynamic>.from(data);
        final documentId = uploadData['documentId'];
        uploadData.remove('collection');
        uploadData.remove('timestamp');
        uploadData.remove('documentId');

        if (documentId != null) {
          // Update existing document
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(documentId)
              .update(uploadData);
        } else {
          // Create new document
          await FirebaseFirestore.instance
              .collection(collection)
              .add(uploadData);
        }

        logger.i('Successfully uploaded data to $collection');
      } catch (e) {
        logger.e('Error processing upload: $e');
        failedUploads.add(data);
      }
    }

    pendingUploads.value = failedUploads;
    await _storage.write('pending_uploads', failedUploads);

    if (failedUploads.isEmpty && _isAppReady) {
      _showSnackbar(
        title: 'Success',
        message: 'Semua data berhasil diupload',
        backgroundColor: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else if (_isAppReady) {
      _showSnackbar(
        title: 'Warning',
        message: 'Beberapa data gagal diupload dan akan dicoba kembali',
        backgroundColor: Colors.orange,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  bool hasPendingUploads() => pendingUploads.isNotEmpty;

  int getPendingUploadsCount() => pendingUploads.length;

  Future<void> clearPendingUploads() async {
    try {
      pendingUploads.clear();
      await _storage.remove('pending_uploads');
      logger.i('Cleared all pending uploads');
    } catch (e) {
      logger.e('Error clearing pending uploads: $e');
    }
  }

  @override
  void onClose() {
    logger.i('ConnectivityService closed');
    super.onClose();
  }
}
