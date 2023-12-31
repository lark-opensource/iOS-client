//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxUIUnitUtils.h"
#import <UIKit/UIKit.h>

@implementation LynxUIUnitUtils

+ (CGFloat)screenScale {
  static CGFloat __scale = 0.0;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    CGContextRef oldCtx = UIGraphicsGetCurrentContext();
    if (oldCtx) {
      UIGraphicsPushContext(oldCtx);
    }
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), YES, 0);
    __scale = CGContextGetCTM(UIGraphicsGetCurrentContext()).a;
    UIGraphicsEndImageContext();
    if (oldCtx) {
      UIGraphicsPopContext();
    }
  });
  return __scale;
}

// The function is needed here to avoid the loss of precision which may be caused by float
// calculation.
+ (void)roundToPhysicalPixel:(CGFloat*)number {
  CGFloat scale = [UIScreen mainScreen].scale;
  *number = round(*number * scale) / scale;
}

+ (void)roundRectToPhysicalPixelGrid:(CGRect*)rect {
  [LynxUIUnitUtils roundToPhysicalPixel:&(rect->origin.x)];
  [LynxUIUnitUtils roundToPhysicalPixel:&(rect->origin.y)];
  [LynxUIUnitUtils roundToPhysicalPixel:&(rect->size.width)];
  [LynxUIUnitUtils roundToPhysicalPixel:&(rect->size.height)];
}

+ (void)roundInsetsToPhysicalPixelGrid:(UIEdgeInsets*)insets {
  [LynxUIUnitUtils roundToPhysicalPixel:&(insets->top)];
  [LynxUIUnitUtils roundToPhysicalPixel:&(insets->left)];
  [LynxUIUnitUtils roundToPhysicalPixel:&(insets->bottom)];
  [LynxUIUnitUtils roundToPhysicalPixel:&(insets->right)];
}

+ (CGFloat)roundPtToPhysicalPixel:(CGFloat)number {
  CGFloat scale = [UIScreen mainScreen].scale;
  return round(number * scale) / scale;
}

@end
