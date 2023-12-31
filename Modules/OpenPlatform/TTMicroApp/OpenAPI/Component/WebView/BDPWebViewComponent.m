//
//  Created by 王浩宇 on 2018/11/18.
//

#import "BDPAppPage.h"
#import "BDPAppPageController.h"
#import <OPFoundation/BDPApplicationManager.h>
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPNavigationController.h"
#import <OPFoundation/BDPRouteMediator.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPWeakProxy.h>
#import "BDPWebViewComponent.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/BDPLogHelper.h>
#import <OPFoundation/TMACustomHelper.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <Masonry/Masonry.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <OPFoundation/EEFeatureGating.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <UniverseDesignTheme/UniverseDesignTheme-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <LarkStorage/LarkStorage-Swift.h>
#import "BDPWebAPILog.h"

#define WebKitErrorPlugInWillHandleLoad 204
#define WebKitErrorCancelRequest 102

static NSString *const k_ALL_URL_ALLOW_TO_LOAD_STR = @"*:*";

@interface BDPWebViewComponent () <BDPWebViewInjectProtocol, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, MetaLoadStatusDelegate>
/// 键盘弹起屏幕偏移量
@property (nonatomic, assign) CGPoint keyBoardPoint;
/// 当前加载的URL
@property (nonatomic, strong) NSURL *bwc_currentURL;
/// 进度条
@property (nonatomic, strong) UIProgressView *bwc_progressView;

/// 临时存储请求内容
@property (nonatomic, strong) WKNavigationAction *navigationAction;
@property (nonatomic, copy) void (^decisionHandler)(WKNavigationActionPolicy);
@property (nonatomic, strong) UDToastForOC *loadingView;

@end

@implementation BDPWebViewComponent

#pragma mark - Initilize
/*-----------------------------------------------*/
//              Initilize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithFrame:(CGRect)frame
                       config:(WKWebViewConfiguration *)config
                  componentID:(NSInteger)componentID
                     uniqueID:(BDPUniqueID *)uniqueID
       progressBarColorString:(NSString *)progressBarColorString
                     delegate:(id<BDPWebViewInjectProtocol>)delegate {
    self = [super initWithFrame:frame config:config delegate:delegate bizType:[[LarkWebViewBizType alloc] init:@"gadget-web-view"] advancedMonitorInfoEnable:YES];
    if (self) {
        [self setupWebViewWithUniqueID:uniqueID];

        // 小程序如果不适配DM,则直接设置成LM
        if (!uniqueID.isAppSupportDarkMode) {
            if (@available(iOS 13.0, *)) {
                BDPWebAPILogInfo(@"%@ not support dark mode, webview component set light mode", uniqueID);
                self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
            }
        }
        self.UIDelegate = self;
        self.navigationDelegate = self;
        self.componentID = componentID;
        self.isFireEventReady = YES;
        self.allowsBackForwardNavigationGestures = YES; // 支持手势返回/前进

        [self bwc_setupInjection];
        [self bwc_setupUserAgentFromConfig:config uniqueID:uniqueID];
        [self bwc_setupObserver];
        [self bwc_setupProgressViewWithProgressBarColorString:progressBarColorString];
        [self bwc_setupMetaLoad];
        //webview组件的域名黑名单 web销毁清除同步的cookie
        [BDPRouteMediator onWebviewCreate:self.uniqueID webview:(BDPWebViewComponent *)self];
        BDPWebAPILogInfo(@"BDPWebViewComponent init");
    }
    return self;
}

- (void)dealloc {
    BDPWebAPILogInfo(@"BDPWebViewComponent dealloc, for uniqueID: %@, self: %@", self.uniqueID, self);
    //原封不动，未修改任何逻辑
    [self removeObserver:self forKeyPath:@"estimatedProgress"];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(canGoBack))];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(title))];
    [self bwc_removeInjection];
    [BDPRouteMediator onWebviewDestroy:self.uniqueID webview:(BDPWebViewComponent *)self];
    [self bwc_removeMetaLoad];
}

/// 键盘将要弹起 
- (void)bwc_keyBoardShow:(id)sender {
    CGPoint point = self.scrollView.contentOffset;
    self.keyBoardPoint = point;
}

/// 键盘将要隐藏
- (void)bwc_keyBoardHidden:(id)sender {
    self.scrollView.contentOffset = self.keyBoardPoint;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [super userContentController:userContentController didReceiveScriptMessage:message];
    if ([self.bwc_currentURL.scheme length] > 0 && [self.bwc_currentURL.scheme isEqualToString:@"file"]) {
        // 非本地包里的页面不能使用刷新等相应功能
        if ([message.name isEqualToString:@"reload"]) {
            [self reload];
        } else if ([message.name isEqualToString:@"openInOuterBrowser"]) {
            [self bwc_openInOuterBrowser];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self] && [keyPath isEqualToString:@"estimatedProgress"]) { // 进度条
        CGFloat newprogress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];

        if (newprogress == 1) { // 加载完成
            // 首先加载到头
            [self.bwc_progressView setProgress:newprogress animated:YES];
            // 之后0.3秒延迟隐藏
            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                weakSelf.bwc_progressView.hidden = YES;
                [weakSelf.bwc_progressView setProgress:0 animated:NO];
            });
        } else { // 加载中
            self.bwc_progressView.hidden = NO;
            [self.bwc_progressView setProgress:newprogress animated:YES];
        }
    } else if ([object isEqual:self] && [keyPath isEqualToString:NSStringFromSelector(@selector(canGoBack))]) {
        BOOL canGoBack = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (self.bwc_canGoBackChangedBlock) {
            self.bwc_canGoBackChangedBlock(canGoBack);
        }
    } else if ([object isEqual:self] && [keyPath isEqualToString:NSStringFromSelector(@selector(title))]) {
        NSString *title = change[NSKeyValueChangeNewKey];
        if (![title isKindOfClass:[NSString class]]) {
            return;
        }
        //如果是错误页，默认展示document.title，不展示page.json或者js设置的
        if ([self.URL.absoluteString containsString:[[self class] bwc_errorPageURL]] || [self.URL.absoluteString containsString:[BDPSDKConfig sharedConfig].unsupportedContextURL]) {
            return;
        }
        [self bwc_setNavigationTitle:title];
    } else { // 其他
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark WKNavigationDelegate
/*-----------------------------------------------*/
//     WKNavigationDelegate - WKWebView协议
/*-----------------------------------------------*/
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    BDPWebAPILogInfo(@"web-view deciding Policy For Navigation Action! url=%@", [BDPLogHelper safeURL:navigationAction.request.URL]);
    if (webView == self) {
        // 走过异常处理环节
        BOOL didProcessedException = NO;
        // 这里做个容错处理，防止二跳的页面不在白名单导致永远打不开页面且不能返回的问题。
        if (navigationAction.navigationType == WKNavigationTypeBackForward
            && self.bwc_currentURL
            && ![[self class] bwc_checkURLCanUse:self.bwc_currentURL]) {
            // 返回上一个成功加载的页面
            if (self.bwc_openInOuterBrowserURL && [self.bwc_openInOuterBrowserURL.absoluteString length] > 0 && [webView.backForwardList.backList count] > 0) {
                for (NSInteger i = [webView.backForwardList.backList count] - 1; i >= 0; --i) {
                    WKBackForwardListItem *item = webView.backForwardList.backList[i];
                    if (item.URL.absoluteString && [item.URL.absoluteString isEqualToString:self.bwc_openInOuterBrowserURL.absoluteString]) {
                        decisionHandler(WKNavigationActionPolicyCancel);
                        didProcessedException = YES;
                        [webView goToBackForwardListItem:item];
                        break;
                    }
                }
            }
        }

        // 安全域名拦截 - 优先级 > 宿主处理
        if (![self bwc_shouldCheckIDEDisableDomain] && [self bwc_shouldCheckSafeDomain]) {
            NSURL *URL = navigationAction.request.URL;
            if (URL) {
                BDPMonitorEvent *monitor = BDPMonitorWithCode(EPMClientOpenPlatformGadgetWebviewComponentCode.intercept_unsafe_url, self.uniqueID);
                monitor.addCategoryValue(@"host", URL.host);
                if ([self bwc_checkURLIsExcepted:URL]) {
                    // URL 在安全范围内
                    BDPWebAPILogInfo(@"url is SAFE to load! url=%@", [BDPLogHelper safeURL:URL]);
                    monitor.addCategoryValue(@"is_intercepted", @0).flush();
                } else {
                    if ([self bwc_enableSafeDomainDoubleCheck] && !BDPIsEmptyString(self.uniqueID.fullString) &&
                        [[MetaLoadStatusManager.shared fetchStatusFor:self.uniqueID.fullString] isEqualToString:@"started"]) {
                        // meta包获取中，等待meta请求返回,3s超时 https://bytedance.feishu.cn/docx/doxcni1Gzc0UkXeoK8MiUIbOR6c
                        BDPWebAPILogInfo(@"url is UNSAFE! waiting for meta request, url=%@", [BDPLogHelper safeURL:URL]);
                        self.navigationAction = navigationAction;
                        self.decisionHandler = decisionHandler;
                        if (!self.loadingView) {
                            self.loadingView = [UDToastForOC showLoadingWith:BDPI18n.OpenPlatform_AppActions_LoadingDesc on:self.uniqueID.window];
                        }
                        WeakSelf;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            StrongSelfIfNilReturn;
                            BDPWebAPILogError(@"wait for meta timeout");
                            [self bwc_waitForMetaFail:YES];
                        });
                        return;
                    }

                    // URL 不在安全范围内，加载拦截页面
                    BDPWebAPILogInfo(@"url is UNSAFE! url=%@", [BDPLogHelper safeURL:URL]);
                    monitor.addCategoryValue(@"is_intercepted", @1).flush();
                    decisionHandler(WKNavigationActionPolicyCancel);
                    [self bwc_loadUnsafeUrlPageWithUnsafeUrl:URL.absoluteString];
                    return;
                }
            }
        }

        // 正常加载逻辑
        if (!didProcessedException) {
            BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
            BDPAuthorization *auth = common.auth;
            NSURL *URL = navigationAction.request.URL;
            NSURL *currentURL = URL;

            // 支持宿主处理
            BDPPlugin(routerPlugin, BDPRouterPluginDelegate);
            if ([routerPlugin respondsToSelector:@selector(bdp_interceptWebViewRequest:uniqueID:fromView:)]
                && [routerPlugin bdp_interceptWebViewRequest:URL uniqueID:self.uniqueID fromView:self]) {
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }

            BDPWebViewURLCheckResultType checkResult;
            if (URL.absoluteString && [[URL.absoluteString stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@"about:blank"]) {
                // about:blank强制放过
                checkResult = BDPWebViewValidURL;
                currentURL = self.bwc_currentURL;
            } else {
                checkResult = [[self class] bwc_checkURL:URL withAuth:auth uniqueID:self.uniqueID];
                URL = [[self class] bwc_redirectedURL:URL withCheckResult:checkResult];
            }

            switch (checkResult) {
                case BDPWebViewValidURL: {
                    self.bwc_currentURL = currentURL;
                    NSLog(@"BDPWebViewValidURL allow: %@", currentURL);
                    decisionHandler(WKNavigationActionPolicyAllow);
                    break;
                }
                case BDPWebViewValidSchema: {
                    NSLog(@"BDPWebViewValidURL allow: %@", URL);
                    [[UIApplication sharedApplication] openURL:URL];
                    decisionHandler(WKNavigationActionPolicyCancel);
                    break;
                }
                case BDPWebViewUnsupportSchema: {
                    NSLog(@"BDPWebViewUnsupportSchema cancel: %@", URL);
                    decisionHandler(WKNavigationActionPolicyCancel);
                    break;
                }
                case BDPWebViewInvalidSchema:
                case BDPWebViewInvalidDomain: {
                    NSLog(@"BDPWebViewUnsupportSchema invalid domain | scheme: %@", URL);
                    decisionHandler(WKNavigationActionPolicyCancel);
                    [self loadRequest:[NSURLRequest requestWithURL:URL]];
                    break;
                }
                default: {
                    decisionHandler(WKNavigationActionPolicyCancel);
                    break;
                }
            }
        }
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    BDPWebAPILogInfo(@"web-view did load url! url=%@", [BDPLogHelper safeURL:webView.URL]);
    // 更新分享和打开的url
    if ([[self class] bwc_checkURLCanUse:webView.URL]) {
        self.bwc_openInOuterBrowserURL = webView.URL;
    }

    // 更新UI
    NSString *script = [NSString stringWithFormat:@"window.__ttjsenv__ = '%@'", BDPStringUglify_microapp];
    [self evaluateJavaScript:script completionHandler:nil];
    /// 进行bindload的回调
    [self bwc_fireEvent:@"onWebviewFinishLoad" webview:webView componentID:self.componentID];

    NSString *webpHookScript = [NSString lss_stringWithContentsOfFile:[[BDPGetResolvedModule(BDPStorageModuleProtocol, self.appType) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLibWebpHook] encoding:NSUTF8StringEncoding error:nil];
    [self evaluateJavaScript:webpHookScript completionHandler:^(id object, NSError *error) {
        if (error) {
            BDPWebAPILogError(@"web hook failed, url=%@, error=%@", [BDPLogHelper safeURLString:webView.URL.absoluteString], error);
        }
    }];

    //如果是错误页，默认展示document.title，不展示page.json或者js设置的
    if ([self.URL.absoluteString containsString:[[self class] bwc_errorPageURL]] || [self.URL.absoluteString containsString:[BDPSDKConfig sharedConfig].unsupportedContextURL]) {
        [self bwc_setFinishNavigationTitle];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    BDPWebAPILogError(@"web-view load url FAILURE! url=%@", [BDPLogHelper safeURL:webView.URL]);
    if (error.code == NSURLErrorCancelled) {
        BDPWebAPILogInfo(@"fail navigation because of NSURLErrorCancelled");
        return;
    }
    if (error.code == WebKitErrorPlugInWillHandleLoad) {
        // code from WebFrameLoaderClient.mm
        // FIXME: WebKitErrorPlugInWillHandleLoad is a workaround for the cancel we do to prevent
        // loading plugin content twice.  See <rdar://problem/4258008>
        BDPWebAPILogInfo(@"fail navigation because of WebKitErrorPlugInWillHandleLoad");
        return;
    }
    // feat: [LKRQ-1713]添加web-view组件bindload属性
    [self bwc_fireEvent:@"onWebviewError" webview:webView componentID:self.componentID];
    [self bwc_fireEvent:@"onWebviewFinishLoad" webview:webView componentID:self.componentID];
    [self bwc_loadFailedPage];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    BDPWebAPILogInfo(@"web-view start loading! url=%@", [BDPLogHelper safeURL:webView.URL]);
    NSString *script = [NSString stringWithFormat:@"window.__ttjsenv__ = '%@'", BDPStringUglify_microapp];
    [self evaluateJavaScript:script completionHandler:nil];
    // feat: [LKRQ-1713]添加web-view组件bindload属性
    [self bwc_fireEvent:@"onWebviewStartLoad" webview:webView componentID:self.componentID];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    BDPWebAPILogError(@"web-view failed to load! url=%@", [BDPLogHelper safeURL:webView.URL]);
    // Ignore NSURLErrorDomain error -999.
    if (error.code == NSURLErrorCancelled) {
        BDPWebAPILogInfo(@"web-view failed due to NSURLErrorCancelled");
        return;
    }
    // Ignore "Fame Load Interrupted" errors. Seen after app store links.
    if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWebComponentIgnoreInterrupted] &&
        [error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == WebKitErrorCancelRequest) {
        BDPWebAPILogInfo(@"web-view failed due to WebKitErrorCancelRequest");
        return;
    }
    // feat: [LKRQ-1713]添加web-view组件bindload属性
    [self bwc_fireEvent:@"onWebviewError" webview:webView componentID:self.componentID];
    [self bwc_fireEvent:@"onWebviewFinishLoad" webview:webView componentID:self.componentID];
    [self bwc_loadFailedPage];
}

- (WKNavigation *)reload {
    WKNavigation *wkNavi = [super reload];
    [self loadRequest:[NSURLRequest requestWithURL:self.bwc_openInOuterBrowserURL]];
    return wkNavi;
}

#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }

    return nil;
}

#pragma mark - appType
- (OPAppType)appType {
    return self.uniqueID ? self.uniqueID.appType : OPAppTypeGadget;
}

//原封不动的换了个问题，未做任何逻辑修改
#pragma mark - WebView Inject
/*-----------------------------------------------*/
//         WebView Inject - WebView注入
/*-----------------------------------------------*/
- (void)bwc_setupInjection {
    id<WKScriptMessageHandler> weakSelf = (id<WKScriptMessageHandler>)[BDPWeakProxy weakProxy:self];
    for (NSString *name in [[self class] bwc_scriptNames]) {
        [self.configuration.userContentController addScriptMessageHandler:weakSelf name:name];
    }
}

- (void)bwc_removeInjection {
    for (NSString *name in [[self class] bwc_scriptNames]) {
        [self.configuration.userContentController removeScriptMessageHandlerForName:name];
    }
}

+ (NSArray *)bwc_scriptNames {
    return @[@"reload", @"openInOuterBrowser"];
}

+ (NSURL *)bwc_redirectedURL:(NSURL *)orignURL withCheckResult:(BDPWebViewURLCheckResultType)type {
    if (!orignURL) return nil;

    switch (type) {
        case BDPWebViewValidURL:
        case BDPWebViewValidSchema: {
            return orignURL;
            break;
        }
        default: {
            NSString *urlString = [NSString stringWithFormat:@"%@?url=%@&language=%@", BDPSDKConfig.sharedConfig.unsupportedUnconfigDomainURL, orignURL.absoluteString, [BDPApplicationManager language]];
            urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            return [NSURL URLWithString:urlString];
            break;
        }
    }
}

+ (NSString *)bwc_errorPagePath {
    return [[BDPBundle mainBundle] pathForResource:@"error-page" ofType:@"html"];
}

+ (NSString *)bwc_errorPageURL {
    NSString *errorPagePath = [[BDPBundle mainBundle] URLForResource:@"error-page" withExtension:@"html"].absoluteString;
    if (errorPagePath) {
        errorPagePath = [NSString stringWithFormat:@"%@?language=%@", errorPagePath, [BDPApplicationManager language]];
    }
    return errorPagePath;
}

+ (NSString *)bwc_unsafeDomainPageURLWithURL:(NSString * _Nonnull)url {
    NSString *unsafeNotePath = OPApplicationService.current.domainConfig.webViewSafeDomain;
    if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWebComponentDomainOpen]) {
        unsafeNotePath = OPApplicationService.current.domainConfig.openDomain;
    }
    if (BDPIsEmptyString(unsafeNotePath)) {
        NSAssert(NO, @"unsafeNotePath is nil!");
        BDPWebAPILogError(@"unsafeNotePath is nil!");
        // 兜底逻辑要有埋点
        return url;
    }
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"https";
    components.host = unsafeNotePath;
    components.path = @"/page/error";
    NSURLQueryItem *queryItemPlatform = [NSURLQueryItem queryItemWithName:@"platform" value:@"ios"];
    NSURLQueryItem *queryItemErrorTitle = [NSURLQueryItem queryItemWithName:@"errorTitle" value:BDPI18n.Lark_OpenPlatform_SecurityPrompt];
    NSURLQueryItem *queryItemErrorText = [NSURLQueryItem queryItemWithName:@"errorText" value:BDPI18n.Lark_OpenPlatform_SecurityPromptDesc];
    NSURLQueryItem *queryItemErrorUrl = [NSURLQueryItem queryItemWithName:@"errorUrl" value:url];
    NSURLQueryItem *queryItemHeaderHeight = [NSURLQueryItem queryItemWithName:@"headerHeight" value:@"0"];
    NSArray<NSURLQueryItem *> *queryItems = @[
        queryItemPlatform,
        queryItemErrorTitle,
        queryItemErrorText,
        queryItemErrorUrl,
        queryItemHeaderHeight
    ];
    components.queryItems = queryItems;
    NSString *targetUrl = components.URL.absoluteString;
    return targetUrl;
}

#pragma mark - KVO Observer
/*-----------------------------------------------*/
//           KVO Observer - KVO状态监听
/*-----------------------------------------------*/
- (void)bwc_setupObserver {
    [self addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(canGoBack)) options:NSKeyValueObservingOptionNew context:nil];
    // 监听通过document.title来修改标题的事件
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(title)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    /// 监听将要弹起
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bwc_keyBoardShow:) name:UIKeyboardWillShowNotification object:nil];
    /// 监听将要隐藏
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bwc_keyBoardHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)bwc_setupProgressViewWithProgressBarColorString:(NSString *)progressBarColorString {
    self.bwc_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.bwc_progressView.trackTintColor = [UIColor clearColor]; // 设置进度条的色彩
    UIColor *progressBarColor;
    if (!BDPIsEmptyString(progressBarColorString)) { // 进度条颜色支持自定义
        progressBarColor = [UIColor colorWithHexString:progressBarColorString] ? : progressBarColor;
    } else {
        progressBarColor = [UIColor colorWithRed:0.32f green:0.63f blue:0.85f alpha:1.f];
    }
    self.bwc_progressView.progressTintColor = progressBarColor;
    [self.bwc_progressView setProgress:0 animated:YES];
    [self addSubview:self.bwc_progressView];
    [self.bwc_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.and.top.mas_equalTo(self);
        make.width.mas_equalTo(self);
        make.height.mas_equalTo(2);
    }];
}

#pragma mark - UserAgent Config
/*-----------------------------------------------*/
//           UserAgent Config - UA配置
/*-----------------------------------------------*/
- (void)bwc_setupUserAgentFromConfig:(WKWebViewConfiguration *)config uniqueID:(OPAppUniqueID *)uniqueID {
    self.customUserAgent = [BDPUserAgent getUserAgentStringWithUniqueID:uniqueID];
}

//  code from wanghaoyu，未进行任何逻辑变化，保证web-view的fireevent和原来完全一致
- (void)fireEvent:(NSString *)event data:(NSDictionary *)data
{
    if (BDPIsEmptyString(event)) {
        BDPWebAPILogWarn(@"[BDPlatform-JSEngine] JSContext cannot fire null event.");
        return;
    }

    if (!BDPIsEmptyDictionary(data)) {
        data = [data encodeNativeBuffersIfNeed];
    } else {
        data = [[NSDictionary alloc] init];
    }

    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
        if (common && !common.isDestroyed) {
            NSString *dataJSONStr = [data JSONRepresentation] ?: @"{}";
            [self fireEventWithArguments:@[event, dataJSONStr]];
        }
    });
}

// 向worker发送webviewComponent生命周期相关的信息
- (void)bwc_fireEvent:(NSString *)event webview:(WKWebView *)webview componentID:(NSInteger)componentID {
    if (![self.superview isKindOfClass:[WKWebView class]]) {
        BDPWebAPILogError(@"superview is not wkwebview, web-view cannot fire event.");
        return;
    }

    // 默认错误页加载成功或失败不fireEvent
    if ([self.bwc_currentURL.absoluteString containsString:[[self class] bwc_errorPagePath]]) {
        BDPWebAPILogError(@"error page need not to fire event.");
        return;
    }

    WKWebView<BDPJSBridgeEngineProtocol> *engine = (WKWebView<BDPJSBridgeEngineProtocol> *)self.superview;
    if (![engine respondsToSelector:@selector(bdp_fireEvent:sourceID:data:)]) {
        BDPWebAPILogError(@"engine not impl fire event.");
        return;
    }
    // 通过这种方式去找与worker通信的channel，是为了兼容之后webviewcomponent与多个worker交流的场景
    // 这里的generateChannelId是一个找channel的临时方案，最优方案是webview直接给定一个channelid。
    NSDictionary *dict = @{
            @"src": self.bwc_currentURL.absoluteString ? : @"",
            @"htmlId": @(componentID),
            @"channel": [BDPWebComponentChannel generateChannelIdWithWebviewComponentId:self.componentID]
    };
    [engine bdp_fireEvent:event sourceID:NSNotFound data:dict];
}

- (void)publishMsgWithApiName:(NSString * _Nonnull)apiName paramsStr:(NSString * _Nonnull)paramsStr webViewId:(NSInteger)webViewId
{
    [super publishMsgWithApiName:apiName paramsStr:paramsStr webViewId:webViewId];
}

- (void)bwc_setNavigationTitle:(NSString *)title {
    if (BDPIsEmptyString(title)) {
        return;
    }
    UIViewController *vc = [self bdp_findFirstViewController];
    //2019-3-21 解决聚美提出的问题，带webview的页面左滑返回一半就取消，之后更新title不正确的问题
    if (![vc isKindOfClass:[BDPAppPageController class]]) {
        return;
    }
    // 获取导航栏
    BDPNavigationController *subNavi = (BDPNavigationController *)vc.navigationController;
    // [SUITE-6537]: iOS在webview的小程序页面设置tt.navigationTitle失效 @yinhao
    /// pageConfig代表的是页面对应的配置，代码是在页面名字.json里，如果配置了navigationBarTitleText并且不为空字符串才可以强行制定导航栏title
    /// 1.如果小程序页面标题设置为空，则允许h5通过url跳转/document.title来修改导航栏标题
    /// 2.否则不允许修改导航栏标题
    BOOL isNavigationBarTitleTextEmpty = BDPIsEmptyString(((BDPAppPageController *)vc).pageConfig.originWindow.navigationBarTitleText);
    if (isNavigationBarTitleTextEmpty) {
        /// 开发者没有强行配置导航栏标题
        [(BDPAppPageController *) vc setCustomNavigationBarTitle:title];
        if ([subNavi isKindOfClass:[BDPNavigationController class]]) {
            [subNavi setNavigationItemTitle:title viewController:vc];
        } else {
            vc.navigationItem.title = title;
        }
    } else {
        /// 开发者强行配置了导航栏标题，此处不跟着web view的document.title走
        BDPWebAPILogInfo(@"developer set navigationBarTitleText");
    }
}

//错误页的标题特殊处理，展示“加载错误”
- (void)bwc_setFinishNavigationTitle {
    [self evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        NSString *title = (NSString *)result;
        if (BDPIsEmptyString(title)) {
            return;
        }
        UIViewController *vc = [self bdp_findFirstViewController];
        //2019-3-21 解决聚美提出的问题，带webview的页面左滑返回一半就取消，之后更新title不正确的问题
        if (![vc isKindOfClass:[BDPAppPageController class]]) {
            return;
        }
        // 获取导航栏
        BDPNavigationController *subNavi = (BDPNavigationController *)vc.navigationController;
        [((BDPAppPageController *)vc) setCustomNavigationBarTitle:title];
        if ([subNavi isKindOfClass:[BDPNavigationController class]]) {
            [subNavi setNavigationItemTitle:title viewController:vc];
        } else {
            vc.navigationItem.title = title;
        }
    }];
}

- (void)bwc_openInOuterBrowser {
    NSString *URLString = self.bwc_openInOuterBrowserURL.absoluteString;
    // 这里校验一下，防止用户随意执行schema
    if ([URLString hasPrefix:@"https://"] || [URLString hasPrefix:@"http://"]) {
        [[UIApplication sharedApplication] openURL:self.bwc_openInOuterBrowserURL];
    } else {
        [TMACustomHelper showCustomToast:BDPI18n.browser_open_failed icon:nil window:self.window];
    }
}

#pragma mark - Failed Process

- (void)bwc_loadFailedPage {
    // 加载失败，打开一个默认兜底页面
    NSString *errorPagePath = [[self class] bwc_errorPagePath];
    
    if ([LSFileSystem fileExistsWithFilePath:errorPagePath isDirectory:nil]) {
        NSString *errorPageURLPath = [[self class] bwc_errorPageURL];
        NSURL *errorPageURL = [NSURL URLWithString:errorPageURLPath];
        [self loadRequest:[NSURLRequest requestWithURL:errorPageURL]];
    }
}

- (void)bwc_loadUnsafeUrlPageWithUnsafeUrl:(NSString * _Nonnull)url {
    // 拦截url，打开兜底页面
    NSURL *errorPageURL = [NSURL URLWithString:[[self class] bwc_unsafeDomainPageURLWithURL:url]];
    if ([errorPageURL.absoluteString isEqualToString:url]) {
        // 获取unsafePage页面url == 当前页面url时，说明获取错误页失败，不跳转
        BDPWebAPILogError(@"get errorPageURL failed, stop load page.");
        return;
    }
    [self loadRequest:[NSURLRequest requestWithURL:errorPageURL]];
}

#pragma mark - Meta Load
- (BOOL)bwc_enableSafeDomainDoubleCheck {
    return [EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWebComponentDoubleCheck];
}

- (void)bwc_setupMetaLoad {
    if (![self bwc_enableSafeDomainDoubleCheck]) {
        BDPWebAPILogInfo(@"double check disable");
        return;
    }
    BDPWebAPILogInfo(@"setup meta load listener");
    [[MetaLoadStatusManager shared] add:self];
}

- (void)bwc_removeMetaLoad {
    if (![self bwc_enableSafeDomainDoubleCheck]) {
        BDPWebAPILogInfo(@"double check disable");
        return;
    }
    BDPWebAPILogInfo(@"remove meta load listener");
    [[MetaLoadStatusManager shared] remove:self];
    if (self.decisionHandler) {
        self.decisionHandler(WKNavigationActionPolicyCancel);
        self.decisionHandler = nil;
    }
    if (self.loadingView) {
        [self.loadingView remove];
        self.loadingView = nil;
    }
}

- (void)loadStatusDidChangeWithStatus:(enum MetaLoadStatus)status identifier:(NSString *)identifier {
    if ([identifier isEqualToString:self.uniqueID.fullString]) {
        if (status == MetaLoadStatusFail) {
            BDPWebAPILogError(@"meta load fail");
            [self bwc_waitForMetaFail:YES];
        } else if (status == MetaLoadStatusSuccess) {
            BDPWebAPILogInfo(@"meta load success");
            [self bwc_waitForMetaFail:NO];
        }
    }
}

- (void)bwc_waitForMetaFail:(BOOL)fail {
    if (self.loadingView) {
        [self.loadingView remove];
        self.loadingView = nil;
    }
    
    if (self.navigationAction == nil || self.decisionHandler == nil) {
        BDPWebAPILogError(@"action or handler is nil");
        return;
    }
    
    WKNavigationAction *navigationAction = self.navigationAction;
    void (^decisionHandler)(WKNavigationActionPolicy) = self.decisionHandler;
    self.navigationAction = nil;
    self.decisionHandler = nil;
    
    if (fail) {
        BDPWebAPILogInfo(@"cancel then load fail page");
        decisionHandler(WKNavigationActionPolicyCancel);
        [self bwc_loadFailedPage];
    } else {
        BDPWebAPILogInfo(@"retry after meta loaded");
        [self webView:self decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }
}

#pragma mark - url checker

+ (BOOL)bwc_checkURLCanUse:(NSURL *)url {
    NSString *errorPagePath = [[self class] bwc_errorPageURL];
    // url == errorPagePath  or  url == 不支持的url（http、schema）
    if ((errorPagePath && [url.absoluteString isEqualToString:[NSURL URLWithString:errorPagePath].absoluteString])
        || [url.absoluteString isEqualToString:[BDPSDKConfig sharedConfig].unsupportedContextURL]
        || [url.absoluteString hasPrefix:[BDPSDKConfig sharedConfig].unsupportedUnconfigSchemaURL]
        || [url.absoluteString hasPrefix:[BDPSDKConfig sharedConfig].unsupportedUnconfigDomainURL]) {
        return NO;
    }
    return YES;
}

+ (BDPWebViewURLCheckResultType)bwc_checkURL:(NSURL *)URL withAuth:(BDPAuthorization *)auth uniqueID:(BDPUniqueID *)uniqueID {
    if (!URL) {
        BDPWebAPILogInfo(@"url is nil");
        return BDPWebViewInValidURL;
    }

    NSString *URLScheme = URL.scheme;
    NSString *URLString = URL.absoluteString;

    // Code Review Question: 这块判断逻辑捋一下，“https://” 是不是逃逸了 absoluteString = scheme + host + path
    // Answer: 这个case在这个方法的最后有兜底逻辑，这里的判断应该只是为了判空
    if ([URLScheme length] == 0 || [URLString length] == 0) {
        BDPWebAPILogInfo(@"url is empty");
        return BDPWebViewInvalidDomain;
    }

    if ([self bwc_checkIsValidLocalFile:URLString]) {
        // 是本地容错页面文件
        return BDPWebViewValidURL;
    }
    // 这里为与头条共用同一分支时添加的特化逻辑，避免干扰除Lark之外的其他宿主
    // 不应该只限定Lark的AppId，因为无法保证Lark后续不会有新的分支版本，如最近的极速版
    if (BDPRouteMediator.sharedManager.allowHttpForUniqueID && BDPRouteMediator.sharedManager.allowHttpForUniqueID(uniqueID)) {
        return BDPWebViewValidURL;
    }

    NSArray *defaultSchemaArr = [auth defaultSchemaSupportList];
    if ([defaultSchemaArr containsObject:URLScheme]) {
        // URL类型
        // URL Host Check
        if ([auth checkAuthorizationURL:URLString authType:BDPAuthorizationURLDomainTypeWebView]) {
            return BDPWebViewValidURL;
        } else {
            BDPWebAPILogInfo(@"check url is invalid, URLScheme=%@, host=%@", URLScheme, URL.host);
            return BDPWebViewInvalidDomain;
        }
    } else if ([URLScheme isEqualToString:@"file"]) {
        // 本地文件访问直接禁止
        BDPWebAPILogInfo(@"check url is file, invalid. url=%@", [BDPLogHelper safeURLString:URLString]);
        return BDPWebViewInvalidSchema;
    } else {
        // Schema类型
        // 对齐微信，支持 "tel:", "mailTo:", "sms:"
        NSArray *specialSchemaList = [auth webViewComponentSpecialSchemaSupportList];
        NSArray *authSchemaList = [auth domainsListWithAuthType:BDPAuthorizationURLDomainTypeWebViewComponentSchema];
        if ([specialSchemaList containsObject:[URLScheme lowercaseString]] || [authSchemaList containsObject:[URLScheme lowercaseString]]) {
            if ([[UIApplication sharedApplication] canOpenURL:URL]) {
                BDPWebAPILogInfo(@"can open url, valid, url=%@", [BDPLogHelper safeURLString:URLString]);
                return BDPWebViewValidSchema;
            } else {
                BDPWebAPILogInfo(@"can not open url, invalid, not support schema=%@, url=%@", URLScheme, [BDPLogHelper safeURLString:URLString]);
                return BDPWebViewUnsupportSchema;
            }
        }
        BDPWebAPILogInfo(@"can not open url, invalid, url=%@", [BDPLogHelper safeURLString:URLString]);
        return BDPWebViewInvalidSchema;
    }
}

+ (BOOL)bwc_checkIsValidLocalFile:(NSString *)URLString {
    NSString *errorPagePath = [self bwc_errorPageURL];
    if (errorPagePath && [[NSURL URLWithString:errorPagePath].absoluteString isEqualToString:URLString]) {
        return YES;
    }
    return NO;
}

- (BOOL)bwc_shouldCheckIDEDisableDomain {
    if (![EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWebComponentIDEDisableCheckDomain]) {
        return NO;
    }
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    NSString *scene = common.schema.scene;
    NSString *ideDisableCheck = common.schema.ideDisableDomainCheck;
    OPAppVersionType versionType = common.schema.versionType;
    BDPWebAPILogInfo(@"lkw web-view ide_disable_domain_check: %@, scene: %@, version_type: %d", ideDisableCheck, scene, versionType);
    if ((OPAppSceneCamera_qrcode==scene.integerValue || OPAppSceneDevice_debug==scene.integerValue) && [ideDisableCheck isEqualToString:@"1"] && OPAppVersionTypePreview==versionType) {
        return YES;
    }
    return NO;
}

// https://bytedance.feishu.cn/docx/doxcn7HzXcUUeSYugY07P0khluf
- (BOOL)bwc_shouldCheckSafeDomain {
    if (![EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWebComponentCheckdomain]) {
        return NO;
    }
    id<ECOConfigService> service = [ECOConfig service];
    id timestamp = BDPSafeDictionary([service getDictionaryValueForKey:@"web_view_safedomain_effective_time"])[@"timestamp"];
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    int64_t versionUpdateTime = common.model.versionUpdateTime;
    BOOL result = NO;
    if (timestamp && [timestamp isKindOfClass:NSNumber.class]) {
        int64_t settingsTimestamp = [timestamp longLongValue];
        result = versionUpdateTime > 0 && settingsTimestamp > 0 && versionUpdateTime > settingsTimestamp;
    }
    BDPWebAPILogInfo(@"bwc_shouldCheckSafeDomain result %@", @(result));
    
    return result;
}

// 检查跳转域名是否在给定安全域名list内 - 该list由业务自行配置，通过小程序meta下发；YES -> 安全
- (BOOL)bwc_checkURLIsExcepted:(NSURL * _Nonnull)url {
    if (url == NULL) {
        NSAssert(url != NULL, @"url cannot be nil!");
        BDPWebAPILogError(@"url cannot be nil!");
        return NO;
    }
    NSString *currentUrlStr = url.absoluteString.lowercaseString;
    NSString *unsafeNoteDomain = OPApplicationService.current.domainConfig.webViewSafeDomain;
    if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWebComponentDomainOpen]) {
        unsafeNoteDomain = OPApplicationService.current.domainConfig.openDomain;
    }

    if (![url.scheme hasPrefix:@"http"]
        || [currentUrlStr isEqualToString:[[self class] bwc_errorPageURL]]
        || [url.host isEqual:unsafeNoteDomain]) {
        // 非 http 开头的不做校验，直接放行.例如打电话 tel://1213123 这种玩意
        // 错误页面不校验，直接放行.
        // unsafe提示页面不校验，直接放行.
        BDPWebAPILogInfo(@"url is safe to load. url=%@", [BDPLogHelper safeURL:url]);
        return YES;
    }

    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    NSArray<NSString *> *gadgetSafeUrls = common.model.gadgetSafeUrls;
    if (BDPIsEmptyArray(gadgetSafeUrls)) {
        // 没有配置安全域名，需要拦截
        BDPWebAPILogWarn(@"url is NOT safe to load, don't have safe domain config. url=%@", [BDPLogHelper safeURL:url]);
        return NO;
    }

    // *:*  ->  放行所有url
    if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWebComponentGlobalEnableURL]) {
        for(int i = 0; i < gadgetSafeUrls.count; i++) {
            NSString *url = gadgetSafeUrls[i];
            if (BDPIsEmptyString(url)){
                continue;
            }
            if ([url isEqualToString:k_ALL_URL_ALLOW_TO_LOAD_STR]) {
                BDPWebAPILogInfo(@"allowed loading all urls.");
                return YES;
            }
        }
    }

    // 查看url是否在安全列表中的域名下
    for (int i = 0; i < gadgetSafeUrls.count; i++) {
        if ([self bwc_checkURL:url withSafeDomain:gadgetSafeUrls[i]]) {
            BDPWebAPILogInfo(@"url is safe to load, url is under safe domain. url=%@", [BDPLogHelper safeURL:url]);
            return YES;
        }
    }
    return NO;
}

/**
 * 配置 https://feishu.cn
 * 合法示例：
 *  https://feishu.cn
 *  https://open.feishu.cn
 *  https://a.open.feishu.cn
 * 不合法示例：
 *  http://feishu.cn
 *  https://afeishu.cn
 *  https://feishu.com
 */
- (BOOL)bwc_checkURL:(NSURL *)url withSafeDomain:(NSString *)domain {
    BDPWebAPILogInfo(@"check url: %@ with safe domain: %@", [BDPLogHelper safeURL:url], domain);
    if (BDPIsEmptyString(domain)) {
        return NO;
    }
    NSURL *safeURL = [NSURL URLWithString:domain];
    // scheme必须匹配
    if (![url.scheme isEqualToString:safeURL.scheme]) {
        return NO;
    }
    // 完全匹配
    if ([url.host isEqualToString:safeURL.host]) {
        return YES;
    }
    // 通配符需要符合二级及以上域名
    if ([safeURL.host componentsSeparatedByString:@"."].count < 2) {
        return NO;
    }
    return [url.host hasSuffix:[@"." stringByAppendingString:safeURL.host]];
}

@end
