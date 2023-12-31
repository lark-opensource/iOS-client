//
//  BDTuringSMSVerifyView.m
//  BDTuring
//
//  Created by bob on 2019/8/28.
//

#import "BDTuringSMSVerifyView.h"
#import "BDTuringVerifyView+UI.h"
#import "BDTuringVerifyView+Delegate.h"

#import "BDTuringPiper.h"
#import "WKWebView+Piper.h"
#import "BDTuringUtility.h"
#import "BDTuringImageTipView.h"
#import "BDTuringUIHelper.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringSettingsKeys.h"

@interface BDTuringSMSVerifyView ()

@property (nonatomic, strong) BDTuringImageTipView *tipView;

@end

@implementation BDTuringSMSVerifyView

- (void)adjustWebViewPosition {
    [super adjustWebViewPosition];
    self.webView.frame = self.bounds;
    if (self.tipView) {
        self.tipView.center = self.webView.center;
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

- (NSDictionary *)customTheme {
    return [[BDTuringUIHelper sharedInstance].smsThemeDictionary copy];
}

- (NSDictionary *)customText {
    return [[BDTuringUIHelper sharedInstance].smsTextDictionary copy];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.webView.frame = self.bounds;
}

@end
