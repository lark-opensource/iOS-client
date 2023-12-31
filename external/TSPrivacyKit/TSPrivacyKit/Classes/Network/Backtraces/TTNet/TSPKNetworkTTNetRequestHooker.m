//
//  TSPKNetworkTTNetRequestHooker.m
//  Musically
//
//  Created by admin on 2022/11/25.
//

#import "TSPKNetworkTTNetRequestHooker.h"
#import "TSPKNetworkConfigs.h"
#import "NSObject+TSAddition.h"
#import "TSPKNetworkUtil.h"
#import "TSPKReporter.h"
#import "TSPKUploadEvent.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSBacktraceProtocol.h>

@implementation TTHttpTask (TSPKNetworkHooker)

+ (void)tspk_network_preload:(Class)clz {
    [clz ts_swizzleInstanceMethod:@selector(resume) with:@selector(tspk_network_resume)];
}

- (void)tspk_network_resume {
    [TSPKNetworkTTNetRequestHooker reportWithBacktrace:@"ttnet" url:[self request].URL];
    [self tspk_network_resume];
}

@end

@implementation TSPKNetworkTTNetRequestHooker

+ (void)preload {
    Class clz = NSClassFromString(@"TTHttpTaskChromium");
    if (clz) {
        [TTHttpTask tspk_network_preload:clz];
    }
}    

@end
