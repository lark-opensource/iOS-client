//
//  BDTuringVerifyView.m
//  BDTuring
//
//  Created by bob on 2019/8/30.
//

#import "BDTuringVerifyView.h"
#import "BDTuringVerifyView+UI.h"
#import "BDTuringVerifyView+Report.h"
#import "BDTuringVerifyView+Piper.h"
#import "BDTuringVerifyView+Delegate.h"
#import "BDTuringVerifyView+Result.h"

#import "BDTuringVerifyModel+View.h"

#import "BDTuringPiper.h"
#import "WKWebView+Piper.h"
#import "BDTuringPresentView.h"
#import "UIColor+TuringHex.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringVerifyConstant.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringMacro.h"
#import "BDTuringToast.h"
#import "BDTuringUtility.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuring+Private.h"

#import "NSData+BDTuring.h"
#import "BDTuringDeviceHelper.h"
#import "BDTuringUIHelper.h"

#import "BDTuringSMSVerifyView.h"
#import "BDTuringPictureVerifyView.h"
#import "BDTuringQAVerifyView.h"
#import "BDTuringEventService.h"
#import "BDTNetworkManager.h"

#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringVerifyViewDefine.h"
#import "BDTuringEventConstant.h"

@interface BDTuringVerifyView ()

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation BDTuringVerifyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.startLoadTime = turing_duration_ms(0);
        self.delegate = nil;
        self.autoVerify = NO;
        self.isShow = NO;

        
        WKWebViewConfiguration *webViewconfig = [WKWebViewConfiguration new];
        WKUserContentController *userContentController = [WKUserContentController new];
        webViewconfig.userContentController = userContentController;
        WKWebView *webView = [[WKWebView alloc] initWithFrame:frame
                                                configuration:webViewconfig];
        
        if (@available(iOS 10.0, *)) {
            webView.configuration.dataDetectorTypes = WKDataDetectorTypeNone;
        }
        if (@available(iOS 11.0, *)) {
            webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        webView.layer.cornerRadius = 8.;
        webView.layer.masksToBounds = YES;
        webView.scrollView.scrollEnabled = NO;
        webView.navigationDelegate = self;
        webView.center = [self subViewCenter];
        
        [self addSubview:webView];
        self.webView = webView;
        
        [self addGestureForWebView];

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.closeStatus = BDTuringVerifyStatusClose;
        webView.scrollView.delegate = self;
        self.isPreloadVerifyView = NO;
        [self installPiper];
    }

    return self;
}

- (void)addGestureForWebView {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeVerifyViewFromMask)];
    [self addGestureRecognizer:tap];
}


- (CGPoint)subViewCenter {
    CGSize size = self.frame.size;
    return CGPointMake(size.width/2, size.height/2);
}

- (void)dealloc {
    [self cleanDelegates];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)scheduleDismissVerifyView {
    BDTuringWeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BDTuringStrongSelf;
        [self handleCallbackStatus:self.closeStatus];
        [self dismissVerifyView];
        [[BDTuringPresentView defaultPresentView] dismissVerifyView];
    });
}


#pragma mark - public

- (void)showVerifyView {
    [[BDTuringPresentView defaultPresentView] presentVerifyView:self];
    
    self.isShow = YES;
    
    if ([self.delegate respondsToSelector:@selector(verifyViewDidShow:)]) {
        [self.delegate verifyViewDidShow:self];
    }
}

- (void)showVerifyViewTillWebViewReady {
    [[BDTuringPresentView defaultPresentView] presentVerifyView:self];
    
    self.isShow = YES;
    
    if ([self.delegate respondsToSelector:@selector(verifyViewDidShow:)]) {
        [self.delegate verifyViewDidShow:self];
    }
    
}


- (void)hideVerifyView {
    [[BDTuringPresentView defaultPresentView] hideVerifyView:self];
    [self cleanDelegates];
    self.isShow = NO;
    if ([self.delegate respondsToSelector:@selector(verifyViewDidHide:)]) {
        [self.delegate verifyViewDidHide:self];
    }
}

- (void)dismissVerifyView {
    [self removeFromSuperview];
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
    [self cleanDelegates];
    self.isShow = NO;
    self.webView = nil;
}

#pragma mark -  close

- (void)closeVerifyViewFromFeedbackClose {
    [self closeEvent:BDTuringEventCloseFeedBackClose];
    [self closeVerifyView:@"feedback_close"];
}

- (void)closeVerifyViewFromFeedbackButton {
    [self closeEvent:BDTuringEventCloseFeedBackClose];
    NSString *language = self.config.language;
    NSString *message = turing_LocalizedString(@"feed_back_ok", language);
    BDTuringWeakSelf;
    turing_toastShow(self, message, ^{
        BDTuringStrongSelf;
        [self closeVerifyView:@"feedback_close"];
    });
}

- (void)closeVerifyViewFromMask {
    if (![BDTuringUIHelper sharedInstance].shouldCloseFromMask) {
        return;
    }

    if (self.closeStatus == BDTuringVerifyStatusNetworkError) {
        [self closeEvent:BDTuringEventCloseFeedBackMask];
    }

    [self closeVerifyView:@"mask_click_close"];
}

@end
