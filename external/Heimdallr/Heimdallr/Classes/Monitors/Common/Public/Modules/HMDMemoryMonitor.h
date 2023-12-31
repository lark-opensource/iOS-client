//
//  HMDMemoryMonitor.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDMonitor.h"

typedef NS_OPTIONS(NSUInteger, HMDMemoryStatusType) {
    HMDMemoryStatusTypeDefault = 1 << 0,             // normal type, scene udpate or timer trigger
    HMDMemoryStatusTypeNormalLevel = 1 << 1,          // APP memory usage drop to the nromal level
    HMDMemoryStatusTypeHighWater = 1 << 2,          // APP memory usage exceed the highWater value set through HMDMemoryMonitorConfig
    
    HMDMemoryStatusTypeSystemWarning = 1 << 3,      // did receive memory warning
    
    HMDMemoryStatusTypeMemoryPressure2 = 1 << 4,    // recive memory pressure warning
    HMDMemoryStatusTypeMemoryPressure4 = 1 << 5,
    HMDMemoryStatusTypeMemoryPressure8 = 1 << 6,
    HMDMemoryStatusTypeMemoryPressure16 = 1 << 7,
    HMDMemoryStatusTypeMemoryPressure32 = 1 << 8
};

// memory pressure mask
#define HMDMemoryStatusWarningMask (HMDMemoryStatusTypeSystemWarning|HMDMemoryStatusTypeMemoryPressure2|HMDMemoryStatusTypeMemoryPressure4|HMDMemoryStatusTypeMemoryPressure8|HMDMemoryStatusTypeMemoryPressure16|HMDMemoryStatusTypeMemoryPressure32)

extern NSString * _Nonnull const kHMDModuleMemoryMonitor;//内存监控
extern NSString * _Nonnull const KHMDMemoryMonitorMemoryWarningNotificationName;//内存监控的通知

@interface HMDMemoryMonitorConfig : HMDMonitorConfig
@property (nonatomic, assign) BOOL enableNotify;
@property (nonatomic, assign) NSUInteger notifyMinInterval;
@property (nonatomic, assign) CGFloat highWaterPercentage;
@end

@interface HMDMemoryMonitor : HMDMonitor

- (nonnull instancetype)init __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));
+ (nonnull instancetype)new __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));

/// 业务方自定义内存日志打点。identifier需保持一致
- (void)customTrackBeginWithIdentifier:(NSString*_Nonnull)identifier;
- (void)customTrackEndWithIdentifier:(NSString*_Nonnull)identifier;

@end
