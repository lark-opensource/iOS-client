//
//  WaterMarkView+Remote.m
//  LarkWaterMark
//
//  Created by AlbertSun on 2023/9/22.
//

#import "WaterMarkView+Remote.h"
#import "LarkWaterMark/LarkWaterMark-Swift.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <LKLoadable/Loadable.h>

@interface WaterMarkLayer (Remote)

@end

@implementation WaterMarkLayer (Remote)

- (bool)watermark_allowsHitTesting {
    return NO;
}

+ (void)replaceAllowsHitTestingMethod {
    [WaterMarkLayer btd_swizzleInstanceMethod:NSSelectorFromString(@"allowsHitTesting")
                                         with:@selector(watermark_allowsHitTesting)];
}

@end

LoadableRunloopIdleFuncBegin(WaterMarkView_Remote)

if ([WaterMarkSwiftFGManager isWatermarkHitTestFGOn]) {
    [WaterMarkLayer replaceAllowsHitTestingMethod];
}

LoadableRunloopIdleFuncEnd(WaterMarkView_Remote)
