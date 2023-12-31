// Copyright 2020 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import "LynxShadowNodeStyle.h"

@interface LynxBaselineShiftLayoutManager : NSLayoutManager

- (instancetype)initWithVerticalAlign:(LynxVerticalAlign)verticalAlign;

@property(nonatomic, assign) LynxVerticalAlign verticalAlign;

@end
