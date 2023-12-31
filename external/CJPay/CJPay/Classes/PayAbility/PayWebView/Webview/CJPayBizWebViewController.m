//
//  CJPayBizWebViewController.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import "CJPayBizWebViewController.h"
#import "CJPayFullPageBaseViewController+Biz.h"
#import "CJPayBizWebViewController+ThemeAdaption.h"
#import "CJPayBizWebViewController+H5Notification.h"
#import "CJPayBizWebViewController+Payment.h"
#import "CJPayUIMacro.h"
#import "CJPayCookieUtil.h"
#import "CJPayWebViewUtil.h"
#import "CJWebViewHelper.h"
#import "CJPayWebviewStyle.h"
#import "UIViewController+CJTransition.h"
#import "CJPayDataPrefetcher.h"
#import "NSURL+CJPayScheme.h"
#import "NSURLComponents+CJPayQueryOperation.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayThemeModeManager.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import <TTBridgeUnify/TTWebViewBridgeEngine.h>
#import <TTReachability/TTReachability.h>
#import "CJPayLoadingManager.h"
#import "NSURL+CJPay.h"
#import "CJPayBaseRequest.h"
#import "CJPayPrivacyMethodUtil.h"
#import "CJPayBridgeAuthManager.h"
#import <IESWebViewMonitor/UIViewController+BlankDetectMonitor.h>
#import <IESJSBridgeCore/IESFastBridge_Deprecated.h>
#import <IESJSBridgeCore/IESJSBridgeCoreABTestManager.h>
#import <IESJSBridgeCore/IESBridgeEngine_Deprecated.h>
#import <IESJSBridgeCore/IESBridgeMessage.h>
#import <IESJSBridgeCore/IESBridgeEngine_Deprecated+Private.h>
#import "CJPayNavigationBarView.h"
#import "CJPayHybridPerformanceMonitor.h"
#import "CJPayWKWebView.h"
#import "CJPayNetworkErrorContext.h"
#import "CJPayBaseHybridWebview.h"
#import "CJPayHybridHelper.h"
#import "CJPayWebViewBlankDetect.h"
#import "CJPaySaasSceneUtil.h"
//#import <IESWebViewMonitor/BDHybridMonitorXCoreReporter.h>
#import "CJPayUniversalPayDeskService.h"
#import <BDXBridgeKit/BDXBridgeEvent.h>
#import <BDXBridgeKit/BDXBridgeEventCenter.h>


static NSErrorDomain CJPayWebViewErrorDomain = @"cjpay.webview.error";

typedef NS_ENUM(NSInteger, CJPayWebViewErrorCode) {
    CJPayWebViewErrorCodeNoNetwork = 400,
    CJPayWebViewErrorCodeTimeout = 401
};

typedef NS_ENUM(NSUInteger, CJPayOfflineActionType) {
    CJPayOfflineActionTypeNew = 0,
    CJPayOfflineActionTypeLoadFinish = 1,
    CJPayOfflineActionTypeDealloc = 2,
};

@interface CJPayBizWebViewController () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, CJPayAPIDelegate>

@property (nonatomic, strong) CJPayWKWebView *webView;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) NSTimeInterval initTime; // since1970  ms
@property (nonatomic, strong) NSTimer *blankDetectionTimer;
@property (nonatomic, copy) void(^ webViewDidFinishLoad)(void);
@property (nonatomic, strong) NSTimer *keyboardTimer;
@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, copy, readwrite) NSString *originUrl;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong, readwrite) CJPayDataPrefetcher *dataPrefetcher;
@property (nonatomic, strong) UIView *fakeStatusBar;
@property (nonatomic, assign, readwrite) BOOL hasFirstLoad;
@property (nonatomic, assign) BOOL isFirstViewDidAppear;
@property (nonatomic, copy) NSString *originalUrlStr;
@property (nonatomic, assign) BOOL hasInjectABSettings;
@property (nonatomic, strong) UIPanGestureRecognizer *swipeBackGestureForTransparent;
@property (nonatomic, assign) BOOL isShowShareButton;
@property (nonatomic, copy) NSString *rifleMegaObject;
@property (nonatomic, copy) NSString *httpHTTPMethod;
@property (nonatomic, copy) NSString *postData;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UIImageView *backGroundView;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIView *mainTitleView;
@property (nonatomic, strong) UIView *imageContentView;
@property (nonatomic, assign) BOOL webviewIsTerminated;
@property (nonatomic, assign) BOOL keepOriginalQuery;
@property (nonatomic, copy, readwrite) NSString *containerID;
@property (nonatomic, assign) BOOL haveBlankDetected;
@property (nonatomic, assign) BOOL isSaasEnv; //财经容器是否处于saas环境
@property (nonatomic, assign) BOOL isOnlyCallback;//直接关闭

@end

#define CJ_BACKGROUND_LOGO_WIDTH 200
#define CJ_STANDARD_WIDTH 375.0

@implementation CJPayBizWebViewController

#pragma mark - Public

- (instancetype)initWithUrlString:(NSString *)urlString
{
    if (![self p_checkUrlValidation:urlString]) {
        [CJMonitor trackService:@"wallet_rd_router_url_invalid"
                       category:@{@"url": CJString(urlString),
                                  @"page": @"web"}
                          extra:@{}];
    }
    self = [self initWithNSUrl:[NSURL cj_URLWithString:urlString]];
    return self;
}

- (instancetype)initWithUrlString:(NSString *)urlString piperClass:(Class)klass
{
    if (![self p_checkUrlValidation:urlString]) {
        [CJMonitor trackService:@"wallet_rd_router_url_invalid"
                       category:@{@"url": CJString(urlString), @"page": @"web"}
                          extra:@{}];
    }
    self = [self initWithNSUrl:[NSURL cj_URLWithString:urlString]];
    self.klass = klass;
    return self;
}


- (instancetype)initWithNSUrl:(NSURL *)url
{
    NSTimeInterval callAPITime = CFAbsoluteTimeGetCurrent();
    self = [self init];
    if (self) {
        self.originalUrlStr = url.absoluteString;
        self.httpHTTPMethod = @"GET";
        [self preparseURL:url];
        [self closeOffline];
        self.webPerformanceMonitor = [[CJPayHybridPerformanceMonitor alloc] initWith:self.originalUrlStr callAPITime:callAPITime];
        [self.webPerformanceMonitor trackPerformanceStage:CJPayHybridPerformanceStageInitFinished defaultTimeStamp:0];
        
        [self p_trackWithEvent:@"wallet_rd_hybrid_init" params:@{}];
        [self p_addWebviewGlobalReport];
    }
    return self;
}
//一键绑卡H5页面会使用这个方法，暂时不覆盖这里了
- (instancetype)initWithRequest:(NSURLRequest *)request {
    NSTimeInterval callAPITime = CFAbsoluteTimeGetCurrent();
    self = [self init];
    if (self) {
        self.request = request;
        self.webPerformanceMonitor = [[CJPayHybridPerformanceMonitor alloc] initWith:self.request.URL.absoluteString callAPITime:callAPITime];
        [self.webPerformanceMonitor trackPerformanceStage:CJPayHybridPerformanceStageInitFinished defaultTimeStamp:0];
        [self p_addWebviewGlobalReport];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allowsPopGesture = YES;
        _showsLoading = YES;
        _startTime = CFAbsoluteTimeGetCurrent();
        _initTime = [[NSDate date] timeIntervalSince1970] * 1000;
        _hasFirstLoad = NO;
        _kernel = @"0";
        _haveBlankDetected = NO;
        self.visibleDuration = 0;
    }
    return self;
}

- (void)p_addWebviewGlobalReport
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CJPayContainerConfig *containerConfig = [CJPaySettingsManager shared].containerConfig;
        if (!containerConfig) {
            containerConfig = [CJPaySettingsManager shared].currentSettings.containerConfig;
        }
//        if (!containerConfig.disableAlog) {
//            [BDHMXReporterInstance addGlobalReportBlock:^(NSString * _Nullable service, NSDictionary * _Nullable reportDic) {
//                NSDictionary *nativeBase = [reportDic cj_dictionaryValueForKey:@"nativeBase"];
//                NSString *nativePage = [nativeBase cj_stringValueForKey:@"native_page"];
//                if ([nativePage isEqualToString:@"CJPayBizWebViewController"]) {
//                    CJPayLogInfo(@"[WebViewMonitor] service: %@, info: %@", service, reportDic);
//                }
//            }];
//        }
    });
}

- (void)dealloc
{
    [self p_trackWithEvent:@"wallet_h5_residence_time" params:@{
        @"time": @([self p_getStayTime]),
        @"path": CJString(self.request.URL.relativePath)
    }];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    double stayTime = (CFAbsoluteTimeGetCurrent() - _startTime)*1000;
    NSDictionary *trackParams = @{@"page_finished": self.hasFirstLoad ? @"1" : @"0",
                                  @"show_error_page": self.isShowErrorView ? @"1" : @"0",
                                  @"page_close_type": CJString(self.pageCloseType),
                                  @"page_close_time" : @(stayTime)};
    
    [self p_trackWithEvent:@"wallet_rd_hybrid_close"
                    params:trackParams];
    
    //这里是原生web内核释放逻辑，hybrid内核这部分由Hybrid底层接管
    if (!self.isHybridKernel) {
        WKUserContentController *userContentController = _webView.configuration.userContentController;
        if (userContentController) {
            if (@available(iOS 14.0, *)) {
                [userContentController removeAllScriptMessageHandlers];
            }
            [userContentController removeAllUserScripts];
        }
        _webView.UIDelegate = nil;
        _webView.navigationDelegate = nil;
        _webView.scrollView.delegate = nil;
        [_webView stopLoading];
        _webView = nil;
    }
    [self closeOffline];
}

- (BOOL)canGoBack {
    return [[self kernelView] canGoBack];
}

- (void)goBack {
    [[self kernelView] goBack];
}

- (void)sendEvent:(NSString *)event params:(nullable NSDictionary *)data {
    if (self.isHybridKernel) {
        [self.hybridView sendEvent:event params:data];
    } else {
        [self.webView.tt_engine fireEvent:event params:data];
    }
}

- (void)setBounce:(BOOL)enable {
    WKWebView *webKernel = [self kernelView];
    if (!webKernel) {
        return;
    }
    
    if (@available(iOS 16.0, *)) {
        webKernel.scrollView.alwaysBounceVertical = enable;
    } else {
        [webKernel.scrollView setBounces:enable];
    }
}

#pragma mark - Overrides
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)cjAllowTransition {
    BOOL allowTransition = self.allowsPopGesture;
    if (self.navigationController.viewControllers.count <= 1 && self.navigationController.modalPresentationStyle != UIModalPresentationFullScreen) { // 解决overfullscreen右滑关闭黑屏的问题
        allowTransition = NO;
    }
    if (self.swipeBackGestureForTransparent.view) { // 避免swipe手势和转场的手势冲突
        self.swipeBackGestureForTransparent.enabled = !allowTransition;
    }
    CJPayLogInfo(@"%@, 允许侧滑返回, %@, kernel_type:%@", self, @(allowTransition), self.kernel);
    return allowTransition;
}

#pragma mark - VC life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    CJPayLogInfo(@"%@, viewDidLoad", self);
    [self p_prepareWebViewStyle];
    if (!self.isHybridKernel) {
        [self p_prepareRquestBeforLoad];
    }
    
    if (![self p_checkUrlValidation:self.urlStr]) {
        [CJMonitor trackService:@"wallet_rd_router_url_invalid"
                       category:@{@"url": CJString(self.originalUrlStr),
                                  @"page": @"web",
                                  @"kernel_type" : CJString(self.kernel)
                                }
                          extra:@{}];
    }
    
    self.isFirstViewDidAppear = YES;
    self.fakeStatusBar = [[UIView alloc] init];
    self.fakeStatusBar.backgroundColor = self.webviewStyle.statusBarColor ?: UIColor.clearColor;
    [self.view insertSubview:self.fakeStatusBar belowSubview:self.navigationBar];
    CJPayMasMaker(self.fakeStatusBar, {
        make.edges.equalTo(self.view);
    });
    // 假的状态栏背景view，加到导航条上面
    self.navigationBar.backgroundColor = self.webviewStyle.navbarBackgroundColor ?: [UIColor whiteColor];
    
    if (self.webviewStyle.isLandScape) {
        self.view.transform = CGAffineTransformMakeRotation(M_PI/2);
        if (CJ_SCREEN_HEIGHT > CJ_SCREEN_WIDTH) {
            self.view.bounds = CGRectMake(0, 0, self.view.cj_height, self.view.cj_width);
        } else {
            self.view.bounds = CGRectMake(0, 0, self.view.cj_width, self.view.cj_height);
        }
    }
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self setNavTitle:CJString(self.webviewStyle.titleText)];
    if (self.webviewStyle.navbarTitleColor) {
        self.navigationBar.titleLabel.textColor = self.webviewStyle.navbarTitleColor;
    }
    
    BOOL disableFontScale = [self p_isDisableFontScale];
    if (!disableFontScale) {
        self.navigationBar.titleLabel.font = [UIFont cj_boldFontOfSize:17];
    } else {
        self.navigationBar.titleLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:17];
    }
    
    // 隐藏状态栏时，也要自动隐藏导航栏
    if (self.webviewStyle.hidesNavbar || self.webviewStyle.hidesStatusBar) {
        self.navigationBar.cj_width = 40;
        self.navigationBar.backgroundColor = UIColor.clearColor;
        self.navigationBar.clipsToBounds = YES;
        self.navigationBar.titleLabel.hidden = YES;

        CJPayMasReMaker(self.navigationBar, {
            make.left.top.equalTo(self.view);
            make.width.mas_equalTo(40);
            make.height.mas_equalTo(CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT);
        });
    }
    if (self.isShowNewUIStyle) {
        [self p_setUIForNewUIStyle];
    }
    
    switch (self.webviewStyle.backButtonStyle) {
        case kCJPayBackButtonStyleArrow:
            //
            break;
        case kCJPayBackButtonStyleClose:
            [self.navigationBar setLeftImage:[UIImage cj_imageWithName:@"cj_close_icon"]]; //  这个图缺少多主题支持，目前使用X的没有暗色主题
            break;
    }

    if (self.webviewStyle.backButtonColor) {
        UIImage *image = [self.navigationBar.backBtn.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.navigationBar.backBtn setImage:image forState:UIControlStateNormal];
        [self.navigationBar.backBtn setTintColor:self.webviewStyle.backButtonColor];
    }

    self.navigationBar.hidden = self.webviewStyle.hidesBackButton && self.webviewStyle.hidesNavbar;
    
    self.navigationBar.shareBtn.hidden = !self.isShowShareButton;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeAllWebFromNoti:) name:CJPayBizNeedCloseAllWebVC object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCookies) name:CJPayBizRefreshCookieNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusFrameChanged:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    if (self.showsLoading) { // 无论容器是否透明，都默认展示loading态
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading url:[self.request.URL cj_getHostAndPath] view:self.view];
    }

    [self registerH5Notification];
    [self p_tryTimeOutCloseWebVC];
    [self p_tryTimeOutShowErrorView];

    [[CJPayCookieUtil sharedUtil] setupCookie:^(BOOL success) {
        [self setupWebView];
        [self loadWebView];
    }];
    if (self.webviewStyle.isNeedFullyTransparent) {
        [self.view addGestureRecognizer:self.swipeBackGestureForTransparent];
    }
    
    [self setNeedsStatusBarAppearanceUpdate]; //解决状态栏颜色刷新不及时的问题
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.webviewIsTerminated) {
        CJPayLogInfo(@"%@, 白屏，触发 WebView 重新刷新 url = %@, isWebViewTerminated = %@, kernel_type=%@", self, self.originUrl, @(self.webviewIsTerminated), self.kernel);
        [self reloadWebView];
        self.webviewIsTerminated = NO;
    }
    
    CJPayLogInfo(@"%@, viewWillAppear", self);
    CJ_CALL_BLOCK(self.ttcjpayLifeCycleBlock, CJPayVCLifeTypeWillAppear);    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 首次展示，不回调viewdidappear
    if (self.shouldNotifyH5LifeCycle && !self.isFirstViewDidAppear) {
        [self sendEvent:@"ttcjpay.visible" params:@{}];
        CJPayLogInfo(@"%@, ttcjpay.visible", self);
    }
    self.isFirstViewDidAppear = NO;
    [self p_startTimer];
    CJPayLogInfo(@"%@, viewDidAppear", self);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    if (self.shouldNotifyH5LifeCycle) {
        [self sendEvent:@"ttcjpay.invisible" params:@{}];
        CJPayLogInfo(@"%@, ttcjpay.invisible", self);
    }
    [self p_endTimer];
    CJPayLogInfo(@"%@, viewWillDisappear", self);
    
    CJPayContainerConfig *containerConfig = [CJPaySettingsManager shared].currentSettings.containerConfig;
    if (!containerConfig.disableBlankDetect && !self.haveBlankDetected) {
        self.haveBlankDetected = YES;
        CJPayBlankDetectContext *context = [[CJPayBlankDetectContext alloc] init];
        context.stayTime = [self p_getStayTime];
        context.isLoadingViewShowing = [[CJPayLoadingManager defaultService] isLoading];
        context.isErrorViewShowing = [self isNoNetworkViewShowing];
        [CJPayWebViewBlankDetect blankDetectionWithWebView:self.kernelView context:context];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.blankDetectionTimer invalidate];
    self.blankDetectionTimer = nil;
    [self.keyboardTimer invalidate];
    self.keyboardTimer = nil;
    CJPayLogInfo(@"%@, viewDidDisappear", self);
    
    BOOL isClosing = self.navigationController.isBeingDismissed;
    isClosing = isClosing || self.isBeingDismissed;
    isClosing = isClosing || (self.isMovingFromParentViewController && self.parentViewController == nil);
    //正在关闭，且走到这里依旧没有设置关闭类型，则说明是手势返回或者抽栈关闭
    if (isClosing) {
        NSString *stayTime = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent() - _startTime];
        if (!Check_ValidString(self.pageCloseType)) {
            self.pageCloseType = @"user";//手势返回
        } else if ([self.pageCloseType isEqualToString:@"nav_close"]) {
            self.pageCloseType = @"worker";//抽栈关闭的
        } else {
            return;//已经设置为user或者worker，则会走closeweb流程上报关闭埋点
        }
    }
}

#pragma mark - Events

- (BOOL)cjNeedAnimation {
    if ([self.webviewStyle isNeedFullyTransparent]) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)cjShouldShowBottomView {
    if ([self.webviewStyle isNeedFullyTransparent]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)showsLoading {
    // 目前可以通过VC.showsLoading赋值和scheme传show_loading字段控制是否展示loading态，两者默认值都是yes，只有两者都为YES时，采取展示loading态
    if (!self.webviewStyle) {
        return _showsLoading;
    }
    return _showsLoading && self.webviewStyle.showsLoading;
}

- (void)setUrl:(NSURL *)url {
    CJPayLogInfo(@"setURL url:%@, origin:%@", url, _url);
    NSURL *temUrl = [self p_tryFilterHttpRequestWithUrl:url];
    _url = [self p_tryReplaceURLHosts:temUrl];
    CJPayLogInfo(@"setURL current:%@", _url);
}

/**
 http请求映射成https请求，否则会有cookie泄漏的安全风险
 具体漏洞链接：https://security.bytedance.net/workbench/orders/detail/113643
 修复方案：https://bytedance.feishu.cn/docs/doccniD65wrgWAnZhZWaEuDdcJg
 如果force_https_enable开关打开，并且url的host不在allow_http_list里就将http替换为https
 */

- (NSURL *)p_tryFilterHttpRequestWithUrl:(NSURL *)url {
    CJPaySettings *curSettings = [CJPaySettingsManager shared].currentSettings;
    if (!url || ![url.scheme isEqualToString:@"http"] || !curSettings.forceHttpsModel.forceHttpsEnable) {
        return url;
    }
    
    if ([self p_isNeedForceHttpsWithUrl:url]) {
        NSURLComponents *tmpUrlComponents = [NSURLComponents componentsWithURL:url
                                                       resolvingAgainstBaseURL:YES];
        tmpUrlComponents.scheme = @"https";
        CJPayLogInfo(@"%@, 强制切换成https, %@", self, url);
        return tmpUrlComponents.URL;
    } else {
        return url;
    }
}

- (NSURL *)p_tryReplaceURLHosts:(NSURL *)url {
    // 宿主主动配置了聚合域名，并且当前URL也走得聚合域名
    NSString *gConfigHost = [CJPayBaseRequest gConfigHost];
    if (Check_ValidString(gConfigHost) && [gConfigHost hasPrefix:@"http"]) {
        NSURLComponents *gConfigHostComponents = [NSURLComponents componentsWithURL:[NSURL URLWithString:[gConfigHost cj_safeURLString]] resolvingAgainstBaseURL:NO];
        gConfigHost = gConfigHostComponents.host;
    }
    if ([CJPayBaseRequest gConfigHost].length > 8 && ![[CJPayBaseRequest gConfigHost] containsString:@"tp-pay.snssdk.com"] && url && [url.host isEqualToString:@"tp-pay.snssdk.com"] ) {
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        CJPaySettings *curSettings = [CJPaySettingsManager shared].currentSettings;
        NSArray *blockList = curSettings.webviewCommonConfigModel.intergratedHostReplaceBlockList;
        // 黑名单内的域名不进行替换
        if (Check_ValidArray(blockList) && Check_ValidString(urlComponents.path) && [blockList containsObject:urlComponents.path]) {
            CJPayLogInfo(@"%@, 宿主配置了聚合域名, 在黑名单内的域名不进行替换, url = %@, kernel_type=%@", self, url, self.kernel);
            return url;
        }
        CJPayLogInfo(@"%@, 宿主配置了聚合域名, 需要替换 %@, kernel_type=%@", self, url, self.kernel);
        urlComponents.host = gConfigHost;
        return urlComponents.URL;
    }
    return url;
}

- (void)p_setUIForNewUIStyle {
    [self.navigationBar addSubview:self.mainTitleView];
    [self.mainTitleView addSubview:self.mainTitleLabel];
    [self.mainTitleView addSubview:self.logoImageView];
    [self.view addSubview:self.subTitleLabel];
    self.subTitleLabel.backgroundColor = self.navigationBar.backgroundColor;
    [self.imageContentView addSubview:self.backGroundView];
    [self.view addSubview:self.imageContentView];
    
    self.navigationBar.titleLabel.hidden = YES;
    
    CJPayMasMaker(self.backGroundView, {
        make.top.right.equalTo(self.imageContentView);
        make.width.height.mas_equalTo(self.view.cj_width * CJ_BACKGROUND_LOGO_WIDTH / CJ_STANDARD_WIDTH);
    })
    
    CJPayMasMaker(self.imageContentView, {
        make.top.right.equalTo(self.view);
        make.width.equalTo(self.backGroundView);
        make.height.mas_equalTo([self naviHeight]);
    })
    
    CJPayMasMaker(self.mainTitleView, {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.navigationBar.backBtn);
        make.top.bottom.equalTo(self.mainTitleLabel);
    })
    
    
    CJPayMasMaker(self.logoImageView, {
        make.left.equalTo(self.mainTitleView);
        make.centerY.equalTo(self.mainTitleLabel);
        make.width.mas_equalTo(83);
        make.height.mas_equalTo(20);
    })
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.left.equalTo(self.logoImageView.mas_right).offset(6);
        make.width.mas_lessThanOrEqualTo(144);
        make.right.equalTo(self.mainTitleView);
        make.centerY.equalTo(self.mainTitleView);
    })
    
    CJPayMasMaker(self.subTitleLabel, {
        make.left.right.equalTo(self);
        make.top.equalTo(self.mainTitleView.mas_bottom).offset(8);
    })
    
    self.mainTitleLabel.text = CJPayLocalizedStr(self.titleStr);
    self.subTitleLabel.text = [NSString stringWithFormat:CJPayLocalizedStr(@"本服务由%@提供"), self.titleStr];
}

#pragma mark Theme
- (BOOL)cj_supportMultiTheme {
    return YES;
}

- (CJPayThemeModeType)cj_currentThemeMode {
    if ([self p_shouldAdaptTheme]) {
        return [super cj_currentThemeMode];
    }
    return CJPayThemeModeTypeLight;
}

- (void)statusFrameChanged: (NSNotification *)noti {
    if (!CJ_Pad) {
        CGRect statusBarFrame = [noti.userInfo[UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
        CGFloat statusHeight = statusBarFrame.size.height;
        UIView *showView = [self showKernelView];
        CGRect viewRect = showView.frame;
        showView.frame = CGRectMake(viewRect.origin.x, viewRect.origin.y, CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT - [self naviHeight] - statusHeight + CJ_STATUSBAR_HEIGHT);
    }
}

- (void)refreshCookies {
    if (self.kernelView) {
        if (@available(iOS 11.0, *)) {
            NSArray<NSHTTPCookie *> *httpCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy];
            for (NSHTTPCookie *cookie in httpCookies) {
                [self.kernelView.configuration.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:nil];
            }
        } else {
            NSString *cookieStr = [[CJPayCookieUtil sharedUtil] getWebCommonScipt:self.urlStr];
            [self.kernelView evaluateJavaScript:cookieStr completionHandler:nil];
        }
        CJPayLogInfo(@"%@, Cookies 刷新, Cookies = %@, kernel_type=%@", self, [[CJPayCookieUtil sharedUtil] _getCookieDic:self.urlStr].allKeys, self.kernel);
        [self reloadWebView];
    }
}

- (void)setupWebView {
    // 设置webview和外边容器的背景色
    self.view.backgroundColor = self.webviewStyle.containerBcgColor;
    //这部分hybrid配置不在这里进行
    if (!self.isHybridKernel) {
        self.webView.scrollView.backgroundColor = self.webviewStyle.containerBcgColor;
        [self.webView setOpaque:NO];
        
        // 设置webview的bounce效果
        if (!self.webviewStyle.bounceEnable) {
            self.webView.scrollView.bounces = NO;
        }
    }
    
    self.showKernelView.backgroundColor = self.webviewStyle.webBcgColor;

    CJPayLogInfo(@"%@", [NSString stringWithFormat:@"启动耗时：%f, kernel_type=%@", CFAbsoluteTimeGetCurrent() - _startTime, self.kernel]);
    
    // 设置webview的frame
    [self.view insertSubview:self.showKernelView belowSubview:self.navigationBar];
    
    [self switchWebViewBlankDetect:YES webView:[self kernelView]];//开启白屏检测
    
    if (CJ_Pad) {
        CGFloat webviewOriginY = [self navigationHeight];
        if (self.webviewStyle.needFullScreen || self.webviewStyle.hidesNavbar) {
            webviewOriginY = 0;
        }
        CJPayMasMaker(self.showKernelView, {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view).offset(webviewOriginY);
            if (CJ_Pad) {
                if (@available(iOS 11.0, *)) {
                    make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
                } else {
                    make.bottom.equalTo(self.view);
                }
            } else {
                make.bottom.equalTo(self.view);
            }
        });
    } else {
        CGFloat webviewOriginY = CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT;
        if (self.webviewStyle.needFullScreen) {
            webviewOriginY = 0;
        } else {
            webviewOriginY = CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT;
            if (self.webviewStyle.hidesStatusBar) { // 隐藏状态栏的话，会把导航条区域也空出来，但会保留返回箭头
                webviewOriginY = 0;
            } else if (self.webviewStyle.hidesNavbar) {
                webviewOriginY = CJ_STATUSBAR_HEIGHT;
            }
        }
        if (self.isShowNewUIStyle) {
            webviewOriginY = CJ_STATUSBAR_HEIGHT + 62;
        }
        
        CJPayMasMaker(self.showKernelView, {
            make.left.right.bottom.equalTo(self.view);
            make.top.equalTo(self.view).offset(webviewOriginY);
        });
    }
}

- (BOOL)allowsPopGesture {
    if (self.webviewStyle.disablePopGesture) {
        return NO;
    }
    
    return _allowsPopGesture;
}

- (void)p_didBecomeActive {
    if (!self.shouldNotifyH5LifeCycle) {
        CJPayLogInfo(@"%@, p_didBecomeActive, shouldNotifyH5LifeCycle 为 NO", self);
        return;
    }
    if ([UIViewController cj_foundTopViewControllerFrom:self] != self) {
        CJPayLogInfo(@"%@, p_didBecomeActive, 当前 topVC 不是自身", self);
        return;
    }
    [self sendEvent:@"ttcjpay.visible" params:@{}];
}

#pragma mark - private method

- (BOOL)p_isDisableFontScale {
    BOOL disableFontScale = Check_ValidString(self.webviewStyle.enableFontScale) && [self.webviewStyle.enableFontScale isEqualToString:@"0"];
    NSDictionary *urlParams = [self.urlStr cj_urlQueryParams];
    if ([[urlParams cj_stringValueForKey:@"enable_font_scale"] isEqualToString:@"0"]) {
        disableFontScale = YES;
    } else if ([[urlParams cj_stringValueForKey:@"enable_font_scale"] isEqualToString:@"1"]) {
        disableFontScale = NO;
    }
    return disableFontScale;
}

- (BOOL)p_checkUrlValidation:(NSString *)urlString {
    NSURL *url = [NSURL cj_URLWithString:urlString];
    NSParameterAssert(url != nil);
    if (url == nil) {
        CJPayLogInfo(@"%@, urlString 转 NSUrl 失败 urlString = %@", self, urlString);
        return NO;
    }
    NSString *schemeAndHost = [url.absoluteString componentsSeparatedByString:@"?"].firstObject;
    if (![url.scheme hasPrefix:@"http"] && ![schemeAndHost hasPrefix:@"sslocal://cjpay"] && ![schemeAndHost hasPrefix:@"aweme://cjpay"]) {
        CJPayLogInfo(@"%@, URL 校验失败，scheme 不是 http 或 sslocal://cjpay 或 aweme://cjpay, url = %@, schemeAndHost = %@", self, url, schemeAndHost);
        return NO;
    }
    return YES;
}

- (void)p_trackWithEvent:(NSString *)event params:(NSDictionary *)paramsDic {
    NSMutableDictionary *params = [@{@"type": @"web",
                                     @"url": CJString(self.urlStr),
                                     @"schema": CJString(self.originUrl),
                                     @"kernel_type" : CJString(self.kernel)
                                   } mutableCopy];
    [params addEntriesFromDictionary:paramsDic];
    [CJTracker event:event params:params];
}

// 超时主页面没有渲染完成就关闭webvc，有风险，所以交给前端控制，只在透明webview以及前端传入timeout的情况下才生效
- (void)p_tryTimeOutCloseWebVC {
    if (![self.webviewStyle isNeedFullyTransparent]) {
        return;
    }
    
    NSInteger timeout = self.webviewStyle.closeWebviewTimeout;
    if (timeout <= 0) {
        return;
    }
    @CJWeakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self && !self.hasFirstLoad) {
            CJPayLogInfo(@"%@, 主页面没有渲染完成就关闭web, 仅在透明webview以及前端传入timeout的情况下才生效 isNeedFullyTransparent = %@, timeout = %@", self, @([self.webviewStyle isNeedFullyTransparent]), @(self.webviewStyle.closeWebviewTimeout));

            @CJStrongify(self)
            [self closeWebVCWithAnimation:YES completion:^{
                @CJStrongify(self)
                if (self.closeCallBack) {
                    self.closeCallBack(@{@"service": @"web", @"action": @"timeout"});
                }
            }];
        }
    });
}

// 超时主页面没有渲染完成就加载失败的兜底页面
- (void)p_tryTimeOutShowErrorView {
    if (![CJWebViewHelper isInShowErrorViewDomains:self.urlStr]) {
        return;
    }
    
    NSInteger timeout = [CJPaySettingsManager shared].currentSettings.webviewCommonConfigModel.showErrorViewTimeout;
    if (timeout <= 0) {
        return;
    }
    
    @CJWeakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self && !self.hasFirstLoad) {
            CJPayLogInfo(@"超时加载错误页面");
            @CJStrongify(self)
            
            CJPayNetworkErrorContext *errorContext = [CJPayNetworkErrorContext new];
            errorContext.error = [NSError errorWithDomain:CJPayWebViewErrorDomain code:CJPayWebViewErrorCodeTimeout userInfo:@{@"errorDesc": @"timeout"}];
            errorContext.urlStr = self.urlStr;
            errorContext.scene = @"timeout";
            [self showNoNetworkViewUseThemeStyle:[self p_shouldAdaptTheme] errorContext:errorContext];
        }
    });
}

- (void)loadWebView {
    [self p_trackWithEvent:@"wallet_open_web" params:@{}];
    if (self.isHybridKernel) {
        //hybridkit内核加载不在这里进行
        return;
    }
    
    BOOL injectSuccess = [CJWebViewHelper injectSecLinkTO:self.webView withScene:self.webviewStyle.secLinkScene withOriginalUrl:self.originalUrlStr]; // 添加secLink，具体是否添加成功需要看内部实现
    if (!injectSuccess) {
        CJPayLogInfo(@"inject secLink fail，originalURL： %@, scene: %@", self.originalUrlStr, self.webviewStyle.secLinkScene);
    }
    
    [[CJPayWebViewUtil sharedUtil] setupUAWithCompletion:^(NSString * _Nullable userAgent) {
        NSString *cjpayUserAgent = userAgent;
        if (Check_ValidString(self.webviewStyle.cjCustomUserAgent)) {
            cjpayUserAgent = CJConcatStr(cjpayUserAgent, @" ", self.webviewStyle.cjCustomUserAgent);
        }
        
        [self.webView setCustomUserAgent:CJString(cjpayUserAgent)];
        [self.webPerformanceMonitor trackPerformanceStage:CJPayHybridPerformanceStageStartLoadURL defaultTimeStamp:0];

        if ([NSThread currentThread].isMainThread) {
            [self.webView loadRequest:self.request];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.webView loadRequest:self.request];
            });
        }
        
        [self p_trackWithEvent:@"wallet_rd_webview_start_load" params:@{
            @"host": CJString(self.request.URL.host),
            @"path": CJString(self.request.URL.path)}
        ];
    }];
    
    if (![self.request.HTTPMethod isEqualToString:@"POST"]) { //POST请求关闭离线包
        [self openOffline];
    }
    
    [self.blankDetectionTimer invalidate];
    NSInteger settingsDelayTime = [CJPaySettingsManager shared].currentSettings.webviewMonitorConfigModel.detectBlankDelayTime;
    NSInteger delayTime = settingsDelayTime > 0 ? settingsDelayTime : 3;
    
    self.blankDetectionTimer = [NSTimer timerWithTimeInterval:delayTime target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(detectBlank) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.blankDetectionTimer forMode:NSDefaultRunLoopMode];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)detectBlank {
    if (self.webView.URL && [CJWebViewHelper isBlankWeb:self.webView]) {
        CJPayLogInfo(@"%@, 白屏重新加载 url = %@", self, self.webView.URL);
        [self.webView reload];
    }
    [self.blankDetectionTimer invalidate];
    self.blankDetectionTimer = nil;
}

- (void)reloadWebView {
    [self.kernelView reload];
    CJPayLogInfo(@"%@, reloadWebView, url = %@", self, self.webView.URL);
}

- (void)closeAllWebFromNoti:(NSNotification *)noti {
    [self closeWebVC];
    CJPayLogInfo(@"%@, 收到通知关掉所有web页面, url = %@, source = %@", self, self.urlStr, [noti.userInfo cj_objectForKey:@"source"]);
}

- (void)back {
    //绑卡银行H5页由前端控制关闭，将事件广播出去
    NSDictionary *urlParams = [CJPayCommonUtil parseScheme:self.originalUrlStr];
    if (!self.isOnlyCallback && Check_ValidString([urlParams cj_stringValueForKey:@"back_hook_action"])) {
        [self.view endEditing:YES];
        NSString *backHookAction = [urlParams cj_stringValueForKey:@"back_hook_action"];
        NSString *timeStampStr = [NSString stringWithFormat:@"%ld", (long)([[NSDate date] timeIntervalSince1970] * 1000)];
        NSString *callBackId = [NSString stringWithFormat:@"cj_callback_id_%@", timeStampStr];
        BDXBridgeEvent *bridgeEvent = [BDXBridgeEvent eventWithEventName:CJString(backHookAction)
                                                                  params:@{@"value": @{@"callback_id":CJString(callBackId)}}];
        [BDXBridgeEventCenter.sharedCenter publishEvent:bridgeEvent];
        [CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService) i_openUniversalPayDeskWithParams:@{@"back_hook_action":CJString(backHookAction),
                                                                                                  @"callback_id":CJString(callBackId)}
                                                                                        referVC:self
                                                                                   withDelegate:self];
        return;
    }
    
    [self sendEvent:@"ttcjpay.receiveSDKNotification" params:@{@"type": @"click.backbutton", @"data": @""}];
    CJPayLogInfo(@"%@, ttcjpay.receiveSDKNotification", self);
    self.pageCloseType = @"user";//走到这里说明用户手动点了返回
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
        return;
    }
    
    void(^closeActionBlock)(void) = ^{
        @CJWeakify(self)
        [self closeWebVCWithAnimation:YES completion:^{
            @CJStrongify(self)
            if (self.closeCallBack) {
                self.closeCallBack(@{@"service": @"web", @"action": @"back"});
            }
        }];
        CJPayLogInfo(@"%@, 关掉当前页面, url = %@", self, self.urlStr);
    };
    
    if ([self canGoBack] && ![self.webviewStyle.disableHistory isEqualToString:@"1"]) {
        [CJWebViewHelper secLinkGoBackFrom:[self kernelView] reachEndBlock:^{
            closeActionBlock();
        }];
    } else {
        closeActionBlock();
    }
}

- (void)share {
    CJPayLogInfo(@"%@, click share", self);
    CJ_DECLARE_ID_PROTOCOL(CJPayShareProtocol);
    if (objectWithCJPayShareProtocol && [objectWithCJPayShareProtocol respondsToSelector:@selector(showSharePanel:)]) {
        if (!Check_ValidString([self.shareParam cj_stringValueForKey:@"url"])) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.shareParam];
            params[@"url"] = self.originUrl;
            params[@"platform"] = @"share_native";
            self.shareParam = [params copy];
        }
        if (!Check_ValidString([self.shareParam cj_stringValueForKey:@"platform"])) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.shareParam];
            params[@"platform"] = @"share_native";
            self.shareParam = [params copy];
        }
        [objectWithCJPayShareProtocol showSharePanel:self.shareParam];
    }
}

- (void)closeWebVC {
    [self closeWebVCWithAnimation:YES completion:nil];
}

- (void)closeWebVCWithAnimation:(BOOL)animation
                     completion:(void (^ __nullable)(void))completion {
    NSString *stayTime = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent() - _startTime];
    //没有设置关闭类型，则说明是通过消息通知的方式调用的关闭
    if (!Check_ValidString(self.pageCloseType)) {
        self.pageCloseType = @"worker";
    }
    // https://stackoverflow.com/questions/27470130/catransaction-completion-block-never-fires
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.navigationController == nil || self.navigationController.viewControllers.count == 1 || self.navigationController.viewControllers.firstObject == self){
            [self dismissViewControllerAnimated:animation completion:^{
                CJ_CALL_BLOCK(completion);
            }];
        } else {
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                CJ_CALL_BLOCK(completion);
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:animation];
            });
            [CATransaction commit];
        }
        if (self.justCloseBlock && !completion) { //closeCallBack被调用时屏蔽justCloseBlock
            self.justCloseBlock();
        }
    });
}

- (CGFloat)naviHeight {
    if (self.isShowNewUIStyle) {
        return CJ_STATUSBAR_HEIGHT + 62;
    }
    return CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT;
}

//解析schema,从schema中提取webview要加载的url以及端能力相关属性
- (void)preparseURL:(NSURL *)url {
    NSParameterAssert(url != nil);
    if (!url) {
        return;
    }
    
    if ([url isCJPayHTTPScheme]) {
        self.url = url;
        return;
    }
    
    __block NSString *urlString = nil;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([item.name isEqualToString:@"url"]) {
            urlString = item.value;
        }
        if ([item.name isEqualToString:@"right_button_type"]) {
            if ([item.value isEqualToString:@"share"]) {
                self.isShowShareButton = YES;
            }
        }
        if ([item.name isEqualToString:@"right_button_color"]) {
            if (Check_ValidString(item.value)) {
                [self.navigationBar.shareBtn cj_setBtnImage:[[UIImage cj_imageWithName:@"cj_share_icon"] cj_changeWithColor:[UIColor cj_colorWithHexString:item.value]]];
            }
        }
        if ([item.name isEqualToString:@"rifle_mega_object"]) {
            self.rifleMegaObject = item.value;
        }
        if ([item.name isEqualToString:@"keep_original_query"]) {
            self.keepOriginalQuery = YES;
        }
        if ([item.name isEqualToString:@"kernel_type"]) {
            self.kernel = item.value;
        }
        if ([item.name isEqualToString:CJPaySaasKey]) {
            self.isSaasEnv = [item.value isEqualToString:@"1"];
        }
        if ([item.name isEqualToString:@"broadcast_dom_content_loaded"]) {
            if ([item.value isEqualToString:@"1"]) {
                self.broadcastDomContentLoaded = YES;
            }
        }
    }];
    
    CJPayContainerConfig *containerConfig = [CJPaySettingsManager shared].currentSettings.containerConfig;
    //允许走hybridkit kernel
    if (Check_ValidArray(containerConfig.cjwebUrlAllowList)) {
        [containerConfig.cjwebUrlAllowList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([urlString hasPrefix:obj]) {
                self.kernel = @"1";
                *stop = YES;
            }
        }];
    }
    //不允许走hybridkit kernel， 优先级更高
    if (Check_ValidArray(containerConfig.cjwebUrlBlockList)) {
        [containerConfig.cjwebUrlBlockList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([urlString hasPrefix:obj]) {
                self.kernel = @"0";
                *stop = YES;
            }
        }];
    }
    //全局开关,没有接入hybrid情况下，降级为旧web
    if (!containerConfig.cjwebEnable || ![CJPayHybridHelper hasHybridPlugin]) {
        self.kernel = @"0";
    }

    self.originUrl = urlString;
    
    if ([urlString length] <= 0) {
        CJPayLogInfo(@"scheme URL无法找到url参数！");
        return;
    }

    NSURL *httpUrl = [NSURL URLWithString:urlString];
    if (httpUrl == nil) { // encode一下URL来抢救一下
        CJPayLogInfo(@"url参数没有按照约定进行编码！");
        CJPayLogInfo(@"接收的urlString: %@", urlString);
        httpUrl = [NSURL cj_URLWithString:urlString];
        CJPayLogInfo(@"尝试解析出URL: %@", httpUrl.absoluteURL);
    }
    
    NSParameterAssert(httpUrl != nil && [httpUrl isCJPayHTTPScheme]);

    self.url = httpUrl;
    
    if (!httpUrl) {
        [CJMonitor trackService:@"wallet_rd_webview_load_url_format_error"
                          extra:@{@"host": CJString(self.url.host),
                                  @"path": CJString(self.url.path)
                          }];
    }
}

- (BOOL)p_isNeedForceHttpsWithUrl:(NSURL *)url {
    CJPaySettings *curSettings = [CJPaySettingsManager shared].currentSettings;
    NSArray<NSString *> *allowHttpList = curSettings.forceHttpsModel.allowHttpList;
    if (!allowHttpList) {
        return YES;
    }
    
    for (NSString *allowedDomain in allowHttpList) {
        if ([url.host hasSuffix:allowedDomain]) {
            return NO;
        }
    }
    return YES;
}

- (void)p_prepareRquestBeforLoad {
    if (_request) {
        return;
    }
    if (!_url) {
        return;
    }
    
    NSURLComponents *componens = [NSURLComponents componentsWithURL:_url resolvingAgainstBaseURL:NO];

    if ([self.webviewStyle needAppendCommonQueryParams]) {
        NSString *timeStr = @([[NSDate date] timeIntervalSince1970] * 1000).stringValue;
        [componens cjpay_setQueryValue:timeStr ifNotExistKey:@"event_id"];
        [[[CJPayBridgeAuthManager shared] allowedDomainsForSDK] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([_url.host hasSuffix:obj]) {
                NSMutableDictionary *extraParams = [[[CJPayCookieUtil sharedUtil] cjpayExtraParams] mutableCopy];
                NSString *themeMode = @"light";
                if ([self cj_currentThemeMode] == CJPayThemeModeTypeDark) {//暗色、浅色模式
                    themeMode = @"dark";
                }
                [extraParams cj_setObject:themeMode forKey:@"tp_theme"];
                if (!_keepOriginalQuery) {
                    [componens cjpay_overrideQueryByDict:extraParams];
                }
                *stop = YES;
            }
        }];
    }
    
    _url = componens.URL;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
    if (request.URL == nil) {
        CJPayLogInfo(@"request URL is nil");
    }
    if ([[self.webviewStyle.openMethod uppercaseString] isEqualToString:@"GET"]) {
        request.HTTPMethod = @"GET";
    } else if ([[self.webviewStyle.openMethod uppercaseString] isEqualToString:@"POST"]) {
        request.HTTPMethod = @"POST";
    }
    if (Check_ValidString(self.webviewStyle.postData)) {
        request.HTTPBody = [self.webviewStyle.postData dataUsingEncoding:NSUTF8StringEncoding];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    }
    
    [self p_updateWebViewStyle];
    
    [self appendHeaderWithRequest:request];
    
    _request = [request copy];
    
    [self.dataPrefetcher startRequest]; // 开始预请求
}

- (void)appendHeaderWithRequest:(NSMutableURLRequest *)request {
    [request setValue:[[CJPayCookieUtil sharedUtil] getWKCookieScript:_url.absoluteString] forHTTPHeaderField:@"Cookie"];
}

- (void)p_prepareWebViewStyle {
    [self p_adaptWebViewStyleByThemeSettingFrom:self.urlStr];
    [self.webviewStyle amendByUrlString:self.originalUrlStr];
}

- (void)p_updateWebViewStyle {
    self.isShowNewUIStyle = [self.webviewStyle.bankSign isEqualToString:@"1"];
    self.titleStr = CJString(self.webviewStyle.bankName);
    if (!Check_ValidString(self.returnUrl)) {
        self.returnUrl = CJString(self.webviewStyle.returnUrl);
    }
}

- (void)p_didEnterBackground {
    if (self.shouldNotifyH5LifeCycle) {
        [self sendEvent:@"ttcjpay.invisible" params:@{}];
    }
    CJPayLogInfo(@"%@, p_didEnterBackground", self);
}


- (NSTimeInterval)p_getStayTime {
    return self.visibleDuration;
}

- (void)p_startTimer {
    self.visibleTime = CFAbsoluteTimeGetCurrent();
}

- (void)p_endTimer {
    self.invisibleTime = CFAbsoluteTimeGetCurrent();
    if ((self.invisibleTime - self.visibleTime) >= 0) {
        self.visibleDuration += self.invisibleTime - self.visibleTime;
    } else {
        CJPayLogInfo(@"stayTime cannot be less than 0");
    }
}

#pragma mark - getter
- (NSString *)urlStr {
    if (Check_ValidString(self.url.absoluteString)) {
        return self.url.absoluteString;
    }
    return CJString(self.request.URL.absoluteString);
}

- (CJPayWKWebView *)webView {
    if (_webView == nil) {
        // 配置下UA
        _webView = [CJWebViewHelper buildWebView:self.urlStr
                                      httpMethod:self.request.HTTPMethod];
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        
        [self addDOMContentLoadedMonitorToWebViewIfNeeded:_webView];
        [self addGlobalPropsToWebViewIfNeeded:_webView];
        
        CJPayLogInfo(@"%@, %@, kernel:0", self, [NSString stringWithFormat:@"创建耗时：%f", CFAbsoluteTimeGetCurrent() - _startTime]);
        CJPayLogInfo(@"navigationDelegate: %@", _webView.navigationDelegate);
    }
    return _webView;
}

- (CJPayBaseHybridWebview *)hybridView {
    if (!_hybridView) {
        _hybridView = [[CJPayBaseHybridWebview alloc] initWithScheme:self.originalUrlStr delegate:self initialData:@{}];
        //相当于默认id=containerID，业务方可以直接传containerID来关闭页面
        if (!Check_ValidString(self.cjVCIdentify)) {
            self.cjVCIdentify = _hybridView.containerID;
        }
        CJPayLogInfo(@"%@, %@, kernel:1", self, [NSString stringWithFormat:@"创建耗时：%f", CFAbsoluteTimeGetCurrent() - _startTime]);
    }
    return _hybridView;
}


- (void)addGlobalPropsToWebViewIfNeeded:(WKWebView *)webview
{
    NSString *jsSource = [self generateJsSourceWithParamName:@"__globalProps" object:@{@"initTimestamp" : CJString([@(self.initTime) stringValue])}];
    if (BTD_isEmptyString(jsSource)) {
        return;
    }
    WKUserScript *wkScript = [[WKUserScript alloc] initWithSource:jsSource injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [webview.configuration.userContentController addUserScript:wkScript];
}

- (NSString *)generateJsSourceWithParamName:(NSString *)name object:(NSDictionary *)props
{
    if (BTD_isEmptyString(name) || BTD_isEmptyDictionary(props)) {
        return @"";
    }
    NSString *jsonStr = [CJPayCommonUtil dictionaryToJson:props];
    return [NSString stringWithFormat:@"window.%@ = %@;", name, jsonStr];
}

- (void)addDOMContentLoadedMonitorToWebViewIfNeeded:(WKWebView *)webview
{
    if (self.broadcastDomContentLoaded) {
        WKUserScript *wkScript = [[WKUserScript alloc] initWithSource:[self p_DOMContentLoadedJS] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [webview.configuration.userContentController addUserScript:wkScript];
        [webview.configuration.userContentController addScriptMessageHandler:self name:@"CJPay_DOMContentLoaded"];
    }
}

- (NSString *)p_DOMContentLoadedJS {
    return @"\
    (function() {\n\
    \n\
     function needReport(params) {\n\
        if (window.location.href === 'about:blank') {\n\
            return false;\n\
        }\n\
        return true;\n\
     }\n\
    \n\
     // pv\n\
     function jsIESLiveTimingMonitorReportStage(params) {\n\
         if (!needReport(params)) {\n\
             return\n\
         }\n\
         if (window.webkit) {\n\
             window.webkit.messageHandlers.CJPay_DOMContentLoaded.postMessage(formatMonitorParams(params));\n\
         }\n\
     }\n\
    \n\
    function formatMonitorParams(params) {\n\
        params.url = window.location.href\n\
        params.event_time = new Date().getTime()\n\
        return JSON.parse(JSON.stringify(params))\n\
    }\n\
    \n\
    \n\
     function onCJPayDomContentLoaded() {\n\
        var msg = {}\n\
        msg.event_name = 'cj_DomContentLoaded';\n\
        jsIESLiveTimingMonitorReportStage(msg);\n\
     }\n\
     // Use the handy event callback\n\
     window.addEventListener( \"DOMContentLoaded\", onCJPayDomContentLoaded );\n\
    \n\
    })();";
}

- (CJPayWebviewStyle *)webviewStyle {
    if (_webviewStyle == nil) {
        _webviewStyle = [[CJPayWebviewStyle alloc] init];
    }
    return _webviewStyle;
}

- (CJPayDataPrefetcher *)dataPrefetcher {
    if (!_dataPrefetcher && Check_ValidString(self.urlStr)) {
        NSError *error;
        NSDictionary *jsonObj = [CJPaySettingsManager shared].currentSettings.webviewPrefetchConfig;
        if (jsonObj) {
            CJPayPrefetchConfig *config = [[CJPayPrefetchConfig alloc] initWithDictionary:jsonObj error:&error];
            _dataPrefetcher = [[CJPayDataPrefetcher alloc] initWith:self.urlStr prefetchConfig:config];
            CJPayLogInfo(@"%@ 数据预取 %@ ", self, config);
        }
    }
    return _dataPrefetcher;
}

- (NSString *)kernel {
    if (!Check_ValidString(_kernel)) {
        return @"0";
    }
    return _kernel;
}

-(void)keyboardWillHide {
    CJPayLogInfo(@"%@ keyboardWillHide", self);
    if (@available(iOS 12.0, *)) {
        if (self.keyboardTimer) {
            return;
        }
        self.keyboardTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(keyboardDisplacementFix) userInfo:nil repeats:false];
        [[NSRunLoop mainRunLoop] addTimer:self.keyboardTimer forMode:NSRunLoopCommonModes];
    }
}

-(void)keyboardWillShow {
    CJPayLogInfo(@"%@ keyboardWillShow", self);
    if (self.keyboardTimer != nil) {
        [self.keyboardTimer invalidate];
        self.keyboardTimer = nil;
    }
}

-(void)keyboardDisplacementFix {
    // https://stackoverflow.com/a/9637807/824966
    UIScrollView *scrollView = [self kernelView].scrollView;
    double maxContentOffset = scrollView.contentSize.height - scrollView.frame.size.height;
    
    if (maxContentOffset < 0) {
        maxContentOffset = 0;
    }
    
    if (scrollView.contentOffset.y > maxContentOffset) {
        [UIView animateWithDuration:.25 animations:^{
            [self kernelView].scrollView.contentOffset = CGPointMake(0, maxContentOffset);
        }];
    }
}

- (UIPanGestureRecognizer *)swipeBackGestureForTransparent {
    if (!_swipeBackGestureForTransparent) {
        _swipeBackGestureForTransparent = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(p_transparentViewSwipeBack:)];
    }
    return _swipeBackGestureForTransparent;
}

// 该字段含义与实际的导航条高度在保留返回按钮时不符合。
- (CGFloat)navigationHeight {
    if (CJ_Pad) {
        return [super navigationHeight];
    }
    if (self.webviewStyle.hidesNavbar) {
        return CJ_STATUSBAR_HEIGHT;
    } else {
        return CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT;
    }
}



- (NSString *)containerID {
    if (_hybridView) {
        return _hybridView.containerID;
    }
    return @"";
}

- (BOOL)isHybridKernel {
    if ([self.kernel isEqualToString:@"1"]) {
        return YES;
    }
    return NO;
}

- (BOOL)isCaijingSaasEnv {
    return self.isSaasEnv || self.webviewStyle.isCaijingSaas;
}
#pragma mark - private

- (void)p_transparentViewSwipeBack:(UIPanGestureRecognizer *)gesture {
    // 用来处理透明webview，不能关闭的问题。
    if (self.cjAllowTransition) { // 支持转场返回的话，就不再走panGesture
        return;
    }
    CGPoint point = [gesture translationInView:self.view];
    if (point.x > 50 && gesture.state == UIGestureRecognizerStateEnded && self.allowsPopGesture) {
        [self back];
    }
}

- (void)openOffline {
    CJPayLogInfo(@"%@, openOffline", self);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CJPayWebViewOfflineNotification" object:@{@"action": @(CJPayOfflineActionTypeNew)}];
}

- (void)closeLegacyVersionOffline {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CJPayWebViewOfflineNotification" object:@{@"action": @(CJPayOfflineActionTypeLoadFinish)}];
}

- (void)closeOffline {
    CJPayLogInfo(@"%@, closeOffline", self);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CJPayWebViewOfflineNotification" object:@{@"action": @(CJPayOfflineActionTypeDealloc)}];
}

- (void)showNoNetworkView {
    [[CJPayLoadingManager defaultService] stopLoading];
    
    CJPayNetworkErrorContext *errorContext = [CJPayNetworkErrorContext new];
    errorContext.error = [NSError errorWithDomain:CJPayWebViewErrorDomain code:CJPayWebViewErrorCodeNoNetwork userInfo:@{@"errorDesc": @"no network"}];
    errorContext.urlStr = self.urlStr;
    errorContext.scene = @"no_network";
    [self showNoNetworkViewUseThemeStyle:[self p_shouldAdaptTheme] errorContext:errorContext];
}

#pragma mark - apiDelegate

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    NSString *serviceStr = [response.data cj_stringValueForKey:@"service"];
    if ([serviceStr isEqualToString:@"only_callback"]) {
        self.isOnlyCallback = YES;
        [self back];
    }
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    CJPayLogInfo(@"%@, didReceiveScriptMessage:%@", message.body);
    
    if ([message.body isKindOfClass:[NSDictionary class]]) {
        NSString *eventName = CJString([message.body cj_stringValueForKey:@"event_name"]);
        if ([eventName isEqualToString:@"cj_DomContentLoaded"]) {
            BDXBridgeEvent *bridgeEvent = [BDXBridgeEvent eventWithEventName:@"cjpay_webview_dom_event"
                                                                      params:message.body];
            [BDXBridgeEventCenter.sharedCenter publishEvent:bridgeEvent];
        }
    }
}

#pragma mark - WKUIDelegate

// 处理可能因为runjavascriptAlertPanel completionHandler不执行导致的crash，这里直接返回调用规避问题
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    [self p_trackWithEvent:@"wallet_webview_alert" params:@{
        @"message": CJString(message),
        @"handler": completionHandler == nil ? @"0" : @"1"}];
    if (completionHandler) {
        if ([NSThread currentThread].isMainThread) {
            [CJToast toastText:message inWindow:self.cj_window];
            completionHandler();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [CJToast toastText:message inWindow:self.cj_window];
                completionHandler();
            });
        }
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    [self p_trackWithEvent:@"wallet_webview_prompt" params:@{@"message": CJString(prompt), @"handler": completionHandler == nil ? @"0" : @"1"}];
    if (completionHandler) {
        completionHandler(@"");
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    [self p_trackWithEvent:@"wallet_webview_confirm" params:@{@"message": CJString(message), @"handler": completionHandler == nil ? @"0" : @"1"}];
    if (completionHandler) {
        completionHandler(YES);
    }
}

#pragma mark - WKWebViewDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if(navigationAction.targetFrame == nil || !navigationAction.targetFrame.isMainFrame) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading url:[self.request.URL cj_getHostAndPath] view:self.view];
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

// 主文档开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    CJPayLogInfo(@"主文档开始加载 url = %@", CJString(self.urlStr));
}

// 主机地址被重定向时调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    CJPayLogInfo(@"主机地址被重定向时调用 url = %@",  CJString(self.urlStr));
}

// 当内容开始返回(收到首个数据包)时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    CJPayLogInfo(@"内容开始返回 url = %@", CJString(self.urlStr));
}
    
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    [self.webPerformanceMonitor trackPerformanceStage:CJPayHybridPerformanceStagePageStarted defaultTimeStamp:0];
    CJPayLogInfo(@"请求跳转 url = %@",CJString(navigationAction.request.URL.absoluteString));

    if ([navigationAction.request.URL.absoluteString hasPrefix:@"tel:"] || [navigationAction.request.URL.absoluteString hasPrefix:@"mailto:"]) {
        CJPayLogInfo(@"跳转电话：%@", navigationAction.request.URL.absoluteString);
        // 调用AppJump敏感方法，需走BPEA鉴权
        [CJPayPrivacyMethodUtil applicationOpenUrl:navigationAction.request.URL
                                        withPolicy:@"bpea-caijing_webview_open_tel"
                                   completionBlock:^(NSError * _Nullable error) {
           
            if (error) {
                CJPayLogError(@"error in bpea-caijing_webview_open_tel");
            }
        }];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([self payment_hasDecidedPolicyForNavigationAction:navigationAction decisionHandler:decisionHandler]) {
        return;
    }
    
    if (Check_ValidString(self.returnUrl) && [navigationAction.request.URL.absoluteString hasPrefix:self.returnUrl]) {
        CJPayLogInfo(@"拦截的returnURL: %@", self.returnUrl);
        @CJWeakify(self)
        [[CJPayLoadingManager defaultService] stopLoading];
        decisionHandler(WKNavigationActionPolicyCancel);
        [self closeWebVCWithAnimation:YES completion:^{
            @CJStrongify(self)
            if (self.closeCallBack) {
                self.closeCallBack(@{@"action": @"return_by_url", @"return_url": CJString(self.returnUrl)});
            }
        }];
        return;
    }
    
    if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        [self showNoNetworkView];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    if (!self.isHybridKernel) {
        self.bridge.webView = self.webView;
        [self.bridge flushMessages];
    }
    
    self.startTime = CFAbsoluteTimeGetCurrent();
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

// 请求之前，决定是否要跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSInteger statusCode = -1;
    if (navigationResponse.response && [navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        statusCode = ((NSHTTPURLResponse *)navigationResponse.response).statusCode;
    }
    if (statusCode != 200) {
        [self p_trackWithEvent:@"wallet_rd_webview_load_fail" params:@{@"host": CJString(self.request.URL.host),
                                                                       @"path": CJString(self.request.URL.path),
                                                                       @"error_code": @(statusCode).stringValue,
                                                                       @"is_http_error": @"1"}];
    } else {
        CJPayLogInfo(@"请求返回 url = %@", CJString(navigationResponse.response.URL.absoluteString));
    }
    
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.webPerformanceMonitor trackPerformanceStage:CJPayHybridPerformanceStagePageFinished defaultTimeStamp:0];
    if (!self.hasInjectABSettings) {
        NSMutableDictionary *abSettingsDic = [[CJPaySettingsManager shared].currentSettings.abSettingsDic ?: @{} mutableCopy];
        NSDictionary *abTestKeyValueDic = [CJPayABTest getExperimentKeyValueDic];
        if (abTestKeyValueDic && abTestKeyValueDic.count > 0) {
            [abSettingsDic addEntriesFromDictionary:abTestKeyValueDic];
        }
        
        NSString *abSettings = [CJPayCommonUtil dictionaryToJson:[abSettingsDic copy] ?: @{}];
        [webView evaluateJavaScript:[NSString stringWithFormat:@"localStorage.setItem('ab_settings', '%@')", abSettings] completionHandler:nil];
        self.hasInjectABSettings = YES;
    }
    
    BOOL disableFontScale = [self p_isDisableFontScale];
    if (!([UIFont cjpayFontMode] == CJPayFontModeNormal) && !disableFontScale) {
        [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust = '%@%%'", [UIFont cjpayPercentFontScale]] completionHandler:nil];
    }
    
    self.hasFirstLoad = YES;
    NSArray *notHideLoadingPaths = @[];
    CJPaySettings *setting = [CJPaySettingsManager shared].currentSettings;
    if (setting && setting.loadingPath.count > 0) {
        notHideLoadingPaths = setting.loadingPath;
    }
    __block BOOL containNotHideLoadingPath = NO;
    [notHideLoadingPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self.urlStr containsString:obj]) {
            containNotHideLoadingPath = YES;
        }
    }];
    if (!containNotHideLoadingPath) {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
    @CJWeakify(self)
    [self.kernelView evaluateJavaScript:@"document.title" completionHandler:^(NSString *_Nullable titleStr, NSError * _Nullable error) {
        @CJStrongify(self)
        if (Check_ValidString(titleStr) && !Check_ValidString(self.webviewStyle.titleText)) {
            if ([NSThread currentThread].isMainThread) {
                [self setNavTitle:titleStr];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setNavTitle:titleStr];
                });
            }
        }
    }];
    
    NSString *loadingTimeStr = @((CFAbsoluteTimeGetCurrent() - _startTime) * 1000).stringValue;
    [CJMonitor trackService:@"wallet_rd_webview_loading_time"
                     metric:@{@"load_time": CJString(loadingTimeStr)}
                   category:@{@"host": CJString(self.request.URL.host),
                              @"path": CJString(self.request.URL.path)}
                      extra:@{@"url": CJString(self.urlStr)}];

    
    CJPayLogInfo(@"%@, %@", self, [NSString stringWithFormat:@"请求耗时：%f", (CFAbsoluteTimeGetCurrent() - _startTime) * 1000]);
    [self p_trackWithEvent:@"wallet_rd_webview_load_success" params:@{@"host": CJString(self.request.URL.host),
                                                                      @"path": CJString(self.request.URL.path)}];
    
    if (_webViewDidFinishLoad) {
        _webViewDidFinishLoad();
    }
    
    [self closeLegacyVersionOffline];
    [CJPayPerformanceMonitor trackPageFinishRenderWithVC:self name:[NSString stringWithFormat:@"%@%@",CJString(self.request.URL.host), CJString(self.request.URL.path)] extra:@{@"state": @"success"}];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    CJPayLogInfo(@"%@, %@", self, [NSString stringWithFormat:@"didFailNavigation: error.code:%ld  error.desc:%@", (long)error.code, error.description]);

    [self handleLoadFailWithError:error];
}

// 当开始加载主文档数据失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    CJPayLogInfo(@"%@, %@", self, [NSString stringWithFormat:@"didFailProvisionalNavigation: error.code:%ld  error.desc:%@", (long)error.code, error.description]);

    [self handleLoadFailWithError:error];
}

- (void)handleLoadFailWithError:(NSError *)error {
    [[CJPayLoadingManager defaultService] stopLoading];
    if (self.webviewStyle.isNeedFullyTransparent && [error code] != NSURLErrorCancelled) {
        self.navigationBar.hidden = NO;
    }
    NSString *errorCode = error ? @(error.code).stringValue : @"";
    
    [self p_trackWithEvent:@"wallet_rd_webview_load_fail" params:@{
        @"host": CJString(self.request.URL.host),
        @"path": CJString(self.request.URL.path),
        @"error_code": CJString(errorCode),
        @"is_http_error": @"0"}];
    
    [self p_trackWithEvent:@"wallet_rd_hybrid_error"
                    params:@{@"stage": @"hybrid_kit",
                             @"error_code": CJString(errorCode),
                             @"error_msg": CJString(error.description)
                           }];
    
    
    if (([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102) || error.code == NSURLErrorCancelled) {
        // Error code 102 "Frame load interrupted" is raised by the WKWebView when the URL is from an http redirect.
        // Error code -999 NSURLErrorCancelled.
        return;
    }
    
    [self closeOffline];
    CJPayNetworkErrorContext *errorContext = [CJPayNetworkErrorContext new];
    errorContext.error = error;
    errorContext.urlStr = self.urlStr;
    errorContext.scene = @"load_failed";
    [self showNoNetworkViewUseThemeStyle:YES errorContext:errorContext];
}

- (void)reloadCurrentView {
    if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        return;
    }
    [self hideNoNetworkView];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading url:[self.request.URL cj_getHostAndPath] view:self.view];
    [self.kernelView loadRequest:self.request];
    CJPayLogInfo(@"%@, 无网重新加载 WebView url = %@", self, self.request.URL);
}

//9.0才能使用，web内容处理中断时会触发
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    self.webviewIsTerminated = YES;
    [CJMonitor trackServiceAllInOne:@"wallet_rd_webview_terminate"
                             metric:@{}
                           category:@{}
                              extra:@{@"url": CJString(self.request.URL.absoluteString)}];
    CJPayLogInfo(@"%@, 收到 WebView terminate 回调 url = %@", self, self.request.URL);
}

- (UIImageView *)backGroundView {
    if (!_backGroundView) {
        _backGroundView = [UIImageView new];
        if (![CJPaySettingsManager shared].currentSettings.abSettingsModel.isHiddenDouyinLogo) {
            [_backGroundView cj_setImage:@"cj_bindcard_logo_icon"];
        }
    }
    return _backGroundView;
}

- (UIImageView *)logoImageView {
    if (!_logoImageView) {
        _logoImageView = [UIImageView new];
        [_logoImageView cj_setImage:@"cj_dy_pay_icon"];
    }
    return _logoImageView;
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [UILabel new];
        _mainTitleLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:16];
        _mainTitleLabel.textColor = [UIColor cj_161823ff];
        _mainTitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _mainTitleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:12];
        _subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _subTitleLabel;
}

- (UIView *)mainTitleView {
    if (!_mainTitleView) {
        _mainTitleView = [UIView new];
    }
    return _mainTitleView;
}

- (UIView *)imageContentView {
    if (!_imageContentView) {
        _imageContentView = [UIView new];
        _imageContentView.clipsToBounds = YES;
    }
    return _imageContentView;
}
//布局的view
- (UIView *)showKernelView {
    if (self.isHybridKernel) {
        return self.hybridView;
    } else {
        return self.webView;
    }
}
//内核view
- (WKWebView *)kernelView {
    if (self.isHybridKernel) {
        return _hybridView.webview;
    } else {
        return _webView;
    }
}

- (CJPiper *)bridge {
    if (!_bridge) {
        if (self.klass) {
            _bridge = [[self.klass alloc] initWithWebView:self.webView];
        } else {
            _bridge = [[CJPiper alloc] initWithWebView:self.webView];
        }
    }
    return _bridge;
}

@end

@interface CJPiper ()

@property (nonatomic, strong) IESBridgeEngine_Deprecated *deprecatedBridgeEngine;
@property (nonatomic, strong) NSMutableDictionary *callbackHandlers;

@end

@implementation CJPiper

- (instancetype)initWithWebView:(WKWebView *)webView
{
    self = [super init];
    if (self) {
        _webView = webView;

        if (!IESPiperCoreABTestManager.sharedManager.shouldUseBridgeEngineV2) {
            _deprecatedBridgeEngine = [[IESBridgeEngine_Deprecated alloc] init];
            _callbackHandlers = [NSMutableDictionary dictionary];
            
            if ([webView isKindOfClass:WKWebView.class]) {
                [IESFastBridge_Deprecated injectionBridge:_deprecatedBridgeEngine intoWKWebView:(WKWebView *)webView];
            }
        }
        
        // Invoke -registerConfigMethod if it exists.
        SEL selector = NSSelectorFromString(@"registerConfigMethod");
        if ([self respondsToSelector:selector]) {
            [self performSelector:selector];
        }
    }
    return self;
}

- (void)flushMessages
{
    NSString *jsString = @"ToutiaoJSBridge._fetchQueue()"; //_canAffectStatusBarAppearance
    @CJWeakify(self)
    [self.webView evaluateJavaScript:jsString completionHandler:^(id result, NSError *error) {
        @CJStrongify(self)
        NSString *resultString = [result description];
        NSArray *messagesData = [resultString btd_jsonArray];
        for(NSDictionary *messageData in messagesData) {
            IESBridgeMessage *msg = [[IESBridgeMessage alloc] init];
            msg.methodName = [messageData objectForKey:@"func"];
            msg.messageType = [messageData objectForKey:@"__msg_type"];
            msg.params = [messageData objectForKey:@"params"];
            msg.callbackID = [messageData objectForKey:@"__callback_id"];
            msg.JSSDKVersion = [messageData objectForKey:@"JSSDK"];
            if ([msg.JSSDKVersion isKindOfClass:NSNumber.class]) {
                msg.JSSDKVersion = [(NSNumber *)msg.JSSDKVersion stringValue];
            }
            msg.from = IESBridgeMessageFromIframe;
            [self processIFrameMessage:msg];
        }
    }];
}

- (void)processIFrameMessage:(IESBridgeMessage*)msg
{
    if([msg.messageType isEqualToString:IESJSMessageTypeCallback]) {
        if(msg.callbackID.length > 0 && [_callbackHandlers objectForKey:msg.callbackID]) {
            IESJSCallbackHandler handler = [_callbackHandlers objectForKey:msg.callbackID];
            if(handler) {
                handler(msg.params);
            }
        }
    } else if([msg.messageType isEqualToString:IESJSMessageTypeCall]) {
        [self.deprecatedBridgeEngine executeMethodsWithMessage:msg];
    }
}

@end
