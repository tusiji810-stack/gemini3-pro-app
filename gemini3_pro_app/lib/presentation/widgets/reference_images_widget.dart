import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/generation_bloc.dart';

/// 参考图片组件
class ReferenceImagesWidget extends StatelessWidget {
  const ReferenceImagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenerationBloc, GenerationState>(
      builder: (context, state) {
        final images = state is GenerationReady 
            ? state.referenceImages 
            : <XFile>[];
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
                      Icons.image_outlined,
                      size: 20.sp,
                      color: const Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '参考图片',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${images.length}/4',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (images.isNotEmpty)
                      TextButton.icon(
                        onPressed: isLoading 
                            ? null 
                            : () => context.read<GenerationBloc>().add(
                                  const ClearReferenceImages(),
                                ),
                        icon: Icon(Icons.delete_outline, size: 16.sp),
                        label: Text(
                          '清除全部',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[400],
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ),
              
              // 图片网格
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: [
                    // 已添加的图片
                    ...images.asMap().entries.map((entry) {
                      final index = entry.key;
                      final image = entry.value;
                      return _ImageThumbnail(
                        image: image,
                        index: index,
                        onRemove: isLoading 
                            ? null 
                            : () => context.read<GenerationBloc>().add(
                                  RemoveReferenceImage(index),
                                ),
                      );
                    }),
                    
                    // 添加按钮
                    if (images.length < 4)
                      _AddImageButton(
                        onTap: isLoading 
                            ? null 
                            : () => _showImageSourceDialog(context),
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

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '选择图片来源',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Icon(Icons.photo_library, color: const Color(0xFF4CAF50)),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: const Color(0xFF4CAF50)),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null && context.mounted) {
        context.read<GenerationBloc>().add(AddReferenceImage(image));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }
}

/// 图片缩略图
class _ImageThumbnail extends StatelessWidget {
  final XFile image;
  final int index;
  final VoidCallback? onRemove;

  const _ImageThumbnail({
    required this.image,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              width: 80.w,
              height: 80.w,
            ),
          ),
        ),
        // 序号标签
        Positioned(
          left: 4.w,
          top: 4.h,
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // 删除按钮
        Positioned(
          right: -4.w,
          top: -4.h,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.close,
                size: 12.sp,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 添加图片按钮
class _AddImageButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddImageButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 28.sp,
              color: const Color(0xFF4CAF50),
            ),
            SizedBox(height: 4.h),
            Text(
              '添加',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
