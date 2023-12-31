//
//  AWEStickerHintView.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/7/23.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <BDWebImage/BDImageView.h>
#import <CameraClient/AWEStickerHintView.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <KVOController/NSObject+FBKVOController.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEStickerHintView ()

@property (nonatomic, strong) UILabel *stickerTipLabel; // 道具提示标签
@property (nonatomic, strong) UIImageView *stickerTipImageView; // 道具提示图片

@property (nonatomic, strong) UIView *stickerTipAnimatedContainerView;
@property (nonatomic, strong) UIImageView *stickerTipAnimatedImageView; // 道具提示动态图片
@property (nonatomic, strong) UILabel *stickerTipAnimatedLabel;

@property (nonatomic, strong) IESEffectModel *stickerModel;

@property (nonatomic, strong) UILabel *stickerTipLottieLabel; //effect instructions lottie type
@property (nonatomic, strong) LOTAnimationView *stickerTipLottieView;

@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation AWEStickerHintView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.stickerTipLabel];
        [self.stickerTipLabel mas_makeConstraints:^(MASConstraintMaker *maker) {
            maker.bottom.equalTo(self).offset(-134);
            maker.centerX.equalTo(self.mas_centerX);
            maker.width.lessThanOrEqualTo(@(ACC_SCREEN_WIDTH - 100));
        }];
        [self addSubview:self.stickerTipImageView];
        ACCMasMaker(self.stickerTipImageView, {
            make.bottom.equalTo(self.stickerTipLabel.mas_top).offset(-12);
            make.centerX.equalTo(self.mas_centerX);
            make.width.lessThanOrEqualTo(@120);
            make.height.lessThanOrEqualTo(@60);
        });
    }
    return self;
}

#pragma mark - Getter & setter

- (UILabel *)stickerTipLabel {
    if (!_stickerTipLabel) {
        _stickerTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _stickerTipLabel.font = [ACCFont() acc_boldSystemFontOfSize:17];
        _stickerTipLabel.textAlignment = NSTextAlignmentCenter;
        _stickerTipLabel.textColor = ACCResourceColor(ACCUIColorConstIconInverse2);
        _stickerTipLabel.layer.shadowColor = ACCResourceColor(ACCUIColorConstGradient).CGColor;
        _stickerTipLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        _stickerTipLabel.layer.shadowOpacity = 1.0f;
        _stickerTipLabel.hidden = YES;
        _stickerTipLabel.numberOfLines = 0;
    }
    return _stickerTipLabel;
}

- (UIImageView *)stickerTipImageView
{
    if (!_stickerTipImageView) {
        _stickerTipImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _stickerTipImageView.contentMode = UIViewContentModeScaleAspectFit;
        _stickerTipImageView.hidden = YES;
    }
    return _stickerTipImageView;
}

- (UIView *)stickerTipAnimatedContainerView {
    if (!_stickerTipAnimatedContainerView) {
        _stickerTipAnimatedContainerView = [[UIView alloc] init];
        _stickerTipAnimatedContainerView.layer.cornerRadius = 6;
        _stickerTipAnimatedContainerView.layer.borderColor = ACCResourceColor(ACCUIColorConstIconInverse2).CGColor;
        _stickerTipAnimatedContainerView.layer.borderWidth = 4;
    }
    return _stickerTipAnimatedContainerView;
}

- (UIImageView *)stickerTipAnimatedImageView {
    if (!_stickerTipAnimatedImageView) {
        _stickerTipAnimatedImageView = [ACCWebImage() animatedImageView];
        _stickerTipImageView.contentMode = UIViewContentModeScaleAspectFit;
        _stickerTipImageView.hidden = YES;
    }
    return _stickerTipAnimatedImageView;
}

- (UILabel *)stickerTipAnimatedLabel {
    if (!_stickerTipAnimatedLabel) {
        _stickerTipAnimatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _stickerTipAnimatedLabel.font = [ACCFont() acc_boldSystemFontOfSize:17];
        _stickerTipAnimatedLabel.textAlignment = NSTextAlignmentCenter;
        _stickerTipAnimatedLabel.textColor = ACCResourceColor(ACCUIColorConstIconInverse2);
        _stickerTipAnimatedLabel.layer.shadowColor = ACCResourceColor(ACCUIColorConstGradient).CGColor;
        _stickerTipAnimatedLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        _stickerTipAnimatedLabel.layer.shadowOpacity = 1.0f;
        _stickerTipAnimatedLabel.hidden = YES;
        _stickerTipAnimatedLabel.numberOfLines = 0;
    }
    return _stickerTipAnimatedLabel;
}

- (UILabel *)stickerTipLottieLabel {
    if (!_stickerTipLottieLabel) {
        _stickerTipLottieLabel = [[UILabel alloc] init];
        _stickerTipLottieLabel.font = [ACCFont() acc_boldSystemFontOfSize:17];
        _stickerTipLottieLabel.textAlignment = NSTextAlignmentCenter;
        _stickerTipLottieLabel.textColor = ACCResourceColor(ACCUIColorConstIconInverse2);
        _stickerTipLottieLabel.layer.shadowColor = ACCResourceColor(ACCUIColorConstGradient).CGColor;
        _stickerTipLottieLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        _stickerTipLottieLabel.layer.shadowOpacity = 1.0f;
        _stickerTipLottieLabel.hidden = YES;
        _stickerTipLottieLabel.numberOfLines = 0;
    }
    return _stickerTipLottieLabel;
}

- (LOTAnimationView *)stickerTipLottieView
{
    if (!_stickerTipLottieView) {
        _stickerTipLottieView = [[LOTAnimationView alloc] init];
        _stickerTipLottieView.loopAnimation = NO;
        _stickerTipLottieView.userInteractionEnabled = NO;
        _stickerTipLottieView.contentMode = UIViewContentModeScaleAspectFit;
        _stickerTipLottieView.hidden = YES;
    }
    return _stickerTipLottieView;
}

- (UIButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.userInteractionEnabled = YES;
        [_closeButton addTarget:self action:@selector(closeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton setImage:ACCResourceImage(@"icon_sticker_hint_close") forState:UIControlStateNormal];
    }
    return _closeButton;
}

#pragma mark - action

- (void)closeButtonClicked
{
    [self stopGifTipsAnimation];
    [self stopLottieTipsAnimation];
}

#pragma mark - public

- (void)showWithEffect:(IESEffectModel *)model
{
    self.stickerModel = model;
    [self remove];
    
    if (!ACC_isEmptyArray(self.stickerModel.hintFileURLs)) { // has guide text and guide image
        NSData *data = [self.stickerModel.extra dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            BOOL isGifType = [[jsonDict allKeys] containsObject:@"gif_type"];
            BOOL isLottieType = [[jsonDict allKeys] containsObject:@"lottie_type"];
            BOOL showCloseButton = [jsonDict[@"manual_close"] boolValue];
            if (isLottieType) {
                [self showLottieTipsAnimationWithLottieType:[jsonDict[@"lottie_type"] integerValue] showCloseButton:showCloseButton];
                return;
            }
            
            if (isGifType) {
                //gif样式引导和提示
                [self showGifTipsAnimationWithGifType:[jsonDict[@"gif_type"] integerValue] showCloseButton:showCloseButton];
                return;
            }
        }
        // 普通样式的引导图片和提示
        [self.stickerTipLabel mas_updateConstraints:^(MASConstraintMaker *maker) {
            maker.bottom.equalTo(self).offset(-134);
        }];
        
        self.stickerTipLabel.text = model.hintLabel;
        [ACCWebImage() imageView:self.stickerTipImageView setImageWithURLArray:self.stickerModel.hintFileURLs];
        self.stickerTipImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.stickerTipLabel.alpha = 0.0;
        self.stickerTipImageView.alpha = 0.0;
        self.stickerTipLabel.hidden = NO;
        self.stickerTipImageView.hidden = NO;
        [self startAnimation];
    } else if (!ACC_isEmptyString(self.stickerModel.hintLabel)) { // 只有引导文字
        [self showWithTitle:model.hintLabel];
    }
}

- (void)showPhotoSensitiveWithEffect:(IESEffectModel *)model
{
    [self remove];
    self.isShowing = YES;
    ACCBLOCK_INVOKE(self.hintViewShowBlock, self.isShowing);
    self.stickerTipImageView.image = ACCResourceImage(@"icon_sticker_photosensitive");
    self.stickerTipLabel.text = ACCLocalizedString(@"photosensitive_seizure_warning", @"");
    self.stickerTipImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.stickerTipLabel.alpha = 0.0;
    self.stickerTipImageView.alpha = 0.0;
    self.stickerTipLabel.hidden = NO;
    self.stickerTipImageView.hidden = NO;
    [UIView animateWithDuration:0.15 animations:^{
        self.stickerTipLabel.alpha = 1.0;
        self.stickerTipImageView.alpha = 1.0;
    }];
}

- (void)removePhotoSensitiveHint
{
    [UIView animateWithDuration:0.15 animations:^{
        self.stickerTipLabel.alpha = 0.0;
        self.stickerTipImageView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self remove];
    }];
}

- (void)showWithTitle:(NSString *)title
{
    [self remove];
    self.isShowing = YES;
    ACCBLOCK_INVOKE(self.hintViewShowBlock, self.isShowing);
    [self.stickerTipLabel mas_remakeConstraints:^(MASConstraintMaker *maker) {
        maker.top.equalTo(self).offset(ACC_SCREEN_HEIGHT / 2 - 56);
        maker.centerX.equalTo(self.mas_centerX);
        maker.width.lessThanOrEqualTo(@(ACC_SCREEN_WIDTH - 100));
    }];
    
    self.stickerTipLabel.text = title;
    self.stickerTipLabel.alpha = 0.0;
    self.stickerTipLabel.hidden = NO;
    [self startAnimation];
}

- (void)showWithTitleRepeat:(NSString *)title
{
    [self remove];
    self.isShowing = YES;
    ACCBLOCK_INVOKE(self.hintViewShowBlock, self.isShowing);
    [self.stickerTipLabel mas_updateConstraints:^(MASConstraintMaker *maker) {
        maker.bottom.equalTo(self).offset(-166);
    }];
    
    self.stickerTipLabel.text = title;
    self.stickerTipLabel.alpha = 0.0;
    self.stickerTipLabel.hidden = NO;
    [self startAnimationRepeat];
}

#pragma mark - Private

- (void)startAnimation
{
    CGFloat appearDismissDuration = 0.3f;
    CGFloat changeAlpahDuration = 0.8f;
    CGFloat totalDuration = appearDismissDuration * 2 + changeAlpahDuration * 6;
    [UIView animateKeyframesWithDuration:totalDuration
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionBeginFromCurrentState
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:(appearDismissDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 1.0;
                                                                    self.stickerTipImageView.alpha = 1.0;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:(appearDismissDuration / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 0.3;
                                                                    self.stickerTipImageView.alpha = 0.3;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((appearDismissDuration + changeAlpahDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 1.0;
                                                                    self.stickerTipImageView.alpha = 1.0;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 2 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 0.3;
                                                                    self.stickerTipImageView.alpha = 0.3;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 3 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 1.0;
                                                                    self.stickerTipImageView.alpha = 1.0;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 4 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 0.3;
                                                                    self.stickerTipImageView.alpha = 0.3;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 5 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 1.0;
                                                                    self.stickerTipImageView.alpha = 1.0;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 6 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(appearDismissDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 0.0;
                                                                    self.stickerTipImageView.alpha = 0.0;
                                                                }];
                              }
                              completion:^(BOOL finished) {
                                    if (finished) {
                                        [self remove];
                                    }

                                    ACCBLOCK_INVOKE(self.duetGreenScreenHintViewCompletionBlock);
                              }];
}

- (void)startAnimationRepeat
{
    CGFloat appearDismissDuration = 0.3f;
    CGFloat changeAlpahDuration = 0.8f;
    CGFloat totalDuration = appearDismissDuration * 2 + changeAlpahDuration * 6;
    [UIView animateKeyframesWithDuration:totalDuration
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewKeyframeAnimationOptionRepeat
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:(appearDismissDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 1.0;
                                                                    self.stickerTipImageView.alpha = 1.0;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:(appearDismissDuration / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 0.3;
                                                                    self.stickerTipImageView.alpha = 0.3;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((appearDismissDuration + changeAlpahDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 1.0;
                                                                    self.stickerTipImageView.alpha = 1.0;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 2 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 0.3;
                                                                    self.stickerTipImageView.alpha = 0.3;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 3 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 1.0;
                                                                    self.stickerTipImageView.alpha = 1.0;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 4 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 0.3;
                                                                    self.stickerTipImageView.alpha = 0.3;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 5 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(changeAlpahDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 1.0;
                                                                    self.stickerTipImageView.alpha = 1.0;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:((changeAlpahDuration * 6 + appearDismissDuration) / totalDuration)
                                                          relativeDuration:(appearDismissDuration / totalDuration)
                                                                animations:^{
                                                                    self.stickerTipLabel.alpha = 0.0;
                                                                    self.stickerTipImageView.alpha = 0.0;
                                                                }];
                              }
                              completion:^(BOOL finished) {
                                    if (finished) {
                                        [self remove];
                                    }
                              }];
}

- (void)startGifTipsAnimationWithImage:(UIImage *)image
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self.stickerTipAnimatedImageView isKindOfClass:[BDImageView class]]) {
        BDImageView *animatedImageView = (BDImageView *)self.stickerTipAnimatedImageView;
        __block NSInteger count = 0;
        @weakify(self);
        [animatedImageView setLoopCompletionBlock:^{
            @strongify(self);
            count++;
            if (count > 1) {
                [self stopGifTipsAnimation];
            }
        }];
    } else {
        if (![self.stickerTipAnimatedImageView respondsToSelector:@selector(currentAnimatedImageIndex)]) {
            return;
        }
        __block NSInteger count = 0;
        [self.KVOController unobserveAll];
        @weakify(self);
        [self.KVOController observe:self.stickerTipAnimatedImageView keyPath:NSStringFromSelector(@selector(currentAnimatedImageIndex)) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            @strongify(self);
            if ([change[@"new"] integerValue] == 0) {
                count += 1;
                if (count > 1) {
                    [self stopGifTipsAnimation];
                    [self.KVOController unobserve:self.stickerTipAnimatedImageView];
                }
            }
        }];
    }
    
#pragma clang diagnostic pop
    
    self.stickerTipAnimatedImageView.image = image;
    self.stickerTipAnimatedImageView.hidden = NO;
    self.stickerTipAnimatedLabel.hidden = NO;
    self.stickerTipAnimatedContainerView.hidden = NO;
    self.stickerTipAnimatedContainerView.alpha = 0;
    self.stickerTipAnimatedLabel.alpha = 0;
    [UIView animateWithDuration:0.3f animations:^{
        self.stickerTipAnimatedContainerView.alpha = 1.0;
    }];
    
    [UIView animateKeyframesWithDuration:3.4
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionRepeat
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:0.2/3.4
                                                                animations:^{
                                                                    self.stickerTipAnimatedLabel.alpha = 1.0;
                                                                    
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:0.2/3.4
                                                          relativeDuration:3/3.4
                                                                animations:^{
                                                                    self.stickerTipAnimatedLabel.alpha = 1;

                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:3.2/3.4
                                                          relativeDuration:0.2/3.4
                                                                animations:^{
                                                                    self.stickerTipAnimatedLabel.alpha = 0;
                                                                }];
                              }
                              completion:^(BOOL finished) {
                                    if (finished) {
                                        [self remove];
                                    }
                              }];
}

- (void)stopGifTipsAnimation
{
    if (!self.isShowing) {
        return;
    }
    [self.stickerTipAnimatedImageView stopAnimating];
    [self.stickerTipAnimatedLabel.layer removeAllAnimations];
    [UIView animateWithDuration:.3 animations:^{
        self.stickerTipAnimatedContainerView.alpha = 0;
        self.stickerTipAnimatedLabel.alpha = 0;
    } completion:^(BOOL finished) {
        [self remove];
    }];
}

- (void)showGifTipsAnimationWithGifType:(NSInteger)gifType showCloseButton:(BOOL)showCloseButton
{
    self.isShowing = YES;
    ACCBLOCK_INVOKE(self.hintViewShowBlock, self.isShowing);

    // Gif hint, gitType == 1 represents horizontal view,  gifType == 2 represents vertical view
    if (self.stickerTipAnimatedContainerView.superview != self) {
        [self.stickerTipAnimatedImageView removeFromSuperview];
        [self.stickerTipAnimatedContainerView removeFromSuperview];
        [self.stickerTipAnimatedLabel removeFromSuperview];
        [self addSubview:self.stickerTipAnimatedContainerView];
        [self.stickerTipAnimatedContainerView addSubview:self.stickerTipAnimatedImageView];
        [self addSubview:self.stickerTipAnimatedLabel];

        if (gifType == 2) {
            // 竖版  2
            ACCMasReMaker(self.stickerTipAnimatedContainerView, {
                make.leading.equalTo(self.mas_leading).offset(94).priority(999);
                make.trailing.equalTo(self.mas_trailing).offset(-94).priority(999);
                make.width.lessThanOrEqualTo(@180).priority(1000);
                make.height.lessThanOrEqualTo(@240).priority(1000);
                make.height.equalTo(self.stickerTipAnimatedContainerView.mas_width).multipliedBy(1.33);
                make.centerX.equalTo(self);
                make.centerY.equalTo(self.mas_centerY).offset(-10);
            });
        } else {
            // 横版  1
            ACCMasReMaker(self.stickerTipAnimatedContainerView, {
                make.leading.equalTo(self.mas_leading).offset(64).priority(999);
                make.trailing.equalTo(self.mas_trailing).offset(-64).priority(999);
                make.width.lessThanOrEqualTo(@240).priority(1000);
                make.height.lessThanOrEqualTo(@180).priority(1000);
                make.height.equalTo(self.stickerTipAnimatedContainerView.mas_width).multipliedBy(0.75);
                make.centerX.equalTo(self);
                make.centerY.equalTo(self.mas_centerY).offset(-10);
            });
        }

        ACCMasMaker(self.stickerTipAnimatedImageView, {
            make.top.leading.offset(8);
            make.bottom.trailing.offset(-8);
        });

        [self.stickerTipAnimatedLabel mas_makeConstraints:^(MASConstraintMaker *maker) {
            maker.top.equalTo(self.stickerTipAnimatedContainerView.mas_bottom).offset(20);
            maker.centerX.equalTo(self.mas_centerX);
            maker.width.lessThanOrEqualTo(@(ACC_SCREEN_WIDTH - 100));
        }];
        
        if (showCloseButton) {
            self.userInteractionEnabled = YES;
            self.stickerTipAnimatedImageView.userInteractionEnabled = YES;
            [self.stickerTipAnimatedImageView addSubview:self.closeButton];
            self.closeButton.hidden = NO;
            ACCMasMaker(self.closeButton, {
                make.width.equalTo(@24);
                make.height.equalTo(@24);
                make.top.equalTo(self.stickerTipAnimatedImageView.mas_top).offset(4);
                make.trailing.equalTo(self.stickerTipAnimatedImageView.mas_trailing).offset(-4);
            });
        }
    }

    
    self.stickerTipAnimatedLabel.text = self.stickerModel.hintLabel;
    // 加载gif
    [ACCWebImage() requestImageWithURLArray:self.stickerModel.hintFileURLs
                                     completion:^(UIImage *image, NSURL *url, NSError *error) {
                                         if (!image || !url || error) {
                                             return;
                                         }
                                         acc_dispatch_main_async_safe(^{
                                             if (self.isShowing) {
                                                 [self startGifTipsAnimationWithImage:image];
                                             }
                                         });
                                     }];
}

- (void)showLottieTipsAnimationWithLottieType:(NSInteger)lottieType showCloseButton:(BOOL)showCloseButton
{
    self.isShowing = YES;
    ACCBLOCK_INVOKE(self.hintViewShowBlock, self.isShowing);

    // Lottie hint, lottieType == 1 represents horizontal view, lottieType == 2 represents vertical view
    if (self.stickerTipLottieView.superview != self) {
        [self.stickerTipLottieView removeFromSuperview];
        [self.stickerTipLottieLabel removeFromSuperview];
        [self addSubview:self.stickerTipLottieView];
        [self addSubview:self.stickerTipLottieLabel];
        
        if (lottieType == 1) {
            //横向
            ACCMasMaker(self.stickerTipLottieView, {
                make.leading.equalTo(self.mas_leading).offset(64).priority(999);
                make.trailing.equalTo(self.mas_trailing).offset(-64).priority(999);
                make.width.lessThanOrEqualTo(@240).priority(1000);
                make.height.lessThanOrEqualTo(@180).priority(1000);
                make.height.equalTo(self.stickerTipLottieView.mas_width).multipliedBy(0.75);
                make.centerX.equalTo(self);
                make.centerY.equalTo(self.mas_centerY).offset(-10);
            });
        } else if (lottieType == 2) {
            //纵向
            ACCMasMaker(self.stickerTipLottieView, {
                make.leading.equalTo(self.mas_leading).offset(94).priority(999);
                make.trailing.equalTo(self.mas_trailing).offset(-94).priority(999);
                make.height.lessThanOrEqualTo(@240).priority(1000);
                make.width.lessThanOrEqualTo(@180).priority(1000);
                make.height.equalTo(self.stickerTipLottieView.mas_width).multipliedBy(1.33);
                make.centerX.equalTo(self);
                make.centerY.equalTo(self.mas_centerY).offset(-10);
            });
        }
        ACCMasMaker(self.stickerTipLottieLabel, {
            make.top.equalTo(self.stickerTipLottieView.mas_bottom).offset(20);
            make.centerX.equalTo(self.mas_centerX);
            make.width.lessThanOrEqualTo(@(ACC_SCREEN_WIDTH - 100));
        });
        
        if (showCloseButton) {
            self.userInteractionEnabled = YES;
            self.stickerTipLottieView.userInteractionEnabled = YES;
            [self.stickerTipLottieView addSubview:self.closeButton];
            self.closeButton.hidden = NO;
            ACCMasMaker(self.closeButton, {
                make.width.equalTo(@24);
                make.height.equalTo(@24);
                make.top.equalTo(self.stickerTipLottieView.mas_top).offset(4);
                make.trailing.equalTo(self.stickerTipLottieView.mas_trailing).offset(-4);
            });
        }
    }
    
    self.stickerTipLottieLabel.text = self.stickerModel.hintLabel;
    @weakify(self);
    [self downloadLottieWithJSONUrl:self.stickerModel.hintFileURLs.firstObject completion:^(NSDictionary * _Nullable animationJSON) {
        @strongify(self);
        if (!animationJSON) {
            return;
        }
        acc_dispatch_main_async_safe(^{
            if (self.isShowing) {
                [self startLottieTipsAnimationWithJSON:animationJSON];
            }
        });
    }];
}

- (void)startLottieTipsAnimationWithJSON:(NSDictionary *)animationJSON
{
    [self.stickerTipLottieView setAnimationFromJSON:animationJSON];
    self.stickerTipLottieView.hidden = NO;
    self.stickerTipLottieLabel.hidden = NO;
    self.stickerTipLottieView.alpha = 0;
    self.stickerTipLottieLabel.alpha = 0;
    [UIView animateWithDuration:0.3f animations:^{
        self.stickerTipLottieView.alpha = 1.0;
    }];
    
    @weakify(self);
    [self.stickerTipLottieView playWithCompletion:^(BOOL animationFinished) {
        @strongify(self);
        [self.stickerTipLottieView playWithCompletion:^(BOOL animationFinished) {
            @strongify(self);
            [self stopLottieTipsAnimation];
        }];
    }];
    
    [UIView animateKeyframesWithDuration:3.4
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionRepeat
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:0.2/3.4
                                                                animations:^{
                                                                    self.stickerTipLottieLabel.alpha = 1.0;
                                                                    
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:0.2/3.4
                                                          relativeDuration:3/3.4
                                                                animations:^{
                                                                    self.stickerTipLottieLabel.alpha = 1;

                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:3.2/3.4
                                                          relativeDuration:0.2/3.4
                                                                animations:^{
                                                                    self.stickerTipLottieLabel.alpha = 0;
                                                                }];
                              }
                              completion:^(BOOL finished) {
                                    if (finished) {
                                        [self remove];
                                    }
                              }];
}

- (void)stopLottieTipsAnimation
{
    if (!self.isShowing) {
        return;
    }
    [self.stickerTipLottieLabel.layer removeAllAnimations];
    [UIView animateWithDuration:.3 animations:^{
        self.stickerTipLottieView.alpha = 0;
        self.stickerTipLottieLabel.alpha = 0;
    } completion:^(BOOL finished) {
        [self remove];
    }];
}

- (void)remove
{
    [self.stickerTipLabel.layer removeAllAnimations];
    [self.stickerTipImageView.layer removeAllAnimations];
    self.stickerTipLabel.hidden = YES;
    self.stickerTipImageView.hidden = YES;
    
    [self.stickerTipAnimatedLabel removeFromSuperview];
    [self.stickerTipAnimatedImageView removeFromSuperview];
    [self.stickerTipAnimatedContainerView removeFromSuperview];
    [self.stickerTipLottieView setCompletionBlock:nil];
    [self.stickerTipLottieView removeFromSuperview];
    [self.stickerTipLottieLabel removeFromSuperview];
    [self.closeButton removeFromSuperview];
    self.stickerTipAnimatedLabel.hidden = YES;
    self.stickerTipAnimatedImageView.hidden = YES;
    self.stickerTipAnimatedContainerView.hidden = YES;
    self.stickerTipLottieView.hidden = YES;
    self.stickerTipLottieView = nil;
    self.stickerTipLottieLabel.hidden = YES;
    self.closeButton.hidden = YES;
    self.isShowing = NO;
    ACCBLOCK_INVOKE(self.hintViewShowBlock, self.isShowing);
}

- (void)downloadLottieWithJSONUrl:(NSString *)urlString completion:(void(^)(NSDictionary * _Nullable animationJSON))completion
{
    if (urlString) {
        [ACCNetService() requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
            requestModel.requestType = ACCRequestTypeGET;
            requestModel.urlString = urlString;
        } completion:^(NSDictionary * _Nullable dic, NSError * _Nullable error) {
            if (dic && !error) {
                ACCBLOCK_INVOKE(completion, dic);
            } else {
                ACCBLOCK_INVOKE(completion, nil);
            }
        }];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if ([view isEqual:self.closeButton]) {
        return self.closeButton;
    }
    return nil;
}

@end
