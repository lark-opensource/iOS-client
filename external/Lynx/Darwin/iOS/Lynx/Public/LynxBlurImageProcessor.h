// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Use to process image into blurred image with given radius
 */
@interface LynxBlurImageProcessor : NSObject <LynxImageProcessor>

- (instancetype)initWithBlurRadius:(CGFloat)radius;

@end

NS_ASSUME_NONNULL_END
