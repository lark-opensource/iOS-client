//
//  TTDnsOuterService.m
//  TTNetworkManager
//
//  Created by xiejin.rudy on 2020/8/7.
//

#import "TTDnsQuery.h"
#import <Foundation/Foundation.h>
#import "TTNetworkManagerChromium.h"
#include "components/cronet/ios/cronet_environment.h"


@implementation TTDnsQuery

@synthesize host = _host;
@synthesize sdkId = _sdkId;
@synthesize uuid = _uuid;
@synthesize result = _result;
@synthesize semaphore = _semaphore;

- (id)initWithHost:(NSString*)host sdkId:(int)sdkId {
    self = [super init];
    if (self) {
        _host = host;
        _sdkId = sdkId;
        _uuid = [NSUUID UUID].UUIDString;
        _semaphore = dispatch_semaphore_create(0);
    }

    return self;
}

- (void)await {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
}

- (void)resume {
    dispatch_semaphore_signal(_semaphore);
}

- (void)doQuery {
    if ([[TTNetworkManager shareInstance] isKindOfClass:[TTNetworkManagerChromium class]]) {
        TTNetworkManagerChromium *ttnetworkManager = (TTNetworkManagerChromium *)[TTNetworkManager shareInstance];
        cronet::CronetEnvironment *engine = (cronet::CronetEnvironment *)ttnetworkManager.getEngine;
        if (engine) {
            engine->TTDnsResolve(base::SysNSStringToUTF8(_host), _sdkId, base::SysNSStringToUTF8(_uuid));
        }
    }
}

@end
