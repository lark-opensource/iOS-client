//
//  OPJSEngineUtilsService.m
//  TTMicroApp
//
//  Created by yi on 2021/12/23.
//

#import "OPJSEngineUtilsService.h"
#import <OPFoundation/BDPUtils.h>
#import <OPJSEngine/JSValue+BDPExtension.h>
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPSDKConfig.h>
#import "OPMicroAppJSRuntime.h"
#import <OPFoundation/EEFeatureGating.h>

@interface OPJSEngineUtilsService ()
@end
@implementation OPJSEngineUtilsService

- (void)executeOnMainQueue:(void (^ _Nullable)(void))block {
    BDPExecuteOnMainQueue(block);
}

- (void)executeOnMainQueueSync:(void (^ _Nullable)(void))block {
    BDPExecuteOnMainQueueSync(block);
}

- (NSDictionary * _Nullable)convertJSValueToObject:(JSValue * _Nonnull)jsValue {
    return [jsValue bdp_object];
}

- (NSNotificationName _Nullable)reachabilityChangedNotification {
    return BDPNetworking.reachabilityChangedNotification;
}

- (BOOL)currentNetworkConnected {
    return BDPCurrentNetworkConnected();
}

- (NSString * _Nonnull)currentNetworkType {
    return BDPCurrentNetworkType();
}

- (BOOL)shouldUseNewBridge {
    return BDPSDKConfig.sharedConfig.shouldUseNewBridge;
}

- (void (^ _Nullable)(void))convertTracingBlock:(void (^ _Nullable)(void))block {
    return [BDPTracingManager convertTracingBlock:block];
}

- (OPRuntimeType)debugRuntimeType {
    return BDPSDKConfig.sharedConfig.debugRuntimeType;
}

@end
