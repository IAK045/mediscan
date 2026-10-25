import 'package:dio/dio.dart';
import '../core/config.dart';

class MediScanApi {
  MediScanApi()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 35),
          sendTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        ));

  final Dio _dio;

  Future<Map<String, dynamic>> searchMedicine(String medicineName) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/medicine/search',
      data: {'name': medicineName},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> explainMedicine({
    required String medicineName,
    required String language,
    required Map<String, dynamic> sourceData,
    required String ocrText,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ai/explain',
      data: {
        'medicine_name': medicineName,
        'language': language,
        'source_data': sourceData,
        'ocr_text': ocrText,
      },
    );
    return response.data ?? <String, dynamic>{};
  }
}
