//
//  ACCStickerPreviewCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/9/24.
//

#import "ACCStickerPreviewCollectionViewCell.h"

#import <EffectPlatformSDK/IESEffectModel.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

static CGFloat const ACCStickerPreviewCollectionViewCellImageEdge = 52.f;

@interface ACCStickerPreviewCollectionViewCell()

@property (nonatomic, strong, readwrite) UIImageView *iconImageView;

@property (nonatomic, strong, readwrite) UILabel     *titleLabel;

@property (nonatomic, strong) UIImageView *downloadIcon;

@property (nonatomic, strong) UIImageView *loadingIcon;

@end

@implementation ACCStickerPreviewCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    UIImageView *iconImageView = [[UIImageView alloc] init];
    iconImageView.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    iconImageView.layer.cornerRadius = ACCStickerPreviewCollectionViewCellImageEdge/2;
    iconImageView.layer.masksToBounds = YES;
    [self addSubview:iconImageView];
    ACCMasMaker(iconImageView, {
        make.centerX.equalTo(self);
        make.top.equalTo(@0);
        make.width.equalTo(@(ACCStickerPreviewCollectionViewCellImageEdge));
        make.height.equalTo(@(ACCStickerPreviewCollectionViewCellImageEdge));
    });
    self.iconImageView = iconImageView;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:12.f];
    [self addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.bottom.equalTo(@0);
        make.height.equalTo(@17);
    });
    self.titleLabel = titleLabel;
    
    UIImageView *downloadIcon = [[UIImageView alloc] init];
    downloadIcon.image = ACCResourceImage(@"iconStickerCellDownload");
    downloadIcon.hidden = YES;
    [self addSubview:downloadIcon];
    ACCMasMaker(downloadIcon, {
        make.width.equalTo(@16);
        make.height.equalTo(@16);
        make.right.equalTo(self.iconImageView);
        make.bottom.equalTo(self.iconImageView);
    });
    self.downloadIcon = downloadIcon;
    
    UIImageView *loadingIcon = [[UIImageView alloc] init];
    loadingIcon.image = ACCResourceImage(@"tool_iconLoadingVoiceChanger");
    loadingIcon.hidden = YES;
    [self addSubview:loadingIcon];
    ACCMasMaker(loadingIcon, {
        make.width.equalTo(@16);
        make.height.equalTo(@16);
        make.right.equalTo(self.iconImageView);
        make.bottom.equalTo(self.iconImageView);
    });
    self.loadingIcon = loadingIcon;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.iconImageView.image = nil;
    self.titleLabel.text = @"";
}

- (void)configCellWithEffect:(IESEffectModel *)effect
{
    [ACCWebImage() imageView:self.iconImageView setImageWithURLArray:effect.iconDownloadURLs placeholder:nil];
    self.titleLabel.text = effect.effectName;
}

- (void)showCurrentTag:(BOOL)show
{
    if (show) {
        self.iconImageView.layer.borderWidth = 2.f;
        self.iconImageView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
        self.titleLabel.textColor = ACCResourceColor(ACCColorPrimary);
    } else {
        self.iconImageView.layer.borderWidth = 0.f;
        self.iconImageView.layer.borderColor = [UIColor clearColor].CGColor;
        self.titleLabel.textColor = [UIColor whiteColor];
    }
}

- (void)updateDownloadStatus:(AWEEffectDownloadStatus)status
{
    switch (status) {
        case AWEEffectDownloadStatusDownloaded:
        {
            self.downloadIcon.hidden = YES;
            self.loadingIcon.hidden = YES;
            [self p_stopLoadingAnimation];
        }
            break;
        case AWEEffectDownloadStatusDownloading:
        {
            self.downloadIcon.hidden = YES;
            self.loadingIcon.hidden = NO;
            [self p_startLoadingAnimation];
        }
            break;
        default:
        {
            self.downloadIcon.hidden = NO;
            self.loadingIcon.hidden = YES;
            [self p_stopLoadingAnimation];
        }
            break;
    }
}

- (void)p_startLoadingAnimation
{
    if (![self.loadingIcon.layer animationForKey:@"rotation"]) {
        [self.loadingIcon.layer removeAllAnimations];
        [self.loadingIcon.layer addAnimation:[self createRotationAnimation] forKey:@"rotation"];
    }
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

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

#pragma mark - Accessibility
- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.titleLabel.text;
}

@end
