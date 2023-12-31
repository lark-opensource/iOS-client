//
//  UIImage+BDBCAdditions.m
//  byted_cert-byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2020/12/24.
//

#import "UIImage+BDCTAdditions.h"
#import "BDCTAdditions.h"
#import "BytedCertUIConfig.h"


@implementation UIImage (BDBCAdditions)

+ (UIImage *)bdct_holdSampleImage {
    return [self bdct_imageWithName:@"hold_sample"];
}

+ (UIImage *)bdct_loadingImage {
    return [self bdct_imageWithName:@"loading"];
}

+ (UIImage *)bdct_imageWithName:(NSString *)name {
    if (!name.length) {
        return nil;
    }
    return [UIImage imageNamed:name inBundle:NSBundle.bdct_bundle compatibleWithTraitCollection:nil];
}

+ (NSData *)bdct_compressImage:(UIImage *)image compressRatio:(CGFloat)ratio {
    if (!image) {
        return nil;
    }
    UIImage *resultImage = image;
    CGFloat sizeRatio = MAX(MAX(resultImage.size.width, resultImage.size.height) / 1280, MIN(resultImage.size.width, resultImage.size.height) / 720);
    if (sizeRatio > 1) {
        CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width / sqrtf(sizeRatio)),
                                 (NSUInteger)(resultImage.size.height / sqrtf(sizeRatio)));
        UIGraphicsBeginImageContext(size);
        [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return UIImageJPEGRepresentation(resultImage, ratio > 0 ? ratio : 0.85);
}

- (UIImage *)bdct_cropToRect:(CGRect)rect {
    CGFloat (^rad)(CGFloat) = ^CGFloat(CGFloat deg) {
        return deg / 180.0f * (CGFloat)M_PI;
    };

    // CGImageCreateWithImageInRect中得rect是获取自UIImage中得rect，而不是UIImageView的；而在UIImage的坐标系中，(0, 0) 点位于左下角，因此在裁剪区域确定时，需要转换成对应坐标系中得区域
    CGAffineTransform rectTransform;
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -self.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -self.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -self.size.width, -self.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    }

    // adjust the transformation scale based on the image scale
    rectTransform = CGAffineTransformScale(rectTransform, self.scale, self.scale);
    // apply the transformation to the rect to create a new, shifted rect
    CGRect transformedCropSquare = CGRectApplyAffineTransform(rect, rectTransform);
    // use the rect to crop the image
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, transformedCropSquare);
    // create a new UIImage and set the scale and orientation appropriately
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    // memory cleanup
    CGImageRelease(imageRef);
    return result;
}

- (UIImage *)bdct_transforCapturedImageWithMaxResoulution:(int)maxResolution isFrontCamera:(BOOL)isFrontCamera {
    // 原本照片的orientation都是UIImageOrientationRight 经过第一步处理都会变成UIImageOrientationUp 这会影响到图片的坐标系
    CGFloat scale = self.size.height / maxResolution;
    CGSize size = CGSizeMake(floor((self.size.width * 100) / (scale * 100)), maxResolution);
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *cropImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGImageRef imgRef = cropImage.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);

    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > maxResolution || height > maxResolution) {
        CGFloat ratio = width / height;
        if (ratio > 1) {
            bounds.size.width = maxResolution;
            bounds.size.height = floor(bounds.size.width / ratio);
        } else {
            bounds.size.height = maxResolution;
            bounds.size.width = floor(bounds.size.height * ratio);
        }
    }

    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;

    boundHeight = bounds.size.height;
    bounds.size.height = bounds.size.width;
    bounds.size.width = boundHeight;
    if (isFrontCamera) {
        transform = CGAffineTransformMakeTranslation(imageSize.height, 0);
        transform = CGAffineTransformRotate(transform, M_PI / 2.0);
    } else {
        transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
        transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
    }

    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, -scaleRatio, scaleRatio);
    CGContextTranslateCTM(context, -height, 0);
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageCopy;
}

- (UIImage *)bdct_resizeWithMaxSide:(CGFloat)maxSide {
    CGFloat scale = 0;
    CGSize size;

    if (self.size.height > self.size.width) {
        scale = self.size.height / maxSide;
        size = CGSizeMake(self.size.width / scale, maxSide);
    } else {
        scale = self.size.width / maxSide;
        size = CGSizeMake(maxSide, self.size.height / scale);
    }

    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];

    UIImage *cropImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return cropImage;
}

@end
