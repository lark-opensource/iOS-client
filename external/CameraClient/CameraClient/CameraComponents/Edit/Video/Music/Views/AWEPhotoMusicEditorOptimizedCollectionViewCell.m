//
//  AWEPhotoMusicEditorOptimizedCollectionViewCell.m
//  Pods
//
//  Created by resober on 2019/5/24.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEPhotoMusicEditorOptimizedCollectionViewCell.h"
#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface AWEPhotoMusicEditorOptimizedCollectionViewCell()
@property (nonatomic, strong) AWEScrollStringLabel *scrollSrtingLabel;
@property (nonatomic, copy) NSString *musicName;
@property (nonatomic, strong) CAGradientLayer *fadeLayer;
@end

@implementation AWEPhotoMusicEditorOptimizedCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupOptimization];
    }
    return self;
}

- (void)setupOptimization {
    [self.recommendedImageView removeFromSuperview];
    [self.musicItemView removeFromSuperview];

    self.musicItemView = [[AWEPhotoMovieMusicItemView alloc] initWithRectangleImageSize:CGSizeMake(56.f, 56.f) radius:2.f];
    [self.musicItemView addSubview:self.recommendedImageView];
    [self.contentView insertSubview:self.musicItemView belowSubview:self.downloadIcon];

    ACCMasUpdate(self.musicItemView, {
        make.top.equalTo(self.contentView);
        make.centerX.equalTo(self.contentView);
        make.width.height.equalTo(@56);
    });

    ACCMasUpdate(self.recommendedImageView, {
        make.left.top.equalTo(self.musicItemView);
        make.width.equalTo(@26);
        make.height.equalTo(@26);
    });
    self.recommendedImageView.image = [self photoMusicEditorRecommendedImage];

    [self.titleLabel removeFromSuperview];
    self.scrollSrtingLabel = [[AWEScrollStringLabel alloc] initWithHeight:15.f];

    [self.contentView addSubview:self.scrollSrtingLabel];
    ACCMasMaker(self.scrollSrtingLabel, {
        make.left.equalTo(self.contentView.mas_left);
        make.right.equalTo(self.contentView.mas_right);
        make.top.equalTo(self.musicItemView.mas_bottom).offset(8);
        make.height.equalTo(@15);
    });
    [self.scrollSrtingLabel configWithTitleWithTextAlignCenter:_musicName titleColor:ACCResourceColor(ACCUIColorTextPrimary) fontSize:12 isBold:NO contentSize:CGSizeMake(72.f, 15.f)];

    self.fadeLayer = [[CAGradientLayer alloc] init];
    self.fadeLayer.backgroundColor = UIColor.clearColor.CGColor;
    CGPoint startPoint = CGPointZero, endPoint = CGPointZero;
    startPoint = CGPointMake(0, 0.5);
    endPoint = CGPointMake(1, 0.5);
    CGFloat fadeInRatio = 6.f / CGRectGetWidth(self.frame);
    self.fadeLayer.startPoint = startPoint;
    self.fadeLayer.endPoint = endPoint;
    self.fadeLayer.locations = @[@(0), @(fadeInRatio), @(1 - fadeInRatio)];
    [self.scrollSrtingLabel.layer addSublayer:self.fadeLayer];
    self.scrollSrtingLabel.layer.mask = self.fadeLayer;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self updateFadeLayerColorWithCurrent:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fadeLayer.frame = self.scrollSrtingLabel.bounds;
}

- (void)updateText:(NSString *)text {
    [super updateText:text];
    _musicName = text;
    CGSize contentItemSize = CGSizeMake(56.f, 15.f);
    [self.scrollSrtingLabel configWithTitleWithTextAlignCenter:_musicName
                                                    titleColor:ACCResourceColor(ACCUIColorConstTextInverse2)
                                                      fontSize:12
                                                        isBold:NO
                                                   contentSize:contentItemSize];
}

- (void)updateFadeLayerColorWithCurrent:(BOOL)isCurrent {
    CGColorRef leftColor = isCurrent ? [UIColor colorWithWhite:1 alpha:0].CGColor : UIColor.whiteColor.CGColor;
    self.fadeLayer.colors = @[(__bridge id)leftColor,
                         (id)UIColor.whiteColor.CGColor,
                         (id)UIColor.whiteColor.CGColor,
                         (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if ([view isEqual:self.musicItemView]) {
        return self;
    }
    if ([view isKindOfClass:[AWEPhotoMovieMusicItemCircleView class]]) {
        return self;
    }
    return view;
}

- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    [super setIsCurrent:isCurrent animated:animated completion:completion];
    [self updateTitleViewState:isCurrent animated:animated];
    [self updateFadeLayerColorWithCurrent:isCurrent];
}

- (void)updateTitleViewState:(BOOL)isCurrent animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? (isCurrent ? 0.2 : 0.1) : 0 animations:^{
        UIColor *primaryColor = ACCResourceColor(ACCColorPrimary);
        UIColor *textPrimaryColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        UIColor *color = isCurrent ? primaryColor : textPrimaryColor;
        [self.scrollSrtingLabel updateTextColor:color];
    }];
    if (isCurrent) {
        [self.scrollSrtingLabel startAnimation];
    } else {
        [self.scrollSrtingLabel stopAnimation];
    }
}

- (UIImage *)photoMusicEditorRecommendedImage
{
    if (![[ACCI18NConfig() currentLanguage] containsString:@"zh"]) {
        return ACCResourceImage(@"icon_mv_recommended_thumb");
    } else {
        return ACCResourceImage(@"icon_mv_recommended");
    }
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.scrollSrtingLabel.leftLabel.text;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end
