//
//  AWEVoiceChangerCell.m
//  Pods
//
//  Created by chengfei xiao on 2019/5/23.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVoiceChangerCell.h"
#import "AWEVoiceChangerItemView.h"
#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CameraClient/AWEEffectPlatformManager.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCModuleConfigProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEVoiceChangerCell ()
@property (nonatomic, strong) AWEVoiceChangerItemView *effectItemView;
@property (nonatomic, strong) UIImageView *downloadIcon;
@property (nonatomic, strong) UIImageView *loadingIcon;
@property (nonatomic, strong) AWEScrollStringLabel *titleLabel;
@property (nonatomic, assign) NSTimeInterval lastTimeRunAnimation;
@property (nonatomic, assign, readwrite) BOOL isCurrent;
@property (nonatomic, strong) id<ACCModuleConfigProtocol> moduleConfig;
@end

@implementation AWEVoiceChangerCell

IESAutoInject(ACCBaseServiceProvider(), moduleConfig, ACCModuleConfigProtocol)

- (void)dealloc
{
    if (_loadingIcon) {
        [_loadingIcon.layer removeAllAnimations];
        _loadingIcon = nil;
    }
    AWELogToolDebug(AWELogToolTagEdit, @"%@ dealloc",[self class]);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    
        [self addSubview:self.effectItemView];
        [self addSubview:self.downloadIcon];
        [self addSubview:self.loadingIcon];
        [self addSubview:self.titleLabel];
        
        ACCMasMaker(self.effectItemView, {
            make.top.equalTo(self).offset(8);
            make.centerX.equalTo(self);
            make.width.height.equalTo(@52);
        });
        
        ACCMasMaker(self.downloadIcon, {
            make.right.equalTo(self.effectItemView.mas_right).offset(0);
            make.bottom.equalTo(self.effectItemView.mas_bottom).offset(0);
            make.width.height.equalTo(@16);
        });
        
        ACCMasMaker(self.loadingIcon, {
            make.right.equalTo(self.effectItemView.mas_right).offset(0);
            make.bottom.equalTo(self.effectItemView.mas_bottom).offset(0);
            make.width.height.equalTo(@16);
        });
        
        ACCMasMaker(self.titleLabel, {
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
            make.top.equalTo(self.effectItemView.mas_bottom).offset(8);
            make.height.equalTo(@18);
        });
    }
    return self;
}

#pragma mark - Getters

- (AWEVoiceChangerItemView *)effectItemView
{
    if (!_effectItemView) {
        _effectItemView = [[AWEVoiceChangerItemView alloc] initWithFrame:CGRectZero];
        _effectItemView.userInteractionEnabled = NO;
    }
    return _effectItemView;
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
        _titleLabel = [[AWEScrollStringLabel alloc] initWithHeight:18 type:AWEScrollStringLabelTypeVoiceEffect];
    }
    return _titleLabel;
}


#pragma mark - Setters

- (void)setCurrentEffect:(IESEffectModel *)currentEffect
{
    _currentEffect = currentEffect;
    
    if (!_currentEffect.effectIdentifier) {
        self.downloadIcon.hidden = YES;
        self.loadingIcon.hidden = YES;
    } else {
        if (_currentEffect.downloaded ||
            ([_currentEffect.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_chipmunk] ||
            [_currentEffect.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_baritone])) {
            self.downloadIcon.hidden = YES;
            self.loadingIcon.hidden = YES;
        } else if (_currentEffect.downloadStatus == AWEEffectDownloadStatusDownloading) {
            [self showLoadingAnimation:YES];
        } else {
            self.downloadIcon.hidden = NO;
            self.loadingIcon.hidden = YES;
        }
    }
    
    if (!_currentEffect.effectIdentifier) {//原声
        [self.effectItemView setCenterImage:ACCResourceImage(@"icVoiceStickerClear") size:CGSizeMake(24, 24)];
    } else {
        if ([_currentEffect.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_chipmunk]) {//内置
            [self.effectItemView setCenterImage:ACCResourceImage(@"tool_VoiceChange_chipmunk") size:CGSizeMake(32, 32)];
        } else if ([_currentEffect.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_baritone]) {//内置
            [self.effectItemView setCenterImage:ACCResourceImage(@"tool_VoiceChange_baritone") size:CGSizeMake(32, 32)];
        } else {
            [self.effectItemView setCenterImage:ACCResourceImage(@"tool_EffectLoadingIcon") size:CGSizeMake(32, 32)];
            NSArray *iconList = _currentEffect.iconDownloadURLs;
            [self setThumbnailURLList:iconList placeholder:nil];
        }
    }
    [self updateText:_currentEffect.effectName?:@""];
}

- (void)setThumbnailURLList:(NSArray *)thumbnailURLList
{
    [self.effectItemView setThumbnailURLList:thumbnailURLList];
}

- (void)setThumbnailURLList:(NSArray *)thumbnailURLList placeholder:(UIImage *)placeholder
{
    [self.effectItemView setThumbnailURLList:thumbnailURLList placeholder:placeholder];
}

- (void)setIsCurrent:(BOOL)isCurrent
            animated:(BOOL)animated
{
    [self setIsCurrent:isCurrent animated:animated completion:nil];
}

- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    self.isCurrent = isCurrent;
    
    if (self.needChangeSelectedTitleColor) {
        UIColor *color = isCurrent ? ACCResourceColor(ACCColorPrimary) : [UIColor whiteColor];
        [self.titleLabel updateTextColor:color];
    }
    if (animated == NO) {
        [self.effectItemView setSelected:isCurrent];
    } else {
        if (isCurrent) {
            [UIView animateWithDuration:0.2 animations:^{
                [self.effectItemView setSelected:YES];
            } completion:completion];
        } else {
            [UIView animateWithDuration:0.1 animations:^{
                [self.effectItemView setSelected:NO];
            }completion:completion];
        }
    }
    
    if (isCurrent) {
        [self.titleLabel startAnimation];
    } else {
        [self.titleLabel stopAnimation];
    }
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
            
            if (self.currentEffect.downloaded || self.currentEffect.downloadStatus == AWEEffectDownloadStatusDownloaded ||
                ([self.currentEffect.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_chipmunk] ||
                 [self.currentEffect.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_baritone])) {
                self.downloadIcon.hidden = YES;
            } else {
                self.downloadIcon.hidden = NO;
            }
        });
    }
}

- (void)updateText:(NSString *)text
{
    [self.titleLabel configWithTitleWithTextAlignCenter:text
                                             titleColor:ACCColorFromRGBA(255, 255, 255, 1.f)
                                               fontSize:[ACCFont() getAdaptiveFontSize:12]
                                                 isBold:[self.moduleConfig useBoldTextForCellTitle]
                                            contentSize:CGSizeMake(60,18)];
}

#pragma mark - Animations

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

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.titleLabel.leftLabel.text;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    if (!self.loadingIcon.hidden) {
        return UIAccessibilityTraitNone;
    }
    return UIAccessibilityTraitButton;
}

- (NSString *)accessibilityValue
{
    return self.isCurrent ? @"已选定" : @"未选定";
}

@end
