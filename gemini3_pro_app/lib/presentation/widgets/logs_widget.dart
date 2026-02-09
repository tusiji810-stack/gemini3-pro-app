import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/generation_bloc.dart';

/// 日志组件
class LogsWidget extends StatelessWidget {
  const LogsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenerationBloc, GenerationState>(
      builder: (context, state) {
        final logs = state is GenerationReady 
            ? state.logs 
            : state is GenerationInProgress 
                ? state.logs 
                : state is GenerationSuccess 
                    ? state.logs 
                    : state is GenerationError 
                        ? state.logs 
                        : <String>[];

        if (logs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      size: 16.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '日志',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[300],
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context.read<GenerationBloc>().add(
                        const ClearLogs(),
                      ),
                      icon: Icon(
                        Icons.clear_all,
                        size: 14.sp,
                        color: Colors.grey[500],
                      ),
                      label: Text(
                        '清空',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 日志内容
              Container(
                constraints: BoxConstraints(
                  maxHeight: 120.h,
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: ListView.builder(
                  reverse: true,
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[logs.length - 1 - index];
                    final isError = log.contains('[错误]');
                    final isSuccess = log.contains('[成功]');
                    final isInfo = log.contains('[信息]');
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            margin: EdgeInsets.only(top: 6.h, right: 8.w),
                            decoration: BoxDecoration(
                              color: isError 
                                  ? Colors.red[400] 
                                  : isSuccess 
                                      ? const Color(0xFF4CAF50)
                                      : isInfo 
                                          ? Colors.blue[400]
                                          : Colors.grey[500],
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              log,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isError 
                                    ? Colors.red[300] 
                                    : isSuccess 
                                        ? const Color(0xFF81C784)
                                        : Colors.grey[300],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }
}
