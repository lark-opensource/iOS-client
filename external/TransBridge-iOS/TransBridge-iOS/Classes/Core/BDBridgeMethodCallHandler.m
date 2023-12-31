//
//  BridgeMethodCallHandler.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/5.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDBridgeMethodCallHandler.h"

@interface BDBridgeMethodCallHandler()

@property (weak , nonatomic) UIView *host;
@property (weak , nonatomic) id<BDBridgeCall> bridge;

@end

@implementation BDBridgeMethodCallHandler

- (instancetype)initWithBridgeCall:(id<BDBridgeCall>)bridge onHostView:(UIView *)host {
    if (self = [super init]) {
        _host = host;
        _bridge = bridge;
    }
    return self;
}

- (void)call:(NSString *)name arguments:(id)arguments forMessager:(NSObject *)messenger completion:(FLTBResponseCallback)callback {
    [self.bridge call:name arguments:arguments forMessager:messenger completion:callback];
}

@end
