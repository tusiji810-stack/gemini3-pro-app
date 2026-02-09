import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/generation_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/prompt_input_widget.dart';
import '../widgets/reference_images_widget.dart';
import '../widgets/params_config_widget.dart';
import '../widgets/api_config_widget.dart';
import '../widgets/generation_button_widget.dart';
import '../widgets/logs_widget.dart';
import '../widgets/results_widget.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<GenerationBloc>().add(const InitializeGeneration());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: const Color(0xFF4CAF50),
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Gemini 3 Pro',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              final isConfigured = state is SettingsLoaded && state.settings.isConfigured;
              return Container(
                margin: EdgeInsets.only(right: 8.w),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.settings,
                        size: 24.sp,
                        color: Colors.black54,
                      ),
                      if (!isConfigured)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<GenerationBloc, GenerationState>(
        listenWhen: (previous, current) =>
            current is GenerationError || current is ImageSaved,
        listener: (context, state) {
          if (state is GenerationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ImageSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.isAll 
                    ? '所有图片已保存到: ${state.path}' 
                    : '图片已保存: ${state.path}'),
                backgroundColor: const Color(0xFF4CAF50),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: BlocBuilder<GenerationBloc, GenerationState>(
            builder: (context, state) {
              if (state is GenerationSuccess) {
                return const ResultsWidget();
              }
              
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 提示词输入
                      const PromptInputWidget(),
                      SizedBox(height: 16.h),
                      
                      // 参考图片
                      const ReferenceImagesWidget(),
                      SizedBox(height: 16.h),
                      
                      // 参数配置
                      const ParamsConfigWidget(),
                      SizedBox(height: 16.h),
                      
                      // API配置 (折叠卡片)
                      const ApiConfigWidget(),
                      SizedBox(height: 16.h),
                      
                      // 日志区域
                      const LogsWidget(),
                      SizedBox(height: 100.h), // 为底部按钮留空间
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const GenerationButtonWidget(),
    );
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenerationBloc, GenerationState>(
      builder: (context, state) {
        if (state is GenerationSuccess) {
          return const ResultsWidget();
        }
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 提示词输入
                const PromptInputWidget(),
                SizedBox(height: 16.h),
                
                // 参考图片
                const ReferenceImagesWidget(),
                SizedBox(height: 16.h),
                
                // 参数配置
                const ParamsConfigWidget(),
                SizedBox(height: 16.h),
                
                // API配置 (折叠卡片)
                const ApiConfigWidget(),
                SizedBox(height: 16.h),
                
                // 日志区域
                const LogsWidget(),
                SizedBox(height: 100.h), // 为底部按钮留空间
              ],
            ),
          ),
        );
      },
    );
  }
}
