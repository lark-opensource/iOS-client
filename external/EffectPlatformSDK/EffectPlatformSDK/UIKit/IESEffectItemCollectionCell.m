//
//  IESEffectItemCollectionCell.m
//
//  Created by Keliang Li on 2017/10/30.
//  Copyright © 2017年 keliang0420. All rights reserved.
//

#import "IESEffectItemCollectionCell.h"
#import "IESEffectUIConfig.h"
#import <IESEffectModel.h>
#import <Masonry/Masonry.h>
#import <BDWebImage/UIImageView+BDWebImage.h>
#import "EffectPlatformBookMark.h"
#import "IESEffectView.h"

@interface IESEffectItemCollectionCell ()
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, strong) UIImageView  *effectImageView;
@property (nonatomic, strong) UIImageView  *downloadIconImageView;
@property (nonatomic, strong) UIView *redDot;
@property (nonatomic, strong) IESEffectUIConfig *uiConfig;
@end

@implementation IESEffectItemCollectionCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupControl];
    }
    return self;
}

- (void)setupControl
{
    _effectImageView = [[UIImageView alloc] init];
    _effectImageView.layer.masksToBounds = YES;

    _downloadIconImageView = [[UIImageView alloc] init];
    _downloadIconImageView.hidden = YES;
    
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _indicator.hidesWhenStopped = YES;
    
    [self addSubview:_effectImageView];
    [self addSubview:_downloadIconImageView];
    [self addSubview:_indicator];
    
    [_effectImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(@0);
    }];
    
    [_downloadIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(_effectImageView);
        make.size.mas_equalTo(CGSizeMake(20, 20));
    }];
    
    [_indicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    _redDot = [[UIView alloc] init];
    _redDot.backgroundColor = [UIColor colorWithRed:255.0 / 255.0 green:34.0 / 255.0 blue:0 alpha:1];
    _redDot.layer.cornerRadius = 3.0;
    _redDot.layer.masksToBounds = YES;
    
    [self addSubview:_redDot];
    [_redDot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.trailing.equalTo(@0);
        make.width.height.equalTo(@6);
    }];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.indicator stopAnimating];
    self.redDot.hidden = YES;
    self.effectImageView.alpha = 1.0;
}

- (void)configWithDefaultWithUIConfig:(IESEffectUIConfig *)config;
{
    _uiConfig = config;
    [self.downloadIconImageView setImage:config.downloadImage];
    [self.effectImageView bd_cancelImageLoad];
    self.effectImageView.image = config.cleanImage;
    self.downloadIconImageView.hidden = YES;
    self.redDot.hidden = YES;
}

- (void)configWithEffect:(IESEffectModel *)effect
                uiConfig:(IESEffectUIConfig *)config;
{
    if (!effect) {
        return;
    }
    _uiConfig = config;
    [self.downloadIconImageView setImage:config.downloadImage];
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    [self.effectImageView bd_setImageWithURL:[NSURL URLWithString:effect.iconDownloadURLs.firstObject]
                                 placeholder:config.placeHolderImage
                                     options:BDImageRequestDefaultOptions
                                  completion:^(BDWebImageRequest *request,
                                               UIImage *image,
                                               NSData *data,
                                               NSError *error,
                                               BDWebImageResultFrom from) {
                                       if (from != BDWebImageResultFromMemoryCache &&
                                           from != BDWebImageResultFromDiskCache) {
                                           CFTimeInterval interval = CFAbsoluteTimeGetCurrent() - currentTime;
                                           if (error) {
                                               [[NSNotificationCenter defaultCenter] postNotificationName:kIESStickerIconDownloadedNotification
                                                                                                   object:nil
                                                                                                 userInfo:@{@"downloadTime": @(interval),
                                                                                                            @"sticker": effect,
                                                                                                            @"error": error
                                                                                                            }];
                                           } else {
                                               [[NSNotificationCenter defaultCenter] postNotificationName:kIESStickerIconDownloadedNotification
                                                                                                   object:nil
                                                                                                 userInfo:@{@"downloadTime": @(interval),
                                                                                                            @"sticker": effect
                                                                                                            }];
                                           }
                                          
                                       }
    }];
    self.downloadIconImageView.hidden = effect.downloaded;
    self.redDot.hidden = ![effect showRedDotWithTag:config.redDotTagForEffect];
}

- (void)markAsRead
{
    self.redDot.hidden = YES;
}

- (void)setEffectApplied:(BOOL)applied;
{
    if (applied) {
        self.effectImageView.layer.borderColor = self.uiConfig.selectedBorderColor.CGColor;
        self.effectImageView.layer.borderWidth = self.uiConfig.selectedBorderWidth;
        self.effectImageView.layer.cornerRadius = self.uiConfig.selectedBorderRadius;
    } else {
        self.effectImageView.layer.borderWidth = 0;
        self.effectImageView.layer.cornerRadius = 0;
    }
}

- (void)startDownloadAnimation
{
    self.effectImageView.alpha = 0.5;
    self.downloadIconImageView.hidden = YES;
    [self.indicator startAnimating];
}

- (void)endDownloadAnimationWithResult:(BOOL)success
{
    self.effectImageView.alpha = 1.f;
    [self.indicator stopAnimating];
    self.downloadIconImageView.hidden = success;
}


@end
