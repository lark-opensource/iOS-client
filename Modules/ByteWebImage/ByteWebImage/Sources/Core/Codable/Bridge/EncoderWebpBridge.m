//
//  EncoderWebpBridge.m
//  ByteWebImage
//
//  Created by kangsiwan on 2022/5/9.
//
//  Included OSS: SDWebImageWebPCoder
//  Copyright (c) Olivier Poitrey <rs@dailymotion.com>
//  spdx license identifier: MIT

#import "EncoderWebpBridge.h"
#import <Accelerate/Accelerate.h>
#if __has_include(<libwebp/webp/demux.h>)
    #import <libwebp/webp/demux.h>
#elif __has_include(<libwebp/demux.h>)
    #import <libwebp/demux.h>
#endif
#import <pthread/pthread.h>
#import <ByteWebImage/ByteWebImage-Swift.h>
#if __has_include(<libwebp/webp/encode.h>)
    #import <libwebp/webp/encode.h>
#elif __has_include(<libwebp/encode.h>)
    #import <libwebp/encode.h>
#endif

@implementation EncoderWebpBridge

+ (NSData *)encodeWithImageRef:(CGImageRef)imageRef quality:(float)quality {
    if (!imageRef) {
        return nil;
    }
    // 获取图片的宽高
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || height == 0 || width > WEBP_MAX_DIMENSION || height > WEBP_MAX_DIMENSION) {
        return nil;
    }

    // 获取颜色空间
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    // 一行占用的字节数
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    // 每个颜色的比特数，例如rgba-32中，r占8
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    // 一个像素的比特数，例如一个像素由rgba组成，一个颜色通道占8，那么一个像素就占32
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    // 一个像素有几个颜色通道
    size_t components = bitsPerPixel / bitsPerComponent;
    // 获取bitmap
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    // 使用kCGBitmapAlphaInfoMask，可以提取bitmap是否包含alpha通道，以及如何生成alpha信息
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    // 字节顺序，查看当前颜色存储是大端序还是小端序
    // 如果是小端序，当前是BGR，alpha为last，就会变成ABGR
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGImageByteOrderMask;

    // 是否有alpha通道
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
            // default为32位大端序
        case kCGImageByteOrderDefault:
            byteOrderNormal = YES;
            break;
        case kCGBitmapByteOrder16Big:
            byteOrderNormal = YES;
            break;
        case kCGBitmapByteOrder32Big:
            byteOrderNormal = YES;
            break;
        default:
            break;
    }
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    if (!dataProvider) {
        return nil;
    }

    // 是否是RGB格式的，其他格式有CMYK、XYZ等
    BOOL isRGB = CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelRGB;
    // 是RGB格式的大端序
    BOOL isRGB888 = isRGB && byteOrderNormal && alphaInfo == kCGImageAlphaNone && components == 3;
    // 是RGBA格式的大端序
    BOOL isRBGA8888 = isRGB && byteOrderNormal && alphaInfo == kCGImageAlphaLast && components == 4;

    CFDataRef dataRef;
    uint8_t *rgba = NULL;
    if (isRGB888 || isRBGA8888) {
        // 等同于swift的dataProvider.data
        dataRef = CGDataProviderCopyData(dataProvider);
        if (!dataRef) {
            return nil;
        }
        rgba = (uint8_t *)CFDataGetBytePtr(dataRef);
    } else {
        // 使用vImage转格式
        vImageConverterRef convertor = NULL;
        vImage_Error error = kvImageNoError;

        vImage_CGImageFormat srcFormat = {
            .bitsPerComponent = (uint32_t)bitsPerComponent,
            .bitsPerPixel = (uint32_t)bitsPerPixel,
            .colorSpace = colorSpace,
            .bitmapInfo = bitmapInfo,
            .renderingIntent = CGImageGetRenderingIntent(imageRef)
        };
        CGColorSpaceRef colorSpace;
        if (@available(iOS 9.0, tvOS 9.0, *)) {
            colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        } else {
            colorSpace = CGColorSpaceCreateDeviceRGB();
        }
        vImage_CGImageFormat destFormat = {
            .bitsPerComponent = 8,
            .bitsPerPixel = hasAlpha ? 32 : 24,
            .colorSpace = colorSpace,
            .bitmapInfo = hasAlpha ? kCGImageAlphaLast | kCGBitmapByteOrderDefault : kCGImageAlphaNone | kCGBitmapByteOrderDefault
        };
        // 转换器是线程安全的
        convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, &destFormat, NULL, kvImageNoFlags, &error);
        if (error != kvImageNoError) {
            return nil;
        }
        vImage_Buffer src;
        error = vImageBuffer_InitWithCGImage(&src, &srcFormat, nil, imageRef, kvImageNoFlags);
        if (error != kvImageNoError) {
            vImageConverter_Release(convertor);
            free(src.data);
            return nil;
        }
        vImage_Buffer dest;

        error = vImageBuffer_Init(&dest, height, width, destFormat.bitsPerPixel, kvImageNoFlags);
        if (error != kvImageNoError) {
            vImageConverter_Release(convertor);
            free(src.data);
            return nil;
        }

        error = vImageConvert_AnyToAny(convertor, &src, &dest, NULL, kvImageNoFlags);
        free(src.data);
        vImageConverter_Release(convertor);
        if (error != kvImageNoError) {
            free(dest.data);
            return nil;
        }
        rgba = dest.data;
        bytesPerRow = dest.rowBytes;
        dataRef = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, rgba, bytesPerRow * height, kCFAllocatorDefault);
    }
    uint8_t *data = NULL;
    size_t size;
    if (hasAlpha) {
        size = WebPEncodeRGBA(rgba, (int)width, (int)height, (int)bytesPerRow, quality, &data);
    } else {
        size = WebPEncodeRGB(rgba, (int)width, (int)height, (int)bytesPerRow, quality, &data);
    }
    if (dataRef) {
        CFRelease(dataRef);
        dataRef = NULL;
    }

    NSData *finalWebpData;
    if (size) {
        // success
        finalWebpData = [NSData dataWithBytes:data length:size];
    }
    if (data) {
        WebPFree(data);
    }
    return finalWebpData;
}

@end
