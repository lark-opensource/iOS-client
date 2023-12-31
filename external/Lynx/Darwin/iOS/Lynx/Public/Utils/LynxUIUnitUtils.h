//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxUIUnitUtils : NSObject

+ (CGFloat)screenScale;

+ (CGFloat)roundPtToPhysicalPixel:(CGFloat)number;

+ (void)roundRectToPhysicalPixelGrid:(CGRect*)rect;

+ (void)roundInsetsToPhysicalPixelGrid:(UIEdgeInsets*)insets;

@end

NS_ASSUME_NONNULL_END
