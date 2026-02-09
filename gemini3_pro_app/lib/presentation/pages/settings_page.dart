import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/settings_bloc.dart';
import '../../data/models/settings_model.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '设置',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is! SettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = state.settings;

          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              // API配置
              _buildSectionHeader('API配置'),
              _buildApiSettingsCard(settings),
              
              // 默认参数
              _buildSectionHeader('默认生成参数'),
              _buildDefaultParamsCard(settings),
              
              // 外观设置
              _buildSectionHeader('外观'),
              _buildAppearanceCard(settings),
              
              // 关于
              _buildSectionHeader('关于'),
              _buildAboutCard(),
              
              SizedBox(height: 32.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildApiSettingsCard(AppSettings settings) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.link, color: Colors.grey[600]),
            title: Text(
              'API地址',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              settings.apiUrl,
              style: TextStyle(fontSize: 12.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _showEditApiUrlDialog(settings),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.vpn_key, color: Colors.grey[600]),
            title: Text(
              'API Key',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              settings.apiKey.isEmpty ? '未配置' : '••••••••${settings.apiKey.substring(settings.apiKey.length > 8 ? settings.apiKey.length - 8 : 0)}',
              style: TextStyle(fontSize: 12.sp),
            ),
            trailing: settings.apiKey.isNotEmpty
                ? Icon(Icons.check_circle, color: const Color(0xFF4CAF50))
                : Icon(Icons.warning, color: Colors.orange),
            onTap: () => _showEditApiKeyDialog(settings),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultParamsCard(AppSettings settings) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.aspect_ratio, color: Colors.grey[600]),
            title: Text(
              '默认宽高比',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              settings.defaultAspectRatio ?? '自动',
              style: TextStyle(fontSize: 12.sp),
            ),
            onTap: () => _showSelectDefaultAspectRatioDialog(settings),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.photo_size_select_large, color: Colors.grey[600]),
            title: Text(
              '默认图像尺寸',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              settings.defaultImageSize ?? '自动',
              style: TextStyle(fontSize: 12.sp),
            ),
            onTap: () => _showSelectDefaultSizeDialog(settings),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.folder_open, color: Colors.grey[600]),
            title: Text(
              '默认保存路径',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              settings.savePath ?? '应用文档目录',
              style: TextStyle(fontSize: 12.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(AppSettings settings) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.brightness_medium, color: Colors.grey[600]),
            title: Text(
              '主题模式',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              _getThemeModeText(settings.themeMode),
              style: TextStyle(fontSize: 12.sp),
            ),
            onTap: () => _showSelectThemeDialog(settings),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(Icons.terminal, color: Colors.grey[600]),
            title: Text(
              '显示日志',
              style: TextStyle(fontSize: 15.sp),
            ),
            value: settings.showLogs,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                UpdateSettings(settings.copyWith(showLogs: value)),
              );
            },
            activeColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey[600]),
            title: Text(
              '版本',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              '1.0.0',
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.code, color: Colors.grey[600]),
            title: Text(
              '开源协议',
              style: TextStyle(fontSize: 15.sp),
            ),
            onTap: () {
              showLicensePage(context: context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red[400]),
            title: Text(
              '清除所有数据',
              style: TextStyle(fontSize: 15.sp, color: Colors.red[400]),
            ),
            onTap: () => _showClearDataDialog(),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showEditApiUrlDialog(AppSettings settings) {
    final controller = TextEditingController(text: settings.apiUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑API地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入API地址',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(
                UpdateApiSettings(apiUrl: controller.text),
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showEditApiKeyDialog(AppSettings settings) {
    final controller = TextEditingController(text: settings.apiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑API Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '输入API Key',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(
                UpdateApiSettings(apiKey: controller.text),
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showSelectDefaultAspectRatioDialog(AppSettings settings) {
    final ratios = ['自动', '1:1', '16:9', '9:16', '4:3', '3:4', '2:3', '3:2', '21:9'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择默认宽高比'),
        children: ratios.map((ratio) {
          final isSelected = (settings.defaultAspectRatio == null && ratio == '自动') ||
                            settings.defaultAspectRatio == ratio;
          return SimpleDialogOption(
            onPressed: () {
              context.read<SettingsBloc>().add(
                UpdateDefaultParams(
                  aspectRatio: ratio == '自动' ? null : ratio,
                  clearAspectRatio: ratio == '自动',
                ),
              );
              Navigator.pop(context);
            },
            child: Row(
              children: [
                if (isSelected)
                  Icon(Icons.check, color: const Color(0xFF4CAF50), size: 20.sp),
                if (isSelected) SizedBox(width: 8.w),
                Text(ratio),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showSelectDefaultSizeDialog(AppSettings settings) {
    final sizes = ['自动', '1K', '2K', '4K', '8K'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择默认图像尺寸'),
        children: sizes.map((size) {
          final isSelected = (settings.defaultImageSize == null && size == '自动') ||
                            settings.defaultImageSize == size;
          return SimpleDialogOption(
            onPressed: () {
              context.read<SettingsBloc>().add(
                UpdateDefaultParams(
                  imageSize: size == '自动' ? null : size,
                  clearImageSize: size == '自动',
                ),
              );
              Navigator.pop(context);
            },
            child: Row(
              children: [
                if (isSelected)
                  Icon(Icons.check, color: const Color(0xFF4CAF50), size: 20.sp),
                if (isSelected) SizedBox(width: 8.w),
                Text(size),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showSelectThemeDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择主题模式'),
        children: ThemeMode.values.map((mode) {
          final isSelected = settings.themeMode == mode;
          return SimpleDialogOption(
            onPressed: () {
              context.read<SettingsBloc>().add(ToggleThemeMode(mode));
              Navigator.pop(context);
            },
            child: Row(
              children: [
                if (isSelected)
                  Icon(Icons.check, color: const Color(0xFF4CAF50), size: 20.sp),
                if (isSelected) SizedBox(width: 8.w),
                Text(_getThemeModeText(mode)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('这将清除所有设置和历史记录，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(const ClearSettings());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('所有数据已清除')),
              );
            },
            child: Text(
              '清除',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }
}
