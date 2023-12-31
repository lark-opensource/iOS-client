//
//  AWEImagesView.h
//  Aweme
//
// Created by Xuxu on December 24, 2017
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    AWEImagesViewContentModeStretch,// Stretching
    AWEImagesViewContentModePreserveAspectRatio,// Maintain aspect ratio
    AWEImagesViewContentModePreserveAspectRatioAndFill,// Maintain aspect ratio
} AWEImagesViewContentMode;

@interface AWEImagesView : UIView

// The height of the images is the same as that of aweimagesview,
// The actual scale of the image: aspect ratio.
// It will be tiled. For example, when there is only one image in imagearray, it will be tiled
- (void)refreshWithImageArray:(NSArray<UIImage *> *)imageArray aspectRatio:(CGFloat)aspectRatio mode:(AWEImagesViewContentMode)mode;

@end
