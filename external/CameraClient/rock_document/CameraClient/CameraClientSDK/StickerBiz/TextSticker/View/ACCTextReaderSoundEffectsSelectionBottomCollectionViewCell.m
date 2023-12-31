//
//  ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/18.
//

#import "ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell.h"

#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <KVOController/NSObject+FBKVOController.h>

#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

/* --- Properties and Variables --- */

static CGFloat const kBGWidthHeight = 52.0f;
static CGFloat const kTitleLableWidth = 60.0f;
static CGFloat const kTitleLableHeight = 15.0f;
static CGFloat const kSpacing = 8.0f;
CGFloat const kTextReaderSoundEffectsSelectionBottomCollectionViewCellWidth = kTitleLableWidth;
CGFloat const kTextReaderSoundEffectsSelectionBottomCollectionViewCellHeight = kBGWidthHeight + kSpacing + kTitleLableHeight;

@interface ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell ()

@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UIView *darkCoverView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *noSpeakerIconImageView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) AWEScrollStringLabel *titleLabel;
@property (nonatomic, strong) UIImageView *downloadStatusIndicator;
@property (nonatomic, strong) LOTAnimationView *playingLottieView;

@property (nonatomic, weak) ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *cellModel;

@end

/* --- Implementation --- */

@implementation ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)dealloc
{
    [self.KVOController unobserveAll];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.KVOController unobserveAll];
}

#pragma mark - Private Methods

- (void)p_setupUI
{
    _borderView = ({
        UIView *view = [[UIView alloc] init];
        [self.contentView addSubview:view];
        view.backgroundColor = [UIColor clearColor];
        view.layer.cornerRadius = (kBGWidthHeight + 4) / 2.0;
        view.layer.borderWidth = 2;
        view.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
        view.layer.masksToBounds = YES;
        view.hidden = YES;
        
        view;
    });
    
    _bgView = ({
        UIView *view = [[UIView alloc] init];
        [self.contentView addSubview:view];
        view.layer.cornerRadius = kBGWidthHeight / 2.0;
        view.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
        
        view;
    });
    
    _noSpeakerIconImageView = ({
        UIImageView *view = [[UIImageView alloc] init];
        [self.contentView addSubview:view];
        view.layer.cornerRadius = kBGWidthHeight / 2.0;
        view.contentMode = UIViewContentModeScaleAspectFit;
        [view setImage:[ACCResourceImage(@"icon_effect_none") imageWithAlignmentRectInsets:UIEdgeInsetsMake(-10, -10, -10, -10)]];
        
        view;
    });
    
    _iconImageView = ({
        UIImageView *view = [[UIImageView alloc] init];
        [self.contentView addSubview:view];
        view.layer.cornerRadius = kBGWidthHeight / 2.0;
        view.contentMode = UIViewContentModeScaleAspectFit;
        
        view;
    });
    
    _darkCoverView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = ACCResourceColor(ACCColorSDSecondary);
        view.layer.cornerRadius = kBGWidthHeight / 2.0;
        [view setHidden:YES];
        [self.contentView addSubview:view];
        
        view;
    });
    
    _downloadStatusIndicator = ({
        UIImageView *view = [[UIImageView alloc] init];
        [self.contentView addSubview:view];
        view.contentMode = UIViewContentModeScaleAspectFit;
        view.image = ACCResourceImage(@"iconCoverTextDownloaded");
        view.hidden = YES;
        
        view;
    });
    
    _playingLottieView = ({
        LOTAnimationView *view = [LOTAnimationView animationWithFilePath:ACCResourceFile(@"acc_sound_playing_lottie.json")];
        [self.iconImageView addSubview:view];
        view.contentMode = UIViewContentModeScaleAspectFit;
        view.loopAnimation = YES;
        
        view;
    });
    
    _titleLabel = ({
        AWEScrollStringLabel *view = [[AWEScrollStringLabel alloc] initWithHeight:kTitleLableHeight];
        [self.contentView addSubview:view];
        
        view;
    });
    
    ACCMasMaker(_bgView, {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.borderView);
        make.width.height.equalTo(@(kBGWidthHeight));
    });
    
    ACCMasMaker(_borderView, {
        make.top.centerX.equalTo(self.contentView);
        make.width.height.equalTo(@(kBGWidthHeight + 4));
    });
    
    ACCMasMaker(self.noSpeakerIconImageView, {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.borderView);
        make.width.height.equalTo(@(kBGWidthHeight));
    });
    
    ACCMasMaker(self.iconImageView, {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.borderView);
        make.width.height.equalTo(@(kBGWidthHeight));
    });
    
    ACCMasMaker(self.darkCoverView, {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.borderView);
        make.width.height.equalTo(@(kBGWidthHeight));
    });
    
    ACCMasMaker(self.downloadStatusIndicator, {
        make.width.equalTo(@16);
        make.height.equalTo(@16);
        make.right.equalTo(self.iconImageView);
        make.bottom.equalTo(self.iconImageView);
    });
    
    ACCMasMaker(self.playingLottieView, {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.borderView);
        make.width.height.equalTo(@(kBGWidthHeight));
    });
    
    ACCMasMaker(self.titleLabel, {
        make.leading.bottom.trailing.equalTo(self.contentView);
        make.height.equalTo(@(kTitleLableHeight));
    });
}

- (void)p_playLottie:(BOOL)shouldPlay
{
    if (shouldPlay) {
        [self.darkCoverView setHidden:NO];
        self.playingLottieView.hidden = NO;
        [self.playingLottieView play];
    } else {
        [self.darkCoverView setHidden:YES];
        [self.playingLottieView stop];
        self.playingLottieView.hidden = YES;
    }
}

- (void)p_showLoadingView:(BOOL)shouldShow
{
    if (shouldShow) {
        ACCMasReMaker(self.downloadStatusIndicator, {
            make.centerX.centerY.equalTo(self.iconImageView);
            make.width.equalTo(@24);
            make.height.equalTo(@24);
        });
        [self.darkCoverView setHidden:NO];
    } else {
        ACCMasReMaker(self.downloadStatusIndicator, {
            make.width.equalTo(@16);
            make.height.equalTo(@16);
            make.right.equalTo(self.iconImageView);
            make.bottom.equalTo(self.iconImageView);
        });
        [self.darkCoverView setHidden:YES];
    }
}

- (void)p_toggleDownloadAnimation:(BOOL)shouldAnimate {
    [self.downloadStatusIndicator.layer removeAllAnimations];
    if (shouldAnimate) {
        CABasicAnimation* rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation * rotations * duration*/  ];
        rotationAnimation.duration = 0.8;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = HUGE_VAL;
        [self.downloadStatusIndicator.layer addAnimation:rotationAnimation forKey:@"transform.rotation.z"];
    }
}

#pragma mark - Public Methods

- (void)configCellWithModel:(ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *)model
{
    if (model == nil) {
        return;
    }
    
    self.cellModel = model;
    
    UIColor *textColor = [UIColor blackColor];
    if (model.isSelected) {
        textColor = ACCResourceColor(ACCColorPrimary);
    } else {
        textColor = ACCResourceColor(ACCColorConstTextInverse3);
    }
    NSString *textString = model.titleString;
    if (model.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeNone) {
        [ACCWebImage() cancelImageViewRequest:self.iconImageView];
        [self.noSpeakerIconImageView setHidden:NO];
        [self.iconImageView setHidden:YES];
        // Remove related indicators
        self.playingLottieView.hidden = YES;
        [self.downloadStatusIndicator removeFromSuperview];
        self.downloadStatusIndicator = nil;
    } else if (model.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeDefault) {
        [self.noSpeakerIconImageView setHidden:YES];
        [self.iconImageView setHidden:NO];
        [ACCWebImage() cancelImageViewRequest:self.iconImageView];
        [self.iconImageView setImage:ACCResourceImage(@"ic_text_reader_sound_effect_default")];
    } else if (model.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeSoundEffect) {
        [self.noSpeakerIconImageView setHidden:YES];
        [self.iconImageView setHidden:NO];
        if (model.iconDownloadURLs != nil && [model.iconDownloadURLs count] > 0) {
            [ACCWebImage() cancelImageViewRequest:self.iconImageView];
            [self.iconImageView setImage:ACCResourceImage(@"imgLoadingStickers")];
            [ACCWebImage() imageView:self.iconImageView
                setImageWithURLArray:model.iconDownloadURLs
                         placeholder:ACCResourceImage(@"imgLoadingStickers")];
        } else {
            [ACCWebImage() cancelImageViewRequest:self.iconImageView];
        }
    }
    [self.titleLabel configWithTitleWithTextAlignCenter:textString
                                             titleColor:textColor
                                               fontSize:11
                                                 isBold:NO
                                            contentSize:CGSizeMake(kTitleLableWidth, kTitleLableHeight)];
    [self updateUIStatus];
    
    [self.KVOController unobserveAll];
    @weakify(self);
    [self.KVOController observe:model
                        keyPath:@"downloadStatus"
                        options:NSKeyValueObservingOptionNew
                          block:^(ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *cell,
                                  ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *model,
                                  NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        [self updateUIStatus];
    }];
}

- (void)updateUIStatus
{
    if (self.cellModel.isSelected) {
        self.borderView.hidden = NO;
        [self.titleLabel startAnimation];
        [self.titleLabel updateTextColor:ACCResourceColor(ACCColorPrimary)];
    } else {
        self.borderView.hidden = YES;
        [self.titleLabel stopAnimation];
        [self.titleLabel updateTextColor:ACCResourceColor(ACCColorConstTextInverse3)];
    }
    AWEEffectDownloadStatus downloadStatus = self.cellModel.downloadStatus;
    switch (downloadStatus) {
        case AWEEffectDownloadStatusDownloadFail:
        case AWEEffectDownloadStatusUndownloaded: {
            [self p_showLoadingView:NO];
            [self p_toggleDownloadAnimation:NO];
            self.downloadStatusIndicator.transform = CGAffineTransformIdentity;
            self.downloadStatusIndicator.hidden = NO;
            self.downloadStatusIndicator.image = ACCResourceImage(@"iconStickerCellDownload");
            [self p_playLottie:NO];
            break;
        }
        case AWEEffectDownloadStatusDownloading: {
            [self p_playLottie:NO];
            [self p_showLoadingView:YES];
            self.downloadStatusIndicator.transform = CGAffineTransformIdentity;
            self.downloadStatusIndicator.hidden = NO;
            self.downloadStatusIndicator.image = ACCResourceImage(@"iconDownloadingMusic");
            [self p_toggleDownloadAnimation:YES];
            break;
        }
        case AWEEffectDownloadStatusDownloaded: {
            [self p_showLoadingView:NO];
            [self p_toggleDownloadAnimation:NO];
            self.downloadStatusIndicator.hidden = YES;
            [self p_playLottie:self.cellModel.isPlaying];
            break;
        }
    }
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    NSString *selectedStatusStr = self.cellModel.isSelected ? @"已选中": @"未选中";
    NSString *contentStr = self.cellModel.titleString;
    return [NSString stringWithFormat:@"%@ %@",
            selectedStatusStr,
            contentStr];
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitNone;
}

@end
