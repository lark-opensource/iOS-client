//
//  BDLynxMonitorPool.m
//  IESWebViewMonitor
//
//  Created by Paklun Cheng on 2020/9/25.
//

#import "BDLynxMonitorPool.h"
#import <Lynx/LynxView.h>

@interface BDLynxMonitorWeakProxy : NSObject

@property (nonatomic, weak) LynxView *weakLynxView;

@end

@implementation BDLynxMonitorWeakProxy

@end

@interface BDLynxMonitorPool ()

@property (nonatomic, strong) NSMutableDictionary *lynxViewMap;

@end

@implementation BDLynxMonitorPool

+ (instancetype) sharedPool {
    static BDLynxMonitorPool *pool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [BDLynxMonitorPool new];
        pool.lynxViewMap = [[NSMutableDictionary alloc] init];
    });
    return pool;
}

+ (LynxView * _Nullable)lynxViewForContainerID:(NSString *)containerID
{
    BDLynxMonitorWeakProxy *obj = [BDLynxMonitorPool.sharedPool.lynxViewMap objectForKey:containerID];
    if (obj && [obj isKindOfClass:BDLynxMonitorWeakProxy.class]) {
        if (obj.weakLynxView) {
            return obj.weakLynxView;
        } else {
            [self removeforContainerID:containerID];
            return nil;
        }
    }
    return nil;
}

+ (void)setLynxView:(LynxView * _Nullable)view forContainerID:(NSString *)containerID
{
    BDLynxMonitorWeakProxy *obj = [BDLynxMonitorPool.sharedPool.lynxViewMap objectForKey:containerID];
    if (!obj) {
        obj = [[BDLynxMonitorWeakProxy alloc] init];
    }
    obj.weakLynxView = view;
    [BDLynxMonitorPool.sharedPool.lynxViewMap setObject:obj forKey:containerID];
}

+ (void)removeforContainerID:(NSString *)containerID
{
    [BDLynxMonitorPool.sharedPool.lynxViewMap removeObjectForKey:containerID];
}

@end
