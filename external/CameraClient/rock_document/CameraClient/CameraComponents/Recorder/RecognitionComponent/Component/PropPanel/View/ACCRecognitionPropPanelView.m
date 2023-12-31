//
//  ACCExposePropPanelView.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/6.
//

#import "ACCRecognitionPropPanelView.h"
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreativeKit/UIImageView+ACCAddtions.h>
#import "AWEPropSecurityTipsHelper.h"

@interface ACCRecognitionPropPanelView ()

@property (nonatomic, strong) ACCAnimatedButton *closeButton;
@property (nonatomic, strong) ACCAnimatedButton *favorButton;
@property (nonatomic, strong) ACCAnimatedButton *moreButton;
@property (nonatomic, strong) UIImageView *securityTipsIconView;

@end

@implementation ACCRecognitionPropPanelView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        backgroundView.backgroundColor = [UIColor clearColor];
        [self addSubview:backgroundView];
        ACCMasMaker(backgroundView, {
            make.height.mas_equalTo(ACC_IPHONE_X_BOTTOM_OFFSET + 54);
            make.left.right.bottom.mas_equalTo(@0);
        });
        _backgroundView = backgroundView;
        
        _panelView = [[ACCRecognitionScrollPropPanelView alloc] init];
        _exposePanGestureRecognizer = [[ACCExposePanGestureRecognizer alloc] initWithTarget:self action:@selector(onGestureRecognizer:)];
        _panelView.exposePanGestureRecognizer = _exposePanGestureRecognizer;

        [self addSubview:self.panelView];
        ACCMasMaker(_panelView, {
            make.left.right.equalTo(@0);
            make.height.mas_equalTo(@80);
            make.top.mas_equalTo(@(self.recordButtonTop));
        })
        
        _securityTipsIconView = [[UIImageView alloc] init];
        _securityTipsIconView.userInteractionEnabled = YES;
        _securityTipsIconView.image = ACCResourceImage(@"icon_security_tips");
        _securityTipsIconView.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-15, -15, -15, -15);
        _securityTipsIconView.hidden = ![AWEPropSecurityTipsHelper shouldShowSecurityTips];
        UITapGestureRecognizer *tapOnSecurityTips = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSecurityTipsTapped)];
        [_securityTipsIconView addGestureRecognizer:tapOnSecurityTips];
        [self addSubview:self.securityTipsIconView];
        ACCMasMaker(_securityTipsIconView, {
            make.right.equalTo(@-20);
            make.centerY.equalTo(self.panelView.mas_top).offset(-30);
            make.width.height.equalTo(@16);
        });

        _closeButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
        [_closeButton setImage:ACCResourceImage(@"ic_submode_close_button") forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.isAccessibilityElement = YES;
        _closeButton.accessibilityLabel = @"关闭";
        _closeButton.accessibilityTraits = UIAccessibilityTraitButton;
        [self addSubview:_closeButton];
        ACCMasMaker(_closeButton, {
            make.size.mas_equalTo(CGSizeMake(48, 48));
            make.centerX.mas_equalTo(@0);
            make.bottom.mas_equalTo(@(2 - ACC_IPHONE_X_BOTTOM_OFFSET));
        });
        
        UIView *favorContainer = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:favorContainer];
        ACCMasMaker(favorContainer, {
            make.left.mas_equalTo(@0);
            make.right.mas_equalTo(_closeButton.mas_left).offset(-20);
            make.height.mas_equalTo(@(48));
            make.bottom.mas_equalTo(@(-4 - ACC_IPHONE_X_BOTTOM_OFFSET));
        });

        _favorButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
        _favorButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-4, -28, -10, -28);
        [_favorButton setTitle:@"收藏" forState:UIControlStateNormal];
        [_favorButton setTitle:@"已收藏" forState:UIControlStateSelected];
        _favorButton.titleLabel.font = [UIFont systemFontOfSize:11];
        _favorButton.titleLabel.shadowColor = [ACCResourceColor(ACCColorLineReverse) colorWithAlphaComponent:0.2];
        _favorButton.titleLabel.shadowOffset = CGSizeMake(0, 1 / ACC_SCREEN_SCALE);
        _favorButton.isAccessibilityElement = YES;
        _favorButton.accessibilityLabel = _favorButton.titleLabel.text;
        _favorButton.accessibilityTraits = UIAccessibilityTraitButton;
        UIImageView *favorImageView = [[UIImageView alloc] init];
        [_favorButton addSubview:favorImageView];
        ACCMasMaker(favorImageView, {
            make.centerX.mas_equalTo(@0);
            make.top.mas_equalTo(@1);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        });
        [[[RACObserve(_favorButton, selected) takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
            if ([x boolValue]) {
                favorImageView.image = ACCResourceImage(@"ic_fav_selected");
            } else {
                favorImageView.image = ACCResourceImage(@"expose_prop_favor");
            }
        }];

        [_favorButton addTarget:self action:@selector(favor) forControlEvents:UIControlEventTouchUpInside];
        _favorButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, -22, 0);
        [favorContainer addSubview:_favorButton];
        ACCMasMaker(_favorButton, {
            make.size.mas_equalTo(CGSizeMake(56, 41));
            make.centerX.mas_equalTo(@0);
            make.bottom.mas_equalTo(@0);
        });

        UIView *moreContainer = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:moreContainer];
        ACCMasMaker(moreContainer, {
            make.right.mas_equalTo(@0);
            make.left.mas_equalTo(_closeButton.mas_right).offset(20);
            make.height.mas_equalTo(@(48));
            make.bottom.mas_equalTo(@(-4 - ACC_IPHONE_X_BOTTOM_OFFSET));
        });
        
        _moreButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
        _moreButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-4, -28, -10, -28);
        [_moreButton setImage:ACCResourceImage(@"expose_prop_more") forState:UIControlStateNormal];
        [_moreButton setTitle:@"更多" forState:UIControlStateNormal];
        _moreButton.titleLabel.font = [UIFont systemFontOfSize:11];
        _moreButton.titleLabel.shadowColor = [ACCResourceColor(ACCColorLineReverse) colorWithAlphaComponent:0.2];
        _moreButton.titleLabel.shadowOffset = CGSizeMake(0, 1 / ACC_SCREEN_SCALE);
        [self setButtonVerticallyCenter:_moreButton];
        [_moreButton addTarget:self action:@selector(more) forControlEvents:UIControlEventTouchUpInside];
        _moreButton.isAccessibilityElement = YES;
        _moreButton.accessibilityLabel = _moreButton.titleLabel.text;
        _moreButton.accessibilityTraits = UIAccessibilityTraitButton;
        [moreContainer addSubview:_moreButton];
        ACCMasMaker(_moreButton, {
            make.size.mas_equalTo(CGSizeMake(56, 41));
            make.centerX.mas_equalTo(@0);
            make.bottom.mas_equalTo(@0);
        });
    }
    return self;
}

- (void)setRecordButtonTop:(CGFloat)recordButtonTop
{
    _recordButtonTop = recordButtonTop;
    ACCMasReMaker(_panelView, {
        make.left.right.equalTo(@0);
        make.height.mas_equalTo(@80);
        make.top.mas_equalTo(@(self.recordButtonTop));
    })
}

- (void)onGestureRecognizer:(ACCExposePanGestureRecognizer *)gesture
{
    
}

- (void)setButtonVerticallyCenter:(UIButton*)button
{
    [button sizeToFit];
    if (button.imageView == nil || button.titleLabel == nil) {
        return;
    }
    
    CGFloat imageWidth = button.imageView.acc_width;
    CGFloat imageHeight = button.imageView.acc_height;
    CGFloat labelWidth = button.titleLabel.acc_width;
    CGFloat labelHeight = button.titleLabel.acc_height;
    CGFloat padding = 4;
    CGFloat imageVerticalOffset = (labelHeight + padding) / 2;
    CGFloat titleVerticalOffset = (imageHeight + padding) / 2;
    CGFloat imageHorizontalOffset = labelWidth / 2;
    CGFloat titleHorizontalOffset = imageWidth / 2;
    button.imageEdgeInsets = UIEdgeInsetsMake(-imageVerticalOffset, imageHorizontalOffset, imageVerticalOffset, -imageHorizontalOffset);
    button.titleEdgeInsets = UIEdgeInsetsMake(titleVerticalOffset, -titleHorizontalOffset, -titleVerticalOffset, titleHorizontalOffset);
    CGFloat edgeOffset = (MIN(imageHeight, labelHeight) + padding) / 2;
    button.contentEdgeInsets = UIEdgeInsetsMake(edgeOffset, 0, edgeOffset, 0);
}

- (void)setShowFavorAndMoreButton:(BOOL)shouldShow
{
    _favorButton.hidden = !shouldShow;
    _moreButton.hidden = !shouldShow;
}

- (void)setFavorButtonSelected:(BOOL)isSelected
{
    if (self.favorButton.enabled){
        self.favorButton.selected = isSelected;
    }
}

- (void)close
{
    if (self.closeButtonClickCallback) {
        self.closeButtonClickCallback();
    }
}

- (void)favor
{
    _favorButton.selected = !_favorButton.selected;
    if (self.favorButtonClickCallback) {
        self.favorButtonClickCallback();
    }
}

- (void)more
{
    if (self.moreButtonClickCallback) {
        self.moreButtonClickCallback();
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self && point.y < self.panelView.acc_top) {
        return nil;
    }
    return view;
}

- (void)handleSecurityTipsTapped
{
    @weakify(self)
    [ACCAlert() showAlertWithTitle:nil
                       description:@"道具中的人脸特效仅用做本地效果实现，不会上传和采集你的人脸特征"
                             image:nil
                 actionButtonTitle:nil
                 cancelButtonTitle:@"我知道了"
                       actionBlock:nil
                       cancelBlock:^{
        @strongify(self)
        self.securityTipsIconView.hidden = YES;
        [AWEPropSecurityTipsHelper handleSecurityTipsDisplayed];
    }];
}

@end
