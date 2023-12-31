//
//  BaseFlutterBridge.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDBaseFlutterBridge.h"
#import "BDFlutterProtocol.h"

static NSString *GLOBAL_CHANNEL_NAME = @"com.bytedance.hybrid.bridge-flutter";

@implementation BDBaseFlutterBridge

+ (NSString *)globalChannelName {
    return GLOBAL_CHANNEL_NAME;
}

+ (void)setGlobalChannelName:(NSString *)globalChannelName {
    GLOBAL_CHANNEL_NAME = globalChannelName;
}

- (instancetype)initWithFlutterAdapter:(id<FLTBMethodChannelCreator>)flutterAdapter {
    if (self = [super init]) {
        _flutterAdapter = flutterAdapter;
    }
    return self;
}

- (id<FLTBMethodChannel>)createMethodChannelForMessager:(NSObject *)messenger {
    return [self.flutterAdapter createMethodChannel:GLOBAL_CHANNEL_NAME forMessenger:messenger];
}

- (id<FLTBMethodChannel>)createMethodChannel:(NSString *)name forView:(NSObject *)messenger {
    return [self.flutterAdapter createMethodChannel:name forMessenger:messenger];
}

@end
