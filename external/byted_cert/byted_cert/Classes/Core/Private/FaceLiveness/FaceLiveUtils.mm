//
//  FaceLiveUtils.m
//  BytedCertIOS
//
//  Created by LiuChundian on 2019/3/23.
//  Copyright © 2019年 bytedance. All rights reserved.
//

#import "FaceLiveUtils.h"
#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <BDAssert/BDAssert.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <smash/ActionLiveness_API.h>

void BGRA2RGBA(unsigned char *src, unsigned char *dst, int numPixels) {
    int col;
    for (col = 0; col < numPixels; col++, src += 4, dst += 4) {
        dst[0] = src[2];
        dst[1] = src[1];
        dst[2] = src[0];
        dst[3] = src[3];
    }
}


@implementation FaceLiveUtils

+ (NSString *)getResource:(NSString *)module resName:(NSString *)resName {
#if TARGET_OS_OSX && !TARGET_OS_IOS
    module = [NSString stringWithFormat:@"Contents/Resources/%@/Contents/Resources", module];
#endif

    NSBundle *bundle = [NSBundle bundleWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:module]];
    BDAssert(bundle != nil, @"bundle with module: %@ is nil.", module);

    NSString *res = [bundle pathForResource:resName ofType:nil];
    BDAssert(res != nil, @"resource with name: %@ is nil.", resName);

    return res;
}

+ (NSData *)convertRawBufferToImage:(unsigned char *)rawData
                          imageName:(NSString *)imageName
                               cols:(int)cols
                               rows:(int)rows
                          saveImage:(bool)saveImage {
    return [self convertRawBufferToImage:rawData imageName:imageName cols:cols rows:rows bgra2rgba:true saveImage:saveImage];
}

+ (NSData *)convertRawBufferToImage:(unsigned char *)rawData
                          imageName:(NSString *)imageName
                               cols:(int)cols
                               rows:(int)rows
                          bgra2rgba:(bool)bgra2rgba
                          saveImage:(bool)saveImage {
    // TODO
    unsigned char *convertedImage;
    if (bgra2rgba) {
        convertedImage = new unsigned char[cols * rows * 4];
        BGRA2RGBA(rawData, convertedImage, rows * cols);
    } else {
        convertedImage = rawData;
    }

    GLubyte *rawBytes = convertedImage;
    NSInteger width = cols;
    NSInteger height = rows;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rawBytes, width, height, 8,
                                                 width * 4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGImageRef dstImage = CGBitmapContextCreateImage(context);
    UIImage *newImg = [UIImage imageWithCGImage:dstImage scale:1 orientation:UIImageOrientationUp];
    CGImageRelease(dstImage);
    CGContextRelease(context);

    NSData *imageData = UIImagePNGRepresentation(newImg);
    imageData = UIImageJPEGRepresentation(newImg, 0.5);
    if (saveImage) {
        NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:imageName];
        [imageData writeToFile:path atomically:NO];
    }
    return imageData;
}

//对数组随机排序
+ (NSArray *)sortedRandomArrayByArray:(NSArray *)array {
    NSArray *randomArray = [[NSArray alloc] init];
    randomArray = [array sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        int seed = arc4random_uniform(2);
        if (seed) {
            return [str1 compare:str2];
        } else {
            return [str2 compare:str1];
        }
    }];

    return randomArray;
}

+ (NSString *)packData:(NSString *)dataString newCryptType:(BOOL *)newCryptType {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSString *result = nil;
    if ([dataString respondsToSelector:@selector(bd_packedData)]) {
        result = [dataString.copy performSelector:@selector(bd_packedData)];
        *newCryptType = YES;
    }
    if (!result.length && [dataString respondsToSelector:@selector(bdct_packedData)]) {
        result = [dataString.copy performSelector:@selector(bdct_packedData)];
        *newCryptType = NO;
    }
#pragma clang diagnostic pop
    NSAssert(result.length, @"加密失败，需依赖['crypto']子库或BDSword");
    return result;
}

+ (NSData *)buildFaceCompareSDKDataWithParams:(NSDictionary *)params {
    NSString *dataStr = [params btd_URLQueryString];

    BOOL newCryptType = NO;
    NSString *cryptStr = [FaceLiveUtils packData:dataStr.copy newCryptType:&newCryptType] ?: @"";
    NSString *sdkDataVersion = newCryptType ? @"4.0" : @"3.0";
    NSMutableString *sdkStr = [[NSMutableString alloc] init];
    if (cryptStr.length) {
        int verStrLen = (int)[sdkDataVersion length];
        [sdkStr appendString:[NSString stringWithFormat:@"%c", verStrLen]];
        [sdkStr appendString:sdkDataVersion];
        [sdkStr appendString:cryptStr];
    }
    return [sdkStr dataUsingEncoding:NSUTF8StringEncoding] ?: [NSData new];
}

+ (NSString *)smashLiveModelName {
    ActionLivenessModelName modelInfo = {0};
    if (ActionLiveness_GetModelVersion(&modelInfo) == 0) {
        return [NSString stringWithUTF8String:modelInfo.namebuffer];
    }
    return @"";
}

+ (NSString *)smashSdkVersion {
    ActionLivenessModelName modelInfo = {0};
    if (ActionLiveness_GetModelVersion(&modelInfo) == 0) {
        return [NSString stringWithUTF8String:modelInfo.version_sdk];
    }
    return @"";
}

@end
