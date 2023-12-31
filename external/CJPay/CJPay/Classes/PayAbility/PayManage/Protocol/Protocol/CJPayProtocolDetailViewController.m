//
//  CJPayProtocolDetailViewController.m
//  CJPay
//
//  Created by 张海阳 on 2019/6/25.
//

#import "CJPayProtocolDetailViewController.h"

#import <WebKit/WKWebView.h>
#import "CJWebViewHelper.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayStyleButton.h"
#import "CJPayTracker.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import <IESWebViewMonitor/UIViewController+BlankDetectMonitor.h>
#import "CJPayWKWebView.h"
#import "CJPayLoadingManager.h"

@interface CJPayProtocolDetailViewController ()<WKNavigationDelegate>

@property (nonatomic, strong) CJPayWKWebView *webView;
@property (nonatomic, strong) CJPayStyleButton *nextStepButton;
@property (nonatomic, strong) UIView *buttonView;

@property (nonatomic, strong) UIView *safeAreaView;
@property (nonatomic, strong) UIView *bottomGradientLayerView;

@end

@implementation CJPayProtocolDetailViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isSupportClickMaskBack = NO;
        self.isShowTitleNubmer = YES;
    }
    return self;
}

- (instancetype)initWithHeight:(CGFloat)height
{
    self = [self init];
    if (self) {
        self.height = height;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self hideBackButton];
    self.navigationBar.title = self.isShowTitleNubmer ? [NSString stringWithFormat:@"《%@》", self.navTitle] : CJString(self.navTitle);

    [self.contentView addSubview:self.safeAreaView];
    CJPayMasMaker(self.safeAreaView, {
        make.left.right.bottom.equalTo(self.safeAreaView.superview);
        make.height.mas_equalTo(CJ_IPhoneX ? 34 : 0);
    });

    self.buttonView = [UIView new];
    self.buttonView.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview:self.buttonView];

    CJPayMasMaker(self.buttonView, {
        make.left.right.equalTo(self.buttonView.superview);
        make.bottom.equalTo(self.safeAreaView.mas_top);
        make.height.equalTo(@0);
    });

    [self.nextStepButton addTarget:self action:@selector(nextStepButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonView addSubview:self.nextStepButton];

    CJPayMasMaker(self.nextStepButton, {
        make.edges.mas_equalTo(UIEdgeInsetsMake(12, 16, 12, 16));
    });
    self.webView = [CJWebViewHelper buildWebView:self.url];
    self.webView.backgroundColor = UIColor.whiteColor;
    self.webView.navigationDelegate = self;
    [self switchWebViewBlankDetect:YES webView:self.webView];
    [self.contentView addSubview:self.webView];

    CJPayMasMaker(self.webView, {
        make.left.top.right.equalTo(self.webView.superview);
        if (self.showContinueButton) {
            make.bottom.equalTo(self.buttonView.mas_top);
        } else {
            make.bottom.equalTo(self.safeAreaView.mas_top);
        }
    });
    
    [self.contentView addSubview:self.bottomGradientLayerView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //延时0.25s，避免看到Loading闪烁
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
        if (!request || !Check_ValidString(self.url)) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[CJPayLoadingManager defaultService] stopLoading];
            });
        }
        [self.webView loadRequest:request];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.bottomGradientLayerView.frame = CGRectMake(0, self.webView.cj_height - 40, self.webView.cj_width, 40);
}

- (void)nextStepButtonAction {
    self.exitAnimationType = HalfVCEntranceTypeFromBottom;
    if (self.agreeCompletionBeforeAnimation) {
        self.agreeCompletionBeforeAnimation();
    }
    [self closeWithAnimation:YES comletion:^(BOOL _) {
        if (self.agreeCompletionAfterAnimation) {
            self.agreeCompletionAfterAnimation();
        }
    }];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:CJString(self.navTitle)];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.nextStepButton.hidden = !self.showContinueButton;
    [self updateButtonHeight];
    if (!([UIFont cjpayFontMode] == CJPayFontModeNormal)) {
        [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust = '%@%%'", [UIFont cjpayPercentFontScale]] completionHandler:nil];
    }
    
    [[CJPayLoadingManager defaultService] stopLoading];
    [self showBackButton];
}

- (void)updateButtonHeight {
    CJPayMasUpdate(self.buttonView, {
        make.height.equalTo(@72);
    });
}

#pragma mark - Getter & Setter
- (CGFloat)containerHeight {
    if (self.height <= CGFLOAT_MIN) {
        return CJ_HALF_SCREEN_HEIGHT_LOW;
    } else {
        return self.height;
    }
}

- (CJPayStyleButton *)nextStepButton {
    if (!_nextStepButton) {
        CJPayStyleButton *button = [CJPayStyleButton new];
        _nextStepButton = button;
        [button setTitle:CJPayLocalizedStr(@"同意协议并继续") forState:UIControlStateNormal];

        button.titleLabel.font = [UIFont cj_fontOfSize:17];
        button.hidden = YES;
        button.layer.cornerRadius = 5;
    }
    return _nextStepButton;
}

- (UIView *)bottomGradientLayerView {
    if (!_bottomGradientLayerView) {
        UIView *gradientLayerView = [UIView new];
        CAGradientLayer *bottomGradientLayer = [CAGradientLayer layer];
        bottomGradientLayer.startPoint = CGPointMake(0, 0);
        bottomGradientLayer.endPoint = CGPointMake(0, 1);
        bottomGradientLayer.colors = @[(__bridge id)[UIColor cj_ffffffWithAlpha:0].CGColor,
                                       (__bridge id)[UIColor cj_ffffffWithAlpha:0.9].CGColor];
        bottomGradientLayer.frame = CGRectMake(0, 0, self.view.cj_width, 40);
        [gradientLayerView.layer insertSublayer:bottomGradientLayer atIndex:0];
        _bottomGradientLayerView = gradientLayerView;
    }
    return _bottomGradientLayerView;
}

- (UIView *)safeAreaView {
    if (!_safeAreaView) {
        _safeAreaView = [UIView new];
        _safeAreaView.backgroundColor = UIColor.whiteColor;
    }
    return _safeAreaView;
}

@end
