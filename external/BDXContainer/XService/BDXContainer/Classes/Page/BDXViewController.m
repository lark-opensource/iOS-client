//
// BDXViewController.m
// BDXContainer
//
// Created by bill on 2021/3/14.
//

#import <BDXServiceCenter/BDXPopupContainerProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BulletX/BulletXDefines.h>
#import <BulletX/BulletXLog.h>
#import <BulletX/NSString+BulletXUrlExt.h>

#import <BDXBridgeKit/BDXBridgeMethod.h>
#import <BDXServiceCenter/BDXContext.h>
#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXSchemaProtocol.h>
#import <BDXServiceCenter/BDXServiceRegister.h>
#import <BulletX/NSURL+BulletXQueryExt.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/BTDResponder.h>
#import <ByteDanceKit/NSData+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import <KVOController/KVOController.h>
#import <Masonry/Masonry.h>
#import <objc/runtime.h>
#import "BDXContainerUtil.h"
#import "BDXNavigationBar.h"
#import "BDXNavigationBarProvider.h"
#import "BDXPageSchemaParam.h"
#import "BDXView.h"
#import "BDXViewController.h"

#if __has_include(<Lynx/BDLynxContextPool.h>)
#import <Lynx/BDLynxContextPool.h>
#endif

NSString *const BulletXViewControllerLoadRequestDidFailedNotification = @"BulletXViewControllerLoadRequestDidFailedNotification";

#define BDX_NAVIGATION_BAR_HEIGHT 44.0f

// TODO: 删除lynx navi相关的代码，我们不做支持，但是需要再生命周期函数中调用lynx的pauseAni，enterAni等函数，前端可以写更复杂的动画 @倪浩
@interface BDXViewController ()
<BDXContainerLifecycleProtocol,
//LynxHolder,
UIGestureRecognizerDelegate>

- (instancetype)initWithRequestURL:(nullable NSURL *)url config:(nullable BDXPageSchemaParam *)configuration context:(BDXContext *)context;

@end

@BDXSERVICE_REGISTER(BDXPageContainerService);

@implementation BDXPageContainerService

+ (BDXServiceScope)serviceScope
{
    return BDXServiceScopeGlobalDefault;
}

+ (BDXServiceType)serviceType
{
    return BDXServiceTypeContainerPage;
}

+ (NSString *)serviceBizID
{
    return DEFAULT_SERVICE_BIZ_ID;
}

- (nullable id<BDXPageContainerProtocol>)create:(NSString *_Nonnull)url context:(nullable BDXContext *)context
{
    NSString *bid = [context getObjForKey:kBDXContextKeyBid];
    Class schemaClz = BDXSERVICE_CLASS_WITH_DEFAULT(BDXSchemaProtocol, bid);

    if (class_conformsToProtocol(schemaClz, @protocol(BDXSchemaProtocol))) {
        if (!context) {
            context = [[BDXContext alloc] init];
        }
        BDXPageSchemaParam *config = (BDXPageSchemaParam *)[schemaClz resolverWithSchema:[NSURL URLWithString:url] contextInfo:context paramClass:BDXPageSchemaParam.class];
        BDXViewController *pageContainer = [[BDXViewController alloc] initWithRequestURL:config.resolvedURL config:config context:context];
        return pageContainer;
    }
    return nil;
}

- (nullable id<BDXPageContainerProtocol>)open:(NSString *_Nonnull)url context:(nullable BDXContext *)context
{
    id<BDXPageContainerProtocol> container = [self create:url context:context];
    if ([container isKindOfClass:BDXViewController.class]) {
        BDXViewController *page = (BDXViewController *)container;
        UIViewController *top = [BTDResponder topViewController];
        if (top && top.navigationController) {
            [top.navigationController pushViewController:page animated:YES];
        }
        return page;
    }
    return nil;
}

@end

@interface BDXViewController ()

@property(nonatomic, assign) UIStatusBarStyle originStatusBarStyle;

@property(nonatomic, strong) UIColor *originStatusBarBackgroundColor;
@property(nonatomic, strong) UIView *statusBarBackgroundView;

@property(nonatomic, assign) BOOL originNavigationBarHidden;
@property(nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property(nonatomic, assign) BOOL statusBarHiddenStatus;

@property(nonatomic, strong) NSURL *originURL;
@property(nonatomic, assign) BOOL isContainerReady;

@property(nonatomic, strong) UIView<BDXNavigationBarProtocol> *navigationBar;

@property(nonatomic, weak) id<UIGestureRecognizerDelegate> oldDelegate;

// 关联弹窗
@property(nonatomic, assign) BOOL hasExecuteDidAppearedOnce;
@property(nonatomic, assign) BOOL isAppearing;
@property(nonatomic, strong) BDXView *viewContainer;
@property(nonatomic, strong) BDXPageSchemaParam *config;

// For navi
@property(nonatomic, strong) NSData *data;
@property(nonatomic, assign) BOOL isUsing;
@property(nonatomic, copy) NSString *url;

@end

@implementation BDXViewController

@synthesize hybridInBackground;
@synthesize hybridAppeared;
@synthesize containerLifecycleDelegate;
@synthesize context;

- (BOOL)close:(nullable NSDictionary *)params
{
    return [self close:params completion:nil];
}

- (BOOL)close:(nullable NSDictionary *)params completion:(nullable dispatch_block_t)completion
{
    if ([BTDResponder isTopViewController:self]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        NSMutableArray *stack = [self.navigationController.viewControllers mutableCopy];
        [stack removeObject:self];
        [self.navigationController setViewControllers:[stack copy]];
    }
    if (completion) {
        completion();
    }
    return YES;
}

- (void)dealloc
{
//    [[LynxNavigator sharedInstance] unregisterLynxHolder:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if __has_include(<Lynx/BDLynxContextPool.h>)
    [[BDLynxContextPool sharedInstance] removeContext:[NSString stringWithFormat:@"%@%@", self.originURL.absoluteString, kBulletContextMetaResourceKey]];
#endif
}

- (instancetype)initWithRequestURL:(NSURL *)url config:(BDXPageSchemaParam *)config context:(BDXContext *)context
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.hidesBottomBarWhenPushed = YES;
        _originURL = url;
        _config = config;
        _isContainerReady = NO;
        _statusBarHiddenStatus = config.hideStatusBar;
        _statusBarStyle = config.statusFontMode;
        _hasExecuteDidAppearedOnce = NO;
        self.hybridInBackground = NO;
        self.oldDelegate = nil;
        self.context = context;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getNotificationAction:) name:kBulletXNotificationConfigireStatusBar object:nil];
        [self.lifeCycleTracker trackLifeCycleWithEvent:@"vc_init_start_time"];

        id<BDXContainerLifecycleProtocol> containerLifecycleDelegate = [context getObjForKey:kBDXContextKeyContainerLifecycleDelegate];
        if (containerLifecycleDelegate) {
            self.containerLifecycleDelegate = containerLifecycleDelegate;
        }
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.oldDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;
    [self.lifeCycleTracker trackLifeCycleWithEvent:@"vc_view_did_load"];
    [self __setDefaultBackgroundColor];
    [self __setupLoadingBackgroundColor];
    [self __setupViewContainer];
    if(self.config.disableSwipe){
        [self __disableLeftPanPop];
    }
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if(!CGSizeEqualToSize(self.config.preferredSize, CGSizeZero)){
        self.preferredContentSize = self.config.preferredSize;
    }

    self.automaticallyAdjustsScrollViewInsets = NO;
    [self loadURL:self.originURL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    // TODO:Check
    // web 场景控制关闭按钮
    // @weakify(self);
    // [self.KVOController observe:self.bulletView.container
    // keyPath:NSStringFromSelector(@selector(canGoBack))
    // options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id
    // _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
    // @strongify(self);
    // if (self.bulletView.kitInstance.kitApi.apiType == BulletXKitApiTypeWeb) {
    // self.navigationBar.closeNaviButton.hidden =
    // !self.bulletView.container.canGoBack;
    // }
    // }];
}

- (void)handleViewDidAppear
{
    BulletXLog(@"lynx_test_bullet: %@, handleViewDidAppear", self.config.viewTag);
    if (self.isContainerReady) {
        [self.viewContainer handleViewDidAppear];
    }
}

- (void)handleViewDidDisappear
{
    [self.viewContainer handleViewDidDisappear];
}

- (void)handleBecomeActive
{
    BulletXLog(@"lynx_test_bullet: %@, handleBecomeActive", self.config.viewTag);
    self.hybridInBackground = NO;
    if ([BDXContainerUtil topBDXViewController] == self) {
        if (self.isContainerReady) {
            [self.viewContainer handleViewDidAppear];
        }
    }
}

- (void)handleResignActive
{
    BulletXLog(@"lynx_test_bullet: %@, handleResignActive", self.config.viewTag);
    self.hybridInBackground = YES;
    if ([BDXContainerUtil topBDXViewController] == self) {
        [self.viewContainer handleViewDidDisappear];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    // 修复BUG: present popup + page的情况，会导致page的右滑事件无效
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    [super viewWillAppear:animated];
    [self setStatusBarBackgroundColor:self.config.statusBarColor];
    self.originNavigationBarHidden = self.navigationController.navigationBarHidden;
    // use customized navigation bar
}

- (void)viewDidAppear:(BOOL)animated
{
    BulletXLog(@"lynx_test_bullet: %@, viewDidAppear", self.config.viewTag);
    [super viewDidAppear:animated];
    self.hybridAppeared = YES;
    self.originStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [self __updateStatusBarStatus];
    if (![self hasPopUpViewController]) {
        [self handleViewDidAppear];
    } else {
        if (!self.hasExecuteDidAppearedOnce) {
            [self handleViewDidAppear];
            [self handleViewDidDisappear];
        }
    }

    self.hasExecuteDidAppearedOnce = YES;
}

- (BOOL)hasPopUpViewController
{
    __block BOOL hasPopUp = NO;
    if (self.childViewControllers.count > 0) {
        [self.childViewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj conformsToProtocol:@protocol(BDXPopupContainerProtocol)]) {
                hasPopUp = YES;
                *stop = YES;
            }
        }];
    }

    return hasPopUp;
}

- (void)setStatusBarBackgroundColor:(UIColor *)color
{
    if (!color) {
        return;
    }

    if (@available(iOS 13.0, *)) {
        UIView *statusBar = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.windowScene.statusBarManager.statusBarFrame];
        [[UIApplication sharedApplication].keyWindow addSubview:statusBar];
        statusBar.backgroundColor = color;
        self.statusBarBackgroundView = statusBar;
    } else {
        UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
        if ([statusBar respondsToSelector:@selector(backgroundColor)]) {
            self.originStatusBarBackgroundColor = [statusBar backgroundColor];
        }

        if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
            statusBar.backgroundColor = color;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    // 修复BUG: present popup + page的情况，会导致page的右滑事件无效
    // 这个不能放在dealloc中，因为那时self.navigationController已经为空了
    self.navigationController.interactivePopGestureRecognizer.delegate = self.oldDelegate;
    [super viewWillDisappear:animated];
    [self __resetStatusBarStyle];
    [self __resetNavigationBarStyle];
}

- (void)viewDidDisappear:(BOOL)animated
{
    BulletXLog(@"lynx_test_bullet: %@, viewDidDisappear", self.config.viewTag);
    [super viewDidDisappear:animated];
    self.hybridAppeared = NO;
    if (![self hasPopUpViewController]) {
        [self handleViewDidDisappear];
    }
}

#pragma UI

- (BOOL)prefersStatusBarHidden
{
    if ([UIDevice btd_isIPhoneXSeries]) {
        return NO;
    }
    return self.statusBarHiddenStatus;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarStyle;
}

// TODO: popup不需要设置背景色吗?
- (void)__setupBackgroundColor
{
    if (self.config.containerBgColor) {
        self.view.backgroundColor = self.config.containerBgColor;
    } else {
        UIColor *bgColor = [self __defaultConatinerBackgroundColor];
        if (bgColor) {
            self.view.backgroundColor = bgColor;
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (void)__setupLoadingBackgroundColor
{
    if (self.config.loadingBgColor) {
        self.view.backgroundColor = self.config.loadingBgColor;
    } else {
        UIColor *bgColor = [self __defaultConatinerBackgroundColor];
        if (bgColor) {
            self.view.backgroundColor = bgColor;
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (void)__setDefaultBackgroundColor
{
    UIColor *bgColor = [self __defaultConatinerBackgroundColor];
    if (bgColor) {
        self.view.backgroundColor = bgColor;
    }
}

- (nullable UIColor *)__defaultConatinerBackgroundColor
{
    return [self.context getObjForKey:kBDXContextKeyContainerBackgroundColor];
}

- (void)__updateStatusBarStatus
{
    self.statusBarStyle = self.config.statusFontMode;
    [[UIApplication sharedApplication] setStatusBarStyle:self.statusBarStyle animated:YES];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)__resetStatusBarStyle
{
    // only config status bar style globaly need to reset style
    [[UIApplication sharedApplication] setStatusBarStyle:self.originStatusBarStyle animated:YES];
    if (@available(iOS 13.0, *)) {
        [self.statusBarBackgroundView removeFromSuperview];
    } else {
        if (self.originStatusBarBackgroundColor) {
            [self setStatusBarBackgroundColor:self.originStatusBarBackgroundColor];
        } else {
            [self setStatusBarBackgroundColor:UIColor.clearColor];
        }
    }
}

- (void)__resetNavigationBarStyle
{
    [self.navigationController setNavigationBarHidden:self.originNavigationBarHidden animated:YES];
}

- (void)__setupViewContainer
{
    CGFloat topOffset = 0;
    if (self.config.transStatusBar) {
        topOffset = 0;
    } else {
        if (!self.config.hideNavBar) {
            topOffset += BDX_NAVIGATION_BAR_HEIGHT;
        }
        if (!self.config.hideStatusBar || [UIDevice btd_isIPhoneXSeries]) {
            topOffset += BDX_STATUS_BAR_NORMAL_HEIGHT;
        }
    }

    [self.view addSubview:self.viewContainer];
    // use AutoLayout for non-fullscreen situation
    [self.viewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view).offset(topOffset);
    }];

    if (self.navigationBar) {
        [self.navigationBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(topOffset);
            make.top.left.right.equalTo(self.view);
        }];
    }
}

- (void)__setupNavigationBar
{
    if (self.config.hideNavBar || self.config.transStatusBar) {
        return;
    }

    self.navigationBar = [self.context getObjForKey:kBDXContextKeyNavBar];

    if (!self.navigationBar) {
        CGFloat statusBarHeight = [UIDevice btd_isIPhoneXSeries] ? 44.0f : 20.0f;
        CGFloat navigationBarHeight = 44.0f;
        self.navigationBar = [[BDXDefaultNavigationBar alloc] initWithFrame:CGRectMake(0, statusBarHeight, CGRectGetWidth([UIScreen mainScreen].bounds), (navigationBarHeight))];
    }

    if (self.navigationBar) {
        self.navigationBar.container = self;
        [self.navigationBar attachToContainerWithParams:self.config];
        [self.view addSubview:self.navigationBar];
    }
}

- (void)__disableLeftPanPop
{
    id target = self.navigationController.interactivePopGestureRecognizer.delegate;
    if (target) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:target action:nil];
        [self.view addGestureRecognizer:pan];
    }
}

- (void)getNotificationAction:(NSNotification *)notification
{
    NSDictionary *infoDic = [notification object];
    NSString *statusBarStyle = [infoDic btd_stringValueForKey:@"style"];
    BOOL visible = [[infoDic objectForKey:@"visible"] boolValue];
    if ([statusBarStyle isEqualToString:@"light"]) {
        self.statusBarStyle = UIStatusBarStyleLightContent;
    } else if ([statusBarStyle isEqualToString:@"dark"]) {
        if (@available(iOS 13.0, *)) {
            self.statusBarStyle = UIStatusBarStyleDarkContent;
        } else {
            // Fallback on earlier versions
        }
    }

    self.statusBarHiddenStatus = !visible;
    [[UIApplication sharedApplication] setStatusBarStyle:self.statusBarStyle animated:YES];
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Public

- (void)loadURL:(NSURL *)url
{
    if (url == nil) {
        return;
    }

    if (self.originURL == nil) {
        self.originURL = url;
    }

    // check mega_object
    // https://bytedance.feishu.cn/docs/doccnhasFnXLrCyJ6AgNB3K5BLe
    //  NSString *URLString = url.absoluteString;
    //// TODO:Check
    // NSMutableDictionary* paramsDict = [URLString
    // bullet_queryDictWithEscapes:YES].mutableCopy; NSString *megaObjectKey =
    // @"bullet_mega_object"; NSString *megaObjectJSONString = [paramsDict
    // btd_stringValueForKey:megaObjectKey]; if
    // (!BTD_isEmptyString(megaObjectJSONString)) { id megaObjectJSON =
    // [megaObjectJSONString btd_jsonValueDecoded]; if ([megaObjectJSON
    // isKindOfClass:NSDictionary.class]) { [paramsDict
    // removeObjectForKey:megaObjectKey]; NSString *key = [NSUUID
    // UUID].UUIDString; [BulletXMegaObject recordMegaObject:megaObjectJSON
    // withKey:key]; paramsDict[@"bullet_mega_object_id"] = key; URLString =
    // [[NSString stringWithFormat:@"%@://%@", URLString.bullet_scheme,
    // URLString.bullet_path] bullet_stringByAddingQueryDict:paramsDict]; url =
    // [NSURL URLWithString:URLString];
    // }
    // }

    // Don't change the following code calling sequence !!!!!!!!!
    //  [self.bulletView configGlobalProps:self.config.globalProps];
    [self.viewContainer loadWithParam:self.config context:self.context];
}

- (void)reload
{
    [self.viewContainer reloadWithContext:self.context];
}

- (void)reloadWithContext:(BDXContext *)context
{
    [self.viewContainer reloadWithContext:context];
}

- (void)updateTitle:(NSString *)title
{
    [self.navigationBar updateTitle:title];
}

- (void)registerXBridgeMethod:(NSArray<Class> *)bridgeMethods
{
    [self.viewContainer.kitView registerXBridgeMethod:bridgeMethods];
}

#pragma mark - BulletLifecycle

- (void)container:(id<BDXContainerProtocol>)container didFinishLoadWithURL:(NSString *_Nullable)url
{
    BulletXLog(@"lynx_test_bullet: %@, didFinishLoadWithURL", self.config.viewTag);
    [self __setupBackgroundColor];
    self.isContainerReady = YES;
    if (!self.hybridInBackground && self.hasExecuteDidAppearedOnce) {
        [self.viewContainer handleViewDidAppear];
    }
}

// TODO:Check
// - (void)loadRequestDidCompleted:(BDXContext *)context
// inInstance:(BulletKitInstance *)instance
// {
//// register Navigator
// if ([instance.kitBaseView
// isKindOfClass:NSClassFromString(@"BulletXLynxView")]) {
// self.fpsLabel.currentEngine = BulletXEngineTypeLynx;
// BulletXLynxView *bulletLynxContainer = (BulletXLynxView
// *)instance.kitBaseView;
// [[LynxNavigator sharedInstance] registerLynxHolder:self
// initLynxView:bulletLynxContainer.lynxView]; } else if ([instance.kitBaseView
// conformsToProtocol:@protocol(IESWebViewProtocol)]) {
// self.fpsLabel.currentEngine = BulletXEngineTypeWeb;
// }
// }
//
// if (_navigationBar && instance.kitApi.apiType == BulletKitApiTypeWeb &&
// [self.bulletView.container
// respondsToSelector:@selector(evaluateJavaScript:completionHandler:)]) {
// @weakify(self);
// [self.bulletView.container evaluateJavaScript:@"document.title"
// completionHandler:^(NSString *title, NSError * _Nullable error) {
// @strongify(self);
// }];
// }
// }

- (void)handleContainerClose
{
}

- (BOOL)shouldAnimateWhenClose
{
    return YES;
}

#pragma mark - Getter & Setter

- (BDXView *)viewContainer
{
    if (!_viewContainer) {
        CGSize size = [[UIScreen mainScreen] bounds].size;
        _viewContainer = [[BDXView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        _viewContainer.containerLifecycleDelegate = self;
        _viewContainer.bdxContentMode = BDXViewContentModeFixedSize;
    }
    
    return _viewContainer;
}

// TODO:Check
// For Lynx Navi
// - (LynxView *)createLynxView:(LynxRoute *)route {
// return [self processSchema:route.templateUrl param:route.param];
// }
//
// - (void)showLynxView:(LynxView *)lynxView name:(NSString *)name {
// [self.view addSubview:lynxView];
// }
//
// - (void)hideLynxView:(LynxView *)lynxView {
// [[BDLynxContextPool sharedInstance] removeContext:lynxView.url];
// [lynxView removeFromSuperview];
// }

// - (LynxView *)processSchema:(NSString *)url param:(NSDictionary *)params {

// BDLynxViewBaseParams *param = [BDLynxParams getBaseParam:url];
//
// IESSparesLynxConfig *config = [IESSparesLynxConfig new];
// config.heightMode = BDLynxViewSizeModeExact;
// config.widthMode = BDLynxViewSizeModeExact;
//// TODO @fulei add resource loader
// BulletXLynxView *lynxCard = [[BulletXLynxView alloc]
// initWithFrame:self.view.bounds config:param kitInstance:nil
// resource:nil]; [lynxCard sendGlobalProps:self.config.globalProps];
// lynxCard.containerConfig = config;
// lynxCard.config = param;
// NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];
// [queryDict addEntriesFromDictionary:[url btd_queryParamDict]];
// [queryDict addEntriesFromDictionary:params];
// lynxCard.config.spares_queryItems = [queryDict copy];
// lynxCard.config.initialProperties = params;
// [lynxCard initSetupWithConfig:param];
//
// [[BDLynxContextPool sharedInstance] addLynxContext:lynxCard
// schema:param.sourceUrl];
//
// if (lynxCard) {
// return lynxCard.lynxView;
// }
// return nil;
// }

- (NSString *)containerID
{
    if (self.viewContainer && [self.viewContainer conformsToProtocol:@protocol(BDXContainerProtocol)]) {
        return self.viewContainer.containerID ?: @"";
    }
    return @"";
}

- (BDXEngineType)viewType
{
    return self.viewContainer.viewType;
}

- (UIView<BDXKitViewProtocol> *)kitView
{
    return self.viewContainer.kitView;
}

- (id<BDXMonitorProtocol>)lifeCycleTracker
{
    id<BDXMonitorProtocol> lifeCycleTracker = [self.context getObjForKey:@"lifeCycleTracker"];
    if (!lifeCycleTracker) {
        // every bdxview has its own tracker , thus init tracker manually.
        Class monitorClass = BDXSERVICE_CLASS(BDXMonitorProtocol, nil);
        lifeCycleTracker = [[monitorClass alloc] init];
        [self.context registerStrongObj:lifeCycleTracker forKey:@"lifeCycleTracker"];
    }
    
    return lifeCycleTracker;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return !self.config.disableSwipe;
}

#pragma mark BDXContainerLifecycleDelegate message forward

- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL ret = [super respondsToSelector:aSelector];
    if (!ret) {
        ret = [self.containerLifecycleDelegate respondsToSelector:aSelector];
    }
    return ret;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL sel = invocation.selector;
    if ([self.containerLifecycleDelegate respondsToSelector:sel]) {
        [invocation setArgument:(void *)(&self) atIndex:2];
        [invocation invokeWithTarget:self.containerLifecycleDelegate];
    }
}

@end
