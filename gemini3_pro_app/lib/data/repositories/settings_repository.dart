import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings_model.dart';

/// 设置仓库
class SettingsRepository {
  static const String _settingsKey = 'app_settings';
  static const String _generationHistoryKey = 'generation_history';
  
  SharedPreferences? _prefs;
  
  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// 获取设置
  AppSettings getSettings() {
    if (_prefs == null) {
      return const AppSettings();
    }
    
    final jsonString = _prefs!.getString(_settingsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return const AppSettings();
    }
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      print('加载设置失败: $e');
      return const AppSettings();
    }
  }
  
  /// 保存设置
  Future<bool> saveSettings(AppSettings settings) async {
    if (_prefs == null) return false;
    
    try {
      final jsonString = jsonEncode(settings.toJson());
      return await _prefs!.setString(_settingsKey, jsonString);
    } catch (e) {
      print('保存设置失败: $e');
      return false;
    }
  }
  
  /// 清除设置
  Future<bool> clearSettings() async {
    if (_prefs == null) return false;
    return await _prefs!.remove(_settingsKey);
  }
  
  /// 获取API URL
  String? getApiUrl() {
    return _prefs?.getString('api_url');
  }
  
  /// 保存API URL
  Future<bool> setApiUrl(String url) async {
    if (_prefs == null) return false;
    return await _prefs!.setString('api_url', url);
  }
  
  /// 获取API Key
  String? getApiKey() {
    return _prefs?.getString('api_key');
  }
  
  /// 保存API Key
  Future<bool> setApiKey(String key) async {
    if (_prefs == null) return false;
    return await _prefs!.setString('api_key', key);
  }
  
  /// 获取生成历史
  List<Map<String, dynamic>> getGenerationHistory() {
    if (_prefs == null) return [];
    
    final jsonString = _prefs!.getString(_generationHistoryKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('加载历史失败: $e');
      return [];
    }
  }
  
  /// 添加生成历史记录
  Future<bool> addGenerationHistory(Map<String, dynamic> record) async {
    if (_prefs == null) return false;
    
    try {
      final history = getGenerationHistory();
      history.insert(0, record);
      
      // 只保留最近50条
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }
      
      final jsonString = jsonEncode(history);
      return await _prefs!.setString(_generationHistoryKey, jsonString);
    } catch (e) {
      print('保存历史失败: $e');
      return false;
    }
  }
  
  /// 清除生成历史
  Future<bool> clearGenerationHistory() async {
    if (_prefs == null) return false;
    return await _prefs!.remove(_generationHistoryKey);
  }
  
  /// 获取最近使用的提示词
  List<String> getRecentPrompts() {
    final history = getGenerationHistory();
    final prompts = <String>[];
    
    for (final record in history) {
      final prompt = record['prompt'] as String?;
      if (prompt != null && prompt.isNotEmpty && !prompts.contains(prompt)) {
        prompts.add(prompt);
        if (prompts.length >= 10) break;
      }
    }
    
    return prompts;
  }
}
