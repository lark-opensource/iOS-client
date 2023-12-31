//
//  UIImage+LV.m
//  CameraClient
//
//  Created by xulei on 2020/6/1.
//

#import <AVFoundation/AVFoundation.h>
#import "CGSize+MV.h"

@implementation UIImage (MV)
- (CGSize)mv_imageSize {
    CGSize size = self.size;
    if (self.imageOrientation == UIImageOrientationLeft || self.imageOrientation == UIImageOrientationRight
        || self.imageOrientation == UIImageOrientationLeftMirrored || self.imageOrientation == UIImageOrientationRightMirrored) {
        size = CGSizeMake(size.height, size.width);
    }
    return size;
}

- (BOOL)mv_hasAlpha {
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage);
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}


+ (nullable UIImage *)mv_imageWithData:(NSData *)data maxSize:(CGSize)maxSize decode:(Boolean)decode {
    @autoreleasepool {
        NSDictionary *options = @{(NSString *)kCGImageSourceShouldCache: @NO};
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data,
                                                                   (__bridge_retained CFDictionaryRef)options);
        if (!imageSource) { return nil; }
        CGFloat maxPixelSize = MAX(maxSize.width, maxSize.height);
        options = @{
            (NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
            (NSString *)kCGImageSourceShouldCacheImmediately: @(decode),
            (NSString *)kCGImageSourceCreateThumbnailWithTransform: @YES,
            (NSString *)kCGImageSourceThumbnailMaxPixelSize: @(maxPixelSize),
        };
        CGImageRef cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource,
                                                                 0,
                                                                 (__bridge_retained CFDictionaryRef)options);
        CFRelease(imageSource);
        if (!cgImage) { return nil; }
        UIImage *image = [[UIImage alloc] initWithCGImage:cgImage];
        CGImageRelease(cgImage);
        return image;
    }
}

- (UIImage *)mv_resizeWithLimitMaxSize:(CGSize)limitMaxSize {
    if (self.size.width <= limitMaxSize.width && self.size.height <= limitMaxSize.height) {
        return self;
    }
    CGSize resize = mv_limitMaxSize(self.size, limitMaxSize);
    CGFloat resizeWidth = round(resize.width / 2.0) * 2.0;
    CGFloat resizeHeight = round(resize.height / 2.0) * 2.0;
    CGSize fixedResize = CGSizeMake(resizeWidth, resizeHeight);
    return [self mv_resizedImageToSize:fixedResize];
}

- (UIImage *)mv_resizeWithLimitMinSize:(CGSize)limitMinSize {
    CGSize resize = mv_limitMinSize(self.size, limitMinSize);
    CGFloat resizeWidth = round(resize.width / 2.0) * 2.0;
    CGFloat resizeHeight = round(resize.height / 2.0) * 2.0;
    CGSize fixedResize = CGSizeMake(resizeWidth, resizeHeight);
    return [self mv_resizedImageToSize:fixedResize];
}
  
// https://github.com/AliSoftware/UIImage-Resize/blob/master/UIImage%2BResize.m
- (UIImage *)mv_resizedImageToSize:(CGSize)dstSize {
    CGImageRef imgRef = self.CGImage;
    CGSize  srcSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    if (CGSizeEqualToSize(srcSize, dstSize)) {
        return self;
    }
    
    CGFloat scaleRatio = dstSize.width / srcSize.width;
    UIImageOrientation orient = self.imageOrientation;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(srcSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(srcSize.width, srcSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, srcSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            dstSize = CGSizeMake(dstSize.height, dstSize.width);
            transform = CGAffineTransformMakeTranslation(srcSize.height, srcSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI_2);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            dstSize = CGSizeMake(dstSize.height, dstSize.width);
            transform = CGAffineTransformMakeTranslation(0.0, srcSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI_2);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            dstSize = CGSizeMake(dstSize.height, dstSize.width);
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            dstSize = CGSizeMake(dstSize.height, dstSize.width);
            transform = CGAffineTransformMakeTranslation(srcSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    /////////////////////////////////////////////////////////////////////////////
    // The actual resize: draw the image on a new context, applying a transform matrix
    UIGraphicsBeginImageContextWithOptions(dstSize, NO, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
       if (!context) {
           return nil;
       }
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -srcSize.height, 0);
    } else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -srcSize.height);
    }
    
    CGContextConcatCTM(context, transform);
    
    // we use srcSize (and not dstSize) as the size to specify is in user space (and we use the CTM to apply a scaleRatio)
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, srcSize.width, srcSize.height), imgRef);
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}
@end

