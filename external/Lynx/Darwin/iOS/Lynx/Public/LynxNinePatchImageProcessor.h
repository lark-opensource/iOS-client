// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxNinePatchImageProcessor : NSObject <LynxImageProcessor>

- (instancetype)initWithCapInsets:(UIEdgeInsets)capInsets;
- (instancetype)initWithCapInsets:(UIEdgeInsets)capInsets capInsetsScale:(CGFloat)capInsetsScale;

@end

NS_ASSUME_NONNULL_END
