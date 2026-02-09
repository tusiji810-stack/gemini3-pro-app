/// 应用设置模型
class AppSettings {
  /// API地址
  final String apiUrl;
  
  /// API密钥
  final String apiKey;
  
  /// 默认宽高比
  final String? defaultAspectRatio;
  
  /// 默认宽度
  final int? defaultWidth;
  
  /// 默认高度
  final int? defaultHeight;
  
  /// 默认图像尺寸
  final String? defaultImageSize;
  
  /// 保存路径
  final String? savePath;
  
  /// 是否显示日志
  final bool showLogs;
  
  /// 主题模式
  final ThemeMode themeMode;

  const AppSettings({
    this.apiUrl = 'https://aigc002.com/v1beta/models/gemini-3-pro-image-preview:generateContent',
    this.apiKey = '',
    this.defaultAspectRatio,
    this.defaultWidth,
    this.defaultHeight,
    this.defaultImageSize,
    this.savePath,
    this.showLogs = true,
    this.themeMode = ThemeMode.system,
  });

  bool get isConfigured => apiKey.isNotEmpty;

  AppSettings copyWith({
    String? apiUrl,
    String? apiKey,
    String? defaultAspectRatio,
    bool clearDefaultAspectRatio = false,
    int? defaultWidth,
    bool clearDefaultWidth = false,
    int? defaultHeight,
    bool clearDefaultHeight = false,
    String? defaultImageSize,
    bool clearDefaultImageSize = false,
    String? savePath,
    bool clearSavePath = false,
    bool? showLogs,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      apiUrl: apiUrl ?? this.apiUrl,
      apiKey: apiKey ?? this.apiKey,
      defaultAspectRatio: clearDefaultAspectRatio 
          ? null 
          : (defaultAspectRatio ?? this.defaultAspectRatio),
      defaultWidth: clearDefaultWidth 
          ? null 
          : (defaultWidth ?? this.defaultWidth),
      defaultHeight: clearDefaultHeight 
          ? null 
          : (defaultHeight ?? this.defaultHeight),
      defaultImageSize: clearDefaultImageSize 
          ? null 
          : (defaultImageSize ?? this.defaultImageSize),
      savePath: clearSavePath 
          ? null 
          : (savePath ?? this.savePath),
      showLogs: showLogs ?? this.showLogs,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiUrl': apiUrl,
      'apiKey': apiKey,
      'defaultAspectRatio': defaultAspectRatio,
      'defaultWidth': defaultWidth,
      'defaultHeight': defaultHeight,
      'defaultImageSize': defaultImageSize,
      'savePath': savePath,
      'showLogs': showLogs,
      'themeMode': themeMode.index,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      apiUrl: json['apiUrl'] as String? ?? 
          'https://aigc002.com/v1beta/models/gemini-3-pro-image-preview:generateContent',
      apiKey: json['apiKey'] as String? ?? '',
      defaultAspectRatio: json['defaultAspectRatio'] as String?,
      defaultWidth: json['defaultWidth'] as int?,
      defaultHeight: json['defaultHeight'] as int?,
      defaultImageSize: json['defaultImageSize'] as String?,
      savePath: json['savePath'] as String?,
      showLogs: json['showLogs'] as bool? ?? true,
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
    );
  }
}

enum ThemeMode {
  system,
  light,
  dark,
}
