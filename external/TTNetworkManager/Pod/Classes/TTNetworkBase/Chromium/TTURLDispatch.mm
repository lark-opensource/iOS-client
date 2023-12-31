//
//  TTURLDispatch.mm
//  TTNetworkManager
//
//  Created by taoyiyuan on 2020/11/6.
//

#import "TTURLDispatch.h"

#import <Foundation/Foundation.h>

#import "TTNetworkDefine.h"
#import "TTNetworkManagerChromium.h"
#include "components/cronet/ios/cronet_environment.h"
#include "net/tt_net/route_selection/tt_net_common_tools.h"

@implementation TTURLDispatch

const int g_timout_millis = 300; // unit: millisecond
const int g_delay_timout_millis = 20; // unit: millisecond

- (id)initWithUrl:(NSString*)url requestTag:(NSString*)requestTag {
    self = [super init];
    if (self) {
        _originalUrl = url;
        _requestTag = requestTag;
        _semaphore = dispatch_semaphore_create(0);
        _delayTimeMils = -1;
    }
    
    return self;
}

- (void)await {
    // Block at most 3/10 seconds for caller thread.
    dispatch_time_t timeOut = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(g_timout_millis * NSEC_PER_MSEC));
    dispatch_semaphore_wait(_semaphore, timeOut);
}

- (void)delayAwait {
    // Block at most 2/100 seconds for caller thread.
    dispatch_time_t timeOut = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(g_delay_timout_millis * NSEC_PER_MSEC));
    dispatch_semaphore_wait(_semaphore, timeOut);
}

- (void)resume {
    dispatch_semaphore_signal(_semaphore);
}

- (void)doDispatch {
    if ([[TTNetworkManager shareInstance] isKindOfClass:[TTNetworkManagerChromium class]]) {
        void(^URLDispatchResultCallback)(const std::string& final_url,
                                         const std::string& etag,
                                         const std::string& epoch) = ^(const std::string& final_url,
                                                                       const std::string& etag,
                                                                       const std::string& epoch) {
            NSString * dispatchUrl =  [NSString stringWithUTF8String:final_url.c_str()];
            if (final_url.empty()) {
                dispatchUrl = nil;
            }
            NSString * dispatchEpoch =  [NSString stringWithUTF8String:epoch.c_str()];
            NSString * dispatchEtag =  [NSString stringWithUTF8String:etag.c_str()];
            TTDispatchResult * result = [[TTDispatchResult alloc] initWithUrl:dispatchUrl etag:dispatchEtag epoch:dispatchEpoch];
            [self setResult:result];
            [self resume];
        };
        const std::string url = CPPSTR(_originalUrl);
        scoped_refptr<net::URLDispatchByAppControl> urlDispatch =
            base::MakeRefCounted<net::URLDispatchByAppControl>(url, base::BindRepeating(URLDispatchResultCallback));
        TTNetworkManagerChromium *ttnetworkManager = (TTNetworkManagerChromium *)[TTNetworkManager shareInstance];
        cronet::CronetEnvironment *engine = (cronet::CronetEnvironment *)ttnetworkManager.getEngine;
        if (![ttnetworkManager ensureEngineStarted] && engine) {
            engine->TTURLDispatch(urlDispatch);
        }
    }
}

- (void)doDelay {
    if ([[TTNetworkManager shareInstance] isKindOfClass:[TTNetworkManagerChromium class]]) {
        void(^URLDispatchDelayCallback)(int delay) = ^(int delay) {
            [self setDelayTimeMils:delay];
            [self resume];
        };
        const std::string url = CPPSTR(_originalUrl);
        const std::string tag = CPPSTR(_requestTag);
        scoped_refptr<net::URLDispatchByAppControl> urlDispatch =
            base::MakeRefCounted<net::URLDispatchByAppControl>(url, tag, base::BindRepeating(URLDispatchDelayCallback));
        TTNetworkManagerChromium *ttnetworkManager = (TTNetworkManagerChromium *)[TTNetworkManager shareInstance];
        cronet::CronetEnvironment *engine = (cronet::CronetEnvironment *)ttnetworkManager.getEngine;
        if (![ttnetworkManager ensureEngineStarted] && engine) {
            engine->TTURLDelay(urlDispatch);
        }
    }
}

@end
