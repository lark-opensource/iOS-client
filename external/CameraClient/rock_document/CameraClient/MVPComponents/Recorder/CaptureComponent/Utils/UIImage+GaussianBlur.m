//
//  UIImage+GaussianBlur.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/20.
//

#import "UIImage+GaussianBlur.h"

#import <Accelerate/Accelerate.h>
#import <CreationKitInfra/ACCLogHelper.h>

#define ACC_GAUSIAN_TO_TENT_RADIUS_RADIO 8.0

@implementation UIImage (GaussianBlur)

- (vImage_Buffer)acc_createBuffer:(CGImageRef)sourceImage
{
    vImage_Buffer srcBuffer;
    vImage_Error error;
    vImage_CGImageFormat format = {
        .bitsPerComponent = 8,
        .bitsPerPixel = 32,
        .colorSpace = NULL,
        .bitmapInfo = (CGBitmapInfo)kCGImageAlphaNoneSkipFirst,
        .version = 0,
        .decode = NULL,
        .renderingIntent = kCGRenderingIntentDefault
    };
    
    error = vImageBuffer_InitWithCGImage(&srcBuffer, &format, NULL, sourceImage, kvImageNoFlags);
    if (error != kvImageNoError) {
        AWELogToolError(AWELogToolTagNone, @"UIImage+GaussianBlur error: acc_createBuffer returned error code %zi for inputImage: %@", error, self);
    }
    return srcBuffer;
}

- (UIImage *)acc_applyGaussianBlur:(CGFloat)radius
{
    if (!self || radius < 0 || self.size.width * self.size.height == 0) {
        return nil;
    }
    
    CGImageRef sourceCgImage = self.CGImage;
    if (sourceCgImage == nil) {
        return nil;
    }
    vImage_Buffer srcBuffer = [self acc_createBuffer:sourceCgImage];
    
    void *pixelBuffer;
    size_t bufferSize = srcBuffer.rowBytes * (int)srcBuffer.height;
    if (bufferSize == 0) {
        return nil;
    }
    pixelBuffer = malloc(bufferSize);
    if(pixelBuffer == NULL) {
        return nil;
    }
    
    vImage_Buffer outputBuffer = {
        pixelBuffer,
        srcBuffer.height,
        srcBuffer.width,
        srcBuffer.rowBytes
    };
    
    int boxSize = (int)floor(radius * ACC_GAUSIAN_TO_TENT_RADIUS_RADIO);
    boxSize |= 1;
    
    vImage_Error error = vImageTentConvolve_ARGB8888(&srcBuffer, &outputBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error != kvImageNoError) {
        return nil;
    }
    
    vImage_CGImageFormat format = {
        .bitsPerComponent = 8,
        .bitsPerPixel = 32,
        .colorSpace = NULL,
        .bitmapInfo = (CGBitmapInfo)kCGImageAlphaNoneSkipFirst,
        .version = 0,
        .decode = NULL,
        .renderingIntent = kCGRenderingIntentDefault
    };
    CGImageRef resultCGImage = vImageCreateCGImageFromBuffer(&outputBuffer, &format, NULL, NULL, kvImageNoFlags, NULL);
    UIImage *resultImage = [[UIImage alloc] initWithCGImage:resultCGImage scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(resultCGImage);
    if (srcBuffer.data) {
        free(srcBuffer.data);
    }
    if (outputBuffer.data) {
        free(outputBuffer.data);
    }
    return resultImage;
}

@end
