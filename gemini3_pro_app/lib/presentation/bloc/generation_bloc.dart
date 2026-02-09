import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/models/generation_request.dart';
import '../../data/models/settings_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/gemini_api_service.dart';

// Events
abstract class GenerationEvent extends Equatable {
  const GenerationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeGeneration extends GenerationEvent {
  const InitializeGeneration();
}

class UpdatePrompt extends GenerationEvent {
  final String prompt;
  
  const UpdatePrompt(this.prompt);
  
  @override
  List<Object?> get props => [prompt];
}

class AddReferenceImage extends GenerationEvent {
  final XFile image;
  
  const AddReferenceImage(this.image);
  
  @override
  List<Object?> get props => [image];
}

class RemoveReferenceImage extends GenerationEvent {
  final int index;
  
  const RemoveReferenceImage(this.index);
  
  @override
  List<Object?> get props => [index];
}

class ClearReferenceImages extends GenerationEvent {
  const ClearReferenceImages();
}

class UpdateAspectRatio extends GenerationEvent {
  final String? ratio;
  final bool isCustom;
  
  const UpdateAspectRatio({this.ratio, this.isCustom = false});
  
  @override
  List<Object?> get props => [ratio, isCustom];
}

class UpdateCustomDimensions extends GenerationEvent {
  final int? width;
  final int? height;
  
  const UpdateCustomDimensions({this.width, this.height});
  
  @override
  List<Object?> get props => [width, height];
}

class UpdateImageSize extends GenerationEvent {
  final String? size;
  
  const UpdateImageSize(this.size);
  
  @override
  List<Object?> get props => [size];
}

class UpdateSeed extends GenerationEvent {
  final int seed;
  
  const UpdateSeed(this.seed);
  
  @override
  List<Object?> get props => [seed];
}

class RandomizeSeed extends GenerationEvent {
  const RandomizeSeed();
}

class StartGeneration extends GenerationEvent {
  const StartGeneration();
}

class CancelGeneration extends GenerationEvent {
  const CancelGeneration();
}

class SaveImage extends GenerationEvent {
  final GeneratedImage image;
  final String? customPath;
  
  const SaveImage(this.image, {this.customPath});
  
  @override
  List<Object?> get props => [image, customPath];
}

class SaveAllImages extends GenerationEvent {
  final String? customPath;
  
  const SaveAllImages({this.customPath});
  
  @override
  List<Object?> get props => [customPath];
}

class ClearResults extends GenerationEvent {
  const ClearResults();
}

class AddLog extends GenerationEvent {
  final String message;
  
  const AddLog(this.message);
  
  @override
  List<Object?> get props => [message];
}

class ClearLogs extends GenerationEvent {
  const ClearLogs();
}

// States
abstract class GenerationState extends Equatable {
  const GenerationState();

  @override
  List<Object?> get props => [];
}

class GenerationInitial extends GenerationState {
  const GenerationInitial();
}

class GenerationReady extends GenerationState {
  final GenerationRequest request;
  final List<XFile> referenceImages;
  final List<String> logs;
  final bool isConfigured;
  
  const GenerationReady({
    required this.request,
    this.referenceImages = const [],
    this.logs = const [],
    this.isConfigured = false,
  });
  
  GenerationReady copyWith({
    GenerationRequest? request,
    List<XFile>? referenceImages,
    List<String>? logs,
    bool? isConfigured,
  }) {
    return GenerationReady(
      request: request ?? this.request,
      referenceImages: referenceImages ?? this.referenceImages,
      logs: logs ?? this.logs,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
  
  @override
  List<Object?> get props => [request, referenceImages, logs, isConfigured];
}

class GenerationInProgress extends GenerationState {
  final GenerationRequest request;
  final double progress;
  final List<String> logs;
  
  const GenerationInProgress({
    required this.request,
    this.progress = 0.0,
    this.logs = const [],
  });
  
  @override
  List<Object?> get props => [request, progress, logs];
}

class GenerationSuccess extends GenerationState {
  final GenerationResult result;
  final GenerationRequest request;
  final List<String> logs;
  
  const GenerationSuccess({
    required this.result,
    required this.request,
    this.logs = const [],
  });
  
  @override
  List<Object?> get props => [result, request, logs];
}

class GenerationError extends GenerationState {
  final String message;
  final GenerationRequest request;
  final List<String> logs;
  
  const GenerationError({
    required this.message,
    required this.request,
    this.logs = const [],
  });
  
  @override
  List<Object?> get props => [message, request, logs];
}

class ImageSaved extends GenerationState {
  final String path;
  final bool isAll;
  
  const ImageSaved(this.path, {this.isAll = false});
  
  @override
  List<Object?> get props => [path, isAll];
}

// BLoC
class GenerationBloc extends Bloc<GenerationEvent, GenerationState> {
  final GeminiApiService _apiService;
  final SettingsRepository _settingsRepository;
  AppSettings _settings = const AppSettings();
  
  GenerationBloc(this._apiService, this._settingsRepository) 
      : super(const GenerationInitial()) {
    on<InitializeGeneration>(_onInitialize);
    on<UpdatePrompt>(_onUpdatePrompt);
    on<AddReferenceImage>(_onAddReferenceImage);
    on<RemoveReferenceImage>(_onRemoveReferenceImage);
    on<ClearReferenceImages>(_onClearReferenceImages);
    on<UpdateAspectRatio>(_onUpdateAspectRatio);
    on<UpdateCustomDimensions>(_onUpdateCustomDimensions);
    on<UpdateImageSize>(_onUpdateImageSize);
    on<UpdateSeed>(_onUpdateSeed);
    on<RandomizeSeed>(_onRandomizeSeed);
    on<StartGeneration>(_onStartGeneration);
    on<CancelGeneration>(_onCancelGeneration);
    on<SaveImage>(_onSaveImage);
    on<SaveAllImages>(_onSaveAllImages);
    on<ClearResults>(_onClearResults);
    on<AddLog>(_onAddLog);
    on<ClearLogs>(_onClearLogs);
  }
  
  Future<void> _onInitialize(
    InitializeGeneration event,
    Emitter<GenerationState> emit,
  ) async {
    _settings = _settingsRepository.getSettings();
    
    emit(GenerationReady(
      request: GenerationRequest(
        prompt: '',
        aspectRatio: _settings.defaultAspectRatio,
        customWidth: _settings.defaultWidth,
        customHeight: _settings.defaultHeight,
        imageSize: _settings.defaultImageSize,
      ),
      isConfigured: _settings.isConfigured,
    ));
  }
  
  Future<void> _onUpdatePrompt(
    UpdatePrompt event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      emit(currentState.copyWith(
        request: currentState.request.copyWith(prompt: event.prompt),
      ));
    }
  }
  
  Future<void> _onAddReferenceImage(
    AddReferenceImage event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      if (currentState.referenceImages.length >= 4) {
        add(const AddLog('最多只能添加4张参考图片'));
        return;
      }
      
      final newImages = [...currentState.referenceImages, event.image];
      emit(currentState.copyWith(referenceImages: newImages));
      add(AddLog('已添加参考图片: ${event.image.name}'));
    }
  }
  
  Future<void> _onRemoveReferenceImage(
    RemoveReferenceImage event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      final newImages = [...currentState.referenceImages];
      if (event.index >= 0 && event.index < newImages.length) {
        newImages.removeAt(event.index);
        emit(currentState.copyWith(referenceImages: newImages));
        add(AddLog('已移除参考图片 ${event.index + 1}'));
      }
    }
  }
  
  Future<void> _onClearReferenceImages(
    ClearReferenceImages event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      emit(currentState.copyWith(referenceImages: []));
      add(const AddLog('已清除所有参考图片'));
    }
  }
  
  Future<void> _onUpdateAspectRatio(
    UpdateAspectRatio event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      final newRequest = currentState.request.copyWith(
        aspectRatio: event.ratio,
        // 如果选择了预设比例，清除自定义宽高
        clearCustomWidth: !event.isCustom && event.ratio != null,
        clearCustomHeight: !event.isCustom && event.ratio != null,
      );
      emit(currentState.copyWith(request: newRequest));
    }
  }
  
  Future<void> _onUpdateCustomDimensions(
    UpdateCustomDimensions event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      final newRequest = currentState.request.copyWith(
        customWidth: event.width,
        customHeight: event.height,
        // 使用自定义尺寸时清除预设比例
        clearAspectRatio: event.width != null || event.height != null,
      );
      emit(currentState.copyWith(request: newRequest));
    }
  }
  
  Future<void> _onUpdateImageSize(
    UpdateImageSize event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      emit(currentState.copyWith(
        request: currentState.request.copyWith(
          imageSize: event.size,
          clearImageSize: event.size == null,
        ),
      ));
    }
  }
  
  Future<void> _onUpdateSeed(
    UpdateSeed event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      emit(currentState.copyWith(
        request: currentState.request.copyWith(seed: event.seed),
      ));
    }
  }
  
  Future<void> _onRandomizeSeed(
    RandomizeSeed event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      final randomSeed = DateTime.now().millisecondsSinceEpoch % 2147483647;
      emit(currentState.copyWith(
        request: currentState.request.copyWith(seed: randomSeed),
      ));
      add(AddLog('已生成随机种子: $randomSeed'));
    }
  }
  
  Future<void> _onStartGeneration(
    StartGeneration event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GenerationReady) return;
    
    if (!_settings.isConfigured) {
      emit(GenerationError(
        message: '请先配置API Key',
        request: currentState.request,
        logs: [...currentState.logs, '[错误] 请先配置API Key'],
      ));
      return;
    }
    
    if (currentState.request.prompt.isEmpty) {
      emit(GenerationError(
        message: '请输入提示词',
        request: currentState.request,
        logs: [...currentState.logs, '[错误] 请输入提示词'],
      ));
      return;
    }
    
    // 转换参考图片为base64
    final List<String> base64Images = [];
    for (final image in currentState.referenceImages) {
      try {
        final bytes = await image.readAsBytes();
        base64Images.add(base64Encode(bytes));
      } catch (e) {
        add(AddLog('读取图片失败: $e'));
      }
    }
    
    final request = currentState.request.copyWith(
      referenceImages: base64Images,
    );
    
    emit(GenerationInProgress(
      request: request,
      logs: [...currentState.logs, '[信息] 开始生成...'],
    ));
    
    try {
      final result = await _apiService.generateImage(
        request: request,
        settings: _settings,
        onProgress: (progress) {
          // 进度更新通过stream处理
        },
      );
      
      if (result.success && result.images.isNotEmpty) {
        // 保存历史记录
        await _settingsRepository.addGenerationHistory({
          'prompt': request.prompt,
          'timestamp': DateTime.now().toIso8601String(),
          'imageCount': result.images.length,
        });
        
        emit(GenerationSuccess(
          result: result,
          request: request,
          logs: [...currentState.logs, '[成功] 生成 ${result.images.length} 张图片'],
        ));
      } else {
        emit(GenerationError(
          message: result.errorMessage ?? '生成失败',
          request: request,
          logs: [...currentState.logs, '[错误] ${result.errorMessage ?? "生成失败"}'],
        ));
      }
    } catch (e) {
      emit(GenerationError(
        message: '生成出错: $e',
        request: request,
        logs: [...currentState.logs, '[错误] 生成出错: $e'],
      ));
    }
  }
  
  Future<void> _onCancelGeneration(
    CancelGeneration event,
    Emitter<GenerationState> emit,
  ) async {
    // 取消当前请求的实现
  }
  
  Future<void> _onSaveImage(
    SaveImage event,
    Emitter<GenerationState> emit,
  ) async {
    try {
      final path = await _saveImageToFile(event.image, event.customPath);
      if (path != null) {
        emit(ImageSaved(path));
        // 恢复到之前的状态
        final currentState = state;
        if (currentState is GenerationSuccess) {
          emit(currentState);
        }
      }
    } catch (e) {
      add(AddLog('保存图片失败: $e'));
    }
  }
  
  Future<void> _onSaveAllImages(
    SaveAllImages event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationSuccess) {
      try {
        final directory = await _getSaveDirectory(event.customPath);
        for (int i = 0; i < currentState.result.images.length; i++) {
          final image = currentState.result.images[i];
          final fileName = 'gemini_${DateTime.now().millisecondsSinceEpoch}_$i.png';
          final file = File('$directory/$fileName');
          await file.writeAsBytes(image.imageData);
        }
        emit(ImageSaved(directory, isAll: true));
        emit(currentState);
        add(AddLog('已保存所有图片到: $directory'));
      } catch (e) {
        add(AddLog('保存图片失败: $e'));
      }
    }
  }
  
  Future<void> _onClearResults(
    ClearResults event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationSuccess) {
      emit(GenerationReady(
        request: currentState.request,
        logs: currentState.logs,
        isConfigured: _settings.isConfigured,
      ));
    }
  }
  
  Future<void> _onAddLog(
    AddLog event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      emit(currentState.copyWith(
        logs: [...currentState.logs, event.message],
      ));
    } else if (currentState is GenerationInProgress) {
      emit(GenerationInProgress(
        request: currentState.request,
        progress: currentState.progress,
        logs: [...currentState.logs, event.message],
      ));
    } else if (currentState is GenerationSuccess) {
      emit(GenerationSuccess(
        result: currentState.result,
        request: currentState.request,
        logs: [...currentState.logs, event.message],
      ));
    } else if (currentState is GenerationError) {
      emit(GenerationError(
        message: currentState.message,
        request: currentState.request,
        logs: [...currentState.logs, event.message],
      ));
    }
  }
  
  Future<void> _onClearLogs(
    ClearLogs event,
    Emitter<GenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GenerationReady) {
      emit(currentState.copyWith(logs: []));
    }
  }
  
  Future<String?> _saveImageToFile(GeneratedImage image, String? customPath) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        return null;
      }
      
      final directory = await _getSaveDirectory(customPath);
      final fileName = 'gemini_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('$directory/$fileName');
      await file.writeAsBytes(image.imageData);
      
      return file.path;
    } catch (e) {
      print('保存图片失败: $e');
      return null;
    }
  }
  
  Future<String> _getSaveDirectory(String? customPath) async {
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return customPath;
    }
    
    final dir = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${dir.path}/generated_images');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return saveDir.path;
  }
}
