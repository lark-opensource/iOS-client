//
//  HMDMonitorCurve+Private.h
//  Heimdallr-a8835012
//
//  Created by bytedance on 2022/9/30.
//

#import "HMDMonitorCurve.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDMonitorCurve (Private)

- (void)asyncActionOnCurveQueue:(dispatch_block_t)action;

@end

NS_ASSUME_NONNULL_END
