//
//  BridgeHost.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDBridgeHost.h"
#import "BDBridgeModuleManager.h"

@interface BDBridgeHost()

@property(weak , nonatomic)NSObject *channelCarrier;

@end

@implementation BDBridgeHost

- (instancetype)initWithChannelCarrier:(NSObject *)carrier {
    if (self = [super init]) {
        self.channelCarrier = carrier;
    }
    return self;
}

#pragma mark - Public

+ (void)addHost:(id<BDBridgeHost>)host {
    if (host) {
        [[BDBridgeModuleManager sharedManager] addModule:host key:self.class carrier:host.channelCarrier];
    }
}

+ (id<BDBridgeHost>)getHostByCarrier:(NSObject *)carrier {
    id<BDBridgeHost> host = [[BDBridgeModuleManager sharedManager] getModule:self.class carrier:carrier];
    return host;
}


+ (void)sendEvent:(NSString *)name data:(NSDictionary *)data forCarrie:(NSObject *)carrier {
    id<BDBridgeHost> host = [self getHostByCarrier:carrier];
    if (host) {
        [host sendEvent:name data:data];
    }
}

#pragma mark - IBridgeHost

- (void)sendEvent:(nonnull NSString *)name data:(nonnull NSDictionary *)data {
    [[BDBridgeHost getHostByCarrier:self.channelCarrier] sendEvent:name data:data];
}

@end
