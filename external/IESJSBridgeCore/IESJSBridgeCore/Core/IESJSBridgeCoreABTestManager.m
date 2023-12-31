//
//  IESJSBridgeCoreABTestManager.m
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/8/21.
//

#import "IESJSBridgeCoreABTestManager.h"

@implementation IESPiperCoreABTestManager

+ (instancetype)sharedManager {
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _useBridgeEngineV2 = YES;
        _monitorJSBInvokeEvent = NO;
        _enableIFrameJSB = NO;
    }
    return self;
}

@end
