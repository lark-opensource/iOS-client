// Copyright 2022 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (BDXElementNativeView)


- (UIView *)bdx_viewWithName:(NSString *)name;

- (NSString *)bdx_nativeViewName;

- (void)setBdx_nativeViewName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
