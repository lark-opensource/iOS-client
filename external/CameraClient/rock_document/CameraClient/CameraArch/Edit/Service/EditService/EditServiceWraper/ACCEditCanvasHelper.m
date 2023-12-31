//
//  ACCEditCanvasHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/10.
//

#import "ACCEditCanvasHelper.h"

@implementation ACCEditCanvasHelper

+ (void)getTopColor:(UIColor **)topColor bottomColor:(UIColor **)bottomColor fromImage:(UIImage *)image
{
    *topColor = [UIColor blackColor];
    if (bottomColor) {
        *bottomColor = [UIColor blackColor];
    }

    CGImageRef cgImage = image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGSize size = CGSizeMake(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
    CGContextRef context = CGBitmapContextCreate(nil, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaNoneSkipLast);
    CGRect rect = {CGPointZero, size};
    CGContextDrawImage(context, rect, cgImage);
    cgImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    if (!cgImage)  {
        return;
    }

    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    const UInt8 *bytes = CFDataGetBytePtr(data);

    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);

    if (topColor) {
        NSCountedSet *countedTopColors = [NSCountedSet set];
        NSInteger topCounter = 0;
        UIColor *dominatedTopColor = [UIColor blackColor];
        for (size_t pixel = 0; pixel < width; pixel++) {
            CGFloat red = bytes[pixel * 4 + 0];
            CGFloat green = bytes[pixel * 4 + 1];
            CGFloat blue = bytes[pixel * 4 + 2];

            UIColor *color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
            [countedTopColors addObject:color];
            if ([countedTopColors countForObject:color] > topCounter)  {
                topCounter = [countedTopColors countForObject:color];
                dominatedTopColor = color;
            }
        }
        *topColor = dominatedTopColor;
    }

    if (bottomColor) {
        NSCountedSet *countedBottomColors = [NSCountedSet set];
        NSInteger bottomCounter = 0;
        UIColor *dominatedBottomColor = [UIColor blackColor];
        for (size_t pixel = (height - 1) * width; pixel < height * width; pixel++) {
            CGFloat red = bytes[pixel * 4 + 0];
            CGFloat green = bytes[pixel * 4 + 1];
            CGFloat blue = bytes[pixel * 4 + 2];

            UIColor *color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
            [countedBottomColors addObject:color];
            if ([countedBottomColors countForObject:color] > bottomCounter)  {
                bottomCounter = [countedBottomColors countForObject:color];
                dominatedBottomColor = color;
            }
        }
        *bottomColor = dominatedBottomColor;
    }

    CFRelease(data);
    CGImageRelease(cgImage);
}

+ (void)getMainColor:(UIColor **)mainColor fromImage:(UIImage *)image
{
    UIImage *resizeImage = [self resizeImageWithSize:CGSizeMake(1, 1) originImage:image];
    [self getTopColor:mainColor bottomColor:NULL fromImage:resizeImage];
}

+ (UIImage *)resizeImageWithSize:(CGSize)size originImage:(UIImage *)originImage
{
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [originImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
