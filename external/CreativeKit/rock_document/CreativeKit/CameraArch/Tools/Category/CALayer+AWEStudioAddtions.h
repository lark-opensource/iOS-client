//
//  CALayer+AWEStudioAddtions.h
//  AWEStudio
//
//  Created by Hao Yipeng on 2018/4/13.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

extern NSString * const AWECAlayerRotationKey;

@interface CALayer (AWEStudioAddtions)

+ (CAShapeLayer *)acc_topLeftRightRoundedLayerWithRect:(CGRect)rect;

- (void)acc_addRotateAnimation;

- (void)acc_fadeShow;

- (void)acc_fadeHidden;

- (void)acc_fadeShowWithDuration:(NSTimeInterval)duration;

- (void)acc_fadeHiddenDuration:(NSTimeInterval)duration;

- (void)acc_fadeShow:(BOOL)show duration:(NSTimeInterval)duration;

@end
