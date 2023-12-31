//
//  HMDMatrixConfig.h
//  BDMemoryMatrix
//
//  Created by zhouyang11 on 2022/5/18.
//

#import <Foundation/Foundation.h>
#import <Heimdallr/HMDModuleConfig.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kHMDModuleMatrix;//线上Matrix监控

@interface HMDMatrixConfig : HMDModuleConfig

@property (nonatomic, assign) BOOL isVCLevelEnabled;
@property (nonatomic, assign) BOOL isEventTimeEnabled;
@property (nonatomic, assign) BOOL isCrashUploadEnabled;
@property (nonatomic, assign) BOOL isMemoryPressureUploadEnabled;
@property (nonatomic, assign) BOOL isWatchDogUploadEnabled;
@property (nonatomic, assign) BOOL isEnforceUploadEnabled;
@property (nonatomic, assign) BOOL isAsyncStackEnabled;
@property (nonatomic, assign) NSUInteger minGenerateMinuteInterval;//一次使用期间两次内存分析之间最小的时间间隔，默认10秒，时间+超过阈值同时满足再进行下一次分析
@property (nonatomic, assign) NSUInteger maxTimesPerDay;//一天之内对单个用户可以触发的最大次数，默认100次
@property (nonatomic, assign) NSUInteger minRemainingDiskSpaceMB; //matrix开启时，当前设备可用磁盘空间最小值，默认300M，小于该值则不开启matrix

@end

NS_ASSUME_NONNULL_END
