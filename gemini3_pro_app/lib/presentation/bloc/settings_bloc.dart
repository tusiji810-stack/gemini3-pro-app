import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/settings_model.dart';
import '../../data/repositories/settings_repository.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateSettings extends SettingsEvent {
  final AppSettings settings;
  
  const UpdateSettings(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

class UpdateApiSettings extends SettingsEvent {
  final String? apiUrl;
  final String? apiKey;
  
  const UpdateApiSettings({this.apiUrl, this.apiKey});
  
  @override
  List<Object?> get props => [apiUrl, apiKey];
}

class UpdateDefaultParams extends SettingsEvent {
  final String? aspectRatio;
  final bool clearAspectRatio;
  final int? width;
  final bool clearWidth;
  final int? height;
  final bool clearHeight;
  final String? imageSize;
  final bool clearImageSize;
  
  const UpdateDefaultParams({
    this.aspectRatio,
    this.clearAspectRatio = false,
    this.width,
    this.clearWidth = false,
    this.height,
    this.clearHeight = false,
    this.imageSize,
    this.clearImageSize = false,
  });
  
  @override
  List<Object?> get props => [
    aspectRatio, clearAspectRatio,
    width, clearWidth,
    height, clearHeight,
    imageSize, clearImageSize,
  ];
}

class ToggleThemeMode extends SettingsEvent {
  final ThemeMode mode;
  
  const ToggleThemeMode(this.mode);
  
  @override
  List<Object?> get props => [mode];
}

class ClearSettings extends SettingsEvent {
  const ClearSettings();
}

// States
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  
  const SettingsLoaded(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;
  
  const SettingsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class SettingsSaved extends SettingsState {
  final AppSettings settings;
  
  const SettingsSaved(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;
  
  SettingsBloc(this._repository) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSettings>(_onUpdateSettings);
    on<UpdateApiSettings>(_onUpdateApiSettings);
    on<UpdateDefaultParams>(_onUpdateDefaultParams);
    on<ToggleThemeMode>(_onToggleThemeMode);
    on<ClearSettings>(_onClearSettings);
  }
  
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    
    try {
      final settings = _repository.getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('加载设置失败: $e'));
    }
  }
  
  Future<void> _onUpdateSettings(
    UpdateSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final success = await _repository.saveSettings(event.settings);
      if (success) {
        emit(SettingsSaved(event.settings));
        emit(SettingsLoaded(event.settings));
      } else {
        emit(const SettingsError('保存设置失败'));
      }
    } catch (e) {
      emit(SettingsError('保存设置失败: $e'));
    }
  }
  
  Future<void> _onUpdateApiSettings(
    UpdateApiSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final newSettings = currentState.settings.copyWith(
        apiUrl: event.apiUrl,
        apiKey: event.apiKey,
      );
      add(UpdateSettings(newSettings));
    }
  }
  
  Future<void> _onUpdateDefaultParams(
    UpdateDefaultParams event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final newSettings = currentState.settings.copyWith(
        defaultAspectRatio: event.aspectRatio,
        clearDefaultAspectRatio: event.clearAspectRatio,
        defaultWidth: event.width,
        clearDefaultWidth: event.clearWidth,
        defaultHeight: event.height,
        clearDefaultHeight: event.clearHeight,
        defaultImageSize: event.imageSize,
        clearDefaultImageSize: event.clearImageSize,
      );
      add(UpdateSettings(newSettings));
    }
  }
  
  Future<void> _onToggleThemeMode(
    ToggleThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final newSettings = currentState.settings.copyWith(
        themeMode: event.mode,
      );
      add(UpdateSettings(newSettings));
    }
  }
  
  Future<void> _onClearSettings(
    ClearSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.clearSettings();
      emit(const SettingsLoaded(AppSettings()));
    } catch (e) {
      emit(SettingsError('清除设置失败: $e'));
    }
  }
}
