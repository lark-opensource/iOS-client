//
//  AWEImagesView.m
//  Aweme
//
// Created by Xuxu on December 24, 2017
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import "AWEImagesView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCMacros.h>

@implementation AWEImagesView

- (void)refreshWithImageArray:(NSArray<UIImage *> *)imageArray aspectRatio:(CGFloat)aspectRatio mode:(AWEImagesViewContentMode)mode
{
    if (imageArray.count == 0) {
        return;
    }

    CGSize imageSize = imageArray.firstObject.size;
    if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
        return;
    }
    if (ACC_FLOAT_EQUAL_ZERO(self.acc_height)) {
        return;
    }

    CGFloat toShowImageHeight = self.acc_height;
    CGFloat toShowImageWidth = aspectRatio * toShowImageHeight;

    CGSize size = CGSizeMake(toShowImageWidth * imageArray.count, toShowImageHeight);

    CGFloat scale = [UIScreen mainScreen].scale;

    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();

    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, size.height);
    CGContextConcatCTM(currentContext, flipVertical);

    CGContextSaveGState(currentContext);

    CGRect clippedRect = CGRectMake(0, 0, size.width, size.height);
    CGContextClipToRect(currentContext, clippedRect);

    BOOL isLargerWidth = NO;
    CGFloat imageAspectRatio = imageSize.width / imageSize.height;
    if (imageAspectRatio > aspectRatio) {// The picture is too wide
        isLargerWidth = YES;
    }

    [imageArray enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect drawRect;
        switch (mode) {
            case AWEImagesViewContentModeStretch: {
                drawRect = CGRectMake(toShowImageWidth * idx,
                                      0,
                                      toShowImageWidth,
                                      toShowImageHeight);
            }
                break;
            case AWEImagesViewContentModePreserveAspectRatio: {
                if (isLargerWidth) { // The picture is too wide. Fit according to the width
                    drawRect = CGRectMake(toShowImageWidth * idx,
                                          (toShowImageHeight - toShowImageWidth / imageAspectRatio) * 0.5,
                                          toShowImageWidth,
                                          toShowImageWidth / imageAspectRatio);
                } else {
                    drawRect = CGRectMake(toShowImageWidth * idx + (toShowImageWidth - toShowImageHeight * imageAspectRatio) * 0.5,
                                          0,
                                          toShowImageHeight * imageAspectRatio,
                                          toShowImageHeight);
                }
            }
                break;
            case AWEImagesViewContentModePreserveAspectRatioAndFill: {
                if (isLargerWidth) {
                    drawRect = CGRectMake(toShowImageWidth * idx - (toShowImageHeight * imageAspectRatio - toShowImageWidth) * 0.5,
                                          0,
                                          toShowImageHeight * imageAspectRatio,
                                          toShowImageHeight);
                } else {
                    drawRect = CGRectMake(toShowImageWidth * idx,
                                          -(toShowImageWidth / imageAspectRatio - toShowImageHeight) * 0.5,
                                          toShowImageWidth,
                                          toShowImageWidth / imageAspectRatio);
                }
            }
                break;
        }
        
        CGRect clipRect = CGRectMake(toShowImageWidth * idx, 0, toShowImageWidth, toShowImageHeight);
        CGContextSaveGState(currentContext);
        CGContextClipToRect(currentContext, clipRect);
        CGContextDrawImage(currentContext, drawRect, obj.CGImage);
        CGContextRestoreGState(currentContext);
    }];

    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    if (resultImage) {
        acc_dispatch_main_async_safe(^{
            self.backgroundColor = [UIColor colorWithPatternImage:resultImage];
        });
    }
}

@end
