//
//  BDTuringTVViewController.m
//  BDTuring-BDTuringResource
//
//  Created by yanming.sysu on 2020/10/29.
//

#import "BDTuringTVViewController.h"
#import "BDTuringTVHelper.h"
#import "BDTuringTVDefine.h"
#import "BDTuringTVTracker.h"
#import "BDTuringTVViewController+Piper.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuring.h"
#import "BDTuring+Private.h"
#import "BDTuringTVViewController+Utility.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringKeyboard.h"
#import "BDTuringUtility.h"
#import <WebKit/WebKit.h>
#import "WKWebView+Piper.h"
#import "BDTuringPiper.h"
#import "BDTuringConfig.h"

@interface BDTuringTVViewController ()

@end

@implementation BDTuringTVViewController


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithParams:(NSDictionary *)params {
    if (self = [super init]) {
        self.params = params;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self setupNotification];
    [self showLoading];
}

- (void)viewDidAppear:(BOOL)animated{
    if ([BDTuringKeyboard sharedKeyboard].keyboardIsShow) {
        [UIView animateWithDuration:0.35 animations:^{
            CGRect oriFrame = self.oriFrame;
            oriFrame.origin.y = [BDTuringKeyboard sharedKeyboard].keyboardTop - self.webViewHeight;
            if ([BDTuringTVHelper isIphoneX]) {
                oriFrame.origin.y = oriFrame.origin.y + [BDTuringTVHelper iphoneXBottomHeight];
            }
            self.webView.frame = oriFrame;
        }];
    }
}

- (void)setupViews {
    self.view.backgroundColor = [UIColor clearColor];
    [self setupBackGroundView];
    [self setupWebViewHeight];
    [self setupWebView];
    if ([BDTuringTVHelper isIphoneX]) {
        [self setupXBottomView];
    }
}

- (void)setupXBottomView {
    //    if ([BDTuringTVHelper isIphoneX]) {
    //        self.webViewHeight += [BDTuringTVHelper iphoneXBottomHeight];
    //    }
    CGSize size = [UIScreen.mainScreen bounds].size;
    UIView *bottomView = [[UIView alloc] init];
    bottomView.backgroundColor = [UIColor whiteColor];
    CGFloat bottomHeight = [BDTuringTVHelper iphoneXBottomHeight];
    bottomView.frame = CGRectMake(0, size.height-bottomHeight, self.webViewWidth, bottomHeight);
    [self.view addSubview:bottomView];
}

- (void)setupWebViewHeight {
    // 高度 发送短信验证：375 x 304，输入验证码：375 x 290，输入帐号密码：375 x 271
    NSString *config = self.params[kBDTuringTVDecisionConfig];
    CGSize size = [UIScreen.mainScreen bounds].size;
    self.webViewHeight = 290;
    if ([config isEqualToString:kBDTuringTVBlockSms]) {
        self.webViewHeight = size.width * 290/375.00;
        self.blockType = kBDTuringTVBlockTypeSms;
    } else if ([config isEqualToString:kBDTuringTVBlockUpsms]) {
        self.webViewHeight = size.width * 304/375.00;
        self.blockType = kBDTuringTVBlockTypeUpsms;
    } else if ([config isEqualToString:kBDTuringTVBlockPassword]) {
        self.webViewHeight = size.width * 271/375.00;
        self.blockType = kBDTuringTVBlockTypePassword;
    }
    self.webViewWidth = size.width;
}

- (void)setupBackGroundView {
    UIView *backView = [[UIView alloc] init];
    backView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    backView.frame = self.view.bounds;
    [self.view addSubview:backView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureResponse:)];
    [backView addGestureRecognizer:tap];
}

- (void)tapGestureResponse:(UITapGestureRecognizer *)tap {
    [self dismissSelfControllerWithParams:nil error:[self createErrorWithErrorCode:kBDTuringTVErrorCodeTypeCancel errorMsg:@"user auto cancel"]];
}

- (void)setupWebView {
    NSURL *url = [self setupRequestURL];
    [self setupWebViewWithURL:url];
}

- (NSURL *)setupRequestURL {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.params];
    [params addEntriesFromDictionary:[self.config twiceVerifyRequestQueryParameters]];
    [params setValue:@"1" forKey:@"is_turing"];
    [params setValue:@"1" forKey:@"use_turing_bridge"];
    self.params = params;
    NSString *requestURL = turing_requestURLWithQuery(self.url, params);
    
    return [NSURL URLWithString:requestURL];;
}


- (void)setupWebViewWithURL:(NSURL *)url {
    CGSize size = [UIScreen.mainScreen bounds].size;
    
    static WKProcessPool *pool;
    pool = [[WKProcessPool alloc] init];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.processPool = pool;
    CGRect webviewFrame = CGRectMake(0, size.height - self.webViewHeight - [BDTuringTVHelper iphoneXBottomHeight], size.width, self.webViewHeight);
    self.oriFrame = webviewFrame;
    WKWebView *webview = [[WKWebView alloc] initWithFrame:webviewFrame configuration:config];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [webview loadRequest:request];
    [webview.scrollView setScrollEnabled:false];
    webview.scrollView.bounces = NO;
    webview.scrollView.panGestureRecognizer.enabled=NO;
    webview.navigationDelegate = self;
    
    [self.view addSubview:webview];
    self.webView = webview;
    
    // 设置圆角
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:webview.bounds byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = webview.bounds;
    maskLayer.path = maskPath.CGPath;
    webview.layer.mask = maskLayer;

    // jsb
    [webview turing_installPiper];
    [self registerClose];
    [self registerFetch];
    [self registerToast];
    [self registerShowLoading];
    [self registerDismissLoading];
    [self registerIsSmsAvailable];
    [self registerOpenSms];
    [self registerCopy];
    [self registerAppInfo];
}

- (void)setupNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect oriFrame = self.oriFrame;
    oriFrame.origin.y = oriFrame.origin.y - keyboardFrame.size.height;
    if ([BDTuringTVHelper isIphoneX]) {
        oriFrame.origin.y = oriFrame.origin.y + [BDTuringTVHelper iphoneXBottomHeight];
    }
    self.webView.frame = oriFrame;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    self.webView.frame = self.oriFrame;
}

#pragma mark - webview delegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // 加载成功
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self dismissLoading];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self dismissLoading];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [self dismissLoading];
}


#pragma mark place holder

- (void)presentMessageComposeViewControllerWithPhone:(NSString *)phone content:(NSString *)content {
    BDTuringPiperOnCallback cacheCallback = self.cacheCallback;
    if (cacheCallback) {
        cacheCallback(BDTuringPiperMsgFailed, nil);
        self.cacheCallback = nil;
    }
}


+ (BOOL)canSendText {
    return  NO;
}

@end
