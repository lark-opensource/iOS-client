//
//  BDXBridgeEvent+Internal.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/6.
//

#import "BDXBridgeEvent+Internal.h"
#import <objc/runtime.h>

@implementation BDXBridgeEvent (Internal)

- (void)setBdx_timestamp:(NSTimeInterval)timestamp
{
    objc_setAssociatedObject(self, @selector(bdx_timestamp), @(timestamp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)bdx_timestamp
{
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)bdx_updateTimestampWithMillisecondTimestamp:(NSTimeInterval)timestamp
{
    self.bdx_timestamp = timestamp / 1000.0;
}

- (void)bdx_updateTimestampWithCurrentDate
{
    self.bdx_timestamp = [[NSDate date] timeIntervalSince1970];
}

@end
