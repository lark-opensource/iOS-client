//
//  ACCPhotoWaterMarkUtil.m
//  Pods
//
//  Created by chengfei xiao on 2019/9/27.
//

#import "ACCPhotoWaterMarkUtil.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/ACCRTLProtocol.h>

const CGFloat ACCPhotoWaterMarkDesignResolution = 1920;
const CGFloat ACCEffectWaterMarkDesignResolution = 720;

@implementation ACCPhotoWaterMarkUtil

#pragma mark - public methods

+ (void)acc_addWaterMarkForSourceImage:(UIImage *)sourceImage waterMarkImageName:(NSString *)waterMarkImageName completion:(void(^)(UIImage *))completionBlock
{
    CGSize sizeInPixel = CGSizeMake(sourceImage.size.width * sourceImage.scale, sourceImage.size.height * sourceImage.scale);
    UIImage *waterMarkImage = [self p_fullSizeImageWithSourceImageSize:sizeInPixel waterMarkImageName:waterMarkImageName];
    
    CGRect rect = CGRectMake(0.0f, 0.0f, sourceImage.size.width, sourceImage.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, sourceImage.scale);
    
    [sourceImage drawInRect:rect];
    [waterMarkImage drawInRect:rect];
    
    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    ACCBLOCK_INVOKE(completionBlock, dstImage);
}

+ (void)acc_addWaterMarkForSourceImage:(UIImage *)sourceImage waterMarkImage:(UIImage *)waterMarkImage completion:(void(^)(UIImage *))completionBlock
{
    CGFloat destRightPadding = 16.0 / MAX(sourceImage.scale, 1.0);
    CGFloat destBottomPadding = 18.0 / MAX(sourceImage.scale, 1.0);
    CGRect destRect = CGRectMake(sourceImage.size.width - waterMarkImage.size.width - destRightPadding,
                                 sourceImage.size.height - waterMarkImage.size.height - destBottomPadding,
                                 waterMarkImage.size.width, waterMarkImage.size.height);
    CGRect rect = CGRectMake(0.0f, 0.0f, sourceImage.size.width, sourceImage.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, sourceImage.scale);
    
    [sourceImage drawInRect:rect];
    [waterMarkImage drawInRect:destRect];
    
    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    ACCBLOCK_INVOKE(completionBlock, dstImage);
}

+ (void)acc_addWaterMarkForSourceImage:(UIImage *)sourceImage completion:(void(^)(UIImage *))completionBlock
{
    [self acc_addWaterMarkForSourceImage:sourceImage waterMarkImageName:@"pictureWaterMark" completion:completionBlock];
}

+ (void)acc_addWatermarkForEffectSourceImage:(UIImage *)sourceImage userName:(NSString *)userName watermarkImage:(UIImage *)waterMarkImage completion:(ACCPhotoWateMarkCompletionBlock)completionBlock
{
    if (!sourceImage || sourceImage.size.width <= 0) {
        ACCBLOCK_INVOKE(completionBlock, nil);
        return;
    }
    CGSize sizeInPixel = CGSizeMake(sourceImage.size.width * sourceImage.scale, sourceImage.size.height * sourceImage.scale);
    CGFloat screenScale = [UIScreen mainScreen].scale;
    
    CGFloat scale = sizeInPixel.width / ACCEffectWaterMarkDesignResolution;
    
    CGFloat finalScale = scale / screenScale;
    CGFloat margin = 20 * finalScale;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:sourceImage];
    imageView.frame = CGRectMake(0, 0, sizeInPixel.width / screenScale, sizeInPixel.height / screenScale);
    
    // user name
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 6 * finalScale;
    shadow.shadowOffset = CGSizeMake(0, 2 * finalScale);
    shadow.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:userName attributes:@{
        NSShadowAttributeName: shadow,
        NSFontAttributeName: [ACCFont() systemFontOfSize:24 * finalScale weight:ACCFontWeightMedium],
        NSForegroundColorAttributeName : [UIColor whiteColor]
    }];
    UILabel *userNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    userNameLabel.attributedText = attributedString;
    CGSize userNameSize = [userNameLabel intrinsicContentSize];
    userNameLabel.frame = CGRectMake([ACCRTL() enableRTL] ? imageView.bounds.size.width - margin - userNameSize.width : margin,
                                     margin,
                                     userNameSize.width,
                                     userNameSize.height);
    [imageView addSubview:userNameLabel];
    
    //gradient
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.startPoint = CGPointMake(0, 0);
    layer.endPoint = CGPointMake(0, 1);
    layer.locations = @[@0, @1];
    layer.colors = @[(__bridge id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0001].CGColor, (__bridge id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2].CGColor];
    CGFloat gradientLayerHeight = 300 * finalScale;
    layer.frame = CGRectMake(0, imageView.bounds.size.height - gradientLayerHeight, imageView.bounds.size.width, gradientLayerHeight);
    [imageView.layer addSublayer:layer];
    
    //watermark
    CGFloat waterMarkWidth = waterMarkImage.size.width * waterMarkImage.scale * finalScale;
    CGFloat waterMarkHeight = waterMarkImage.size.height * waterMarkImage.scale * finalScale;
    UIImageView *waterMarkImageView = [[UIImageView alloc] initWithImage:waterMarkImage];
    waterMarkImageView.frame = CGRectMake(imageView.bounds.size.width - margin - waterMarkWidth,
                                          imageView.bounds.size.height - margin - waterMarkHeight,
                                          waterMarkWidth,
                                          waterMarkHeight);
    [imageView addSubview:waterMarkImageView];
    
    UIImage *dstImage = [self p_imageWithViewOnScreenScale:imageView];
    ACCBLOCK_INVOKE(completionBlock, dstImage);
}


#pragma mark - private methods

//传入原图的像素尺寸
+ (UIImage *)p_fullSizeImageWithSourceImageSize:(CGSize)sourceSize waterMarkImageName:(NSString *)waterMarkImageName
{
    //像素点转成point
    CGFloat screenScale = [UIScreen mainScreen].scale;
    CGSize sourceSizeToPoint = CGSizeMake(sourceSize.width / screenScale, sourceSize.height / screenScale);
    UIImage *waterMarkImage = ACCResourceImage(waterMarkImageName);

    CGFloat finalWaterMarkWidthInPoint = 0;
    CGFloat finalWaterMarkHeightInPoint = 0;

    CGFloat scale = 0;
    if (sourceSize.width > sourceSize.height) {//图片高度小，按照高度来除
        scale = sourceSize.height / ACCPhotoWaterMarkDesignResolution;
    } else {
        scale = sourceSize.width / ACCPhotoWaterMarkDesignResolution;
    }
    finalWaterMarkWidthInPoint = waterMarkImage.size.width * waterMarkImage.scale * scale / screenScale;
    finalWaterMarkHeightInPoint = waterMarkImage.size.height * waterMarkImage.scale * scale / screenScale;

    CGFloat waterMarkRightMarginInPoint = 52 * scale / screenScale;
    CGFloat waterMarkBottomMarginInPoint = 52 * scale / screenScale;

    UIImageView *waterMarkImageView = [[UIImageView alloc] initWithImage:waterMarkImage];
    waterMarkImageView.frame = CGRectMake(sourceSizeToPoint.width - finalWaterMarkWidthInPoint - waterMarkRightMarginInPoint, sourceSizeToPoint.height - finalWaterMarkHeightInPoint - waterMarkBottomMarginInPoint, finalWaterMarkWidthInPoint, finalWaterMarkHeightInPoint);

    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, sourceSizeToPoint.width, sourceSizeToPoint.height)];
    [containerView addSubview:waterMarkImageView];

    return [self p_imageWithViewOnScreenScale:containerView];
}

+ (UIImage *)p_fullSizeImageWithSourceImageSize:(CGSize)sourceSize waterMarkImage:(UIImage *)waterMarkImage
{
    //像素点转成point
    CGFloat screenScale = [UIScreen mainScreen].scale;
    CGSize sourceSizeToPoint = CGSizeMake(sourceSize.width / screenScale, sourceSize.height / screenScale);
    
    CGFloat finalWaterMarkWidthInPoint = 0;
    CGFloat finalWaterMarkHeightInPoint = 0;
    
    CGFloat scale = 0;
    if (sourceSize.width > sourceSize.height) {//图片高度小，按照高度来除
        scale = sourceSize.height / ACCPhotoWaterMarkDesignResolution;
    } else {
        scale = sourceSize.width / ACCPhotoWaterMarkDesignResolution;
    }
    finalWaterMarkWidthInPoint = waterMarkImage.size.width * waterMarkImage.scale * scale / screenScale;
    finalWaterMarkHeightInPoint = waterMarkImage.size.height * waterMarkImage.scale * scale / screenScale;
    
    CGFloat waterMarkRightMarginInPoint = 52 * scale / screenScale;
    CGFloat waterMarkBottomMarginInPoint = 52 * scale / screenScale;
    
    UIImageView *waterMarkImageView = [[UIImageView alloc] initWithImage:waterMarkImage];
    waterMarkImageView.frame = CGRectMake(sourceSizeToPoint.width - finalWaterMarkWidthInPoint - waterMarkRightMarginInPoint, sourceSizeToPoint.height - finalWaterMarkHeightInPoint - waterMarkBottomMarginInPoint, finalWaterMarkWidthInPoint, finalWaterMarkHeightInPoint);
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, sourceSizeToPoint.width, sourceSizeToPoint.height)];
    [containerView addSubview:waterMarkImageView];
    
    return [self p_imageWithViewOnScreenScale:containerView];
}

+ (UIImage *)p_imageWithViewOnScreenScale:(UIView *)view
{
    CGSize s = view.bounds.size;
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
