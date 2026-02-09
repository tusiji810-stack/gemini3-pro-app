import 'dart:convert';
import 'dart:typed_data';

/// 图像生成请求模型
class GenerationRequest {
  /// 提示词
  final String prompt;
  
  /// 参考图片列表 (base64编码)
  final List<String> referenceImages;
  
  /// 宽高比 (例如: "16:9", 可为null表示自动)
  final String? aspectRatio;
  
  /// 自定义宽度 (可为null)
  final int? customWidth;
  
  /// 自定义高度 (可为null)
  final int? customHeight;
  
  /// 图像尺寸 (例如: "2K", 可为null表示自动)
  final String? imageSize;
  
  /// 随机种子 (0表示随机)
  final int seed;
  
  const GenerationRequest({
    required this.prompt,
    this.referenceImages = const [],
    this.aspectRatio,
    this.customWidth,
    this.customHeight,
    this.imageSize,
    this.seed = 0,
  });

  /// 检查是否使用自定义宽高
  bool get hasCustomDimensions => customWidth != null || customHeight != null;

  /// 获取实际使用的宽高比
  String? get effectiveAspectRatio {
    if (hasCustomDimensions && customWidth != null && customHeight != null) {
      // 根据自定义宽高计算比例
      final gcd = _gcd(customWidth!, customHeight!);
      return '${customWidth! ~/ gcd}:${customHeight! ~/ gcd}';
    }
    return aspectRatio;
  }

  /// 最大公约数计算
  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  GenerationRequest copyWith({
    String? prompt,
    List<String>? referenceImages,
    String? aspectRatio,
    int? customWidth,
    int? customHeight,
    String? imageSize,
    int? seed,
    bool clearAspectRatio = false,
    bool clearCustomWidth = false,
    bool clearCustomHeight = false,
    bool clearImageSize = false,
  }) {
    return GenerationRequest(
      prompt: prompt ?? this.prompt,
      referenceImages: referenceImages ?? this.referenceImages,
      aspectRatio: clearAspectRatio ? null : (aspectRatio ?? this.aspectRatio),
      customWidth: clearCustomWidth ? null : (customWidth ?? this.customWidth),
      customHeight: clearCustomHeight ? null : (customHeight ?? this.customHeight),
      imageSize: clearImageSize ? null : (imageSize ?? this.imageSize),
      seed: seed ?? this.seed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'referenceImages': referenceImages,
      'aspectRatio': aspectRatio,
      'customWidth': customWidth,
      'customHeight': customHeight,
      'imageSize': imageSize,
      'seed': seed,
    };
  }

  factory GenerationRequest.fromJson(Map<String, dynamic> json) {
    return GenerationRequest(
      prompt: json['prompt'] as String,
      referenceImages: (json['referenceImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      aspectRatio: json['aspectRatio'] as String?,
      customWidth: json['customWidth'] as int?,
      customHeight: json['customHeight'] as int?,
      imageSize: json['imageSize'] as String?,
      seed: json['seed'] as int? ?? 0,
    );
  }
}

/// 生成的图像结果
class GeneratedImage {
  /// 图像数据
  final Uint8List imageData;
  
  /// 图像宽度
  final int width;
  
  /// 图像高度
  final int height;
  
  /// 生成时间戳
  final DateTime timestamp;
  
  /// 文件大小 (字节)
  final int fileSize;

  const GeneratedImage({
    required this.imageData,
    required this.width,
    required this.height,
    required this.timestamp,
    required this.fileSize,
  });

  String get sizeLabel => '${width}x$height';
  
  String get fileSizeLabel {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// 生成结果
class GenerationResult {
  /// 生成的图像列表
  final List<GeneratedImage> images;
  
  /// 是否成功
  final bool success;
  
  /// 错误信息 (如果失败)
  final String? errorMessage;
  
  /// 响应文本 (如果有)
  final String? textResponse;

  const GenerationResult({
    required this.images,
    this.success = true,
    this.errorMessage,
    this.textResponse,
  });

  factory GenerationResult.success(List<GeneratedImage> images, {String? text}) {
    return GenerationResult(
      images: images,
      success: true,
      textResponse: text,
    );
  }

  factory GenerationResult.error(String message) {
    return GenerationResult(
      images: const [],
      success: false,
      errorMessage: message,
    );
  }
}
