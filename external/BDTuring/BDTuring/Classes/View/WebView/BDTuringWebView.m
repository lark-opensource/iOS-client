//
//  BDTuringWebView.m
//  BDTuring
//
//  Created by bob on 2020/2/25.
//

#import "BDTuringWebView.h"
#import <WebKit/WebKit.h>
#import "BDTuringPiper.h"
#import "WKWebView+Piper.h"
#import "BDTuringMacro.h"
#import "BDTuringPresentView.h"

@interface BDTuringWebView ()

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation BDTuringWebView

- (void)loadWebView {
    WKWebViewConfiguration *webViewconfig = [WKWebViewConfiguration new];
    WKUserContentController *userContentController = [WKUserContentController new];
    webViewconfig.userContentController = userContentController;
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.bounds
                                            configuration:webViewconfig];
    if (@available(iOS 10.0, *)) {
        webView.configuration.dataDetectorTypes = WKDataDetectorTypeNone;
    }
    if (@available(iOS 11.0, *)) {
        webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    webView.layer.masksToBounds = YES;
    webView.navigationDelegate = self;
    [webView turing_installPiper];
    
    [self addSubview:webView];
    self.webView = webView;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.loadingSuccess = NO;
}

- (void)dealloc {
    self.webView.navigationDelegate = nil;
}

- (void)dismissVerifyView {
    [self removeFromSuperview];
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
    self.webView.navigationDelegate = nil;
    self.webView = nil;
    self.indicatorView = nil;
    
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(webViewDidDismiss:)]) {
        [delegate webViewDidDismiss:sself];
    }
}

- (void)scheduleDismissVerifyView {
    BDTuringWeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BDTuringStrongSelf;
        [self dismissVerifyView];
    });
}

- (void)showVerifyView {
    [[BDTuringPresentView defaultPresentView] presentVerifyView:self];
    
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(webViewDidShow:)]) {
        [delegate webViewDidShow:sself];
    }
}

- (void)hideVerifyView {
    [[BDTuringPresentView defaultPresentView] hideVerifyView:self];
    self.webView.navigationDelegate = nil;
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(webViewDidHide:)]) {
        [delegate webViewDidHide:sself];
    }
}

- (UIViewController *)controller {
    UIResponder *nextResponder = [self nextResponder];
    while (nextResponder) {
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }

        nextResponder = nextResponder.nextResponder;
    }
    
    return [UIApplication sharedApplication].keyWindow.rootViewController;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.loadingSuccess = YES;
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(webViewLoadDidSuccess:)]) {
        [delegate webViewLoadDidSuccess:sself];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.webView.navigationDelegate = nil;
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(webViewLoadDidFail:)]) {
        [delegate webViewLoadDidFail:sself];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.webView.navigationDelegate = nil;
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(webViewLoadDidFail:)]) {
        [delegate webViewLoadDidFail:sself];
    }
}

#pragma mark - UIScrollViewDelegate

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    scrollView.contentOffset = CGPointZero;
//}

#pragma mark - load state

- (void)startLoadingView {
    if (!self.indicatorView) {
        UIActivityIndicatorView *indicatorView = [self createIndicatorView];
        self.indicatorView = indicatorView;
        [self addSubview:indicatorView];
    }
    self.indicatorView.hidden = NO;
    [self bringSubviewToFront:self.indicatorView];
    [self.indicatorView startAnimating];
}

- (void)stopLoadingView {
    if (self.indicatorView.isAnimating) {
        [self.indicatorView stopAnimating];
    }
}

- (UIActivityIndicatorView *)createIndicatorView {
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    indicatorView.center = self.webView.center;
    indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    indicatorView.hidesWhenStopped = YES;

    return indicatorView;
}

@end
