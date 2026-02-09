import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/generation_bloc.dart';
import '../bloc/settings_bloc.dart';

/// API配置组件 (可折叠)
class ApiConfigWidget extends StatefulWidget {
  const ApiConfigWidget({super.key});

  @override
  State<ApiConfigWidget> createState() => _ApiConfigWidgetState();
}

class _ApiConfigWidgetState extends State<ApiConfigWidget> {
  bool _isExpanded = false;
  bool _showApiKey = false;
  late TextEditingController _urlController;
  late TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _keyController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        // 同步设置到控制器
        if (settingsState is SettingsLoaded) {
          final settings = settingsState.settings;
          if (_urlController.text != settings.apiUrl) {
            _urlController.text = settings.apiUrl;
          }
          if (_keyController.text != settings.apiKey) {
            _keyController.text = settings.apiKey;
          }
        }

        final isConfigured = settingsState is SettingsLoaded && 
                            settingsState.settings.isConfigured;

        return BlocBuilder<GenerationBloc, GenerationState>(
          builder: (context, genState) {
            final isLoading = genState is GenerationInProgress;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ExpansionTile(
                initiallyExpanded: _isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isExpanded = expanded;
                  });
                },
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                childrenPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.vpn_key_outlined,
                  size: 20.sp,
                  color: isConfigured 
                      ? const Color(0xFF4CAF50) 
                      : Colors.orange,
                ),
                title: Row(
                  children: [
                    Text(
                      'API配置',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (isConfigured)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w, 
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '已配置',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w, 
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '未配置',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Icon(
                  _isExpanded 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[400],
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // API地址
                        _buildSectionTitle('API地址'),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: _urlController,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            hintText: '输入API地址',
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[400],
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black87,
                          ),
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                              UpdateApiSettings(apiUrl: value),
                            );
                          },
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // API Key
                        _buildSectionTitle('API Key'),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: _keyController,
                          enabled: !isLoading,
                          obscureText: !_showApiKey,
                          decoration: InputDecoration(
                            hintText: '输入API Key',
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[400],
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _showApiKey = !_showApiKey;
                                });
                              },
                              icon: Icon(
                                _showApiKey 
                                    ? Icons.visibility_off 
                                    : Icons.visibility,
                                size: 20.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black87,
                          ),
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                              UpdateApiSettings(apiKey: value),
                            );
                            // 同时更新GenerationBloc的配置状态
                            context.read<GenerationBloc>().add(
                              const InitializeGeneration(),
                            );
                          },
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // 操作按钮
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isLoading 
                                    ? null 
                                    : () {
                                        final settingsBloc = context.read<SettingsBloc>();
                                        if (settingsState is SettingsLoaded) {
                                          settingsBloc.add(UpdateSettings(
                                            settingsState.settings,
                                          ));
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('配置已保存'),
                                            backgroundColor: Color(0xFF4CAF50),
                                          ),
                                        );
                                      },
                                icon: Icon(Icons.save, size: 18.sp),
                                label: const Text('保存配置'),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}
