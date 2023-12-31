//
//  ACCRecordMeteorModeGuidePanel.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/8.
//

#import "ACCRecordMeteorModeGuidePanel.h"
#import "ACCConfigKeyDefines.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/View+MASAdditions.h>
#import <YYImage/YYAnimatedImageView.h>

static CGFloat const kAnimatedImageViewTopOffset = 32;
static CGFloat const kAnimatedImageViewHeight = 178;
static CGFloat const kTitleLabelTopOffset = 24;
static CGFloat const kDescriptionLabelTopOffset = 14;
static CGFloat const kConfirmButtonHeight = 44;
static CGFloat const kConfirmButtonTopOffset = 28;
static CGFloat const kConfirmButtonBottomOffset = 16;

static BOOL isShowing = NO;

@interface ACCRecordMeteorModeGuidePanel ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) ACCAnimatedButton *closeButton;
@property (nonatomic, strong) YYAnimatedImageView *animatedImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) ACCAnimatedButton *confirmButton;

@property (nonatomic, copy) dispatch_block_t confirmBlock;
@property (nonatomic, copy) void(^dismissBlock)(ACCRecordMeteorModeGuidePanelDismissScene);
@property (nonatomic, assign) BOOL hasBackground;

@end

@implementation ACCRecordMeteorModeGuidePanel

+ (void)showOnView:(UIView *)containerView
  withConfirmBlock:(dispatch_block_t)confirmBlock
      dismissBlock:(nullable void (^)(ACCRecordMeteorModeGuidePanelDismissScene))dismissBlock
     hasBackground:(BOOL)hasBackground
{
    if (isShowing) {
        return;
    }
    isShowing = YES;
    ACCRecordMeteorModeGuidePanel *panel = [[ACCRecordMeteorModeGuidePanel alloc] initWithHasBackground:hasBackground];
    panel.confirmBlock = confirmBlock;
    panel.dismissBlock = dismissBlock;
    panel.frame = CGRectMake(0, [ACCRecordMeteorModeGuidePanel contentViewHeight], ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT);
    [containerView addSubview:panel];
    
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.0 :0.4 :0.2 :1.0]];
    panel.bgView.alpha = 0;
    [UIView animateWithDuration:0.275 animations:^{
        panel.bgView.alpha = 1;
        panel.acc_top = 0;
    }];
    [CATransaction commit];
}

+ (NSString *)titleContent
{
    return @"全新「一闪而过」模式";
}


+ (NSString *)descriptionContent
{
    return @"开启一闪而过后，这个作品只能被每个用户查看一次";
}

+ (CGFloat)contentViewHeight
{
    CGFloat height = kAnimatedImageViewTopOffset + kAnimatedImageViewHeight + kTitleLabelTopOffset + kDescriptionLabelTopOffset + kConfirmButtonHeight + kConfirmButtonTopOffset + kConfirmButtonBottomOffset + ACC_IPHONE_X_BOTTOM_OFFSET; // height except for content label height;
    CGFloat titleContentHeight = [[self titleContent] boundingRectWithSize:CGSizeMake(ACC_SCREEN_WIDTH - 40, CGFLOAT_MAX)
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium]}
                                                                         context:nil].size.height;
    CGFloat descriptionContentHeight = [[self descriptionContent] boundingRectWithSize:CGSizeMake(ACC_SCREEN_WIDTH - 40, CGFLOAT_MAX)
                                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                                            attributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:14]}
                                                                               context:nil].size.height;
    return height + titleContentHeight + descriptionContentHeight;
}

- (instancetype)initWithHasBackground:(BOOL)hasBackground
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self acc_addSingleTapRecognizerWithTarget:self action:@selector(p_didClickMask:)];
        self.hasBackground = hasBackground;
        [self p_setupUI];
    }
    return self;
}

- (void)layoutSubviews
{
    self.bgView.frame = CGRectMake(0, -self.frame.size.height, self.frame.size.width, self.frame.size.height * 2);
}

- (void)p_setupUI
{
    if (self.hasBackground) {
        self.bgView = [[UIView alloc] initWithFrame:CGRectMake(0, -self.frame.size.height, self.frame.size.width, self.frame.size.height * 2)];
        self.bgView.backgroundColor = ACCResourceColor(ACCColorSDTertiary);
        [self addSubview:self.bgView];
    }
    
    [self addSubview:self.contentView];
    
    ACCMasMaker(self.contentView, {
        make.left.bottom.right.equalTo(self);
        make.height.equalTo(@([ACCRecordMeteorModeGuidePanel contentViewHeight]));
    });
    
    [self.contentView addSubview:self.closeButton];
    [self.contentView addSubview:self.animatedImageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.descriptionLabel];
    [self.contentView addSubview:self.confirmButton];
    
    ACCMasMaker(self.closeButton, {
        make.top.equalTo(self.contentView).offset(8);
        make.right.equalTo(self.contentView).offset(-8);
        make.size.equalTo(@(CGSizeMake(32, 32)));
    })
    
    ACCMasMaker(self.animatedImageView, {
        make.top.equalTo(self.contentView).offset(kAnimatedImageViewTopOffset);
        make.centerX.equalTo(self.contentView);
        make.height.equalTo(@(kAnimatedImageViewHeight));
    });
    
    ACCMasMaker(self.titleLabel, {
        make.top.equalTo(self.animatedImageView.mas_bottom).offset(kTitleLabelTopOffset);
        make.centerX.equalTo(self.contentView);
    });
    
    ACCMasMaker(self.descriptionLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(kDescriptionLabelTopOffset);
        make.centerX.equalTo(self.contentView);
        make.width.lessThanOrEqualTo(self.contentView).offset(-32);
    });
    
    ACCMasMaker(self.confirmButton, {
        make.top.equalTo(self.descriptionLabel.mas_bottom).offset(kConfirmButtonTopOffset);
        make.left.equalTo(self.contentView).offset(16);
        make.centerX.equalTo(self.contentView);
        make.height.equalTo(@(kConfirmButtonHeight));
    });
}

#pragma mark - Actions

- (void)p_didClickMask:(id)sender
{
    [self p_dismiss:ACCRecordMeteorModeGuidePanelDismissSceneClickMaskView];
}

- (void)p_didClickCloseButton:(id)sender
{
    [self p_dismiss:ACCRecordMeteorModeGuidePanelDismissSceneClickCloseButton];
}

- (void)p_didClickConfirmButton:(id)sender
{
    ACCBLOCK_INVOKE(self.confirmBlock);
    [self p_dismiss:ACCRecordMeteorModeGuidePanelDismissSceneClickConfirmButton];
}

- (void)p_dismiss:(ACCRecordMeteorModeGuidePanelDismissScene)scene
{
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.3 :0 :0.9 :0.6]];
    self.bgView.alpha = 1;
    [UIView animateWithDuration:0.275 animations:^{
        self.bgView.alpha = 0;
        self.acc_top = [ACCRecordMeteorModeGuidePanel contentViewHeight];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        ACCBLOCK_INVOKE(self.dismissBlock, scene);
    }];
    [CATransaction commit];
    isShowing = NO;
}

#pragma mark - Getters

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = ACCResourceColor(ACCColorBGReverse);
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [ACCRecordMeteorModeGuidePanel contentViewHeight] + ACC_IPHONE_X_BOTTOM_OFFSET)
                                                byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                      cornerRadii:CGSizeMake(10, 10)].CGPath;
        _contentView.layer.mask = shapeLayer;
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:nil];
        [_contentView addGestureRecognizer:tapGestureRecognizer];
    }
    return _contentView;
}

- (ACCAnimatedButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        _closeButton.accessibilityLabel = @"关闭";
        [_closeButton setImage:ACCResourceImage(@"icon_album_first_creative_close") forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(p_didClickCloseButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (YYAnimatedImageView *)animatedImageView
{
    if (!_animatedImageView) {
        _animatedImageView = [[YYAnimatedImageView alloc] init];
        _animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
        NSString *imageUrl = ACCConfigString(kConfigString_meteor_mode_guide_url);
        if (ACC_isEmptyString(imageUrl)) {
            imageUrl = @"https://lf3-static.bytednsdoc.com/obj/eden-cn/617eh7nuvahpqps/meteor_intro_anim.webp";
            AWELogToolError2(@"meteor_guide_panel", AWELogToolTagMonitor, @"getting aweme_meteor_mode_guide_url from Settings failed");
        }
        [ACCWebImage() imageView:_animatedImageView
            setImageWithURLArray:@[imageUrl]
                     placeholder:ACCResourceImage(@"meteor_guide_panel_placehodler") completion:^(UIImage *image, NSURL *url, NSError *error) {
            if (error) {
                AWELogToolError2(@"meteor_guide_panel", AWELogToolTagMonitor, @"download failed");
            }
        }];
    }
    return _animatedImageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorTextReverse);
        _titleLabel.text = [ACCRecordMeteorModeGuidePanel titleContent];
    }
    return _titleLabel;
}

- (UILabel *)descriptionLabel
{
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.font = [ACCFont() systemFontOfSize:14];
        _descriptionLabel.numberOfLines = 0;
        _descriptionLabel.textAlignment = NSTextAlignmentCenter;
        _descriptionLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        _descriptionLabel.text = [ACCRecordMeteorModeGuidePanel descriptionContent];
    }
    return _descriptionLabel;
}

- (ACCAnimatedButton *)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        _confirmButton.layer.cornerRadius = 2;
        _confirmButton.layer.masksToBounds = YES;
        if (ACCConfigBool(ACCConfigBool_meteor_mode_on)) {
            _confirmButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
            _confirmButton.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
            [_confirmButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
            [_confirmButton setTitle:@"开始体验" forState:UIControlStateNormal];
            [_confirmButton addTarget:self action:@selector(p_didClickConfirmButton:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            _confirmButton.enabled = NO;
            _confirmButton.titleLabel.font = [ACCFont() systemFontOfSize:13];
            [_confirmButton setTitle:@"该玩法暂未对你开放" forState:UIControlStateNormal];
            [_confirmButton setTitleColor:ACCResourceColor(ACCColorTextReverse3) forState:UIControlStateNormal];
            _confirmButton.layer.borderColor = ACCResourceColor(ACCColorTextReverse4).CGColor;
            _confirmButton.layer.borderWidth = 0.5;
        }
    }
    return _confirmButton;
}

@end
