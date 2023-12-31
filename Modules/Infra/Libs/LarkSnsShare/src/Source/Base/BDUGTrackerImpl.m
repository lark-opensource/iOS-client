//
//  BDUGTrackerImpl.m
//  BDUGPushDemo
//
//  Created by bytedance on 2019/6/19.
//  Copyright © 2019年 bytedance. All rights reserved.
//

#if LarkSnsShare_InternalSnsShareDependency
#import "BDUGTrackerImpl.h"
#import <BDUGContainer/BDUGContainer.h>
#import <BDUGTrackerInterface/BDUGTrackerInterface.h>
#import <BDUGMonitorInterface/BDUGMonitorInterface.h>
#import <LKLoadable/Loadable.h>

@interface BDUGTrackerImpl() <BDUGTrackerInterface, BDUGMonitorInterface>
@end

@implementation BDUGTrackerImpl

LoadableRunloopIdleFuncBegin(BDUGTrackerRegister)
BDUG_BIND_CLASS_PROTOCOL(self, BDUGTrackerInterface);
BDUG_BIND_CLASS_PROTOCOL(self, BDUGMonitorInterface);
LoadableRunloopIdleFuncEnd(BDUGTrackerRegister)

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDUGTrackerImpl *instance;
    dispatch_once(&onceToken, ^{
        instance = [[BDUGTrackerImpl alloc] init];
    });
    return instance;
}

- (void)event:(NSString *)event params:(NSDictionary * _Nullable)params {}
- (void)trackService:(NSString *)serviceName attributes:(NSDictionary *)attributes {}

@end
#endif
