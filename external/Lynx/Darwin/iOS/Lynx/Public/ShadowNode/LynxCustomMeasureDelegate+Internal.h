// Copyright 2021 The Lynx Authors. All rights reserved.

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import "LynxCustomMeasureDelegate.h"

NS_ASSUME_NONNULL_BEGIN
@interface MeasureContext ()
@property(nonatomic, readonly) CGFloat rootWidth;
@property(nonatomic, readonly) LynxMeasureMode rootWidthMode;
@property(nonatomic, readonly) CGFloat rootHeight;
@property(nonatomic, readonly) LynxMeasureMode rootHeightMode;
@property(nonatomic, readonly) BOOL finalMeasure;
@end
NS_ASSUME_NONNULL_END
