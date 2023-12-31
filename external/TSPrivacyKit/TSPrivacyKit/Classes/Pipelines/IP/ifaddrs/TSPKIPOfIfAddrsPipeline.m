//
//  TSPKIPOfIfAddrsPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKIPOfIfAddrsPipeline.h"
#import <ifaddrs.h>
#import "TSPKFishhookUtils.h"
#include <BDFishhook/BDFishhook.h>

static NSString *const Getifaddrs = @"getifaddrs";

static int (*old_getifaddrs)(struct ifaddrs **) = getifaddrs;

static int tspk_new_getifaddrs(struct ifaddrs ** addrs)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKIPOfIfAddrsPipeline handleAPIAccess:Getifaddrs];
        if (result.action == TSPKResultActionFuse) {
            return -1;
        } else {
            return old_getifaddrs(addrs);
        }
    }
}

@implementation TSPKIPOfIfAddrsPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineIPOfIfAddrs;
}

+ (NSString *)dataType
{
    return TSPKDataTypeIP;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct bd_rebinding getifaddrs;
        getifaddrs.name = [Getifaddrs UTF8String];
        getifaddrs.replacement = tspk_new_getifaddrs;
        getifaddrs.replaced = (void *)&old_getifaddrs;
        struct bd_rebinding rebs[]={getifaddrs};
        tspk_rebind_symbols(rebs, 1);
    });
}

+ (NSArray<NSString *> * _Nullable)stubbedCAPIs
{
    return @[Getifaddrs];
}

+ (NSString *)stubbedClass
{
    return nil;
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
