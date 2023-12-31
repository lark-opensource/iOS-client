//
//  CJPaySimpleHalfScreenWebViewController.m
//  CJPay
//
//  Created by liyu on 2020/7/14.
//

#import "CJPaySimpleHalfScreenWebViewController.h"

#import <WebKit/WKWebView.h>
#import <WebKit/WKNavigationDelegate.h>
#import "CJWebViewHelper.h"
#import "CJPayLineUtil.h"
#import <IESWebViewMonitor/UIViewController+BlankDetectMonitor.h>
#import "CJPayWKWebView.h"
#import "CJPayUIMacro.h"
#import "CJPayLoadingManager.h"

@interface CJPaySimpleHalfScreenWebViewController () <WKNavigationDelegate>

@property (nonatomic, strong) CJPayWKWebView *webView;
@property (nonatomic, copy) NSString *urlString;

@end

@implementation CJPaySimpleHalfScreenWebViewController

- (instancetype)initWithUrlString:(NSString *)urlString
{
    self = [super init];
    if (self) {
        _urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
        self.isSupportClickMaskBack = NO;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.contentView addSubview:self.webView];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
    [self switchWebViewBlankDetect:YES webView:self.webView];
    CJPayMasMaker(self.webView, {
        make.leading.trailing.top.equalTo(self.contentView);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.equalTo(self.view);
        }
    });
    
    [CJPayLineUtil addBottomLineToView:self.navigationBar marginLeft:0 marginRight:0 marginBottom:0];
}

- (void)back
{
    @CJWeakify(self);
    [super closeWithAnimation:YES comletion:^(BOOL isFinish) {
        @CJStrongify(self);
        CJ_CALL_BLOCK(self.didTapCloseButtonBlock);
    }];
}

#pragma mark - Subviews

- (CJPayWKWebView *)webView {
    if (!_webView) {
        _webView = [CJWebViewHelper buildWebView:self.urlString];
        _webView.backgroundColor = UIColor.whiteColor;
        _webView.navigationDelegate = self;
    }
    return _webView;
}

- (CGFloat)containerHeight {
    return CJ_IPhoneX ? 579 : 545;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:self.title];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (!([UIFont cjpayFontMode] == CJPayFontModeNormal)) {
        [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust = '%@%%'", [UIFont cjpayPercentFontScale]] completionHandler:nil];
    }
    [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinHalfLoading];
}

@end
