//
//  AWELyricStyleCollectionViewCell.m
//  AWEStudio
//
//  Created by Liu Deping on 2019/10/16.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWELyricStyleCollectionViewCell.h"
#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <YYImage/YYAnimatedImageView.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWELyricStyleCollectionViewCell ()

@property (nonatomic, strong) UIImageView *downloadIcon;
@property (nonatomic, strong) UIImageView *loadingIcon;
@property (nonatomic, strong) AWEScrollStringLabel *titleLabel;
@property (nonatomic, strong) YYAnimatedImageView *effectImageView;
@property (nonatomic, assign) NSTimeInterval lastTimeRunAnimation;

@end

@implementation AWELyricStyleCollectionViewCell

- (void)dealloc
{
    if (_loadingIcon) {
        [_loadingIcon.layer removeAllAnimations];
        _loadingIcon = nil;
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.effectImageView];
        [self.contentView addSubview:self.downloadIcon];
        [self.contentView addSubview:self.loadingIcon];
        [self.contentView addSubview:self.titleLabel];
        
        ACCMasMaker(self.effectImageView, {
            make.top.centerX.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(52, 52));
        });
        
        ACCMasMaker(self.downloadIcon, {
            make.right.equalTo(self.effectImageView.mas_right).offset(0);
            make.bottom.equalTo(self.effectImageView.mas_bottom).offset(0);
            make.width.height.equalTo(@16);
        });
        
        ACCMasMaker(self.loadingIcon, {
            make.right.equalTo(self.effectImageView.mas_right).offset(0);
            make.bottom.equalTo(self.effectImageView.mas_bottom).offset(0);
            make.width.height.equalTo(@16);
        });
        
        ACCMasMaker(self.titleLabel, {
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
            make.top.equalTo(self.effectImageView.mas_bottom).offset(7);
            make.height.equalTo(@15);
        });
    }
    return self;
}

- (void)setCurrentEffectModel:(IESEffectModel *)currentEffectModel
{
    _currentEffectModel = currentEffectModel;
    
    
    if (!_currentEffectModel.effectIdentifier) {
        self.downloadIcon.hidden = YES;
        self.loadingIcon.hidden = YES;
    } else {
        if (_currentEffectModel.downloaded) {
            self.downloadIcon.hidden = YES;
            self.loadingIcon.hidden = YES;
        } else if (_currentEffectModel.downloadStatus == AWEEffectDownloadStatusDownloading) {
            [self showLoadingAnimation:YES];
        } else {
            self.downloadIcon.hidden = NO;
            self.loadingIcon.hidden = YES;
        }
    }
    
    @weakify(self);
    [ACCWebImage() imageView:self.effectImageView setImageWithURLArray:currentEffectModel.iconDownloadURLs placeholder:ACCResourceImage(@"tool_EffectLoadingIcon") completion:^(UIImage *image, NSURL *url, NSError *error) {
        @strongify(self);
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.effectImageView.image = image;
            });
        }
    }];
    
    [self updateText:currentEffectModel.effectName ? : @""];
}

- (void)setIsCurrent:(BOOL)isCurrent
{
    _isCurrent = isCurrent;
    if (isCurrent) {
        self.effectImageView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
        self.effectImageView.layer.borderWidth = 2.0f;
        [self.titleLabel configWithTitleWithTextAlignCenter:self.currentEffectModel.effectName
                                                 titleColor:ACCResourceColor(ACCColorPrimary)
                                                   fontSize:12
                                                     isBold:YES
                                                contentSize:CGSizeMake(60,15)];
    } else {
        self.effectImageView.layer.borderColor = [UIColor clearColor].CGColor;
        self.effectImageView.layer.borderWidth = 0;
        [self.titleLabel configWithTitleWithTextAlignCenter:self.currentEffectModel.effectName
                                                 titleColor:[UIColor whiteColor]
                                                   fontSize:12
                                                     isBold:YES
                                                contentSize:CGSizeMake(60,15)];
    }
}

- (void)updateText:(NSString *)text
{
    [self.titleLabel configWithTitleWithTextAlignCenter:text
                                             titleColor:[UIColor whiteColor]
                                               fontSize:12
                                                 isBold:YES
                                            contentSize:CGSizeMake(60,15)];
}

- (void)showLoadingAnimation:(BOOL)show
{
    if (show) {
        self.lastTimeRunAnimation = CFAbsoluteTimeGetCurrent();
        self.downloadIcon.hidden = YES;
        self.loadingIcon.hidden = NO;
        [self p_startLoadingAnimation];
    } else {
        CGFloat waitTime = 0.f;
        CGFloat minGap  = 0.1f;
        if (fabs(CFAbsoluteTimeGetCurrent() - self.lastTimeRunAnimation) < minGap) {
            waitTime  = minGap;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.loadingIcon.hidden = YES;
            [self p_stopLoadingAnimation];
            
            if (self.currentEffectModel.downloaded || self.currentEffectModel.downloadStatus == AWEEffectDownloadStatusDownloaded) {
                self.downloadIcon.hidden = YES;
            } else {
                self.downloadIcon.hidden = NO;
            }
        });
    }
}

- (void)p_startLoadingAnimation
{
    [self.loadingIcon.layer removeAllAnimations];
    [self.loadingIcon.layer addAnimation:[self createRotationAnimation] forKey:@"rotation"];
}

- (void)p_stopLoadingAnimation
{
    [self.loadingIcon.layer removeAllAnimations];
}

- (CAAnimation *)createRotationAnimation
{
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = 0.8;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VAL;
    return rotationAnimation;
}

- (UIImageView *)downloadIcon
{
    if (!_downloadIcon) {
        _downloadIcon = [[UIImageView alloc] init];
        _downloadIcon.image = ACCResourceImage(@"iconStickerCellDownload");
    }
    return _downloadIcon;
}

- (UIImageView *)loadingIcon
{
    if (!_loadingIcon) {
        _loadingIcon = [[UIImageView alloc] init];
        _loadingIcon.image = ACCResourceImage(@"tool_iconLoadingVoiceChanger");
    }
    return _loadingIcon;
}

- (AWEScrollStringLabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[AWEScrollStringLabel alloc] initWithHeight:15];
    }
    return _titleLabel;
}

- (YYAnimatedImageView *)effectImageView
{
    if (!_effectImageView) {
        _effectImageView = [[YYAnimatedImageView alloc] init];
        _effectImageView.layer.cornerRadius = 26.0f;
        _effectImageView.layer.masksToBounds = YES;
    }
    return _effectImageView;
}

@end
