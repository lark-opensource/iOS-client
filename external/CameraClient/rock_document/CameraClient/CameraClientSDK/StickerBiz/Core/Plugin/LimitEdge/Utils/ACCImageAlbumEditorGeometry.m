//
//  ACCImageAlbumEditorGeometry.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/25.
//

#import "ACCImageAlbumEditorGeometry.h"
#import <CreativeKit/ACCMacros.h>

BOOL ACCImageEditWidthIsValid(CGFloat width) {
    return isfinite(width) && ACC_FLOAT_GREATER_THAN(width, ACC_FLOAT_ZERO);
}

BOOL ACCImageEditSizeIsValid(CGSize size) {
    return (ACCImageEditWidthIsValid(size.width) && ACCImageEditWidthIsValid(size.height));
}

BOOL ACCImageEditRatioIs16To9(CGSize size)
{
    if (!ACCImageEditSizeIsValid(size)) {
        return NO;
    }
    if (fabs(size.height / size.width - 16.f / 9.f) > 0.005f) {
        return NO;
    }
    return YES;
}

UIViewContentMode ACCImageEditGetWidthFitImageDisplayContentMode(CGSize imageSize, CGSize contentSize)
{
    if (!ACCImageEditSizeIsValid(contentSize) || !ACCImageEditSizeIsValid(imageSize)) {
        return UIViewContentModeScaleAspectFit;
    }

    CGFloat playFrameRatio = contentSize.width / contentSize.height;
    CGFloat imageRatio = imageSize.width / imageSize.height;
    
    // 16:9由于是高度撑满 所以刚好相反
    if (ACCImageEditRatioIs16To9(imageSize)) {
        return  (imageRatio >= playFrameRatio) ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
    } else {
        return  (imageRatio >= playFrameRatio) ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
    }
}

CGRect ACCImageEditorMakeRectWithAspectRatioOutsideRect(CGSize aspectRatio, CGRect boundingRect)
{
    if (!ACCImageEditSizeIsValid(aspectRatio) || !ACCImageEditSizeIsValid(boundingRect.size)) {
        return boundingRect;
    }
    
    CGSize boundingSize =  boundingRect.size;
    
    CGFloat targetWidthScale = aspectRatio.width / boundingSize.width;
    CGFloat targetHeightScale = aspectRatio.height / boundingSize.height;
    
    CGFloat realScale = MIN(targetWidthScale, targetHeightScale);

    CGSize graphicsSize = CGSizeMake(aspectRatio.width / realScale, aspectRatio.height / realScale);
    CGFloat dx = graphicsSize.width / 2.f - boundingSize.width / 2.f;
    CGFloat dy = graphicsSize.height / 2.f - boundingSize.height / 2.f;
    
    return CGRectMake(-dx + CGRectGetMinX(boundingRect), -dy + CGRectGetMinY(boundingRect), graphicsSize.width, graphicsSize.height);
}

CGSize ACCImageEditGetWidthFitImageDisplaySize(CGSize imageSize, CGSize contentSize, BOOL needClipHeight)
{
    if (!ACCImageEditSizeIsValid(imageSize) ||
        !ACCImageEditSizeIsValid(contentSize)) {
        
        return CGSizeZero;
    }
    
    // 等比缩放和屏幕等宽，超出高度的裁剪
    CGFloat layerWidth = contentSize.width;
    
    CGFloat w_h_ratio = imageSize.width / layerWidth;
    
    CGFloat layerHeight = imageSize.height / w_h_ratio;
    
    // 超出高度的裁剪
    if (needClipHeight) {
        layerHeight = MIN(contentSize.height, layerHeight);
    }
    return CGSizeMake(layerWidth, layerHeight);
}

CGSize  ACCImageEditGetHeightFitImageDisplaySize(CGSize imageSize, CGSize contentSize, BOOL needClipWidth)
{
    if (!ACCImageEditSizeIsValid(imageSize) ||
        !ACCImageEditSizeIsValid(contentSize)) {
        
        return CGSizeZero;
    }
    
    // 等比缩放和屏幕等高，超出宽度的裁剪
    CGFloat layerHeight = contentSize.height;
    
    CGFloat h_w_ratio = imageSize.height / layerHeight;
    
    CGFloat layerWidth = imageSize.width / h_w_ratio;
    
    // 超出宽度的裁剪
    if (needClipWidth) {
        layerWidth = MIN(contentSize.width, layerWidth);
    }
    return CGSizeMake(layerWidth, layerHeight);
}

CGRect ACCImageEditorMakeRectWithAspectRatio16To9(CGSize containerSize, CGSize imageSize)
{
    CGRect defaultRect = CGRectMake(0, 0, containerSize.width, containerSize.height);
    
    if (!ACCImageEditSizeIsValid(containerSize) || !ACCImageEditSizeIsValid(imageSize)) {
        return defaultRect;
    }
    
    if (!ACCImageEditRatioIs16To9(imageSize)) {
        return defaultRect;
    } else {
        CGFloat contentHeight = containerSize.height;
        CGFloat contentWidth = contentHeight / 16.f * 9.f;
        return CGRectMake((containerSize.width - contentWidth) / 2, 0, contentWidth, contentHeight);
    }
}

/*
视频贴纸端上坐标系(中心绝对)
               +y
                ↑·> (0,300)
                |
                |
  (-300,0)      |             (300,0)
 --^----------(0,0)-----------^--> +x
                |
                |
                |
                |·>(0,-300)
 
图文贴纸VE&端上的坐标系(左上相对)
······························player
· (0,0)------------------->x ·
· |                   (1,0)  ·
· |                          ·
· |            |             ·
· |       -(0.5,0.5) -       ·
· |            |             ·
· |                          ·
· |                          ·
· ↓                          ·
· (0,1)               (1,1)  ·
y······························

*/
CGPoint ACCImageEditorCovertVideoCenterAbsoluteOffsetToImageOffset(CGPoint videoOffset, CGSize imageLayerSize)
{
    if (!ACCImageEditSizeIsValid(imageLayerSize)) {
        return CGPointZero;
    }
    CGSize halfImageSize = CGSizeMake(imageLayerSize.width/2, imageLayerSize.height/2);
    
    CGSize offsetSize = CGSizeMake(halfImageSize.width + videoOffset.x, halfImageSize.height - videoOffset.y);
    
    CGPoint imageOffset = CGPointMake(offsetSize.width / imageLayerSize.width, offsetSize.height / imageLayerSize.height);
    
    return imageOffset;
}

@implementation ACCImageAlbumEditorGeometry

@end
