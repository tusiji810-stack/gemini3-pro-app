import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import '../models/generation_request.dart';
import '../models/settings_model.dart';

/// Gemini API 服务
class GeminiApiService {
  late Dio _dio;
  
  // 超时设置
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 600000; // 10分钟

  GeminiApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: connectTimeout),
        receiveTimeout: const Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    
    // 添加日志拦截器
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false, // 不打印二进制响应
      ),
    );
  }

  /// 生成图像
  Future<GenerationResult> generateImage({
    required GenerationRequest request,
    required AppSettings settings,
    void Function(double progress)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);
      
      // 构建请求URL
      final url = '${settings.apiUrl}?key=${settings.apiKey}';
      
      // 构建parts
      final List<Map<String, dynamic>> parts = [
        {'text': request.prompt},
      ];
      
      // 添加参考图片
      for (final imageBase64 in request.referenceImages) {
        parts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': imageBase64,
          },
        });
      }
      
      onProgress?.call(0.3);
      
      // 构建imageConfig
      final Map<String, dynamic> imageConfig = {};
      
      // 优先使用自定义宽高计算的比例
      final aspectRatio = request.effectiveAspectRatio;
      if (aspectRatio != null && aspectRatio != '自动') {
        imageConfig['aspectRatio'] = aspectRatio;
      }
      
      if (request.imageSize != null && request.imageSize != '自动') {
        imageConfig['imageSize'] = request.imageSize;
      }
      
      // 构建请求体
      final Map<String, dynamic> payload = {
        'contents': [
          {
            'role': 'user',
            'parts': parts,
          },
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
          if (imageConfig.isNotEmpty) 'imageConfig': imageConfig,
        },
      };
      
      // 添加seed
      if (request.seed > 0) {
        payload['generationConfig']['seed'] = request.seed;
      }
      
      onProgress?.call(0.5);
      
      // 发送请求
      final response = await _dio.post(
        url,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${settings.apiKey}',
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress?.call(0.5 + (sent / total) * 0.2);
          }
        },
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(0.7 + (received / total) * 0.3);
          }
        },
      );
      
      onProgress?.call(0.8);
      
      if (response.statusCode != 200) {
        return GenerationResult.error(
          'API返回错误: ${response.statusCode} - ${response.statusMessage}',
        );
      }
      
      // 解析响应
      final result = response.data as Map<String, dynamic>;
      final List<GeneratedImage> images = [];
      String? textResponse;
      
      final candidates = result['candidates'] as List<dynamic>?;
      if (candidates != null) {
        for (final candidate in candidates) {
          final content = candidate['content'] as Map<String, dynamic>?;
          if (content != null) {
            final parts = content['parts'] as List<dynamic>?;
            if (parts != null) {
              for (final part in parts) {
                // 处理图像数据
                final inlineData = part['inline_data'] ?? part['inlineData'];
                if (inlineData != null) {
                  final data = inlineData['data'] as String?;
                  if (data != null && data.isNotEmpty) {
                    try {
                      final imageBytes = base64Decode(data);
                      final decodedImage = img.decodeImage(imageBytes);
                      
                      if (decodedImage != null) {
                        images.add(GeneratedImage(
                          imageData: Uint8List.fromList(imageBytes),
                          width: decodedImage.width,
                          height: decodedImage.height,
                          timestamp: DateTime.now(),
                          fileSize: imageBytes.length,
                        ));
                      }
                    } catch (e) {
                      print('解析图像失败: $e');
                    }
                  }
                }
                
                // 处理文本响应
                final text = part['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  textResponse = text;
                }
              }
            }
          }
        }
      }
      
      onProgress?.call(1.0);
      
      if (images.isEmpty && textResponse == null) {
        return GenerationResult.error('未生成任何内容');
      }
      
      return GenerationResult.success(images, text: textResponse);
      
    } on DioException catch (e) {
      String errorMsg;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          errorMsg = '连接超时，请检查网络';
          break;
        case DioExceptionType.receiveTimeout:
          errorMsg = '接收数据超时，请稍后重试';
          break;
        case DioExceptionType.connectionError:
          errorMsg = '网络连接失败，请检查网络设置';
          break;
        case DioExceptionType.badResponse:
          errorMsg = '服务器返回错误: ${e.response?.statusCode}';
          if (e.response?.data != null) {
            errorMsg += '\n${e.response?.data}';
          }
          break;
        default:
          errorMsg = '请求失败: ${e.message}';
      }
      return GenerationResult.error(errorMsg);
    } catch (e) {
      return GenerationResult.error('发生错误: $e');
    }
  }

  /// 验证API配置
  Future<bool> validateSettings(AppSettings settings) async {
    if (settings.apiKey.isEmpty) return false;
    
    try {
      final url = '${settings.apiUrl}?key=${settings.apiKey}';
      final response = await _dio.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
