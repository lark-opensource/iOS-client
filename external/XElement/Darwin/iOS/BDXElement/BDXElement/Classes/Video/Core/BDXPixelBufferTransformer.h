//
//  BDXPixelBufferTransformer.h
//  BDXElement
//
//  Created by bill on 2020/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXPixelBufferTransformer : NSObject

+ (UIImage *)bdx_imageFromCVPixelBufferRefForSystemPlayer:(CVPixelBufferRef)pixelBuffer;
+ (UIImage *)bdx_imageFromCVPixelBufferRefForTTPlayer:(CVPixelBufferRef)pixelBuffer;
+ (CVPixelBufferRef)bdx_pixelBufferFromImage:(UIImage *)originImage;

@end

NS_ASSUME_NONNULL_END
