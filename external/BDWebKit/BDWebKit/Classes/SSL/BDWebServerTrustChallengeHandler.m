//
//  BDServerTrustChallengeHandler.m
//  ByteWebView
//
//  Created by Nami on 2019/3/5.
//

#import "BDWebServerTrustChallengeHandler.h"
#import "WKWebView+BDWebServerTrust.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDWebViewDebugKit.h"
#import "BDWebKitSettingsManger.h"

typedef NS_ENUM(NSUInteger, BDWebChallengeState) {
    BDWebChallengeStateUnspecified = 0,
    BDWebChallengeStateUserProcessing,
    BDWebChallengeStatePass,
    BDWebChallengeStateFail,
};

typedef void (^ChallenggeCompletion)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable);
typedef void (^TTNetCompletion)(BOOL trustSSL);

@interface BDWebServerTrustChallengeModel : NSObject

@property (nonatomic, strong) NSURLAuthenticationChallenge *challenge;
@property (nonatomic, copy) ChallenggeCompletion challengeCompletion;
@property (nonatomic, copy) TTNetCompletion ttnetCompletion;

@end

@implementation BDWebServerTrustChallengeModel

@end

@interface BDWebServerTrustChallengeHandler ()

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) NSURL *currentURL;
@property (nonatomic, assign) BDWebChallengeState challengeState;
@property (nonatomic, strong) NSMutableArray<BDWebServerTrustChallengeModel *> *challenges;

@end

@implementation BDWebServerTrustChallengeHandler

- (void)dealloc {
    for (BDWebServerTrustChallengeModel *model in _challenges) {
        model.challengeCompletion ? model.challengeCompletion(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil) : NULL;
        model.ttnetCompletion ? model.ttnetCompletion(NO) : NULL;
    }
    [_challenges removeAllObjects];
}

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super init];
    if (self) {
        self.webView = webView;
    }
    return self;
}

#pragma mark - webview deleggate
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    [self webView:self.webView challenge:challenge challengecCompletion:completionHandler ttnetErrorURL:nil ttnetCompletion:nil needForceMainThread:!self.webView.bdw_enableServerTrustAsync];
}

#pragma mark - TTNet
- (BOOL)shouldSkipSSLCertificateError {
    if (self.webView.bdw_skipAndPassAllServerTrust || [self.webView.URL.absoluteString hasPrefix:@"file://"] || self.webView.URL.absoluteString.length == 0) {
        return YES;
    }
    
    if (![self.currentURL.host isEqualToString:self.webView.URL.host]) {
        return NO;
    }
    
    switch (self.challengeState) {
        case BDWebChallengeStateUnspecified:
        case BDWebChallengeStateUserProcessing:
        case BDWebChallengeStateFail:
            return NO;
        case BDWebChallengeStatePass:
            return YES;
    }
    
    return NO;
}

- (void)handleSSLError:(NSURL *)errorURL WithComplete:(void (^)(BOOL trustSSL))complete {
    if (!complete) {
        return;
    }
    
    BDWDebugLog(@"webView(%p) certificate risk received，URL : %@", self.webView, self.webView.URL.absoluteString);
    [self webView:self.webView challenge:nil challengecCompletion:nil ttnetErrorURL:errorURL ttnetCompletion:complete needForceMainThread:!self.webView.bdw_enableServerTrustAsync];
}

- (void)webView:(WKWebView *)webView
                challenge:(NSURLAuthenticationChallenge *)challenge
     challengecCompletion:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))challengeCompletion
            ttnetErrorURL:(NSURL *)errorURL
          ttnetCompletion:(void (^)(BOOL trustSSL))ttnetCompletion
      needForceMainThread:(BOOL)needForceMainThread {
    BDWDebugLog(@"webView(%p) certificate risk received，URL : %@", self.webView, webView.URL.absoluteString);
    
    NSURL *url = webView.URL;
    if ([BDWebKitSettingsManger bdFixWKRecoveryAttempterCrash]) {
        BDWDebugLog(@"webView(%p) certificate risk received，URL : %@", self.webView, webView.URL.absoluteString);
        if (!webView.URL || webView.URL.absoluteString.length <=0) {
            BDWebKitSSL_InfoLog(@"URL is empty，trust by default.");
            
            ttnetCompletion ? ttnetCompletion(YES) : NULL;
            
            if (challenge && challengeCompletion) {
                if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                    if (challenge.previousFailureCount == 0) {
                        NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
                        challengeCompletion(NSURLSessionAuthChallengeUseCredential, card);
                    } else {
                        challengeCompletion(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
                    }
                } else {
                    challengeCompletion(NSURLSessionAuthChallengePerformDefaultHandling, nil);
                }
            }
            return;
        }
        
        url = [[NSURL alloc] initWithString:webView.URL.absoluteString];
    }
    
    @weakify(self);
    [self dispatchHandler:^{
        @strongify(self);
        [self webView:webView challenge:challenge challengecCompletion:challengeCompletion ttnetErrorURL:errorURL ttnetCompletion:ttnetCompletion url:url];
    } needForceMainThread:needForceMainThread];
}

- (void)dispatchHandler:(void(^)(void))handler needForceMainThread:(BOOL)needForceMainThread {
    if (needForceMainThread) {
        if ([NSThread isMainThread]) {
            handler();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler();
            });
        }
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            handler();
        });
    }
}

#pragma mark - private
- (void)webView:(WKWebView *)webView
           challenge:(NSURLAuthenticationChallenge *)challenge
challengecCompletion:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))challengeCompletion
       ttnetErrorURL:(NSURL *)errorURL
     ttnetCompletion:(void (^)(BOOL trustSSL))ttnetCompletion
                 url:(NSURL *)url
{
    if (!challengeCompletion && !ttnetCompletion) {
        return;
    }
    
    if (webView.bdw_skipAndPassAllServerTrust ||
        [url.absoluteString hasPrefix:@"file://"] ||
        url.absoluteString.length == 0) {
        BDWDebugLog(@"webView(%p) trust certificate by default", self.webView);
        BDWebKitSSL_InfoLog(@"trust certificate by default");
        
        ttnetCompletion ? ttnetCompletion(YES) : NULL;
        
        if (challenge && challengeCompletion) {
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                if (challenge.previousFailureCount == 0) {
                    NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
                    challengeCompletion(NSURLSessionAuthChallengeUseCredential, card);
                } else {
                    challengeCompletion(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
                }
            } else {
                challengeCompletion(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            }
        }
        return;
    }

    BOOL isPageHostChanged = NO;
    if (![self.currentURL.host isEqualToString:url.host]) {
        [self setPageChallengeIsPass:NO withHost:self.currentURL.host];
        self.challengeState = BDWebChallengeStateUnspecified;
        if (self.currentURL != nil) {
            isPageHostChanged = YES;
        }
    }
    self.currentURL = url;

    if (challenge && challengeCompletion) {
        if (![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            // 对于其他验证方法直接进行处理流程
            BDWebKitSSL_InfoLog(@"other process");
            challengeCompletion(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            return;
        }

        if (challenge.previousFailureCount != 0) {
            // 失败多次，取消授权
            BDWebKitSSL_InfoLog(@"Failed many times, cancel authorization");
            challengeCompletion(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
        
        // 证书是否可信。
        SecTrustResultType trustResult = kSecTrustResultInvalid;
        OSStatus status = SecTrustEvaluate(challenge.protectionSpace.serverTrust, &trustResult);
        BOOL allowConnection = NO;
        if (status == noErr) {
            allowConnection = (trustResult == kSecTrustResultProceed || trustResult == kSecTrustResultUnspecified);
        }
        if (allowConnection) {
            // 证书可信
            BDWebKitSSL_InfoLog(@"Trusted ertificate");
            challengeCompletion(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            return;
        }
    }

    // if there is no change for webview.host, check host from challenge
    if (!isPageHostChanged) {
        NSString *hostForChallenge = nil;
        if (challenge && challenge.protectionSpace && challenge.protectionSpace.host) {
            hostForChallenge = challenge.protectionSpace.host;
        } else if (errorURL && errorURL.host) {
            hostForChallenge = errorURL.host;
        }
        if (hostForChallenge && [hostForChallenge isKindOfClass:[NSString class]] && hostForChallenge.length > 0) {
            // 如果页面Host没有改变,同时证书校验失败的Host与页面不相同,认定此请求是子资源请求,不应该弹窗阻碍用户浏览
            if (![hostForChallenge isEqualToString:url.host]) {
                self.challengeState = BDWebChallengeStatePass;
            }
        }
    }

    switch (self.challengeState) {
        case BDWebChallengeStateUnspecified: {
            BDWDebugLog(@"webView(%p) Certificate not trusted   confirm", self.webView);
            BDWebKitSSL_InfoLog(@"Certificate not trusted   confirm");
            BDWebServerTrustChallengeModel *model = [BDWebServerTrustChallengeModel new];
            model.challenge = challenge;
            model.challengeCompletion = challengeCompletion;
            model.ttnetCompletion = ttnetCompletion;
            [self.challenges addObject:model];
            @weakify(self);
            [self dispatchHandler:^{
                @strongify(self);
                [self _tryShowWarningAlertController];
            } needForceMainThread:YES];
            
            break;
        }
        case BDWebChallengeStateUserProcessing: {
            BDWebServerTrustChallengeModel *model = [BDWebServerTrustChallengeModel new];
            model.challenge = challenge;
            model.challengeCompletion = challengeCompletion;
            model.ttnetCompletion = ttnetCompletion;
            [self.challenges addObject:model];
            break;
        }
        case BDWebChallengeStatePass:
            BDWDebugLog(@"webView(%p) Certificate not trusted   passed", self.webView);
            BDWebKitSSL_InfoLog(@"Certificate not trusted   passed");
            if (challenge && challengeCompletion) {
                challengeCompletion(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            }
            ttnetCompletion ? ttnetCompletion(YES) : NULL;
            break;
        case BDWebChallengeStateFail:
            BDWDebugLog(@"webView(%p) Certificate not trusted   failed", self.webView);
            BDWebKitSSL_InfoLog(@"Certificate not trusted   failed");
            challengeCompletion ? challengeCompletion(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil) : NULL;
            ttnetCompletion ? ttnetCompletion(NO) : NULL;
            break;
    }
}

/**
 此方法放在子模块的类中，用于定位SDK中的语言文件
 @return bundle
 */
- (NSBundle *)myBDWebKitBundle {
    NSString *bundleName = @"BDWebKit";
    static dispatch_once_t onceToken;
    static NSBundle *bundle = nil;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:bundleName ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath: path];
    });
    return bundle;
}

/**
 @param key 多语言关键词
 @return multiLangText 从key获取到的文本
 */
- (NSString *) getMultiLangText:(NSString *)key {
    return NSLocalizedStringFromTableInBundle(key, @"BDWebKit", [self myBDWebKitBundle], nil);
}

- (void)_showWarningAlertController:(NSString *)host {
    BDWDebugLog(@"webView(%p) Certificate not trusted   Popup", self.webView);
    BDWebKitSSL_InfoLog(@"Certificate not trusted   Popup");
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:[self getMultiLangText:@"hint"] message:[self getMultiLangText:@"certificate_not_trusted"] preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self)weakSelf = self;
    [ac addAction:[UIAlertAction actionWithTitle:[self getMultiLangText:@"continue_to_visit"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf setPageChallengeIsPass:YES withHost:host];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:[self getMultiLangText:@"cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf setPageChallengeIsPass:NO withHost:host];
    }]];
    if (self.webView) {
        [[BTDResponder topViewControllerForView:self.webView] presentViewController:ac animated:YES completion:nil];
    }
}

- (void)_tryShowWarningAlertController {
    self.challengeState = BDWebChallengeStateUserProcessing;

    NSString *host = self.currentURL.host;
    if (self.webView.bdw_serverTrustDelegate && [self.webView.bdw_serverTrustDelegate respondsToSelector:@selector(webView:decideServerTrustWithHost:completion:)]) {
        [self.webView.bdw_serverTrustDelegate webView:self.webView decideServerTrustWithHost:host completion:^(BDWebServerUntrustOperation operation) {
            BDWebKitSSL_InfoLog(@"Proxy callback %@", @(operation));
            if (operation == BDWebServerUntrustPass) {
                [self setPageChallengeIsPass:YES withHost:host];
            }
            else if (operation == BDWebServerUntrustReject) {
                [self setPageChallengeIsPass:NO withHost:host];
            }
            else {
                [self _showWarningAlertController:host];
            }
        }];
    } else {
        BDWebKitSSL_InfoLog(@"Default popup");
        [self _showWarningAlertController:host];
    }
}

- (void)setPageChallengeIsPass:(BOOL)isPass withHost:(NSString *)host {
    if (![self.currentURL.host isEqualToString:host]) {
        return;
    }

    self.challengeState = isPass ? BDWebChallengeStatePass : BDWebChallengeStateFail;
    [self.challenges enumerateObjectsUsingBlock:^(BDWebServerTrustChallengeModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (model.challengeCompletion) {
            if (isPass) {
                model.challengeCompletion(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:model.challenge.protectionSpace.serverTrust]);
            } else {
                model.challengeCompletion(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
        }
        model.ttnetCompletion ? model.ttnetCompletion(isPass) : NULL;
    }];
    [self.challenges removeAllObjects];
}

- (NSMutableArray<BDWebServerTrustChallengeModel *> *)challenges {
    if (!_challenges) {
        _challenges = [NSMutableArray array];
    }
    return _challenges;
}

@end
