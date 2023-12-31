//
//  UIImage+ACC.m
//  CameraClient
//
//  Created by lxp on 2019/12/31.
//

#import "UIImage+ACC.h"

static inline CGSize swapWidthAndHeight(CGSize size) {
    CGFloat swap = size.width;
    size.width = size.height;
    size.height = swap;
    return size;
}

@implementation UIImage (ACC)

- (UIImage *)acc_rotate:(UIImageOrientation)orient {
    CGImageRef cgimg = self.CGImage;
    CGAffineTransform tran = CGAffineTransformIdentity;
    CGRect rect = CGRectMake(0, 0, CGImageGetWidth(cgimg), CGImageGetHeight(cgimg));
    CGSize size = rect.size;
    
    switch (orient)
    {
        case UIImageOrientationUp:
            return self;
            break;
        case UIImageOrientationUpMirrored:
            tran = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown:
            tran = CGAffineTransformMakeTranslation(rect.size.width, rect.size.height);
            tran = CGAffineTransformRotate(tran, M_PI);
            break;
            
        case UIImageOrientationDownMirrored:
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.height);
            tran = CGAffineTransformScale(tran, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeft:
            size = swapWidthAndHeight(size);
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.width);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeftMirrored:
            size = swapWidthAndHeight(size);
            tran = CGAffineTransformMakeTranslation(rect.size.height,
                                                    rect.size.width);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRight:
            size = swapWidthAndHeight(size);
            tran = CGAffineTransformMakeTranslation(rect.size.height, 0.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored:
            size = swapWidthAndHeight(size);
            tran = CGAffineTransformMakeScale(-1.0, 1.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        default:
            return self;
    }
    
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    switch (orient)
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextScaleCTM(ctx, -1.0, 1.0);
            CGContextTranslateCTM(ctx, -rect.size.height, 0.0);
            break;
        default:
            CGContextScaleCTM(ctx, 1.0, -1.0);
            CGContextTranslateCTM(ctx, 0.0, -rect.size.height);
            break;
    }
    CGContextConcatCTM(ctx, tran);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, cgimg);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}


- (UIImage *)acc_crop:(CGRect)rect
{
    if (CGSizeEqualToSize(rect.size, self.size) && CGPointEqualToPoint(CGPointZero, rect.origin)) { return self; }
    rect.origin.x *= self.scale;
    rect.origin.y *= self.scale;
    rect.size.width *= self.scale;
    rect.size.height *= self.scale;
    if (rect.size.width <= 0 || rect.size.height <= 0) return self;
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

- (UIImage *)acc_imageWithBorder:(CGFloat)borderWidth borderColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius
{
    CGSize size = CGSizeMake(self.size.width + borderWidth * 2.0, self.size.height + borderWidth * 2.0);
    UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:cornerRadius];
    [color setFill];
    [path fill];
    [path addClip];
    [self drawInRect:CGRectMake(borderWidth, borderWidth, self.size.width, self.size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)downsampleWithLimitSize:(CGSize)limitSize {
    CGFloat maxPixelSize = MAX(limitSize.width, limitSize.height);
    NSData *data = UIImageJPEGRepresentation(self, 1.0);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data,
                                (__bridge CFDictionaryRef)@{(NSString *)kCGImageSourceShouldCache: @NO});
    
    UIImage *thumbnail = nil;
    if (imageSource) {
        NSDictionary *options = @{ (__bridge id)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                   (__bridge id)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                   (__bridge id)kCGImageSourceThumbnailMaxPixelSize : @(maxPixelSize) };

        CGImageRef scaledImageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
        if (scaledImageRef) {
            thumbnail = [UIImage imageWithCGImage:scaledImageRef];
            CFRelease(scaledImageRef);
        }
        CFRelease(imageSource);
    }
    return thumbnail;
}

+(CGSize)limitSizeWithMinSize:(CGSize)size size:(CGSize)realSize {
    CGSize newSize = CGSizeZero;
    CGFloat wRatio = realSize.width / size.width;
    CGFloat hRatio = realSize.height / size.height;
    if (wRatio >= hRatio) {
        CGFloat compressHeight = 0;
        if (realSize.height >= size.height) {
            compressHeight = size.height;
        } else {
            compressHeight = realSize.height;
        }
        CGFloat compressWidth = compressHeight * realSize.width / realSize.height;
        newSize = CGSizeMake(compressWidth, compressHeight);
    } else {
        CGFloat compressWidth = 0;
        if (realSize.width >= size.width) {
            compressWidth = size.width;
        } else {
            compressWidth = realSize.width;
        }
        CGFloat compressHeight = compressWidth * realSize.height / realSize.width;
        newSize = CGSizeMake(compressWidth, compressHeight);
    }
    return newSize;
}

- (UIImage *)downsampleToSize:(CGSize)downSize
         interpolationQuality:(CGInterpolationQuality)interpolationQuality {
    CGImageRef cgImage = self.CGImage;
    CGFloat width = downSize.width;
    CGFloat height = downSize.height;
    size_t bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
    size_t bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(cgImage);

    CGContextRef context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);

    CGContextSetInterpolationQuality(context, interpolationQuality);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);

    CGImageRef scaledcgImage = CGBitmapContextCreateImage(context);
    
    UIImage *result = [UIImage imageWithCGImage:scaledcgImage];

    CGContextRelease(context);
    CGImageRelease(scaledcgImage);
    return result;
}

+ (UIImage *)snapshotWithView:(UIView *)targetView {
    UIGraphicsBeginImageContextWithOptions(targetView.bounds.size, YES, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [targetView.layer renderInContext:ctx];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}


+ (UIImage *)downsampledImageWithSize:(CGSize)size sourcePath:(NSString *)path
{
    if (!path) {
        return nil;
    }
    
    NSURL *url = [NSURL fileURLWithPath:path];
    CGFloat maxPixelSize = MAX(size.width, size.height);

    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);

    UIImage *thumbnail = nil;
    if (imageSource) {
        NSDictionary *options = @{ (__bridge id)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                   (__bridge id)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                   (__bridge id)kCGImageSourceThumbnailMaxPixelSize : @(maxPixelSize) };

        CGImageRef scaledImageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
        if (scaledImageRef) {
            thumbnail = [UIImage imageWithCGImage:scaledImageRef];
            CFRelease(scaledImageRef);
        }
        CFRelease(imageSource);
    }
    return thumbnail;
}

+ (UIImage *)acc_imageFromColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(size);                        // Create picture
    CGContextRef context = UIGraphicsGetCurrentContext();     // Create picture context
    CGContextSetFillColorWithColor(context, [color CGColor]); // Sets the graphics context for the current fill color
    CGContextFillRect(context, rect);                         // Fill color

    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

+ (UIImage *)acc_composeImage:(UIImage *)image1 withImage:(UIImage *)image2
{
    if (!image1) {
        return image2;
    }

    if (!image2) {
        return image1;
    }

    CGSize size1 = CGSizeMake(image1.size.width * image1.scale, image1.size.height * image1.scale);
    CGSize size2 = CGSizeMake(image2.size.width * image2.scale, image2.size.height * image2.scale);
    
    if (size1.width > size2.width) {
        if (size1.width > 0) {
            size1 = CGSizeMake(size2.width, size1.height * size2.width / size1.width);
        }
    } else {
        if (size2.width > 0) {
            size2 = CGSizeMake(size1.width, size2.height * size1.width / size2.width);
        }
    }

    UIGraphicsBeginImageContext(size1);
    [image1 drawInRect:CGRectMake(0, 0, size1.width, size1.height)];
    [image2 drawInRect:CGRectMake((size1.width - size2.width) / 2.0, (size1.height - size2.height) / 2.0, size2.width, size2.height)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resultImage;
}

@end
