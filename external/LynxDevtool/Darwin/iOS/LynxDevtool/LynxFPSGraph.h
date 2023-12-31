// Copyright 2021 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>

@interface LynxFPSGraph : UIView

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color;

- (void)onTick:(NSTimeInterval)timestamp;

@end
