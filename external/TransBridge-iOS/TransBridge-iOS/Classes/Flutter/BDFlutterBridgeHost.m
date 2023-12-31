//
//  FlutterBridgeHost.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDFlutterBridgeHost.h"

@interface BDFlutterBridgeHost()

@property(strong , nonatomic)id<FLTBMethodChannel> channel;

@end

@implementation BDFlutterBridgeHost

- (instancetype)initWithCarrier:(NSObject *)carrier methodChannel:(id<FLTBMethodChannel>)channel {
    if (self = [super initWithChannelCarrier:carrier]) {
        self.channel = channel;
    }
    return self;
}

- (void)sendEvent:(NSString *)name data:(NSDictionary *)data {
    if (self.channel) {
        [self.channel invokeMethod:name arguments:data];
    }
}

@end
