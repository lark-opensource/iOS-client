//
//  FlutterMethodCallHandler.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/7.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDFlutterMethodCallHandler.h"
#import "BDFlutterMethodManager.h"
#import "BDFlutterBridgeContext.h"

@implementation BDFlutterMethodCallHandler

- (void)call:(NSString *)name arguments:(id)arguments forMessager:(NSObject *)messenger completion:( FLTBResponseCallback)callback {
    BDFlutterBridgeContext *context = [[BDFlutterBridgeContext alloc] initWithMessage:messenger];
    [[BDFlutterMethodManager sharedManager] callMethod:name argument:arguments callback:callback inContext:context];
}

@end
