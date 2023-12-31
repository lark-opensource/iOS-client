// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxFlowerPixelBufferTransformer : NSObject

+ (UIImage *)bdx_imageFromCVPixelBufferRefForSystemPlayer:(CVPixelBufferRef)pixelBuffer;
+ (UIImage *)bdx_imageFromCVPixelBufferRefForTTPlayer:(CVPixelBufferRef)pixelBuffer;
+ (CVPixelBufferRef)bdx_pixelBufferFromImage:(UIImage *)originImage;

@end

NS_ASSUME_NONNULL_END
