//
//  BDWebViewUtil.m
//  ByteWebView
//
//  Created by Lin Yong on 2019/5/5.
//

#import "BDWebKitUtil+BlankDetect.h"
#import "BDWebKitSettingsManger.h"

@implementation BDWebKitUtil (BlankDetect)

+ (BOOL)checkWebContentBlank:(UIImage *)image withBlankColor:(UIColor *)color
{
    if ([BDWebKitSettingsManger useNewBlankCheck]) {
        return [self _newCheckWebContentBlank:image withBlankColor:color];
    } else {
        return [self _oldCheckWebContentBlank:image withBlankColor:color];
    }
}

typedef struct BlankDetectRGBData_t {
    UInt32 r;
    UInt32 g;
    UInt32 b;
    UInt32 a;
    UInt32 sameCount;
}BlankDetectRGBData;

+ (BlankDetectRGBData)fetchCompareColor:(UInt8 *)data withWidth:(size_t)width withHeight:(size_t)height withBlankColor:(UIColor *)blankColor
{
    BlankDetectRGBData dataList[10];
    CGFloat r, g, b, a;
    [blankColor getRed:&r green:&g blue:&b alpha:&a];  // get r,g,b of blankColor
    dataList[0].r = r*255;
    dataList[0].g = g*255;
    dataList[0].b = b*255;
    dataList[0].a = a*255;
    dataList[0].sameCount = 0;

    // get r,g,b of ImageData
    size_t tempIndex = 1, tempRow, tempColumn, pixelIndex;
    for (int i = 0; i < 3; ++i) {
        tempRow = (height - 1) * i / 2;
        for (int j = 0; j < 3; ++j) {
            tempColumn = (width - 1) * j / 2;
            pixelIndex = tempRow * width * 4 + tempColumn * 4;
            dataList[tempIndex].r = data[pixelIndex];
            dataList[tempIndex].g = data[pixelIndex + 1];
            dataList[tempIndex].b = data[pixelIndex + 2];
            dataList[tempIndex].a = data[pixelIndex + 3];
            dataList[tempIndex].sameCount = 0;
            tempIndex++;
            if (tempIndex > 9) {
                break;
            }
        }
        if (tempIndex > 9) {
            break;
        }
    }

    size_t maxIndex = 0;
    UInt32 maxCount = 0;
    for (int i=0; i<10; ++i) {
        if (dataList[i].sameCount > 0) {
            continue;
        }
        for (int j=i+1; j<10; ++j) {
            BOOL isEqual = dataList[i].r == dataList[j].r &&
                           dataList[i].g == dataList[j].g &&
                           dataList[i].b == dataList[j].b &&
                           dataList[i].a == dataList[j].a;
            if (isEqual) {
                dataList[i].sameCount += 1;
                dataList[j].sameCount += 1;
                if (dataList[i].sameCount > maxCount) {
                    maxCount = dataList[i].sameCount;
                    maxIndex = i;
                }
            }
        }
        if (maxCount >= 5) {
            break;
        }
    }

    // check result
    if (maxCount == 0) {
        BlankDetectRGBData whiteResult;
        whiteResult.r = 255;
        whiteResult.g = 255;
        whiteResult.b = 255;
        whiteResult.a = 255;
        whiteResult.sameCount = 0;
        return whiteResult;
    }

    return dataList[maxIndex];
}

+ (BOOL)_oldCheckWebContentBlank:(UIImage *)image withBlankColor:(UIColor *)color {
    // 缩小到原来的 1/6 大，在保证准确率的情况下减少需要遍历像素点的数量
    size_t width = image.size.width/6;
    size_t height = image.size.height/6;
    CGImageRef imageRef = [image CGImage];
    if (width == 0 || height == 0 || imageRef == NULL) {
        return NO;
    }
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                width,
                                                height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                colorSpaceRef,
                                                kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), imageRef);
    UInt8* data = CGBitmapContextGetData(bitmap);
    
    if (data == NULL) {
        CGContextRelease(bitmap);
        CGColorSpaceRelease(colorSpaceRef);
        return NO;
    }

    BlankDetectRGBData blankRGBData = [self fetchCompareColor:data withWidth:width withHeight:height withBlankColor:color];
    UInt32 ri = blankRGBData.r, gi = blankRGBData.g, bi = blankRGBData.b;
    NSUInteger clearColorCount = 0;
    NSUInteger otherCount = 0;
    // 如果存在大于总像素点的5%个非背景像素点则认为不是白屏
    long availableCount = (width * height) * 0.05;
    // 如果存在大于总像素点的50%个透明像素点则认为是白屏
    long limitCount = (width * height) * 0.5;
    for (size_t i = 0; i < height; i++) {
        for (size_t j = 0; j < width; j++) {
            size_t pixelIndex = i * width * 4 + j * 4;
            UInt32 r = data[pixelIndex];
            UInt32 g = data[pixelIndex + 1];
            UInt32 b = data[pixelIndex + 2];
            UInt32 a = data[pixelIndex + 3];
            
            if (r != ri || g != gi || b != bi) {
                otherCount++;
            }
            
            if (r == 0 && g == 0 && b == 0 && a == 0) {
                clearColorCount++;
            }
            
            if (otherCount > availableCount && clearColorCount != otherCount) {
                CGColorSpaceRelease(colorSpaceRef);
                CGContextRelease(bitmap);
                return NO;
            }
            
            if (clearColorCount >= limitCount) {
                CGColorSpaceRelease(colorSpaceRef);
                CGContextRelease(bitmap);
                return YES;
            }
        }
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(bitmap);
    return YES;
}


+ (BOOL)_newCheckWebContentBlank:(UIImage *)image withBlankColor:(UIColor *)color {
    // 缩小到原来的 1/6 大，在保证准确率的情况下减少需要遍历像素点的数量
    size_t width = image.size.width/6;
    size_t height = image.size.height/6;
    CGImageRef imageRef = [image CGImage];
    if (width == 0 || height == 0 || imageRef == NULL) {
        return NO;
    }
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                width,
                                                height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                colorSpaceRef,
                                                kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), imageRef);
    UInt8* data = CGBitmapContextGetData(bitmap);
    
    if (data == NULL) {
        CGContextRelease(bitmap);
        CGColorSpaceRelease(colorSpaceRef);
        return NO;
    }
    
    BlankDetectRGBData blankRGBData = [self fetchCompareColor:data withWidth:width withHeight:height withBlankColor:color];
    UInt32 ri = blankRGBData.r, gi = blankRGBData.g, bi = blankRGBData.b, ai = blankRGBData.a;
    NSUInteger clearColorCount = 0;
    NSUInteger otherCount = 0;
    // 如果存在大于总像素点的5%个非背景像素点则认为不是白屏
    long availableCount = (width * height) * 0.05;
    // 如果存在大于总像素点的95%个透明像素点则认为是白屏
    long limitCount = (width * height) * 0.95;
    for (size_t i = 0; i < height; i++) {
        for (size_t j = 0; j < width; j++) {
            size_t pixelIndex = i * width * 4 + j * 4;
            UInt32 r = data[pixelIndex];
            UInt32 g = data[pixelIndex + 1];
            UInt32 b = data[pixelIndex + 2];
            UInt32 a = data[pixelIndex + 3];
            
            if (r != ri || g != gi || b != bi || a != ai) {
                otherCount++;
            }
            
            if (r == 0 && g == 0 && b == 0 && a == 0) {
                clearColorCount++;
            }
            
            if (otherCount > availableCount && clearColorCount != otherCount) {
                CGColorSpaceRelease(colorSpaceRef);
                CGContextRelease(bitmap);
                return NO;
            }
            
            if (clearColorCount >= limitCount) {
                CGColorSpaceRelease(colorSpaceRef);
                CGContextRelease(bitmap);
                return YES;
            }
        }
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(bitmap);
    return YES;
}

@end
