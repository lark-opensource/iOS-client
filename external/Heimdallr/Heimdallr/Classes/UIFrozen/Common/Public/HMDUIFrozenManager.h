//
//  HMDUIFrozenManager.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/24.
//

#import <Foundation/Foundation.h>


extern NSUInteger HMDUIFrozenDefaultOperationCountThreshold;
extern NSTimeInterval HMDUIFrozenDefaultLaunchCrashThreshold;
extern BOOL HMDUIFrozenDefaultUploadAlog;
extern NSUInteger HMDUIFrozenDefaultGestureCountThreshold;
extern BOOL HMDUIFrozenDefaultEnableGestureMonitor;

// App进入后台后，判断是否存在冻屏，若存在则发出此通知
// 通知的Object为多次无效操作的第一响应者View
extern NSNotificationName _Nullable const HMDUIFrozenNotificationDidEnterBackground;

// 通过Object字典对象Key
extern NSString * _Nullable const kHMDUIFrozenKeyTargetView;
extern NSString * _Nullable const kHMDUIFrozenKeyType;
extern NSString * _Nullable const kHMDUIFrozenKeyOperationCount;
extern NSString * _Nullable const kHMDUIFrozenKeyStartTimestamp;


@protocol HMDUIFrozenDetectProtocol;

@interface HMDUIFrozenManager : NSObject

+ (nonnull instancetype)sharedInstance;

// 冻屏检测是否开启
// Default: NO
@property(nonatomic, assign, readonly)BOOL enable;

//最大操作数，用户进行无效操作的次数超过此阈值则判定为冻屏
// Default: 5 Range: [1, 10]
@property(nonatomic, assign)NSUInteger operationCountThreshold;

// 启动崩溃时间阈值
// Default: 10.0 Range: [1.0, 60.0]
@property(nonatomic, assign) NSTimeInterval launchCrashThreshold;

// 在上传冻屏日志时是否同步上传Alog日志
// Default: NO
@property(nonatomic, assign)BOOL uploadAlog;

// 是否开启手势监控
// Default: NO
@property(nonatomic, assign)BOOL enableGestureMonitor;

//最大未响应手势数，业务方累计未消费的手势数量
// Default: 10 Range: [1, 20]
@property(nonatomic, assign)NSUInteger gestureCountThreshold;

@property(nonatomic, weak, nullable)id<HMDUIFrozenDetectProtocol> delegate;


- (void)start;
- (void)stop;

@end

