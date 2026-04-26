// lib/features/sync/services/api_service.dart
//
// Abstraksi semua HTTP call ke backend Node.js/Express.
// SyncManager menggunakan class ini untuk mengirim data ke MongoDB Atlas.
//
// Tugas: Adjie Ali (feature/offlineSync)

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sync_queue_model.dart';

/// Response dari API backend
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? errorMessage;
  final DateTime? serverUpdatedAt;

  const ApiResponse({
    required this.success,
    this.data,
    this.errorMessage,
    this.serverUpdatedAt,
  });
}

class ApiService {
  // TODO: Ganti dengan URL backend kalian saat sudah deploy
  static const String _baseUrl = 'https://soalku-api.example.com/api/v1';

  // JWT token — diisi setelah login (dari Hive, oleh modul Auth - Jibril)
  String? _authToken;

  void setAuthToken(String token) => _authToken = token;
  void clearAuthToken() => _authToken = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Kirim satu operasi sync ke backend.
  ///
  /// Backend akan menentukan endpoint berdasarkan entityType + operation.
  /// Contoh:
  ///   - create Question  → POST   /questions
  ///   - update Question  → PUT    /questions/:id
  ///   - delete Question  → DELETE /questions/:id
  Future<ApiResponse> sendSyncEntry(SyncQueueModel entry) async {
    try {
      final uri = _buildUri(entry);
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;

      http.Response response;

      switch (entry.operation) {
        case SyncOperation.create:
          response = await http
              .post(uri, headers: _headers, body: jsonEncode(payload))
              .timeout(const Duration(seconds: 15));
          break;
        case SyncOperation.update:
          response = await http
              .put(uri, headers: _headers, body: jsonEncode(payload))
              .timeout(const Duration(seconds: 15));
          break;
        case SyncOperation.delete:
          response = await http
              .delete(uri, headers: _headers)
              .timeout(const Duration(seconds: 15));
          break;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        DateTime? serverUpdatedAt;
        if (responseBody['updatedAt'] != null) {
          serverUpdatedAt = DateTime.tryParse(responseBody['updatedAt']);
        }
        return ApiResponse(
          success: true,
          data: responseBody,
          serverUpdatedAt: serverUpdatedAt,
        );
      } else {
        return ApiResponse(
          success: false,
          errorMessage: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Ambil data terbaru dari server untuk satu entitas (untuk LWW comparison).
  Future<ApiResponse> fetchLatestFromCloud(
      String entityType, String entityId) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/${_entityPath(entityType)}/$entityId');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        DateTime? serverUpdatedAt;
        if (data['updatedAt'] != null) {
          serverUpdatedAt = DateTime.tryParse(data['updatedAt']);
        }
        return ApiResponse(
          success: true,
          data: data,
          serverUpdatedAt: serverUpdatedAt,
        );
      } else if (response.statusCode == 404) {
        // Entitas belum ada di cloud — oke, berarti local lebih baru
        return const ApiResponse(success: true, data: null);
      } else {
        return ApiResponse(
          success: false,
          errorMessage: 'HTTP ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(success: false, errorMessage: e.toString());
    }
  }

  Uri _buildUri(SyncQueueModel entry) {
    final path = _entityPath(entry.entityType);
    switch (entry.operation) {
      case SyncOperation.create:
        return Uri.parse('$_baseUrl/$path');
      case SyncOperation.update:
      case SyncOperation.delete:
        return Uri.parse('$_baseUrl/$path/${entry.entityId}');
    }
  }

  /// Mapping entityType ke path REST API backend
  String _entityPath(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'question':
        return 'questions';
      case 'quizsession':
        return 'quiz-sessions';
      case 'quizanswer':
        return 'quiz-answers';
      case 'user':
        return 'users';
      case 'collection':
        return 'collections';
      case 'downloadpackage':
        return 'download-packages';
      default:
        return entityType.toLowerCase() + 's';
    }
  }
}
