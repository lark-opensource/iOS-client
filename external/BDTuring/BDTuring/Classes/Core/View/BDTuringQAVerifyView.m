//
//  BDTuringQAVerifyView.m
//  BDTuring
//
//  Created by bob on 2020/2/24.
//

#import "BDTuringQAVerifyView.h"
#import "BDTuringVerifyView+UI.h"
#import "BDTuringVerifyView+Delegate.h"

#import "BDTuringImageTipView.h"
#import <WebKit/WebKit.h>
#import "UIColor+TuringHex.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringKeyboard.h"
#import "BDTuringUIHelper.h"

@interface BDTuringQAVerifyView ()

@property (nonatomic, strong) BDTuringImageTipView *tipView;

@end

@implementation BDTuringQAVerifyView

- (void)adjustWebViewPosition {
    [super adjustWebViewPosition];
    if (self.tipView) {
        self.tipView.center = self.webView.center;
    }
    if (self.pop) {
        CGFloat keyboardTop = [BDTuringKeyboard sharedKeyboard].keyboardTop;
        [self onKeyboardWillShow:keyboardTop];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [super webView:webView didFailNavigation:navigation withError:error];
    [self addTipView];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [super webView:webView didFailProvisionalNavigation:navigation withError:error];
    [self addTipView];
}

- (void)addTipView {
    if (self.tipView) {
        return;
    }
    
    NSString *language = self.config.language;
    CGFloat with = self.frame.size.width;
    BDTuringImageTipView *tipView = [[BDTuringImageTipView alloc] initWithFrame:CGRectMake(0, 0, with, 97)
                                                                       language:language];
    tipView.center = self.webView.center;
    [self addSubview:tipView];
    self.tipView = tipView;
}

- (void)onKeyboardWillShow:(CGFloat)keyboardTop {
    CGSize verifySize = self.bounds.size;
    /// adjust keyboard
    if (verifySize.height > verifySize.width + 1) {
        CGRect webViewFrame = self.webView.frame;
        CGFloat webViewBottom = CGRectGetMaxY(webViewFrame);
        if (webViewBottom >= keyboardTop
            && [BDTuringKeyboard sharedKeyboard].keyboardIsShow) {
            CGFloat dy = keyboardTop - 20 - webViewBottom;
            self.webView.frame = CGRectOffset(webViewFrame, 0, dy);
        }
    }
}

- (void)onKeyboardWillHide:(CGFloat)keyboardTop {
    if (self.adjustViewWhenKeyboardHiden && self.pop) {
        [self adjustWebViewPosition];
    }
}

- (NSDictionary *)customTheme {
    return [[BDTuringUIHelper sharedInstance].qaThemeDictionary copy];
}

- (NSDictionary *)customText {
    return [[BDTuringUIHelper sharedInstance].qaTextDictionary copy];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.webView.frame = self.bounds;
}

@end
