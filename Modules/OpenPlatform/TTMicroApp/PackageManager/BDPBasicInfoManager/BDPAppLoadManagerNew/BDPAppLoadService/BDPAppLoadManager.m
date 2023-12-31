//
//  BDPAppLoaderManager.m
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import "BDPAppLoadManager+Private.h"
#import <OPFoundation/BDPModuleManager.h>
#import "BDPStorageManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <LKLoadable/Loadable.h>

// 记录飞书冷启动开始时间
static NSTimeInterval gLarkAppColdLaunchTime;
LoadableMainFuncBegin(EMAAppDelegateGetAppLaunchTime)
gLarkAppColdLaunchTime = NSDate.date.timeIntervalSince1970;
LoadableMainFuncEnd(EMAAppDelegateGetAppLaunchTime)

NSTimeInterval BDPLarkColdLaunchTime(void) {
    return gLarkAppColdLaunchTime;
}

@implementation BDPAppLoadManager

static BDPAppLoadManager *manager = nil;
+ (instancetype)shareService {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BDPAppLoadManager alloc] init];
        manager.loader = BDPGetResolvedModule(CommonAppLoadProtocol, BDPTypeNativeApp);
        manager.serialQueue = dispatch_queue_create("com.bytedance.timor.BDPAppLoadManager.serialQueue", NULL);
        dispatch_queue_set_specific(manager.serialQueue,
                                    (__bridge void *)[self class],
                                    (__bridge void *)manager.serialQueue,
                                    NULL);
    });
    return manager;
}

@end
