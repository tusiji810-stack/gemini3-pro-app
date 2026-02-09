import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/generation_bloc.dart';

/// 参数配置组件 - 支持自定义宽高比和空值
class ParamsConfigWidget extends StatefulWidget {
  const ParamsConfigWidget({super.key});

  @override
  State<ParamsConfigWidget> createState() => _ParamsConfigWidgetState();
}

class _ParamsConfigWidgetState extends State<ParamsConfigWidget> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _seedController;
  
  // 是否使用自定义宽高
  bool _useCustomDimensions = false;

  // 预设的宽高比选项
  final List<String> _aspectRatios = [
    '自动',
    '1:1',
    '16:9',
    '9:16',
    '4:3',
    '3:4',
    '2:3',
    '3:2',
    '21:9',
  ];

  // 预设的图像尺寸
  final List<String> _imageSizes = [
    '自动',
    '1K',
    '2K',
    '4K',
    '8K',
  ];

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _seedController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenerationBloc, GenerationState>(
      builder: (context, state) {
        if (state is GenerationReady) {
          // 同步状态到UI
          _syncStateToUI(state);
        }
        
        final isLoading = state is GenerationInProgress;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 20.sp,
                      color: const Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '生成参数',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 宽高比选择 - 可空值
                    _buildSectionTitle('宽高比', isOptional: true),
                    SizedBox(height: 8.h),
                    
                    // 预设比例选择
                    _buildAspectRatioSelector(state, isLoading),
                    
                    SizedBox(height: 12.h),
                    
                    // 自定义尺寸开关
                    Row(
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: Checkbox(
                            value: _useCustomDimensions,
                            onChanged: isLoading 
                                ? null 
                                : (value) {
                                    setState(() {
                                      _useCustomDimensions = value ?? false;
                                    });
                                    if (!_useCustomDimensions) {
                                      // 关闭自定义时清除宽高值
                                      _widthController.clear();
                                      _heightController.clear();
                                      context.read<GenerationBloc>().add(
                                        const UpdateCustomDimensions(
                                          width: null, 
                                          height: null,
                                        ),
                                      );
                                    }
                                  },
                            activeColor: const Color(0xFF4CAF50),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '自定义宽高',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    
                    // 自定义宽高输入
                    if (_useCustomDimensions) ...[
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDimensionInput(
                              label: '宽度',
                              controller: _widthController,
                              hint: '自动',
                              isLoading: isLoading,
                              onChanged: (value) {
                                final width = int.tryParse(value);
                                context.read<GenerationBloc>().add(
                                  UpdateCustomDimensions(
                                    width: width,
                                    height: int.tryParse(_heightController.text),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              '×',
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildDimensionInput(
                              label: '高度',
                              controller: _heightController,
                              hint: '自动',
                              isLoading: isLoading,
                              onChanged: (value) {
                                final height = int.tryParse(value);
                                context.read<GenerationBloc>().add(
                                  UpdateCustomDimensions(
                                    width: int.tryParse(_widthController.text),
                                    height: height,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    SizedBox(height: 20.h),
                    
                    // 图像尺寸 - 可空值
                    _buildSectionTitle('图像尺寸', isOptional: true),
                    SizedBox(height: 8.h),
                    _buildImageSizeSelector(state, isLoading),
                    
                    SizedBox(height: 20.h),
                    
                    // 随机种子
                    _buildSectionTitle('随机种子'),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _seedController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: '0 (随机)',
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
                              final seed = int.tryParse(value) ?? 0;
                              context.read<GenerationBloc>().add(
                                UpdateSeed(seed),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        IconButton(
                          onPressed: isLoading 
                              ? null 
                              : () => context.read<GenerationBloc>().add(
                                    const RandomizeSeed(),
                                  ),
                          icon: Icon(
                            Icons.casino,
                            size: 24.sp,
                            color: isLoading 
                                ? Colors.grey[300] 
                                : const Color(0xFF4CAF50),
                          ),
                          tooltip: '随机生成',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _syncStateToUI(GenerationReady state) {
    final request = state.request;
    
    // 同步宽高状态
    final hasCustomDims = request.hasCustomDimensions;
    if (_useCustomDimensions != hasCustomDims) {
      _useCustomDimensions = hasCustomDims;
    }
    
    // 同步宽度
    if (request.customWidth != null) {
      final widthText = request.customWidth.toString();
      if (_widthController.text != widthText) {
        _widthController.text = widthText;
      }
    } else if (_widthController.text.isNotEmpty && !hasCustomDims) {
      _widthController.clear();
    }
    
    // 同步高度
    if (request.customHeight != null) {
      final heightText = request.customHeight.toString();
      if (_heightController.text != heightText) {
        _heightController.text = heightText;
      }
    } else if (_heightController.text.isNotEmpty && !hasCustomDims) {
      _heightController.clear();
    }
    
    // 同步seed
    final seedText = request.seed.toString();
    if (_seedController.text != seedText) {
      _seedController.text = seedText;
    }
  }

  Widget _buildSectionTitle(String title, {bool isOptional = false}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        if (isOptional) ...[
          SizedBox(width: 4.w),
          Text(
            '(可选)',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[400],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAspectRatioSelector(GenerationState state, bool isLoading) {
    final currentRatio = state is GenerationReady 
        ? state.request.aspectRatio 
        : null;
    
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _aspectRatios.map((ratio) {
        final isSelected = currentRatio == ratio || 
                          (ratio == '自动' && currentRatio == null);
        final isCustom = ratio == '自定义';
        
        return ChoiceChip(
          label: Text(ratio),
          selected: isSelected && !_useCustomDimensions,
          onSelected: isLoading 
              ? null 
              : (selected) {
                  if (selected) {
                    // 关闭自定义模式
                    setState(() {
                      _useCustomDimensions = false;
                    });
                    _widthController.clear();
                    _heightController.clear();
                    
                    context.read<GenerationBloc>().add(
                      UpdateAspectRatio(
                        ratio: ratio == '自动' ? null : ratio,
                      ),
                    );
                  }
                },
          selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
          backgroundColor: Colors.grey[100],
          labelStyle: TextStyle(
            fontSize: 13.sp,
            color: isSelected && !_useCustomDimensions
                ? const Color(0xFF4CAF50)
                : Colors.black87,
            fontWeight: isSelected && !_useCustomDimensions
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
            side: BorderSide(
              color: isSelected && !_useCustomDimensions
                  ? const Color(0xFF4CAF50)
                  : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageSizeSelector(GenerationState state, bool isLoading) {
    final currentSize = state is GenerationReady 
        ? state.request.imageSize 
        : null;
    
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _imageSizes.map((size) {
        final isSelected = currentSize == size || 
                          (size == '自动' && currentSize == null);
        
        return ChoiceChip(
          label: Text(size),
          selected: isSelected,
          onSelected: isLoading 
              ? null 
              : (selected) {
                  if (selected) {
                    context.read<GenerationBloc>().add(
                      UpdateImageSize(size == '自动' ? null : size),
                    );
                  }
                },
          selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
          backgroundColor: Colors.grey[100],
          labelStyle: TextStyle(
            fontSize: 13.sp,
            color: isSelected
                ? const Color(0xFF4CAF50)
                : Colors.black87,
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDimensionInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isLoading,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[400],
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
            suffixText: 'px',
            suffixStyle: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[400],
            ),
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black87,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
