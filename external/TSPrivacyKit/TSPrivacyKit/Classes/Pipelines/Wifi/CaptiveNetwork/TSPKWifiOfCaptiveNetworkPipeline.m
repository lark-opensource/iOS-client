//
//  TSPKWifiOfSystemConfigurationPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKWifiOfCaptiveNetworkPipeline.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#include <BDFishhook/BDFishhook.h>
#import "TSPKFishhookUtils.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"

static NSString *const copyCurrentNetworkInfo = @"CNCopyCurrentNetworkInfo";

static CFDictionaryRef (*old_CNCopyCurrentNetworkInfo)(CFStringRef interfaceName) = CNCopyCurrentNetworkInfo;

static CFDictionaryRef tspk_new_CNCopyCurrentNetworkInfo(CFStringRef interfaceName)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKWifiOfCaptiveNetworkPipeline handleAPIAccess:copyCurrentNetworkInfo];
        
        if (result.action == TSPKResultActionFuse) {
            return NULL;
        } else if (result.action == TSPKResultActionCache) {
            NSString *api = copyCurrentNetworkInfo;
            if (!result.cacheNeedUpdate) {
                return (__bridge CFDictionaryRef)[[TSPKCacheEnv shareEnv] get:api];
            }
            CFDictionaryRef originResult = old_CNCopyCurrentNetworkInfo(interfaceName);
            [[TSPKCacheEnv shareEnv] updateCache:api newValue:(__bridge NSDictionary*)originResult];
            return originResult;
        } else {
            return old_CNCopyCurrentNetworkInfo(interfaceName);
        }
    }
}

@implementation TSPKWifiOfCaptiveNetworkPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineWifiOfCaptiveNetwork;
}

+ (NSString *)dataType {
    return TSPKDataTypeWifi;
}

+ (NSArray<NSString *> * _Nullable)stubbedCAPIs
{
    return @[copyCurrentNetworkInfo];
}

+ (NSString *)stubbedClass
{
    return nil;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct bd_rebinding copyNetwork;
        copyNetwork.name = [copyCurrentNetworkInfo UTF8String];
        copyNetwork.replacement = tspk_new_CNCopyCurrentNetworkInfo;
        copyNetwork.replaced = (void *)&old_CNCopyCurrentNetworkInfo;

        struct bd_rebinding rebs[]={copyNetwork};
        tspk_rebind_symbols(rebs, 1);
    });
}

+ (BOOL)isEntryDefaultEnable
{
    return NO;
}

- (BOOL)deferPreload
{
    return YES;
}

@end
