//
//  OPGadgetPluginImpl.m
//  EEMicroAppSDK
//
//  Created by justin on 2023/1/3.
//

#import "OPGadgetPluginImpl.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/BDPWarmBootManager.h>

@implementation OPGadgetPluginImpl

+ (id<OPGadgetPluginDelegate>)sharedPlugin {
    static OPGadgetPluginImpl *gadgetImpl = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gadgetImpl = [[OPGadgetPluginImpl alloc] init];
    });
    return gadgetImpl;
}

+ (NSString *)blockIDWithID:(OPAppUniqueID *)uniqueID {
    return uniqueID.blockID;
}

+ (NSString *)hostWithID:(OPAppUniqueID *)uniqueID {
    return uniqueID.host;
}

+ (NSString * _Nullable)packageVersionWithID:(OPAppUniqueID *)uniqueID {
    return uniqueID.packageVersion;
}

+ (id<OPTraceProtocol> _Nullable)blockTraceWithID:(OPAppUniqueID *)uniqueID {
    return uniqueID.blockTrace;
}

+ (BOOL)enablePrehandle {
    //BDPPreloadHelper.preHandleEnable()
    return [BDPPreloadHelper preHandleEnable];
}

// From: BDPTimorClient 的 onMaxBootCacheCountChanged 实现
+ (void)updateMaxWarmBootCacheCount:(int)maxCount {
    [[BDPWarmBootManager sharedManager] updateMaxWarmBootCacheCount:maxCount];
}

@end
