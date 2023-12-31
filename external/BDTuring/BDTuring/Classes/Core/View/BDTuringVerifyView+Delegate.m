//
//  BDTuringVerifyView+Delegate.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView+Delegate.h"
#import "BDTuringVerifyView+Report.h"
#import "BDTuringVerifyView+Loading.h"

#import "BDTuringVerifyViewDefine.h"

@implementation BDTuringVerifyView (Delegate)

- (void)cleanDelegates {
    WKWebView *webView = self.webView;
    webView.scrollView.delegate = nil;
    webView.navigationDelegate = nil;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    scrollView.contentOffset = CGPointZero;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    /// this code borrow from geetek
    [webView evaluateJavaScript:@"document.documentElement.style.webkitUserDrag='none';" completionHandler:nil];
    [webView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';" completionHandler:nil];
    [webView evaluateJavaScript:@"document.documentElement.style.webkitMaskImage='none';" completionHandler:nil];
    [webView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none';" completionHandler:nil];
    [webView evaluateJavaScript:@"document.documentElement.style.webkitTapHighlightColor='transparent';" completionHandler:nil];
    if (@available(iOS 9.0, *)) {
        /// do nothing
    } else {
        [webView evaluateJavaScript:[NSString stringWithFormat:@"document.querySelector('meta[name=\"viewport\"]').setAttribute('content', 'width=%d;', false); ", (int)webView.bounds.size.width] completionHandler:nil];
    }
    [self onWebViewFinish];
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(verifyWebViewLoadDidSuccess:)]) {
        [delegate verifyWebViewLoadDidSuccess:sself];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self webViewFailWithError:error];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self webViewFailWithError:error];
}

- (void)webViewFailWithError:(NSError *)error {
    [self stopLoadingView];
    self.webView.hidden = NO;
    self.closeStatus = BDTuringVerifyStatusNetworkError;
    [self onWebViewFailWithError:error];
    [self cleanDelegates];
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(verifyWebViewLoadDidFail:)]) {
        [delegate verifyWebViewLoadDidFail:sself];
    }
}

@end
