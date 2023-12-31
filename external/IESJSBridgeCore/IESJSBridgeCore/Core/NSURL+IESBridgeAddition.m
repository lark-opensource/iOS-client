//
//  NSURL+IESBridgeAddition.m
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/7/19.
//

#import "NSURL+IESBridgeAddition.h"

static NSString * const kPiperSchemeNativeApp = @"nativeapp";
static NSString * const kPiperSchemeByteDance = @"bytedance";

static NSArray<NSString *> *bridgeSchemes() {
    return @[kPiperSchemeNativeApp, kPiperSchemeByteDance];
}

@implementation NSURL (IESBridgeAddition)

- (BOOL)jsb_isMatchedInBridgeSchemes
{
    __block BOOL matched = NO;
    [bridgeSchemes() enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqualToString:self.scheme.lowercaseString]) {
            matched = YES;
            *stop = YES;
        }
    }];
    return matched;
}

@end
