// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Describe a image processor when you want to process image after image download.
 @see LynxImageLoader
 */
@protocol LynxImageProcessor <NSObject>

- (UIImage*)processImage:(UIImage*)image;

- (NSString*)cacheKey;

@end

NS_ASSUME_NONNULL_END
