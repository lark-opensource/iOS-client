//
//  AWEStickerSwitchImageView.m
//  Aweme
//
//  Created by 郝一鹏 on 2017/7/4.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWEStickerSwitchImageView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <BDWebImage/UIImage+BDImageTransform.h>
#import <BDWebImage/UIImage+BDWebImage.h>

@implementation AWEStickerSwitchImageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.coverMarkImgView];
        [self.coverMarkImgView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    
    [self.coverMarkImgView removeObserver:self forKeyPath:@"image"];
}

#pragma mark - markImage 出现/消失

- (void)coverMarkImgViewAppear {
    
    self.coverMarkImgView.hidden = NO;
    self.coverMarkImgView.transform = CGAffineTransformMakeScale(0.0, 0.0);
    [UIView animateKeyframesWithDuration:1
                                   delay:0.3
                                 options:UIViewKeyframeAnimationOptionCalculationModeLinear
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:0.7
                                                                animations:^{
                                                                    self.coverMarkImgView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:0.7
                                                          relativeDuration:0.3
                                                                animations:^{
                                                                    self.coverMarkImgView.transform = CGAffineTransformIdentity;
                                                                }];
                              }
                              completion:nil];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"image"]) {
        UIImage *newImage = change[NSKeyValueChangeNewKey];
        if ((NSNull *)newImage == [NSNull null]) {
            return;
        }
        if (!CGSizeEqualToSize(newImage.size, CGSizeZero)) {
            CGSize scaleSize = CGSizeMake(newImage.size.width / 3 * [UIScreen mainScreen].scale, newImage.size.height / 3 * [UIScreen mainScreen].scale);
            self.coverMarkImgView.frame = CGRectMake(21, self.frame.size.height - 32 - scaleSize.height, scaleSize.width, scaleSize.height);
            [self coverMarkImgViewAppear];
        }
    }
}

#pragma mark - lazy init prop

- (BDImageView *)coverMarkImgView {
    
    if (!_coverMarkImgView) {
        _coverMarkImgView = [[BDImageView alloc] initWithFrame:CGRectMake(42, self.frame.size.height - 64, 0, 0)];
        _coverMarkImgView.autoPlayAnimatedImage = YES;
        _coverMarkImgView.layer.anchorPoint = CGPointMake(0, 1.0);
        _coverMarkImgView.hidden = YES;
    }
    return _coverMarkImgView;
}

- (UIImage *)defaultImage {
    if (!_defaultImage) {
        _defaultImage = ACCResourceImage(@"icon_sticker");
    }
    return _defaultImage;
}

#pragma mark - public method

- (void)replaceCoverImageWithImage:(UIImage *)newImage isDynamic:(BOOL)isDynamic {
    
    if (!newImage) {
        newImage = self.defaultImage;
    }
    if (self.image == newImage) {
        return;
    }

    if (isDynamic) {
        newImage = [UIImage bd_imageWithData:newImage.bd_imageDataRepresentation downsampleSize:self.bounds.size];
    } else {
        newImage = [newImage bd_imageByResizeToSize:self.bounds.size];
    }

    [UIView animateKeyframesWithDuration:0.3
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionCalculationModeLinear
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:0.5
                                                                animations:^{
                                                                    self.transform = CGAffineTransformMakeScale(0.01, 0.01);
                                                                }];
                                  self.image = newImage;
                                  [UIView addKeyframeWithRelativeStartTime:0.5
                                                          relativeDuration:0.5
                                                                animations:^{
                                                                    self.transform = CGAffineTransformIdentity;
                                                                }];
                              }
                              completion:nil];
}

@end
