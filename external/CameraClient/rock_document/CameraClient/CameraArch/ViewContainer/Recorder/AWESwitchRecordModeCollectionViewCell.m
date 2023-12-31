//
//  AWERecordSwitchRecordModeCollectionViewCell.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/13.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWESwitchRecordModeCollectionViewCell.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import "AWESwitchModeSingleTabConfigD.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CameraClient/ACCFlowerCampaignManagerProtocol.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <CameraClient/ACCConfigKeyDefines.h>

static const CGFloat ImageWidth = 16.f;
static const CGFloat ImageTitlePadding = 4.f;
NSString * const kACCTextModeRedDotAppearedOnceKey = @"kACCTextModeRedDotAppearedOnceKey";


@interface AWESwitchRecordModeFlowerView: UIView

@property (nonatomic, strong) UILabel *flowerHint;
@property (nonatomic, strong) UIImageView *flowerArrow;
@property (nonatomic, strong) UIView *flowerBackView;
@property (nonatomic, strong) UIImageView *flowerBackgroundView;
@property (nonatomic, strong) LOTAnimationView *flowerAnimationView;

@end

@implementation AWESwitchRecordModeFlowerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        
        self.flowerBackView = [[UIView alloc] init];
        self.flowerBackView.backgroundColor = [UIColor blackColor];
        self.flowerBackView.layer.cornerRadius = 8.0f;
        self.flowerBackView.layer.masksToBounds = YES;
        [self addSubview:self.flowerBackView];
        
        UIImage *backImg = ACCResourceImage(@"flower_mode_background_red");
        self.flowerBackgroundView = [[UIImageView alloc] initWithImage:backImg];
        self.flowerBackgroundView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.flowerBackgroundView];
        
        self.flowerHint = [[UILabel alloc] init];
        self.flowerHint.backgroundColor = [UIColor clearColor];
        self.flowerHint.adjustsFontSizeToFitWidth = YES;
        self.flowerHint.minimumScaleFactor = 0.2;
        self.flowerHint.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        NSString *flowerTabHint = @"春节集卡";
        if(!ACC_isEmptyString([ACCFlowerCampaignManager() flowerTabHint])){
            flowerTabHint = [ACCFlowerCampaignManager() flowerTabHint];
        }
        self.flowerHint.text = flowerTabHint;
        self.flowerHint.textColor = [UIColor whiteColor];
        if (ACC_SCREEN_WIDTH < 375) {
            self.flowerHint.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightSemibold];
        } else {
            self.flowerHint.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
        }
        [self addSubview:self.flowerHint];
        
        UIImage *arrowIcon = ACCResourceImage(@"flower_mode_arrow");
        self.flowerArrow = [[UIImageView alloc] initWithImage:arrowIcon];
        self.flowerArrow.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.flowerArrow];
        
        
        self.flowerAnimationView = [ACCFlowerCampaignManager() flowerEntryLottieView];
        self.flowerAnimationView.loopAnimation = YES;
        self.flowerAnimationView.repeatCount = 3;
        [self addSubview:self.flowerAnimationView];
        [self.flowerAnimationView playWithCompletion:^(BOOL animationFinished) {
        }];
        
        ACCMasMaker(self.flowerBackView, {
            make.leading.equalTo(self.mas_leading);
            make.top.equalTo(self.mas_top);
            make.trailing.equalTo(self.mas_trailing);
            make.bottom.equalTo(self.mas_bottom);
        });
        
        ACCMasMaker(self.flowerBackgroundView, {
            make.leading.equalTo(self.mas_leading);
            make.top.equalTo(self.mas_top);
            make.trailing.equalTo(self.mas_trailing);
            make.bottom.equalTo(self.mas_bottom);
        });
        
        ACCMasMaker(self.flowerArrow, {
            make.size.mas_equalTo(FlowerArrowSize());
            make.trailing.equalTo(self.mas_trailing).offset(-4);
            make.centerY.equalTo(self.mas_centerY);
        });
        
        ACCMasMaker(self.flowerHint, {
            make.leading.equalTo(self.mas_leading).offset(8);
            make.trailing.equalTo(self.flowerArrow.mas_leading).offset(ACC_SCREEN_WIDTH < 375 ? 0 : 2);
            make.top.equalTo(self.mas_top);
            make.bottom.equalTo(self.mas_bottom);
        });
        
        ACCMasMaker(self.flowerAnimationView, {
            make.leading.equalTo(self.mas_leading);
            make.top.equalTo(self.mas_top).offset(-1);
            make.trailing.equalTo(self.mas_trailing);
            make.bottom.equalTo(self.mas_bottom).offset(1);
        });
    }
    return self;
}

@end

@interface AWESwitchRecordModeCollectionViewCell ()

@property (nonatomic, strong) UIView *cornerBackView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UILabel *topRightTipLabel;
@property (nonatomic, strong) UIView *infoGradientView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) AWESwitchModeSingleTabConfig *tabConfig;
@property (nonatomic, assign) BOOL blackStyle;
@property (nonatomic, assign) BOOL cellSelected;
@property (nonatomic, strong) UIView *redDotView;
@property (nonatomic, strong) AWESwitchRecordModeFlowerView *flowerView;

@end

@implementation AWESwitchRecordModeCollectionViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.tabConfig = nil;
    [ACCWebImage() cancelImageViewRequest:self.imageView];
    self.imageView.image = nil;
    self.titleLabel.text = nil;
    [self updateInfoViewHidden:YES];
    [self showRedDot:NO];
    [self showTopRightTipIfNeeded];
    [self.flowerView removeFromSuperview];
}

- (void)updateInfoViewHidden:(BOOL)hidden
{
    self.infoGradientView.hidden = hidden;
    self.infoLabel.hidden = hidden;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        if (ACCConfigBool(kConfigInt_lite_theme_tab_style) == 1) {
            [self.contentView addSubview:self.cornerBackView];
        }
        
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.infoGradientView];
        [self.contentView addSubview:self.redDotView];
        [self.contentView addSubview:self.topRightTipLabel];
        CGRect frame = CGRectMake(self.bounds.size.width - 8, 2, 32, 16);
        self.infoGradientView.frame = frame;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    NSString *topRightTipText = ACCDynamicCast(self.tabConfig, AWESwitchModeSingleTabConfigD).topRightTipText;
    if (topRightTipText) {
        CGSize size = [topRightTipText acc_sizeWithFont:[ACCFont() acc_boldSystemFontOfSize:10] width:CGFLOAT_MAX maxLine:1];
        size.height = size.height + 4;
        size.width = size.width + 10;
        self.topRightTipLabel.acc_size = size;
        self.topRightTipLabel.acc_left = self.contentView.acc_right - 5;        
    }
    
    if (ACCConfigInt(kConfigInt_lite_theme_tab_style) == 1) {
        NSInteger padding = ACC_SCREEN_WIDTH < 375 ? 10 : 15;
        self.cornerBackView.frame = CGRectMake(-padding, 3, self.acc_width + padding * 2, self.acc_height - 6);
        self.cornerBackView.layer.cornerRadius = (self.acc_height - 6) / 2;
    }
}

- (void)buildWithTabConfig:(AWESwitchModeSingleTabConfig *)tabConfig {
    self.tabConfig = tabConfig;
    [self.titleLabel setText:tabConfig.title];
    if (tabConfig.imageName) {
        [self.imageView setImage:[ACCResourceImage(tabConfig.imageName) imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    } else if (tabConfig.imageURLArray) {
        [ACCWebImage() imageView:self.imageView setImageWithURLArray:tabConfig.imageURLArray];
    }
    if (tabConfig.info) {
        [self.infoLabel setText:tabConfig.info];
        [self updateInfoViewHidden:NO];
    }
    [self showRedDot:tabConfig.showRedDot];
    [self showTopRightTipIfNeeded];
    [self p_configSubviewLayout];
}

- (void)configCellWithUIStyle:(BOOL)blackStyle selected:(BOOL)selected color:(UIColor *)color animated:(BOOL)animated
{
    self.blackStyle = blackStyle;
    self.selected = selected;
    if (animated) {
        [UIView transitionWithView:self.titleLabel duration:.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.titleLabel.textColor = color;
        } completion:nil];
        [UIView animateWithDuration:.25 animations:^{
            self.imageView.tintColor = color;
        }];
    } else {
        [self refreshColorWithSelected:selected uiColor:color];
    }
}

- (void)refreshColorWithSelected:(BOOL)selected uiColor:(UIColor *)color {
    self.cellSelected = selected;
    self.titleLabel.textColor = color;
    self.imageView.tintColor = color;
    if (selected) {
        [self updateInfoViewHidden:YES];
    }
    
    if (ACCConfigInt(kConfigInt_lite_theme_tab_style) == 1) {
        self.cornerBackView.hidden = !self.cellSelected;
    }
}

- (void)refreshColorWithUIStyle:(BOOL)blackStyle normalColor:(UIColor *)normalColor selectedColor:(UIColor *)selectedColor animated:(BOOL)animated {
    self.blackStyle = blackStyle;
    UIColor *color = self.cellSelected ? selectedColor : normalColor;
    if (animated) {
        [UIView transitionWithView:self.titleLabel duration:.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.titleLabel.textColor = color;
        } completion:nil];
        [UIView animateWithDuration:.25 animations:^{
            self.imageView.tintColor = color;
        }];
    } else {
        [self refreshColorWithSelected:self.cellSelected uiColor:color];
    }
}

- (void)showRedDot:(BOOL)show
{
    self.redDotView.hidden = !show;
}

- (void)showTopRightTipIfNeeded
{
    NSString *topRightTipText = ACCDynamicCast(self.tabConfig, AWESwitchModeSingleTabConfigD).topRightTipText;
    if (!ACC_isEmptyString(topRightTipText)) {
        self.topRightTipLabel.text = ACCDynamicCast(self.tabConfig, AWESwitchModeSingleTabConfigD).topRightTipText;
        self.topRightTipLabel.hidden = NO;
    } else {
        self.topRightTipLabel.hidden = YES;
    }
}

- (void)showFlowerViewIfNeeded:(BOOL)show animated:(BOOL)animated
{
    if(show){
      [self.flowerView removeFromSuperview];
      [self.contentView addSubview:self.flowerView];
      [self.contentView bringSubviewToFront:self.flowerView];
    } else {
        if(_flowerView) {
            [self.flowerView removeFromSuperview];
        }
    }
}

+ (NSInteger)cellWidthWithTabConfig:(AWESwitchModeSingleTabConfig *)tabConfig {
    CGSize size = [tabConfig.title acc_sizeWithFont:[ACCFont() acc_boldSystemFontOfSize:15] width:CGFLOAT_MAX maxLine:1];
    BOOL hasImage = !ACC_isEmptyString(tabConfig.imageName) || !ACC_isEmptyArray(tabConfig.imageURLArray);
    CGFloat width = (hasImage ? ImageWidth + ImageTitlePadding : 0) + size.width;
    if (tabConfig.info) {
        width += 4;
    }
    return ceil(width);
}

+ (NSString *)identifier {
    return NSStringFromClass(self.class);
}

- (void)p_configSubviewLayout
{
    CGSize size = [self.tabConfig.title acc_sizeWithFont:[ACCFont() acc_boldSystemFontOfSize:15] width:CGFLOAT_MAX maxLine:1];
    self.titleLabel.acc_size = size;
    BOOL hasImage = !ACC_isEmptyString(self.tabConfig.imageName) || !ACC_isEmptyArray(self.tabConfig.imageURLArray);
    if (hasImage) {
        self.imageView.acc_centerY = self.acc_height * .5;
        self.titleLabel.acc_left = self.imageView.acc_right + ImageTitlePadding - 1;
    } else {
        self.titleLabel.acc_centerX = self.acc_width *.5;
    }
    self.titleLabel.acc_centerY = self.acc_height * .5;
    self.redDotView.acc_left = self.titleLabel.acc_width + 2;
    self.redDotView.acc_top = self.titleLabel.acc_top - 2;
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        if (ACC_SCREEN_WIDTH < 375) {
            _titleLabel.font = [ACCFont() acc_boldSystemFontOfSize:13];
        } else {
            _titleLabel.font = [ACCFont() acc_boldSystemFontOfSize:15];
        }
        _titleLabel.textColor = ACCResourceColor(ACCUIColorBGContainer6);
    }
    return _titleLabel;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ImageWidth, ImageWidth)];
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

-(UILabel *)infoLabel
{
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 32, 16)];
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.font = [ACCFont() acc_systemFontOfSize:10];
        _infoLabel.textColor = [UIColor whiteColor];
        _infoLabel.hidden = YES;
    }
    return _infoLabel;
}

- (UIView *)infoGradientView
{
    if (!_infoGradientView) {
        _infoGradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 16)];
        _infoGradientView.hidden = YES;
        CAGradientLayer *gradientLayer = [CAGradientLayer new];
        gradientLayer.frame = _infoGradientView.bounds;
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1, 1);
        gradientLayer.cornerRadius = 8;
        gradientLayer.colors = @[(__bridge id)[UIColor acc_colorWithHexString:@"#ff1764"].CGColor,
                                 (__bridge id)[UIColor acc_colorWithHexString:@"#ed3495"].CGColor];
        [_infoGradientView.layer addSublayer:gradientLayer];
        [_infoGradientView addSubview:self.infoLabel];
    }
    return _infoGradientView;
}

- (UIView *)redDotView
{
    if (!_redDotView) {
        _redDotView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 8)];
        _redDotView.backgroundColor = ACCUIColorFromRGBA(0xfe2c55, 1.0);
        _redDotView.layer.cornerRadius = 4;
        _redDotView.layer.masksToBounds = YES;
        _redDotView.hidden = YES;
    }
    return _redDotView;
}

- (UILabel *)topRightTipLabel
{
    if (!_topRightTipLabel) {
        _topRightTipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _topRightTipLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        _topRightTipLabel.textColor = UIColor.whiteColor;
        _topRightTipLabel.backgroundColor = ACCColorFromHexString(@"FE2C55");
        _topRightTipLabel.textAlignment = NSTextAlignmentCenter;
        _topRightTipLabel.layer.cornerRadius = 7;
        _topRightTipLabel.layer.masksToBounds = YES;
    }
    return _topRightTipLabel;
}

- (AWESwitchRecordModeFlowerView *)flowerView
{
    if(!_flowerView){
        _flowerView = [[AWESwitchRecordModeFlowerView alloc] initWithFrame:CGRectMake(0, 5, FlowerEntrySize().width, FlowerEntrySize().height)];
    }
    return _flowerView;
}

- (UIView *)cornerBackView
{
    if (!_cornerBackView) {
        _cornerBackView = [[UIView alloc] initWithFrame:CGRectZero];
        _cornerBackView.userInteractionEnabled = NO;
        _cornerBackView.hidden = YES;
        _cornerBackView.backgroundColor = ACCUIColorFromRGBA(0xFFFFFF, 0.1);
        _cornerBackView.layer.masksToBounds = YES;
    }
    return _cornerBackView;
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    if (self.cellSelected
        && self.flowerView != nil
        && self.flowerView.superview == self.contentView
        && self.flowerView.hidden == NO) {
        return @"春节集卡";
    }
    return [NSString stringWithFormat:@"%@ %@", self.cellSelected ? @"已选中" : @"未选中", self.titleLabel.text];
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end
