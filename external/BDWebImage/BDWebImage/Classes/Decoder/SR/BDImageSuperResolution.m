//
//  BDImageSuperResolution.m
//  BDWebImageToB
//
//  Created by 陈奕 on 2020/11/5.
//
#if __is_target_arch(arm64) || __is_target_arch(arm64e)
#import "BDImageSuperResolution.h"
#import "BDWebImageError.h"
#import "asr.h"
#import "BDImageDecoderFactory.h"
#import "BDWebImageSRError.h"

@implementation BDImageSuperResolution

+ (UIImage *)superResolutionImageWithImage:(UIImage *)image error:(NSError * _Nullable __autoreleasing *_Nullable)error {
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    if ([image isKindOfClass:[BDImage class]] && ((BDImage *)image).isAnimateImage) {
        if (error) {
            *error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageSRError userInfo:@{ NSLocalizedDescriptionKey: @"Animated images cannot be super-resolution", NSLocalizedFailureReasonErrorKey:@(SRErrorTypeAnimatedImageNotSupported) }];
        }
        return image;
    }
    
    if (width % 4 != 0 || height % 4 != 0) {
        if (error) {
            *error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageSRError userInfo:@{ NSLocalizedDescriptionKey: @"The width or height is not a multiple of 4, so super resolution is not possible", NSLocalizedFailureReasonErrorKey:@(SRErrorTypeNotDivisibleByFour) }];
        }
        return image;
    }
    
    CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    if (bytesPerRow == 0 || width == 0 || height == 0) return NULL;
    
    void *rawData = calloc(1, height * bytesPerRow);
    if(!rawData) {
        if (error) {
            *error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageSRError userInfo:@{ NSLocalizedDescriptionKey: @"Not enough memory, super resolution failed", NSLocalizedFailureReasonErrorKey:@(SRErrorTypeMemoryNotEnough) }];
        }
        return image;
    }
    
    CGContextRef context = CGBitmapContextCreate(rawData,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 space,
                                                 bitmapInfo);
    if(!context) {
        if(rawData) {
            free(rawData);
        }
        return image;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        asr2_context_initialize();
    });
    
    void *m_pasrHandle = create_asr_handle(2, 0);
    
    NSUInteger srWidth = width * 3;
    NSUInteger srHeight = height * 3;

    int status;
    asr_param param = {0};
    size_t srBytesPerRow = BDImageByteAlign(bitsPerPixel / 8 * srWidth, 32);
    size_t srLength = srBytesPerRow * srHeight;
    void *dstdata = calloc(1, srLength);

    param.b_stretch = ASR_DO_SCALE_3X3;
    param.strength = 30;
    param.speed = 2;
    param.chroma_format_in = CF_RGB8888;
    param.chroma_format_out = CF_RGB8888;
    param.chroma_mask = 7;
    param.src[0] = rawData;
    param.dst[0] = dstdata;
    param.spit[0] = (int)bytesPerRow;
    param.dpit[0] = (int)srBytesPerRow;

    param.width = (int)width;
    param.height = (int)height;
    param.dwidth = (int)srWidth;
    param.dheight = (int)srHeight;

    status = do_picture_asr(m_pasrHandle, &param);
    release_asr_handle(m_pasrHandle);
    if (rawData) {
        free(rawData);
    }
    if (status != 0) {
        if(dstdata) {
            free(dstdata);
        }
        if (error) {
            *error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageSRError userInfo:@{ NSLocalizedDescriptionKey: @"Super resolution failed", NSLocalizedFailureReasonErrorKey:@(SRErrorTypeCoreFailed) }];
        }
        return image;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(dstdata, dstdata, srLength, BDCGDataProviderReleaseDataCallback);
    if (!provider) {
        free(dstdata);
        if (error) {
            *error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageSRError userInfo:@{ NSLocalizedDescriptionKey: @"Super resolution completed, image creation failed", NSLocalizedFailureReasonErrorKey:@(SRErrorTypeImageCreationFailed) }];
        }
        return nil;
    }
    
    CGColorSpaceRef colorSpaceRef = BDCGColorSpaceGetDeviceRGB();
    
    CGImageRef srImage = CGImageCreate(srWidth,
                                       srHeight,
                                       bitsPerComponent,
                                       bitsPerPixel,
                                       srBytesPerRow,
                                       colorSpaceRef,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       false,
                                       kCGRenderingIntentDefault);
    CFRelease(provider);
    CGImageRef decoded = BDCGImageCreateDecodedCopy(srImage, YES);
    CGImageRelease(srImage);
    UIImage *result = [UIImage imageWithCGImage:decoded];
    CGImageRelease(decoded);
    return result;
}

size_t BDImageByteAlign(size_t size, size_t alignment) {
    return ((size + (alignment - 1)) / alignment) * alignment;
}

static void BDCGDataProviderReleaseDataCallback(void *info, const void *data, size_t size) {
    free((void *)data);
}

@end
#endif
