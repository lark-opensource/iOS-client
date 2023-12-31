//
//  BDPImageHelper.m
//  Timor
//
//  Created by 刘相鑫 on 2018/12/10.
//

#import "BDPImageHelper.h"

@implementation BDPImageHelper

+ (NSString *)mimeTypeForImageData:(NSData *)data
{
    BDPImageFormat format = [self contentFormatForImageData:data];
    NSString *mimeType = [self mimeTypeForBDPImageFormat:format];
    return mimeType;
}

+ (BDPImageFormat)contentFormatForImageData:(NSData *)imageData
{
    if (!imageData) {
        return BDPImageFormatUnkonw;
    }
    
    BDPImageFormat format = BDPImageFormatUnkonw;
    char bytes[12] = {0};
    [imageData getBytes:bytes length:12];
    
    const char bmp[2] = {'B', 'M'};
    const char gif[3] = {'G', 'I', 'F'};
    const char swf[3] = {'F', 'W', 'S'};
    const char swc[3] = {'C', 'W', 'S'};
    const char jpg[3] = {0xff, 0xd8, 0xff};
    const char psd[4] = {'8', 'B', 'P', 'S'};
    const char iff[4] = {'F', 'O', 'R', 'M'};
    const char webp[4] = {'R', 'I', 'F', 'F'};
    const char ico[4] = {0x00, 0x00, 0x01, 0x00};
    const char tif_ii[4] = {'I','I', 0x2A, 0x00};
    const char tif_mm[4] = {'M','M', 0x00, 0x2A};
    const char png[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
    const char jp2[12] = {0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50, 0x20, 0x20, 0x0D, 0x0A, 0x87, 0x0A};
    
    if (!memcmp(bytes, bmp, 2)) {
        return BDPImageFormatBMP;
    }
    if (!memcmp(bytes, gif, 3)) {
        return BDPImageFormatGIF;
    }
    if (!memcmp(bytes, jpg, 3)) {
        return BDPImageFormatJPEG;
    }
    if (!memcmp(bytes, psd, 4)) {
        return BDPImageFormatPSD;
    }
    if (!memcmp(bytes, iff, 4)) {
        return BDPImageFormatIFF;
    }
    if (!memcmp(bytes, webp, 4)) {
        return BDPImageFormatWebP;
    }
    if (!memcmp(bytes, ico, 4)) {
        return BDPImageFormatICO;
    }
    if (!memcmp(bytes, tif_ii, 4)) {
        return BDPImageFormatTIFF;
    }
    if (!memcmp(bytes, tif_mm, 4)) {
        return BDPImageFormatTIFF;
    }
    if (!memcmp(bytes, png, 8)) {
        return BDPImageFormatPNG;
    }
    if (!memcmp(bytes, jp2, 8)) {
        return BDPImageFormatJP2;
    }
    
    
    return format;
}

+ (NSString *)mimeTypeForBDPImageFormat:(BDPImageFormat)format
{
    NSString *mime = nil;
    switch (format) {
        case BDPImageFormatPNG:
            mime = @"image/png";
            break;
        case BDPImageFormatJPEG:
            mime = @"image/jpeg";
            break;
        case BDPImageFormatGIF:
            mime = @"image/gif";
            break;
        case BDPImageFormatWebP:
            mime = @"image/webp";
            break;
        case BDPImageFormatTIFF:
            mime = @"image/tiff";
            break;
        case BDPImageFormatICO:
            mime = @"image/vnd.microsoft.icon";
            break;
        case BDPImageFormatBMP:
            mime = @"image/x-ms-bmp";
            break;
        case BDPImageFormatJP2:
            mime = @"image/jp2";
            break;
        case BDPImageFormatIFF:
            mime = @"image/iff";
            break;
        case BDPImageFormatPSD:
            mime = @"image/psd";
            break;
        case BDPImageFormatUnkonw:
            break;
    }
    
    return mime;
}

@end
