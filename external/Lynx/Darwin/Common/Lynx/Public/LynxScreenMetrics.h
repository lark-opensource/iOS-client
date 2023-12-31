// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXSCREENMETRICS_H_
#define DARWIN_COMMON_LYNX_LYNXSCREENMETRICS_H_

#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxScreenMetrics : NSObject
@property(nonatomic, assign, readwrite) CGSize screenSize;
@property(nonatomic, assign, readwrite) CGFloat scale;

+ (LynxScreenMetrics*)getDefaultLynxScreenMetrics;
- (instancetype)initWithScreenSize:(CGSize)screenSize scale:(CGFloat)scale;
- (void)setLynxScreenSize:(CGSize)screenSize;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_LYNXSCREENMETRICS_H_
