// Copyright 2019 The Lynx Authors. All rights reserved.
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import "LynxCSSType.h"

@interface LynxLayoutStyle : NSObject

- (instancetype)initWithNativePtr:(int64_t)ptr;
- (LynxFlexDirection)flexDirection;

// Now only supports computed length, length with auto and percentage will be 0
- (CGFloat)computedMarginLeft;
- (CGFloat)computedMarginRight;
- (CGFloat)computedMarginTop;
- (CGFloat)computedMarginBottom;
- (CGFloat)computedPaddingLeft;
- (CGFloat)computedPaddingRight;
- (CGFloat)computedPaddingTop;
- (CGFloat)computedPaddingBottom;
- (CGFloat)computedWidth;
- (CGFloat)computedHeight;

@end
