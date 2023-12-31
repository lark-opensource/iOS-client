// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@class LynxTextView;

@interface LynxTextOverflowLayer : CALayer

@property(nonatomic, weak) LynxTextView *view;

- (instancetype)init;
- (instancetype)initWithView:(nullable LynxTextView *)view;

@end

NS_ASSUME_NONNULL_END
