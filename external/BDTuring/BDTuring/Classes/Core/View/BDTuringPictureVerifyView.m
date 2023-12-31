//
//  BDTuringPictureVerifyView.m
//  BDTuring
//
//  Created by bob on 2019/8/28.
//

#import "BDTuringPictureVerifyView.h"
#import "BDTuringVerifyView+UI.h"
#import "BDTuringVerifyView+Delegate.h"
#import "BDTuringVerifyView+Loading.h"
#import "BDTuring+Private.h"

#import "BDTuringPiper.h"
#import "WKWebView+Piper.h"
#import "BDTuringUtility.h"
#import "BDTuringNetworkTipView.h"
#import "BDTuringCoreConstant.h"
#import "UIColor+TuringHex.h"
#import "BDTuringConfig.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringKeyboard.h"
#import "BDTuringUIHelper.h"

@interface BDTuringPictureVerifyView ()<BDTuringKeyboardDelegate>

@property (nonatomic, strong) BDTuringNetworkTipView *tipView;

@end

@implementation BDTuringPictureVerifyView


- (void)adjustWebViewPosition {
    [super adjustWebViewPosition];
    CGFloat keyboardTop = [BDTuringKeyboard sharedKeyboard].keyboardTop;
    [self onKeyboardWillShow:keyboardTop];
}

- (void)showVerifyView {
    [super showVerifyView];
    self.webView.hidden = YES;
    [self startLoadingView];
    [BDTuringKeyboard sharedKeyboard].delegate = self;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [super webView:webView didFailNavigation:navigation withError:error];
    [self addTipViewWithFrame:webView.frame];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [super webView:webView didFailProvisionalNavigation:navigation withError:error];
    [self addTipViewWithFrame:webView.frame];
}

- (void)addTipViewWithFrame:(CGRect)frame {
    if (self.tipView) {
        return;
    }
    NSString *language = self.config.language;
    BDTuringNetworkTipView *tip = [[BDTuringNetworkTipView alloc] initWithFrame:frame
                                                                       language:language
                                                                         target:self];
    [self addSubview:tip];
    self.tipView = tip;
}

- (void)hideVerifyView {
    [super hideVerifyView];
    [BDTuringKeyboard sharedKeyboard].delegate = nil;
}

- (void)onKeyboardWillShow:(CGFloat)keyboardTop {
    CGSize verifySize = self.bounds.size;
    /// adjust frame
    if (verifySize.height > verifySize.width + 1) {
        CGRect webViewFrame = self.webView.frame;
        CGFloat webViewBottom = CGRectGetMaxY(webViewFrame);
        if (webViewBottom >= keyboardTop
            && [BDTuringKeyboard sharedKeyboard].keyboardIsShow) {
            CGFloat dy = keyboardTop - 20 - webViewBottom;
            self.webView.frame = CGRectOffset(webViewFrame, 0, dy);
        }
    }
    
    if (self.tipView) {
        self.tipView.center = self.webView.center;
    }
}

- (void)onKeyboardWillHide:(CGFloat)keyboardTop {
    if (self.adjustViewWhenKeyboardHiden) {
        [self adjustWebViewPosition];
    }
}

- (NSDictionary *)customTheme {
    return [[BDTuringUIHelper sharedInstance].verifyThemeDictionary copy];
}

- (NSDictionary *)customText {
    return [[BDTuringUIHelper sharedInstance].verifyTextDictionary copy];
}


@end
