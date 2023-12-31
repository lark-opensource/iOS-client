//
//  OPPerformanceUtil.h
//  OPSDK
//
//  Created by 尹清正 on 2021/3/29.
//  File copy from EEMicroAppSDK>EMAPerformanceUtil.h (origin author: yinyuan.0@bytedance.com)

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 代码拷贝于EEMicroAppSDK中的EMAPerformanceUtil，只添加部分注释，未修改逻辑
@interface OPPerformanceUtil : NSObject

/// 开启FPS检测
+ (void)runFPSMonitor;
/// 停止FPS检测
+ (void)stopFPSMonitor;
/// 获取当前帧率，只有在FPS检测开启状态下才有值
+ (float)fps;
/// 当前应用使用的内存，以MB为单位
+ (float)usedMemoryInMB;
/// 当前CPU的占用率
+ (float)cpuUsage;

+ (float)availableMemory;

@end

NS_ASSUME_NONNULL_END
