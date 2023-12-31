//
//  TSPKURLProtocolHooker.m
//  Musically
//
//  Created by admin on 2022/11/28.
//

#import "TSPKURLProtocolHooker.h"
#import "TSPKNetworkConfigs.h"
#import "NSObject+TSAddition.h"
#import "TSPKReporter.h"
#import "TSPKNetworkUtil.h"
#import "TSPKUploadEvent.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSBacktraceProtocol.h>

@implementation NSURLSessionTask (TSPKNetworkHooker)

+ (void)tspk_inhouse_preload {
    [self ts_swizzleInstanceMethod:@selector(resume) with:@selector(tspk_inhouse_resume)];
}

- (void)tspk_inhouse_resume {
    [TSPKURLProtocolHooker reportWithBacktrace:@"urlprotocol" url:[self currentRequest].URL];
    [self tspk_inhouse_resume];
}

@end

@implementation TSPKURLProtocolHooker

+ (void)preload {
    [NSURLSessionTask tspk_inhouse_preload];
}

@end
