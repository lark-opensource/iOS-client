//
//  HMDUIFrozenConfig.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/24.
//

#import "HMDTrackerConfig.h"


extern NSString *const kHMDModuleUIFrozenKey; //冻屏监控

@interface HMDUIFrozenConfig : HMDTrackerConfig

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

@end

