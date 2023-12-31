//
//  HMDWatchdogProtectConfig.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/8.
//

#import "HMDTrackerConfig.h"

    
extern NSString * _Nullable const kHMDModuleWatchdogProtectKey; //卡死保护

@interface HMDWatchdogProtectConfig : HMDTrackerConfig

@property(nonatomic, assign)NSTimeInterval timeoutInterval;

@property(nonatomic, assign)NSTimeInterval launchThreshold;

@property(nonatomic, strong, nullable)NSArray<NSString *>* typeList;

@property(nonatomic, strong, nullable)NSArray<NSString *> *dynamicProtect;    // this mean only on main thread

@property(nonatomic, strong, nullable)NSArray<NSString *> *dynamicProtectAnyThread;

@end

