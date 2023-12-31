//
//  BDXPixelBufferTransformer.m
//  BDXElement
//
//  Created by bill on 2020/3/25.
//

#import "BDXPixelBufferTransformer.h"

@implementation BDXPixelBufferTransformer

+ (UIImage *)bdx_imageFromCVPixelBufferRefForTTPlayer:(CVPixelBufferRef)pixelBuffer
{
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
    UIImage *image = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    CVPixelBufferRelease(pixelBuffer);
    return image;
}

+ (UIImage *)bdx_imageFromCVPixelBufferRefForSystemPlayer:(CVPixelBufferRef)pixelBuffer
{
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    size_t bytePerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t bitPerCompoment = 8;
    size_t bitPerPixel = 4 * bitPerCompoment;
    size_t length = CVPixelBufferGetDataSize(pixelBuffer);
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    unsigned char *imageData = (unsigned char *)malloc(length);
    memcpy(imageData, baseAddress, length);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [self convertBGRAtoRGBA:imageData withSize:length];
    CFDataRef data = CFDataCreate(NULL, imageData, length);
    free(imageData);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width, height, bitPerCompoment, bitPerPixel, bytePerRow, colorSpace, bitmapInfo, provider, NULL, NULL, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CFRelease(data);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    return image;
}

+ (void)convertBGRAtoRGBA:(unsigned char *)imageData withSize:(size_t)length
{
    uint8_t *p = (uint8_t *)imageData;
    for (int y = 0; y < length; y = y + 4) {
        uint8_t temp = p[0];
        p[0] = p[2];
        p[2] = temp;
        p += 4;
    }
}

+ (CVPixelBufferRef)bdx_pixelBufferFromImage:(UIImage *)originImage
{
    CGImageRef image = originImage.CGImage;
    NSDictionary *optionsDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                nil];
    CVPixelBufferRef pixelBuffer = NULL;
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);

    CVPixelBufferCreate(kCFAllocatorDefault,
                        frameWidth,
                        frameHeight,
                        kCVPixelFormatType_32ARGB,
                        (__bridge CFDictionaryRef) optionsDic,
                        &pixelBuffer);

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    uint32_t bitmapInfo = (CGBitmapInfo)kCGImageAlphaNoneSkipFirst;
    CGContextRef contextRef = CGBitmapContextCreate(pixelData,
                                                    frameWidth,
                                                    frameHeight,
                                                    bitsPerComponent,
                                                    bytesPerRow,
                                                    colorSpaceRef,
                                                    bitmapInfo);
    
    CGContextConcatCTM(contextRef, CGAffineTransformIdentity);
    
    
    CGRect rect = CGRectMake(0,
                             0,
                             frameWidth,
                             frameHeight);
    CGContextDrawImage(contextRef, rect, image);
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(contextRef);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    return pixelBuffer;
}

@end
