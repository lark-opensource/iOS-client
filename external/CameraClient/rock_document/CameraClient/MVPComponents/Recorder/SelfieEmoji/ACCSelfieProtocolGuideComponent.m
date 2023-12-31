//
//  ACCSelfieProtocolGuideComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liujingchuan on 2021/8/29.
//

#import "ACCSelfieProtocolGuideComponent.h"
#import "AWEIMGuideSelectionImageView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCUIThemeManager.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/Masonry.h>
#import <CreativeKit/ACCMacros.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import "ACCSelfieGuideService.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/ACCWebViewProtocol.h>
#import <CameraClient/ACCAPPSettingsProtocol.h>

@interface ACCSelfieProtocolGuideComponent() <AWEIMGuideSelectionImageViewDelegate>

@property (strong, nonatomic) UIView *grayBackView;
@property (strong, nonatomic) UIView *contentContainerView;
@property (strong, nonatomic) UIImageView *xmojiImageView;
@property (strong, nonatomic) UILabel *topTitleLabel;
@property (strong, nonatomic) CAShapeLayer *backgroundTypeMaskLayer;
@property (strong, nonatomic) AWEIMGuideSelectionImageView *selectionCircleView;//勾选框
@property (strong, nonatomic) UILabel *agreeTipsLabel;
@property (strong, nonatomic) UIButton *openPrivacyPageButton;
@property (strong, nonatomic) UIButton *confirmButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIControl *expandSelectControl;
@property (strong, nonatomic) id<ACCRecorderViewContainer> viewContainer;
@property (strong, nonatomic) id<ACCSelfieGuideService> guaideImpl;

@end

@implementation ACCSelfieProtocolGuideComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, guaideImpl, ACCSelfieGuideService)

- (void)loadComponentView {
    [self.viewContainer.interactionView addSubview:self.grayBackView];
    [self.grayBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.viewContainer.interactionView);
    }];

    [self.grayBackView addSubview:self.contentContainerView];
    [self.contentContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.grayBackView);
        make.height.mas_equalTo(374);
        make.top.mas_equalTo([UIScreen mainScreen].bounds.size.height);
    }];

    [self.contentContainerView addSubview:self.xmojiImageView];
    [self.xmojiImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.contentContainerView);
        make.height.width.mas_equalTo(160);
        make.top.mas_equalTo(32);
    }];

    [self.contentContainerView addSubview:self.topTitleLabel];
    [self.topTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.xmojiImageView.mas_bottom).mas_offset(16);
        make.centerX.mas_equalTo(self.contentContainerView);
        make.height.mas_offset(28);
    }];
    [self.contentContainerView addSubview:self.expandSelectControl];
    [self.expandSelectControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.topTitleLabel.mas_bottom);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.height.mas_equalTo(40);
    }];

    [self.expandSelectControl addSubview:self.selectionCircleView];
    [self.selectionCircleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.expandSelectControl);
        make.height.width.mas_equalTo(20);
        make.left.mas_equalTo(69);
    }];

    [self.expandSelectControl addSubview:self.agreeTipsLabel];
    [self.agreeTipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.expandSelectControl);
        make.left.mas_equalTo(self.selectionCircleView.mas_right).mas_offset(8);
    }];

    [self.expandSelectControl addSubview:self.openPrivacyPageButton];
    [self.openPrivacyPageButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.agreeTipsLabel.mas_right);
        make.centerY.mas_equalTo(self.expandSelectControl);
    }];

    [self.contentContainerView addSubview:self.cancelButton];
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.width.mas_equalTo(168);
        make.height.mas_equalTo(44);
        make.top.mas_equalTo(self.expandSelectControl.mas_bottom).mas_offset(14);
    }];

    [self.contentContainerView addSubview:self.confirmButton];
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-16);
        make.top.width.height.mas_equalTo(self.cancelButton);
    }];
}

- (NSString *)didAgreeProtocolKey {
    id<ACCUserModelProtocol> user = [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel];
    return [NSString stringWithFormat:@"%@_%@",  user.userID ?: @"", @"kACCDidAgreeProtocolKey"];
}

- (void)componentDidMount {
    BOOL agrred = [ACCCache() boolForKey:[self didAgreeProtocolKey]];
    if (!agrred) {
        [self loadComponentView];
    }
}

- (void)componentDidAppear {
    [ACCTracker() trackEvent:@"xmoji_privacy_popup" params:@{@"action_type" : @"show"}];
    [self p_addView:self.contentContainerView withRoundedCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(16, 16)];
    BOOL agrred = [ACCCache() boolForKey:[self didAgreeProtocolKey]];
    if (!agrred) {
        [self p_showAgreementViewWithAnimation];
    }
}

- (void)p_showAgreementViewWithAnimation {
    [self.contentContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo([UIScreen mainScreen].bounds.size.height - 374);
    }];
    [UIView animateWithDuration:0.25 delay:0.2 options:UIViewAnimationOptionTransitionCurlUp animations:^{
        [self.grayBackView layoutIfNeeded];
    } completion:nil];
}

- (void)p_dismissAgreementViewWithAnimation:(void(^)(void))completion {
    [self.contentContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo([UIScreen mainScreen].bounds.size.height);
    }];
    [UIView animateWithDuration:0.25 delay:0.2 options:UIViewAnimationOptionTransitionCurlDown animations:^{
        [self.grayBackView layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.grayBackView.hidden = YES;
        ACCBLOCK_INVOKE(completion);
    }];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase {
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - getter

- (UIView *)grayBackView {
    if (!_grayBackView) {
        _grayBackView = [[UIView alloc] init];
        _grayBackView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.34];
    }
    return _grayBackView;
}

- (UIView *)contentContainerView {
    if (!_contentContainerView) {
        _contentContainerView = [[UIView alloc] init];
        _contentContainerView.backgroundColor = ACCResourceColor(ACCColorBGReverse);
    }
    return _contentContainerView;
}

- (UIImageView *)xmojiImageView {
    if (!_xmojiImageView) {
        _xmojiImageView = [[UIImageView alloc] init];
        _xmojiImageView.image = ACCResourceImage(@"ic_xmoji_sample");
    }
    return _xmojiImageView;
}

- (UILabel *)topTitleLabel {
    if (!_topTitleLabel) {
        _topTitleLabel = [[UILabel alloc] init];
        _topTitleLabel.text = @"自拍表情";
        _topTitleLabel.textAlignment = NSTextAlignmentCenter;
        _topTitleLabel.font = [ACCFont() acc_boldSystemFontOfSize:20];
        _topTitleLabel.textColor = ACCResourceColor(ACCColorTextReverse);
        _topTitleLabel.backgroundColor = UIColor.clearColor;
    }
    return _topTitleLabel;
}

- (UILabel *)agreeTipsLabel {
    if (!_agreeTipsLabel) {
        _agreeTipsLabel = [[UILabel alloc] init];
        _agreeTipsLabel.text = @"同意";
        _agreeTipsLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        _agreeTipsLabel.font = [ACCFont() acc_boldSystemFontOfSize:14];
        _agreeTipsLabel.textAlignment = NSTextAlignmentCenter;
        _agreeTipsLabel.backgroundColor = UIColor.clearColor;
    }
    return _agreeTipsLabel;
}

- (UIButton *)openPrivacyPageButton {
    if (!_openPrivacyPageButton) {
        _openPrivacyPageButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _openPrivacyPageButton.backgroundColor = UIColor.clearColor;
        [_openPrivacyPageButton setTitle:@"《自拍表情制作及使用须知》" forState:UIControlStateNormal];
        _openPrivacyPageButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:14];
        _openPrivacyPageButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_openPrivacyPageButton setTitleColor:ACCResourceColor(ACCColorLink4) forState:UIControlStateNormal];
        [_openPrivacyPageButton addTarget:self action:@selector(p_openPrivacyPage:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _openPrivacyPageButton;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _cancelButton.backgroundColor = ACCResourceColor(ACCColorBGTertiary);
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:15];
        _cancelButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_cancelButton setTitleColor:ACCResourceColor(ACCColorTextReverse) forState:UIControlStateNormal];
        _cancelButton.layer.cornerRadius = 2.0;
        _cancelButton.clipsToBounds = YES;
        _cancelButton.layer.borderWidth = 1.0;
        _cancelButton.layer.borderColor = ACCResourceColor(ACCColorLineReverse).CGColor;
        [_cancelButton addTarget:self action:@selector(p_cancelButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _confirmButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
        _confirmButton.layer.cornerRadius = 2.0;
        _confirmButton.clipsToBounds = YES;
        _confirmButton.enabled = YES;
        [_confirmButton setTitle:@"开始拍摄" forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:15];
        _confirmButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_confirmButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(p_confirmButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (AWEIMGuideSelectionImageView *)selectionCircleView {
    if (!_selectionCircleView) {
        _selectionCircleView = [[AWEIMGuideSelectionImageView alloc] init];
        _selectionCircleView.delegate = self;
    }
    return _selectionCircleView;
}

- (UIControl *)expandSelectControl {
    if (!_expandSelectControl) {
        _expandSelectControl = [[UIControl alloc] init];
        [_expandSelectControl addTarget:self action:@selector(expandControlTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    return _expandSelectControl;
}

- (void)p_addView:(UIView *)view withRoundedCorners:(UIRectCorner)corners cornerRadii:(CGSize)radii {
    UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corners cornerRadii:radii];
    CAShapeLayer *shape = [[CAShapeLayer alloc] init];
    shape.path = roundedPath.CGPath;
    view.layer.mask = shape;
}

- (void)p_openPrivacyPage:(UIButton *)btn {
    NSString *urlStr = [ACCAPPSettings() xmojiGeneratePrivacyHintURLString];
    BOOL isLightModel = [ACCUIThemeManager sharedInstance].currentThemeStyle == ACCUIThemeStyleLight;
    NSURL *url = [NSURL btd_URLWithString:urlStr queryItems:@{@"theme" : isLightModel ? @"light" : @"dark"}];

    let webViewObj = IESAutoInline(ACCBaseServiceProvider(), ACCWebViewProtocol);
    UIViewController *webVC = [webViewObj createWebviewControllerWithUrl:url.absoluteString title:@"自拍表情制作及使用须知"];
    [self.controller.root.navigationController pushViewController:webVC animated:YES];
    [ACCTracker() trackEvent:@"enter_xmoji_agreement" params:@{}];
}

- (void)p_cancelButtonClick:(UIButton *)btn {
    [ACCTracker() trackEvent:@"xmoji_privacy_popup" params:@{@"action_type" : @"cancel"}];
    [self p_dismissAgreementViewWithAnimation:^{
        [self.controller close];
        [self.guaideImpl didClickCancleAction:btn];
    }];

}

- (void)p_confirmButtonClick:(UIButton *)btn {
    [ACCTracker() trackEvent:@"xmoji_privacy_popup" params:@{@"action_type" : @"start"}];
    [self p_dismissAgreementViewWithAnimation:^{
        [ACCCache() setBool:YES forKey:[self didAgreeProtocolKey]];
        [self.guaideImpl didClickConfirmAction:btn];
    }];
}

- (void)expandControlTouched {
    [self.selectionCircleView setIsSelected:!self.selectionCircleView.isSelected];
    [self selectionImageViewDidChangeSelected:self.selectionCircleView.isSelected];
}

- (void)selectionImageViewDidChangeSelected:(BOOL)selected {
    if (selected) {
        self.confirmButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
        [self.confirmButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
        self.confirmButton.enabled = YES;
    } else {
        self.confirmButton.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
        [self.confirmButton setTitleColor:ACCResourceColor(ACCColorTextReverse4) forState:UIControlStateNormal];
        self.confirmButton.enabled = NO;
    }
}

@end
