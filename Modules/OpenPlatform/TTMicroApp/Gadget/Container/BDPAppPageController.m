//
//  BDPAppPageController.m
//  Timor
//
//  Created by 王浩宇 on 2018/11/18.
//

#import "BDPAppPageController.h"
#import "BDPAppPage+BDPNavBarAutoChange.h"
#import "BDPAppPage+BDPPullRefresh.h"
#import "BDPAppPage+BDPScroll.h"
#import "BDPAppPageURL.h"
#import "BDPAppRouteManager.h"
#import <OPFoundation/BDPApplicationManager.h>
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPDeviceManager.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import "BDPNavigationController.h"
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPResponderHelper.h>
#import "BDPTaskManager.h"
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import "UIViewController+Navigation.h"
#import <OPFoundation/UIViewController+TMATrack.h>
#import "BDPAppPage+BDPTextArea.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPTracingManager.h>
#import "BDPTabBarPageController.h"
#import <OPPluginManagerAdapter/BDPJSBridgeCenter.h>

#import <OPFoundation/EEFeatureGating.h>
#import <OPSDK/OPSDK-Swift.h>
#import "OPNoticeView.h"
#import <ECOInfra/EMANetworkManager.h>
#import <KVOController/KVOController.h>
#import "OPNoticeManager.h"
#import "OPNoticeModel.h"
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import "BDPSubPackageManager.h"
#import "BDPLeaveComfirmModel.h"
#import "BDPXScreenNavigationBar.h"
#import "BDPXScreenManager.h"
#import "BDPPerformanceProfileManager.h"
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPTracingManager+Gadget.h"

static CGFloat kXScreenNaviBarHeight = 48.f;

@interface BDPAppPageController ()<OPNoticeViewDelegate>

@property (nonatomic, strong, readwrite) BDPAppPageURL *page;
/** 如果onAppPage的时候还没有AppPage或者pageManager中没登记, 就会记录下openType */
@property (nonatomic, copy) NSString *openType;
@property (nonatomic, copy) NSDictionary *vdom;
@property (nonatomic, strong) BDPTracing *lifeCycleTrace;

@property (nonatomic, weak, nullable) OPContainerContext *containerContext;
@property (nonatomic, strong) OPNoticeView *noticeView;

@property (nonatomic, assign) BOOL gagdetTakeoverBackEvent;
@property (nonatomic, strong) BDPLeaveComfirmModel *leaveComfirm;
@property (nonatomic, assign) BOOL  disableSetDarkColorInInit; //只有FG为YES，非暗黑模式（系统非暗黑或小程序不支持暗黑或关闭暗黑）下，在Init中不设置view背景颜色，移到viewDidload；默认是NO，在Init 中设置背景颜色;

@property (nonatomic, strong) BDPXScreenNavigationBar *XScreenNaviBar;
@property (nonatomic, strong) CAShapeLayer *XScreenMaskLayer;

@end

@implementation BDPAppPageController

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID pageURL:(NSString *)pageURL containerContext:(OPContainerContext *)containerContext
{
    return [self initWithUniqueID:uniqueID page:[[BDPAppPageURL alloc] initWithURLString:pageURL] containerContext:containerContext];
}

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID page:(BDPAppPageURL *)page containerContext:(OPContainerContext *)containerContext
{
    return [self initWithUniqueID:uniqueID page:page vdom:nil containerContext:containerContext];
}

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID page:(BDPAppPageURL *)page vdom:(NSDictionary *)vdom containerContext:(OPContainerContext *)containerContext
{
    self = [super init];
    if (self) {
        _uniqueID = uniqueID;
        _performanceMonitor = [BDPPerformanceMonitor<TMAPageTiming> new];
        _page = page;
        _vdom = [vdom copy];
        self.containerContext = containerContext;
        
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
        _page.path = [self checkPath:_page.path default:task.config.entryPagePath];
        _statusBarHidden = NO;
        _gagdetTakeoverBackEvent = NO;
        _canShowHomeButton = YES;
        if (BDPIsEmptyDictionary(vdom)) {
            _pageConfig = [[task.config getPageConfigByPath:_page.path] copy];
        }
        _pageOrientation = GadgetMetaOritationNotSet;
        _pageInterfaceOrientation = UIInterfaceOrientationPortrait;
        if ([OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
            _pageOrientation = [self currentPageOrientationWithAppConfig:task.config pageConfig:_pageConfig];
        }
        BDPLogInfo(@"%@ pageOrientation: %zd", _page.path, _pageOrientation);
        // EntryPage即首屏, 只有首屏才在初始化时创建AppPage, 其他Tab页或二级界面, 都在viewDidLoad时才创建. 首屏主线程少干事
        // vdom 的时候也提前创建
        if (!BDPIsEmptyDictionary(vdom) || [task.config.entryPagePath isEqualToString:page.path]) {
            [self setupAppPageIfNeed];
        }
        // init 中调用self.view 会导致viewDidLoad 提前执行
        _disableSetDarkColorInInit = [self isDisableThemeColorInInit];
        if (!_disableSetDarkColorInInit) {
            [self setupContainerViewThemeColor];
        }

    }
    return self;
}

- (void)setupAppPageIfNeed
{
    if (!self.appPage) {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
        self.appPage = [task.pageManager dequeueAppPage];
        self.appPage.appPageDelegate = (id<BDPAppPageProtocol>)task.containerVC;
        self.appPage.bap_config = task.config;
        self.appPage.bap_path = self.page.path;
        self.appPage.bap_queryString = self.page.queryString;
        self.appPage.bap_absolutePathString = self.page.absoluteString;
        self.appPage.disableSetDarkColorInInit = self.disableSetDarkColorInInit;
    }
}

- (void)setupContainerViewThemeColor {
    // 防止切换tab闪动时背景色和和webview的背景色不一致(大色差时)导致的闪动问题
    // 备注:放在viewdidload或loadView中都不行
    UIColor *themeColor = [self containerViewThemeColor];
    if (themeColor) {
        self.view.backgroundColor = themeColor;
    }
}

// 是否 在Init中初始化view 的backgroundColor
// 默认NO，在Init 初始化； YES，在ViewDidLoad中初始化
- (BOOL)isDisableThemeColorInInit {
    if(!OPSDKFeatureGating.disableSetThemeColorInInit){
        return NO;
    }
    // 当前是系统是暗黑模式，小程序支持暗黑模式，FG允许小程序开启Dark Mode, 设置背景颜色
    if(self.uniqueID.isAppDarkMode){
        return NO;
    }
    // 非暗黑模式下禁止init 中初始化view 的背景色
    return YES;
}

- (void)dealloc
{
    BDPLogInfo(@"appPageController dealloc, app=%@", self.uniqueID);
    [self.appPage bdp_removePageObserver];

    // 将自己所持有的appPage(webview)对象标识为预期销毁
    [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedDestroy for:self.appPage];
}

#pragma mark - View & Layout
/*-----------------------------------------------*/
//          View & Layout - 加载及布局相关
/*-----------------------------------------------*/
- (void)viewDidLoad
{
    [super viewDidLoad];
    // 如果FG禁止初始化设置背景色，就再viewDidload 中设置
    if (self.disableSetDarkColorInInit) {
        [self setupContainerViewThemeColor];
    }
    [self.performanceMonitor timing_pageStart];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tmaTrackStayEnable = YES;
    
    [self setupViews];
    [self setupPlugins];
    
    // 开启滑动刷新
    if ([self.pageConfig.window.enablePullDownRefresh boolValue]) {
        self.appPage.scrollView.bounces = YES;
    }
    
    // 禁用页面滑动
    if ([self.pageConfig.window.disableScroll boolValue]) {
        self.appPage.scrollView.scrollEnabled = NO;
    }

    if([self.appPage bdp_enableNavBarAutoChangeIfNeed]) {
        WeakSelf;
        [self.appPage setBap_updateCallBack:^(CGFloat alpha, BOOL transparnt) {
            StrongSelfIfNilReturn;
            [self updateViewControllerStyle:YES];
        }];
    }

    if (self.pageConfig.window.navigationBarBgTransparent) {
        // 由于导航栏实际上不透明，此时需要VC布局渗透上方导航栏，但是避免渗透下方的tabbar
        self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeRight | UIRectEdgeTop;
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    
    if (self.containerContext.apprearenceConfig.forceExtendedLayoutIncludesOpaqueBars) {
        self.extendedLayoutIncludesOpaqueBars = YES;
    }

    if ([OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
        self.pageInterfaceOrientation = [OPGadgetRotationHelper currentDeviceOrientation];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view setNeedsLayout];
    BDPTracing *appTracing = [BDPTracingManager.sharedInstance getTracingByUniqueID:self.uniqueID];
    self.lifeCycleTrace = [BDPTracingManager.sharedInstance generateTracingWithParent:appTracing];
    [self.appPage webviewWillAppear];
    
    [self recoverAppPageFrameIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self adjustInterfaceOrientation];
    [self.performanceMonitor timing_pageNavigationComplete];
    BDPMonitorWithCode(GDMonitorCodeLifecycle.page_appear, self.uniqueID)
    .bdpTracing(self.lifeCycleTrace)
    .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar)
    .flush();
    self.isAppeared = YES;
    self.hadDidAppeared = YES;

    //BDPJSBridgeCenter registerContextMethod方法里是根据uniqueid等来作为key存储handler的，
    //同一个小程序有新页面push之后，本页面的注册会失效，所以需要每次在viewDidAppear的时候需要重新注册
    //详见：https://bytedance.feishu.cn/docs/doccn7VURN8d7D2eeIYnVvUKUfc#
    [self setupPlugins];

    // 开启滑动刷新， 每次在viewDidAppear的时候需要重新注册，不然会导致之前注册的界面失效。
    if ([self.pageConfig.window.enablePullDownRefresh boolValue]) {
        [self.appPage bap_registerPullToRefreshWithUniqueID:self.uniqueID];
        [self.appPage bdp_enablePullToRefresh];
    }

    // 每次viewDidAppear时设置一次page的dataLoadErrorHandleDelegate代理，刷新一次错误
    if (self.appPage) {
        self.appPage.dataLoadErrorHandleDelegate = self;
    }
    
    [[NSNotificationCenter defaultCenter]postNotificationName:kBDPSwitchPageNotification object:nil userInfo:@{kBDPPageVCKey:self,kBDPIsPageLeavingKey:[NSNumber numberWithBool:NO]}];
    // Enter Page之后lastHasWebView状态重置
    [BDPTracker beginLogPageView:self.page.path query:self.page.queryString hasWebview:self.appPage.isHasWebView uniqueID:self.uniqueID];
    
    /// 如果failedRefreshView仍然显示，则toolBar的颜色需要重新刷新一下，呈现反色
    if (self.failedRefreshViewIsOn && self.toolBarView != nil) {
        self.toolBarView.moreButton.tintColor = UDOCColor.iconN1;
        self.toolBarView.closeButton.tintColor = UDOCColor.iconN1;
    }
    
    if(self.appPage){
        [self.appPage pageDidAppear];
    }
    [self.appPage webviewDidAppear];
    
    // 补偿dm/lm调用缺失
    if ([OPSDKFeatureGating enableCompensateTraitCollectionDidChange]) {
        [self compensateTraitCollectionDidChange];
    }

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 这里处理VC的逻辑
    // 组件需要关心appPage viewWillDisappear的事件
    [self.appPage webviewWillDisappear];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.isAppeared = NO;
    
    // 当切换新页面时，之前的页面下拉刷新无法结束，对齐微信实现，将当前页面的下拉刷新结束
    if ([self.pageConfig.window.enablePullDownRefresh boolValue]) {
        [self.appPage.scrollView tmaFinishPullDownWithSuccess:YES];
    }
    
    [self eventStayPage];
    [[NSNotificationCenter defaultCenter]postNotificationName:kBDPSwitchPageNotification object:nil userInfo:@{kBDPPageVCKey:self,kBDPIsPageLeavingKey:[NSNumber numberWithBool:YES]}];
    [self.appPage webviewDidDisappear];
    BDPMonitorWithCode(GDMonitorCodeLifecycle.page_disappear, self.uniqueID)
    .bdpTracing(self.lifeCycleTrace)
    .setPlatform(OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea)
    .flush();
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        self.view.layer.mask = self.XScreenMaskLayer;
    } else {
        self.view.layer.mask = nil;
    }

    if ([OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
        self.pageInterfaceOrientation = [OPGadgetRotationHelper currentDeviceOrientation];
    }

    /// toolBar保持置顶，在任何情况下都保持在最上方
    if (self.toolBarView) {
        [self.view bringSubviewToFront:self.toolBarView];
    }
    
    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        CGFloat XScreenMaskHeight = [BDPXScreenManager XScreenAppropriateMaskHeight:self.uniqueID];
        CGFloat XScreenPresentHeight = [BDPXScreenManager XScreenAppropriatePresentationHeight:self.uniqueID];

        /*
         处理别的Native页面dismiss时(发现问题是选择联系人页面)，在有Tabbar组件的小程序出现时系统将self.view高度改小的问题
         bug单:https://meego.feishu.cn/larksuite/issue/detail/5500842?parentUrl=%2Flarksuite%2FissueView%2Fj1ZvyBxbrF
         这里的逻辑尽量限制到与showTabBar/hideTabBar控制的范围一致，只处理单tab的首页
         关于时机:viewwillappear的时机过早，viewdidappear会有肉眼可见的抖动
         这里需要包含页面处于编辑的情况，否则键盘消失后，依旧会出现高度不够导致响应区域不正确的问题
         详情请参见
         BDPTabBarPageController - (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)(BOOL))completion
         */
        if ([self.tabBarController isKindOfClass:[BDPTabBarPageController class]] && self.navigationController.viewControllers.firstObject == self) {
            self.view.bdp_height = XScreenPresentHeight;
        }
        
        [self.view setFrame:CGRectMake(0, XScreenMaskHeight, self.view.bdp_width, XScreenPresentHeight)];
        
        // 在可编辑场景下，需要锁定apppage的frame
        if (!self.appPage.bap_lockFrameForEditing) {
            
            /*
             对于普通小程序而言，self.tabBarController为主Tabbar，在小程序打开的情况，tabbar被系统隐藏，之前的逻辑只是凑巧命中了该逻辑，从实际语义看是错误的，也是存在风险的。
             对于主导航小程序而言，不能命中BDPTabBarPageController相关逻辑
            */

            // 过滤主导航和普通小程序
            BOOL isAppWithTabbar = [self.tabBarController isKindOfClass:[BDPTabBarPageController class]];
            if (isAppWithTabbar) {
                /* self.view.bounds.size.height在tabbar重新present时会多次刷新，如果appPage的height由此计算得来可能会造成闪动
                 */
                CGFloat hideTabBarOffsetY = UIScreen.mainScreen.bounds.size.height - self.view.frame.origin.y;
                CGFloat showTabBarOffsetY = UIScreen.mainScreen.bounds.size.height - self.tabBarController.tabBar.bdp_height - self.view.frame.origin.y;
                BOOL isRootVC = (self.navigationController.viewControllers.firstObject == self);
                
                /* 此前逻辑存在异常，未提前判断self.tabBarController，出现递归到最外层tabbar的情况，当前判断确认是BDPTabBarPageController
                 */
                CGFloat appPageHeight = (self.tabBarController.tabBar.isHidden || !isRootVC)? hideTabBarOffsetY : showTabBarOffsetY;
                
                CGFloat topOffset = [self navigationBarHidden] ? 0 : kXScreenNaviBarHeight;
                if (![self navigationBarHidden] && [self navigationBarTransparent]) {
                    topOffset = 0;
                }
                CGSize expectSize = CGSizeMake(self.view.bounds.size.width, appPageHeight - topOffset);
                if (!CGSizeEqualToSize(self.appPage.frame.size, expectSize)) {
                    self.appPage.frame = CGRectMake(self.appPage.frame.origin.x, topOffset, expectSize.width, expectSize.height);
                }
            } else {
                // 位置不变，大小跟随
                // 避免频繁触发Page的高度变更
                CGFloat topOffset = [self navigationBarHidden] ? 0 : kXScreenNaviBarHeight;
                CGSize expectSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height - topOffset);
                if (!CGSizeEqualToSize(self.appPage.frame.size, expectSize)) {
                    self.appPage.frame = CGRectMake(self.appPage.frame.origin.x, topOffset, expectSize.width, expectSize.height);
                }
            }
        }
        
    } else {
        
        /*
         处理别的Native页面dismiss时(发现问题是选择联系人页面)，在有Tabbar组件的小程序出现时系统将self.view高度改小的问题
         bug单:https://meego.feishu.cn/larksuite/issue/detail/5500842?parentUrl=%2Flarksuite%2FissueView%2Fj1ZvyBxbrF
         这里的逻辑尽量限制到与showTabBar/hideTabBar控制的范围一致，只处理单tab的首页
         关于时机:viewwillappear的时机过早，viewdidappear会有肉眼可见的抖动
         这里需要包含页面处于编辑的情况，否则键盘消失后，依旧会出现高度不够导致响应区域不正确的问题
         详情请参见
         BDPTabBarPageController - (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)(BOOL))completion
         */
        if ([self.tabBarController isKindOfClass:[BDPTabBarPageController class]] && self.navigationController.viewControllers.firstObject == self) {
            self.view.bdp_height = self.tabBarController.view.bdp_height;
        }
        
        // 在可编辑场景下，需要锁定apppage的frame
        if (!self.appPage.bap_lockFrameForEditing) {
            
            /*
             对于普通小程序而言，self.tabBarController为主Tabbar，在小程序打开的情况，tabbar被系统隐藏，之前的逻辑只是凑巧命中了该逻辑，从实际语义看是错误的，也是存在风险的。
             对于主导航小程序而言，不能命中BDPTabBarPageController相关逻辑
            */
            
            // 过滤主导航和普通小程序
            BOOL isAppWithTabbar = [self.tabBarController isKindOfClass:[BDPTabBarPageController class]];
            if (isAppWithTabbar) {
                /* self.view.bounds.size.height在tabbar重新present时会多次刷新，如果appPage的height由此计算得来可能会造成闪动
                 */
                
                /*
                 iPad present的场景下，容器VC并不占满屏幕的高度，目前已知场景只有该场景
                 判断本身并不完全可靠，获取tabbarVC的高度更为稳妥
                */
                CGFloat outerTabbarControllerViewHeight = UIScreen.mainScreen.bounds.size.height;
                if ([EEFeatureGating boolValueForKey: EEFeatureGatingKeyIGadgetPresentFrameFixEnable]) {
                    outerTabbarControllerViewHeight = self.tabBarController.view.bdp_height;
                }
                CGFloat hideTabBarOffsetY = outerTabbarControllerViewHeight - self.view.frame.origin.y;
                CGFloat showTabBarOffsetY = outerTabbarControllerViewHeight - self.tabBarController.tabBar.bdp_height - self.view.frame.origin.y;
                BOOL isRootVC = (self.navigationController.viewControllers.firstObject == self);
                
                /* 此前逻辑存在异常，未提前判断self.tabBarController，出现递归到最外层tabbar的情况，当前判断确认是BDPTabBarPageController
                 */
                CGFloat appPageHeight = (self.tabBarController.tabBar.isHidden || !isRootVC)? hideTabBarOffsetY : showTabBarOffsetY;
                CGSize expectSize = CGSizeMake(self.view.bounds.size.width, appPageHeight);
                if (!CGSizeEqualToSize(self.appPage.frame.size, expectSize)) {
                    self.appPage.frame = CGRectMake(self.appPage.frame.origin.x, self.appPage.frame.origin.y, expectSize.width, expectSize.height);
                }
            } else {
                // 位置不变，大小跟随
                // 避免频繁触发Page的高度变更
                if (!CGSizeEqualToSize(self.appPage.frame.size, self.view.bounds.size)) {
                    self.appPage.frame = CGRectMake(self.appPage.frame.origin.x, self.appPage.frame.origin.y, self.view.bounds.size.width, self.view.bounds.size.height);
                }
            }
        }
    }

    [self layoutNavigationBarIfNeeded];
    if (self.bottomBar) {
        self.bottomBar.bdp_bottom = self.view.bdp_height;
        self.appPage.bdp_height -= self.bottomBar.bdp_height;
    }
    if(self.noticeView && ![self navigationBarHidden]){
        self.appPage.bdp_height -= self.noticeView.bdp_height;
    }
}

-(void)viewDidLayoutSubviews
{
    if ([OPSDKFeatureGating shouldFixToolBarPosition:self.uniqueID]) {
        // 新逻辑不再执行下面的逻辑
        return;
    }
    UINavigationItem * item=self.navigationItem;
    NSArray * array=item.rightBarButtonItems;
    if (array&&array.count!=0){
        //这里需要注意,你设置的第一个leftBarButtonItem的customeView不能是空的,也就是不要设置UIBarButtonSystemItemFixedSpace这种风格的item
        UIBarButtonItem * buttonItem=array[0];
        UIView * view =[[[buttonItem.customView superview] superview] superview];
        NSArray * arrayConstraint=view.constraints;
        for (NSLayoutConstraint * constant in arrayConstraint) {
            //在plus上这个值为20
            if (fabs(constant.constant)==20 || fabs(constant.constant)== 16) {
                constant.constant= -6;
            }
        }
    }
}

- (void)recoverAppPageFrameIfNeeded {
    // 半屏功能开启时，从半屏切换到全屏,尝试先还原下origin.y（在全屏下,诸如BDPInputView，也会对小程序webview的y做置0操作）。
    if ([BDPXScreenManager isXScreenFGConfigEnable] && ![BDPXScreenManager isXScreenMode:self.uniqueID]) {
        if (self.appPage.bdp_top != 0) {
            self.appPage.bdp_top = 0;
        }
        
        // 存在通知的情况下，需要下移
        if (![EEFeatureGating boolValueForKey: EEFeatureGatingKeyResetFrameFixDisable]) {
            if(self.noticeView && ![self navigationBarHidden]){
                self.appPage.bdp_top = self.noticeView.bdp_height;
            }
        }
    }
}

#pragma mark - NavigationBar Style

- (void)layoutNavigationBarIfNeeded
{
    // 因为在BDPAppPageAnimatedTransitioning,依赖了toolBarView的frame来进行动画，所以这里不改为autolayout了
    // 原始toolBarView在viewdidload里拿view的frame,实际是不准的，所以适配iPad利用viewWillLayoutSubviews方法修改自定义toolBarView的frame即可
    if (self.toolBarView && [self navigationBarHidden]) {
        // iOS原始逻辑：adaptTop = isLandscape ? 15 : ([BDPDeviceHelper isIPhoneXSeriesDevice] ? [UIApplication sharedApplication].delegate.window.safeAreaInsets.top + 6 : 26);
        // 经过询问：原始需求是，有刘海屏的才拿safeAreaInsets去适配，所以不需要判断isIPhoneXSeriesDevice（比较脆，新增机型就不适配了）
        // iPad采取竖屏布局方式
        BOOL isLandscape = !([BDPDeviceHelper isPadDevice]) && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);

        if ([OPSDKFeatureGating gadgetUseStatusBarOrientation]) {
            // 这边使用UIApplication的statuBarOrientation替换UIDevice的方向
            // 小程序预期获取的是界面是否为横屏
            isLandscape = ![OPGadgetRotationHelper isPad] && [OPGadgetRotationHelper isLandscape];
        }

        CGFloat safeAreaTop = [BDPResponderHelper safeAreaInsets:self.view.window].top;
        CGFloat adaptTop = isLandscape ? 15 : safeAreaTop == 0 ? 26 : safeAreaTop;

        CGFloat toolbarViewHeight = self.toolBarView.bdp_height;
        // 支持横竖屏时, 需要动态获取toolbarView的高度.因为不同尺寸设备横屏下导航栏高度不同.(iPad不会进入此逻辑)
        // 否则自定义导航栏页面->系统导航栏页面.导航栏尺寸如果不同,则会前后两个页面toolbarView的布局不同,视觉上跳动;
        if ([OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
            BOOL interfaceIsLandscape = [OPGadgetRotationHelper isLandscape];
            adaptTop = interfaceIsLandscape ? 0 : adaptTop;
            toolbarViewHeight = [OPGadgetRotationHelper navigationBarHeight];
            BDPLogInfo(@"page: %@ interfaceIsLandscape: %d, adaptTop: %f, toolbarViewHeight: %f", self.page.path, interfaceIsLandscape, adaptTop, toolbarViewHeight);
        }
        self.toolBarView.frame = CGRectMake(self.view.bdp_size.width - self.toolBarView.bdp_width - 6, adaptTop, self.toolBarView.bdp_width, toolbarViewHeight);
    }
    
    // https://meego.feishu.cn/larksuite/issue/detail/7188909?parentUrl=%2Flarksuite%2FissueView%2Fj1ZvyBxbrF
    if (self.toolBarView && ![self navigationBarHidden]) {
        if ([BDPXScreenManager isXScreenFGConfigEnable]) {
            /*
             页面层级结构出现错乱时，self.toolBarView会直接被加载到UINavigationBar下,会导致self.toolBarView直接显示在了导航栏的最左侧
             在iOS16下，self.toolBarView不会被加载到UINavigationBar下，但是size会被改成奇怪的值，比如14promax会改成{14,0},![self.toolBarView isAppropriateSize]用来解决系统导航栏误改的问题
            */
            if([self.toolBarView.superview isKindOfClass:[UINavigationBar class]] || ![self.toolBarView isAppropriateSize]) {
                //UINavigationBar会将self.toolBarView的宽高设置成{0,0}，并对内部增加了约束，导致'...'和关闭按钮错位，并不能响应事件(宽高均为0)
                [self.toolBarView resetToAppropriateFrame];
                UIBarButtonItem *rightBar = [[UIBarButtonItem alloc] initWithCustomView:self.toolBarView];
                [self.navigationItem setRightBarButtonItem:rightBar animated:NO];
                
                // 需要在设置到UINavigationBar上之后再次进行布局，原因在于self.toolBarView -layoutSubviews方法内判断了父视图的结构来更新约束
                [self.toolBarView setNeedsLayout];
                [self.toolBarView layoutIfNeeded];
            }
        }
    }
    
    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        self.XScreenNaviBar.hidden = [self navigationBarHidden];
        [self.XScreenNaviBar setNavigationBarTransparent:[self navigationBarTransparent]];
    }
    
    if([BDPDeviceHelper isPadDevice] && [self.navigationController isKindOfClass:BDPNavigationController.class]){
        //适配iPad旋转的场景，更新下 title
        [self updateNavigationBarStyle:NO];
    }
}

// @override
- (void)setupNavigationBar
{
    if(self.containerContext && self.containerContext.apprearenceConfig.forceNavigationBarHidden) {
        // 适配强制无导航模式，强制隐藏导航栏和 Toolbar，任何条件都不允许开启
        return;
    }
    
    BDPToolBarView *toolBarView = [[BDPToolBarView alloc] initWithUniqueID:self.uniqueID];

    BDPWindowConfig *windowConfig = self.pageConfig.window;
    if (!windowConfig && self.vdom[@"config"][@"navigationBar"]) {
        windowConfig = [[BDPWindowConfig alloc] initWithDictionary:self.vdom[@"config"][@"navigationBar"] error:nil];
    }
    
    BDPPlugin(loadingViewPlugin, BDPLoadingViewPluginDelegate);
    if ([loadingViewPlugin respondsToSelector:@selector(bdp_getLoadingViewWithConfig:)]) {
        toolBarView.h5Style = /** Lark小程序右上角维持使用带边框按钮 [loadingViewPlugin bdp_getLoadingViewWithConfig:@{kBDPLoadingViewConfigUniqueID: self.uniqueID ?: @""}] ? BDPToolBarViewH5StyleApp : */BDPToolBarViewH5StyleNone;
    }
    BOOL navigationBarHidden = [windowConfig.navigationStyle isEqualToString:@"custom"];
    if (navigationBarHidden) {
        // 导航栏配置隐藏的情况下，会通过直接添加的方式添加 ToolBar
        NSString *textStyle = [windowConfig navigationBarTextStyleWithReverse:NO];
        BDPToolBarViewStyle toolBarStyle = [textStyle isEqualToString:@"black"] ? BDPToolBarViewStyleLight : BDPToolBarViewStyleDark;
        if (self.uniqueID.isAppSupportDarkMode) {
            if ([textStyle isEqualToString:@"black"]) {
                toolBarStyle = BDPToolBarViewStyleLight;
            } else if ([textStyle isEqualToString:@"white"]) {
                toolBarStyle = BDPToolBarViewStyleDark;
            } else {
                // 缺省颜色按照 Light Mode
                toolBarStyle = BDPToolBarViewStyleLight;
            }
        }
        toolBarView.toolBarStyle = toolBarStyle;
        self.toolBarView = toolBarView;
        [self layoutNavigationBarIfNeeded];
        [self.view addSubview:toolBarView];
    } else {
        BOOL reverse = self.appPage.bap_navBarItemColorShouldReverse;
        NSString *textStyle = [windowConfig navigationBarTextStyleWithReverse:reverse];
        BDPToolBarViewStyle toolBarStyle = [textStyle isEqualToString:@"black"] ? BDPToolBarViewStyleLight : BDPToolBarViewStyleDark;
        if (self.uniqueID.isAppSupportDarkMode) {
            if ([textStyle isEqualToString:@"black"]) {
                toolBarStyle = BDPToolBarViewStyleLight;
            } else if ([textStyle isEqualToString:@"white"]) {
                toolBarStyle = BDPToolBarViewStyleDark;
            } else {
                // 缺省颜色按照 Light Mode
                toolBarStyle = BDPToolBarViewStyleLight;
            }
        }
        toolBarView.toolBarStyle = toolBarStyle;
        UIBarButtonItem *rightBar = [[UIBarButtonItem alloc] initWithCustomView:toolBarView];
        
        self.navigationItem.rightBarButtonItem = rightBar;
        self.toolBarView = toolBarView;
    }

    // 当生成完成ToolBarView之后需要去预获取红点逻辑,仅当开启插件以及预获取红点逻辑才可以被执行
    [toolBarView updateMenuHanlderIfNeeded];
    
    [self setupXscreenNavigationBar];
}

- (void)setupXscreenNavigationBar {
    // 开关在整个App生命周期内只可能是一个值，不会存在状态切换，可以使用开关限制组件加载，并且在切换状态(半屏/全屏)时不缺少组件
    if (![BDPXScreenManager isXScreenFGConfigEnable]) {
        return;
    }
    // 增加半屏导航栏
    BDPXScreenNavigationBar *XScreenNaviBar = [[BDPXScreenNavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bdp_width, kXScreenNaviBarHeight) UniqueID:self.uniqueID];
    self.XScreenNaviBar = XScreenNaviBar;
    self.XScreenNaviBar.hidden = YES;
    [self.view addSubview:XScreenNaviBar];
    
    [self.XScreenNaviBar.closeButton addTarget:self action:@selector(closeTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.XScreenNaviBar.backButton addTarget:self action:@selector(backTap:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)closeTap:(UIButton *)btn {
    [[OPApplicationService.current getContainerWithUniuqeID:self.uniqueID] unmountWithMonitorCode:GDMonitorCode.xscreen_navi_dismiss];
}

- (void)backTap:(UIButton *)btn {
    [self.navigationController popViewControllerAnimated:YES];
}

/// 新逻辑灰度完成后删除旧逻辑
- (void)updateNavigationBarStyleOld:(BOOL)animated
{
    BDPNavigationController *superNavi = (BDPNavigationController *)self.navigationController;

    BDPWindowConfig *windowConfig = self.pageConfig.window;
    if (!windowConfig && self.vdom[@"config"][@"navigationBar"]) {
        windowConfig = [[BDPWindowConfig alloc] initWithDictionary:self.vdom[@"config"][@"navigationBar"] error:nil];
    }

    if ([superNavi isKindOfClass:[BDPNavigationController class]]) {
        BOOL navigationBarHidden = [windowConfig.navigationStyle isEqualToString:@"custom"];
        self.bdp_fakeNavigationBarBG.hidden = navigationBarHidden;
        BDPToolBarView *toolBarView = [self getRightToolBarViewNavigationBarHidden:navigationBarHidden];
        BDPCommon *common = BDPCommonFromUniqueID(self.uniqueID);
        toolBarView.moreButtonBadgeNum = common.moreBtnBadgeNum;
        if (!navigationBarHidden) {
            NSString *title = self.customNavigationBarTitle ?: windowConfig.navigationBarTitleText;
            // 导航栏背景色本身不应该有透明度
            UIColor *navigationBarBackgroundColor = [UIColor colorWithHexString:windowConfig.navigationBarBackgroundColor defaultValue:@"#000000"];
            navigationBarBackgroundColor = [navigationBarBackgroundColor colorWithAlphaComponent:1.0];
            // 根据需要是否反转主题
            BOOL reverse = [self.appPage bap_navBarItemColorShouldReverse];
            NSString *navigationBarTintColorHex = [windowConfig navigationBarTintColorWithReverse:reverse];
            UIColor *navigationBarTintColor = [UIColor colorWithHexString:navigationBarTintColorHex defaultValue:@"#000000"];
            NSDictionary *titleAttributes = [windowConfig titleTextAttributesWithReverse:reverse];
            //标记此时导航栏是不是应该为透明状态
            BOOL bgTransparnt = [windowConfig navigationBarBgTransparent];
            //透明度alpha
            CGFloat alpha = [self.appPage bap_scrollGapPercentage];

            [superNavi setNavigationItemTitle:title viewController:self];
            [superNavi setNavigationBarTitleTextAttributes:titleAttributes viewController:self];
            [superNavi setNavigationBarBackgroundColor:navigationBarBackgroundColor];
            [superNavi setNavigationItemTintColor:navigationBarTintColor viewController:self];
            if (toolBarView) {
                BDPToolBarViewStyle toolBarStyle = [[windowConfig navigationBarTextStyleWithReverse:reverse] isEqualToString:@"black"] ? BDPToolBarViewStyleLight : BDPToolBarViewStyleDark;
                toolBarView.toolBarStyle = toolBarStyle;
            }
            if (bgTransparnt) {
                UIColor *bgColor = [navigationBarBackgroundColor colorWithAlphaComponent:alpha];
                self.bdp_fakeNavigationBarBG.backgroundColor = bgColor;
            } else {
                self.bdp_fakeNavigationBarBG.backgroundColor = navigationBarBackgroundColor;
            }
        } else {
            if (toolBarView) {
                BDPToolBarViewStyle toolBarStyle = [[windowConfig navigationBarTextStyleWithReverse:NO] isEqualToString:@"black"] ? BDPToolBarViewStyleLight : BDPToolBarViewStyleDark;
                toolBarView.toolBarStyle = toolBarStyle;
            }
        }
    }
}

- (void)updateNavigationBarStyle:(BOOL)animated
{
    BDPNavigationController *superNavi = (BDPNavigationController *)self.navigationController;

    BDPWindowConfig *windowConfig = self.pageConfig.window;
    if (!windowConfig && self.vdom[@"config"][@"navigationBar"]) {
        windowConfig = [[BDPWindowConfig alloc] initWithDictionary:self.vdom[@"config"][@"navigationBar"] error:nil];
    }
    
    if ([superNavi isKindOfClass:[BDPNavigationController class]]) {
        BOOL navigationBarHidden = [windowConfig.navigationStyle isEqualToString:@"custom"];
        self.bdp_fakeNavigationBarBG.hidden = navigationBarHidden;
        BDPToolBarView *toolBarView = [self getRightToolBarViewNavigationBarHidden:navigationBarHidden];
        BDPCommon *common = BDPCommonFromUniqueID(self.uniqueID);
        toolBarView.moreButtonBadgeNum = common.moreBtnBadgeNum;
        if (!navigationBarHidden) {
            NSString *title = self.customNavigationBarTitle ?: windowConfig.navigationBarTitleText;
            // 导航栏背景色本身不应该有透明度
            UIColor *navigationBarBackgroundColor = [UIColor colorWithHexString:windowConfig.navigationBarBackgroundColor];
            if (!navigationBarBackgroundColor) {
                if (self.uniqueID.isAppSupportDarkMode) {
                    // 支持 Dark Mode 情况下，缺省的背景为 whiteColor
                    navigationBarBackgroundColor = UIColor.whiteColor;
                } else {
                    // 不支持 Dark Mode 情况下，缺省的背景为 blackColor（线上现状）
                    navigationBarBackgroundColor = UIColor.blackColor;
                }
            }
            // 去除颜色的 alpha 通道，不支持透明色
            navigationBarBackgroundColor = [navigationBarBackgroundColor colorWithAlphaComponent:1.0];
            // 根据需要是否反转主题
            BOOL reverse = [self.appPage bap_navBarItemColorShouldReverse];
            // 导航栏标题、icon、toolbar 的风格
            NSString *textStyle = [windowConfig navigationBarTextStyleWithReverse:reverse];

            UIColor *navigationBarTintColor = UIColor.blackColor;
            if (windowConfig) {
                if (self.uniqueID.isAppSupportDarkMode) {
                    // 支持 Dark Mode 情况下，缺省的背景为 whiteColor ，缺省的Title颜色为 blackColor
                    navigationBarTintColor = UIColor.blackColor;
                    if ([textStyle isEqualToString:@"white"]) {
                        navigationBarTintColor = UIColor.whiteColor;
                    }
                } else {
                    // 不支持 Dark Mode 情况下，缺省的背景为 blackColor ，缺省的Title颜色为 whiteColor（线上现状）
                    navigationBarTintColor = UIColor.whiteColor;
                    if ([textStyle isEqualToString:@"black"]) {
                        navigationBarTintColor = UIColor.blackColor;
                    }
                }
            }
                
            NSMutableDictionary *titleAttributes = nil;
            if (windowConfig) {
                titleAttributes = [[NSMutableDictionary alloc] initWithCapacity:1];
                [titleAttributes setValue:navigationBarTintColor forKey:NSForegroundColorAttributeName];
            }
            
            //标记此时导航栏是不是应该为透明状态
            BOOL bgTransparnt = [windowConfig navigationBarBgTransparent];
            //透明度alpha
            CGFloat alpha = [self.appPage bap_scrollGapPercentage];

            [superNavi setNavigationItemTitle:title viewController:self];
            [superNavi setNavigationBarTitleTextAttributes:titleAttributes.copy viewController:self];
            [superNavi setNavigationBarBackgroundColor:navigationBarBackgroundColor];
            [superNavi setNavigationItemTintColor:navigationBarTintColor viewController:self];
            if (toolBarView) {
                BDPToolBarViewStyle toolBarStyle = [textStyle isEqualToString:@"black"] ? BDPToolBarViewStyleLight : BDPToolBarViewStyleDark;
                if (self.uniqueID.isAppSupportDarkMode) {
                    if ([textStyle isEqualToString:@"black"]) {
                        toolBarStyle = BDPToolBarViewStyleLight;
                    } else if ([textStyle isEqualToString:@"white"]) {
                        toolBarStyle = BDPToolBarViewStyleDark;
                    } else {
                        // 缺省颜色按照 Light Mode
                        toolBarStyle = BDPToolBarViewStyleLight;
                    }
                }
                toolBarView.toolBarStyle = toolBarStyle;
            }
            if (bgTransparnt) {
                UIColor *bgColor = [navigationBarBackgroundColor colorWithAlphaComponent:alpha];
                self.bdp_fakeNavigationBarBG.backgroundColor = bgColor;
            } else {
                self.bdp_fakeNavigationBarBG.backgroundColor = navigationBarBackgroundColor;
            }
        } else {
            if (toolBarView) {
                NSString *textStyle = [windowConfig navigationBarTextStyleWithReverse:NO];
                BDPToolBarViewStyle toolBarStyle = [textStyle isEqualToString:@"black"] ? BDPToolBarViewStyleLight : BDPToolBarViewStyleDark;
                if (self.uniqueID.isAppSupportDarkMode) {
                    if ([textStyle isEqualToString:@"black"]) {
                        toolBarStyle = BDPToolBarViewStyleLight;
                    } else if ([textStyle isEqualToString:@"white"]) {
                        toolBarStyle = BDPToolBarViewStyleDark;
                    } else {
                        // 缺省颜色按照 Light Mode
                        toolBarStyle = BDPToolBarViewStyleLight;
                    }
                }
                toolBarView.toolBarStyle = toolBarStyle;
            }
        }
        
        // 半屏
        if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
            NSString *title = self.customNavigationBarTitle ?: windowConfig.navigationBarTitleText;
            [self.XScreenNaviBar setNavigationBarTitle:title];
            
            UIColor *navigationBarBackgroundColor = [UIColor colorWithHexString:windowConfig.navigationBarBackgroundColor];
            navigationBarBackgroundColor = [navigationBarBackgroundColor colorWithAlphaComponent:1.0];
            [self.XScreenNaviBar setNavigationBarBackgroundColor:navigationBarBackgroundColor];
            
            self.toolBarView.hidden = YES;
            self.bdp_fakeNavigationBarBG.hidden = YES;
            [self.XScreenNaviBar setNavigationBarBackButtonHidden:self.navigationController.viewControllers.count <= 1];
            
            // navigationStyle == "custom" 隐藏，优先级高
            self.XScreenNaviBar.hidden = [self navigationBarHidden];
            [self.XScreenNaviBar setNavigationBarTransparent:[self navigationBarTransparent]];
            
        } else {
            // 这里之前存在遗漏，当半屏功能未开启情况下也会进入该逻辑
            if ([BDPXScreenManager isXScreenFGConfigEnable]) {
                self.XScreenNaviBar.hidden = YES;
                self.toolBarView.hidden = NO;
                // 自定义导航栏时，假的背景的显示隐藏逻辑与上面更新的逻辑保持一致
                if ([superNavi isKindOfClass:[BDPNavigationController class]]) {
                    BOOL navigationBarHidden = [windowConfig.navigationStyle isEqualToString:@"custom"];
                    self.bdp_fakeNavigationBarBG.hidden = navigationBarHidden;
                }
            }

        }
        
    }
}

- (BOOL)navigationBarHidden {
    BDPWindowConfig *windowConfig = self.pageConfig.window;
    if (!windowConfig && self.vdom[@"config"][@"navigationBar"]) {
        windowConfig = [[BDPWindowConfig alloc] initWithDictionary:self.vdom[@"config"][@"navigationBar"] error:nil];
    }
    return [windowConfig.navigationStyle isEqualToString:@"custom"];
}

- (BOOL)navigationBarTransparent {
    BDPWindowConfig *windowConfig = self.pageConfig.window;
    if (!windowConfig && self.vdom[@"config"][@"navigationBar"]) {
        windowConfig = [[BDPWindowConfig alloc] initWithDictionary:self.vdom[@"config"][@"navigationBar"] error:nil];
    }
    
    if ([windowConfig.navigationStyle isEqualToString:@"default"]) {
        if ([windowConfig.transparentTitle isEqualToString:@"always"] ||
            [windowConfig.transparentTitle isEqualToString:@"auto"]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)popGestureEnable {
    BDPWindowConfig *windowConfig = self.pageConfig.window;
    if (!windowConfig && self.vdom[@"config"][@"navigationBar"]) {
        windowConfig = [[BDPWindowConfig alloc] initWithDictionary:self.vdom[@"config"][@"navigationBar"] error:nil];
    }
    return ![windowConfig.disableSwipeBack boolValue];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self applyTraitCollectionChange];
        }
    }
}

- (void)applyTraitCollectionChange {
    if (!self.uniqueID.isAppSupportDarkMode) {
        // 不支持 DarkMode
        return;
    }
    if (@available(iOS 13.0, *)) {
        [self.pageConfig applyDarkMode:self.traitCollection.userInterfaceStyle==UIUserInterfaceStyleDark];
        [self updateViewControllerStyle:NO];
        [self updateStatusBarStyle:NO];
        [self setNeedsStatusBarAppearanceUpdate];
    }
}


/// 带tabbar小程序在dm/lm切换时，如果停留在非首页，那么traitCollectionDidChange:可能不会被调用。针对这种情况，在每次页面展示的时候进行检查，再次更新dm/lm
- (void)compensateTraitCollectionDidChange {
    if([self.tabBarController isKindOfClass:[BDPTabBarPageController class]]) {
        [self applyTraitCollectionChange];
    }
}

#pragma mark - Setup Basement
/*-----------------------------------------------*/
//          Setup Basement - 基础内容加载
/*-----------------------------------------------*/
- (void)setupViews
{
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    [self setupAppPageIfNeed];
    
    UIColor *backgroundColor = [self containerViewThemeColor];
    self.appPage.scrollView.backgroundColor = backgroundColor;
    self.appPage.backgroundColor = backgroundColor;
    
    self.appPage.bap_pageConfig = self.pageConfig;
    self.appPage.opaque = NO;
    self.appPage.bap_vdom = self.vdom;
    [self.appPage tryLoadVdom];
    
    // 监听page的frame变化，通知JSSDK调整布局
    [self observePageResize];

    self.appPage.frame = self.view.bounds; // 修复接电话时小程序跳转新页面顶部视图多出20px的空间

    [self.view insertSubview:self.appPage atIndex:0];
    [task.pageManager addAppPage:self.appPage];
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    if (common.isSubpackageEnable) {
        [[BDPSubPackageManager sharedManager] prepareSubPackagesForPage:self.appPage.bap_path
                                                           withUniqueID:self.uniqueID
                                                              isWorker:YES
                                                      jsExecuteCallback:^(BDPSubPackageExtraJSLoadStep loadStep, NSError * _Nonnull error) {
            BDPLogInfo(@"prepareSubPackagesForPage with current step:%@", @(loadStep));
            if (error) {
                BDPLogError(@"prepareSubPackagesForPage with error response:%@ in step:%@", error, @(loadStep));
            }
            if (loadStep == BDPSubPackageLoadAppServiceEnd) {
                // 告知AppPage viewDidLoad, 可以做必要的加载了
                [self.appPage appPageViewDidLoad];
                // 如果onAppPage的时候还没有AppPage或者pageManager中没登记, 那就在里补发一下
                if (self.openType) {
                    [self onAppRoute:self.openType];
                }
                [self.appPage bdp_setupPageObserver];
            }
        }];

        // 预加载分包
        [[BDPSubPackageManager sharedManager] preloadWithRulesInPagePath:self.appPage.bap_path withUniqueID:self.uniqueID];
    } else {
        // 告知AppPage viewDidLoad, 可以做必要的加载了
        [self.appPage appPageViewDidLoad];
        // 如果onAppPage的时候还没有AppPage或者pageManager中没登记, 那就在里补发一下
        if (self.openType) {
            [self onAppRoute:self.openType];
        }
        [self.appPage bdp_setupPageObserver];
    }
}

- (void)observePageResize {
    if (!self.appPage) {
        return;
    }
    BDPUniqueID *uniqueID = self.uniqueID;
    NSInteger sourceID = self.appPage.appPageID;
    [self.KVOController unobserve:self.appPage keyPath:@"frame"];

    WeakSelf;
    [self.KVOController observe:self.appPage
                           keyPath:@"frame"
                           options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                             block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        StrongSelfIfNilReturn;
        NSValue *oldFrameValue = change[NSKeyValueChangeOldKey];
        NSValue *newFrameValue = change[NSKeyValueChangeNewKey];
        CGSize oldSize = oldFrameValue.CGRectValue.size;
        CGSize newSize = newFrameValue.CGRectValue.size;
        if (!CGSizeEqualToSize(oldSize, newSize)) {
            BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
            BDPJSBridgeEngine engine = task.context;
            if ([engine respondsToSelector:@selector(bdp_fireEvent:sourceID:data:)]) {
                if ([OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
                    [self fireOnPageResizeEventWithPageSize:newSize sourceID:sourceID];
                } else {
                    CGSize screenSize = [UIScreen mainScreen].bounds.size;
                    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:
                                                     @{
                                                        @"size": @{
                                                            @"pageWidth": @(newSize.width),
                                                            @"pageHeight": @(newSize.height),
                                                            @"screenWidth" : @(screenSize.width),
                                                            @"screenHeight" : @(screenSize.height),
                                                            @"windowWidth" : @(self.view.bdp_width),
                                                            @"windowHeight" : @(self.view.bdp_height)
                                                        },
                                                        @"pageOrientation" : @"portrait",
                                                        @"webviewId":@(sourceID)
                                                    }];

                    // iPad上方向的定义与iPhone有所不同.因为iPad支持左右拖动.因此这个字段在iPad上不返回.
                    if ([OPGadgetRotationHelper isPad]) {
                        [data removeObjectForKey:@"pageOrientation"];
                    }

                    [engine bdp_fireEvent:@"onPageResize"
                                 sourceID:sourceID
                                     data:data
                     ];
                }
            }

        }
    }];
}

-(void)setupNoticeViewWithModel:(OPNoticeModel *)model{
    BOOL shouldShowNoticeView = [[OPNoticeManager sharedManager] shouldShowNoticeViewForModel:model];
    if (!shouldShowNoticeView) {
        return ;
    }
    [[OPNoticeManager sharedManager] recordShowNoticeViewForModel:model appID:self.uniqueID.appID];
    if (![self navigationBarHidden]) {
        self.noticeView = [[OPNoticeView alloc] initWithFrame:CGRectMake(0, 0, self.view.bdp_width, 100) model:model isAutoLayout:NO];
        self.noticeView.delegate = self;
        [self.view addSubview:self.noticeView];
        self.appPage.bdp_top += self.noticeView.op_height;
        self.appPage.bdp_height -= self.noticeView.op_height;//x掉后更新
    } else {
        self.noticeView = [[OPNoticeView alloc] initWithFrame:CGRectMake(0, self.toolBarView.bdp_bottom, self.view.bdp_width, 100) model:model isAutoLayout:NO];
        self.noticeView.delegate = self;
        [self.view addSubview:self.noticeView];
    }
}

- (void)setupPlugins
{
    WeakSelf;
    
    // getCurrentRoute
    [BDPJSBridgeCenter registerContextMethod:@"getCurrentRoute" isSynchronize:NO isOnMainThread:NO engine:self.appPage type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{@"route": self.page.path ?: @""})
    }];
    
    // disableScrollBounce
    [BDPJSBridgeCenter registerContextMethod:@"disableScrollBounce" isSynchronize:NO isOnMainThread:YES engine:self.appPage type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        self.appPage.scrollView.bounces = ![params bdp_boolValueForKey:@"disable"];
        BDP_CALLBACK_SUCCESS
    }];

    // endEditing
    [BDPJSBridgeCenter registerContextMethod:@"endEditing" isSynchronize:NO isOnMainThread:YES engine:self.appPage type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        [self.appPage endEditing:YES];
        BDP_CALLBACK_SUCCESS
    }];
}

- (void)eventStayPage
{
    NSString *exitType = [BDPTracker getTag:BDPTrackerExitType];
    if (exitType) {
        [BDPTracker setTag:BDPTrackerExitType value:nil];
    } else {
        exitType = @"new_page";
    }
    [BDPTracker endLogPageView:self.page.path query:self.page.queryString duration:(NSUInteger)(self.tmaTrackStayTime * 1000) exitType:exitType uniqueID:self.uniqueID];
    [self tma_resetStayTime];
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                Utils - 工具
/*-----------------------------------------------*/
- (NSString *)checkPath:(NSString *)path default:(NSString *)defaultPath
{
    NSString *validPath;
    if (!BDPIsEmptyString(path)) {
        validPath = path;
    } else {
        validPath = defaultPath;
    }
    validPath = [validPath hasSuffix:@".html"] ? [[validPath componentsSeparatedByString:@".html"] firstObject] : validPath;
    return validPath;
}

- (UIColor *)containerViewThemeColor {
    return self.pageConfig.window.themeBackgroundColor;
}

#pragma mark - StatusBar
/*------------------------------------------*/
//            StatusBar - 状态栏
/*------------------------------------------*/
- (UIStatusBarStyle)preferredStatusBarStyle
{
    BOOL reverse = self.appPage.bap_navBarItemColorShouldReverse;
    return [self.pageConfig.window statusBarStyleWithReverse:reverse];
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    if (_statusBarHidden != statusBarHidden) {
        _statusBarHidden = statusBarHidden;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BDPToolBarView *)getRightToolBarViewNavigationBarHidden:(BOOL)navigationBarHidden
{
    if (navigationBarHidden) {
        return self.toolBarView;
    } else {
        UIView *customView = self.navigationItem.rightBarButtonItem.customView;
        if ([customView isKindOfClass:[BDPToolBarView class]]) {
            return (BDPToolBarView *)customView;
        }
    }

    return nil;
}

#pragma mark - Orientation
/*------------------------------------------*/
//          Orientation - 屏幕旋转
/*------------------------------------------*/
//- (BOOL)shouldAutorotate
//{
//    return [BDPDeviceManager shouldAutorotate];
//}
//
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskPortrait;
//}

#pragma mark - OnAppRoute
/*-----------------------------------------------*/
//              OnAppRoute - 页面路由
/*-----------------------------------------------*/
- (void)onAppRoute:(NSString *)openType
{
    // Non-Null OpenType
    if (BDPIsEmptyString(openType)) {
        BDPLogInfo(@"[BDP] onAppRoute openType nil");
        return;
    }
    
    // 非首屏启动, 此时还没有创建AppPage, 记录下打开类型。一会创建好了再补发
    if (!self.appPage) {
        self.openType = openType;
        BDPLogInfo(@"[BDP] onAppRoute appPage nil");
        return;
    }
    
    // Update OpenType
    self.appPage.bdp_openType = openType;
    
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    
    // 确保JSContextReady, 就可以发
    if (!task.context.isContextReady) {
        self.appPage.isNeedRoute = YES;
        BDPLogInfo(@"[BDP] onAppRoute not ready");
        return;
    }
    
    // 发OnAppRoute前, 再次确保webview已登记! 如果没有, 那登记一下。一会setupViews中注册到pageManager中再发
    if (![task.pageManager appPageWithID:self.appPage.appPageID]) {
        BDPLogInfo(@"[BDP] onAppRoute appPage unregister");
        self.openType = openType;
        return;
    }

    // 注入到 JS Page 的根trace object
    BDPTracing *pageTrace = [BDPTracingManager.sharedInstance getTracingByAppPage:self.appPage];
    
    // FireEvent AppRoute
    [task.context bdp_fireEvent:@"onAppRoute"
                       sourceID:self.appPage.appPageID
                           data:@{@"webviewId": @(self.appPage.appPageID),
                                  @"path": BDPSafeString(self.page.path),
                                  @"query": BDPSafeString(self.page.queryString),
                                  @"openType": openType,
                                  @"trace": @{
                                          @"traceId": BDPSafeString(pageTrace.traceId),
                                          @"createTime": @(pageTrace.createTime),
                                          @"extensions": @[]
                                  }}];
    BDPLogInfo(@"[BDP] onAppRoute type: %@", openType);
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithStartKey:BDPPerformanceDomready uniqueId:self.uniqueID extra:nil];
    if([BDPPerformanceProfileManager.sharedInstance enableProfileForCommon:common]){
        [[BDPPerformanceProfileManager sharedInstance] flushLaunchPointsWhenDomready];
    }
    self.openType = nil;
}

- (CAShapeLayer *)XScreenMaskLayer {
    if (!_XScreenMaskLayer) {
        _XScreenMaskLayer = [[CAShapeLayer alloc] init];
        _XScreenMaskLayer.frame = [[UIScreen mainScreen] bounds];
        _XScreenMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect:[[UIScreen mainScreen] bounds]
                                                       byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft
                                                             cornerRadii:CGSizeMake(8, 8)].CGPath;
    }
    return _XScreenMaskLayer;
}

- (void)updateViewControllerStyle:(BOOL)animated {
    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        [super updateViewControllerStyle:NO];
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    } else {
        [super updateViewControllerStyle:animated];
    }
}

#pragma mark - BDPAppPageDataLoadErrorHandleDelegate

- (void)appPage:(BDPAppPage *)appPage didTriggerDataLoadError:(NSError *)error {
    if (appPage.parentController != self || !appPage.bdp_isVisible) {
        BDPLogInfo(@"invisible page DataLoadError. uniqueID: %@, error: %@", self.uniqueID, error);
        return;
    }

    if (error.opError) {
        [OPSDKRecoveryEntrance handleErrorWithUniqueID:self.uniqueID with:error recoveryScene:RecoveryScene.gadgetRuntimeFail contextUpdater:nil];
    }
}

#pragma mark - OPNoticeViewDelegate

-(void)didCloseNoticeView{
    [[OPNoticeManager sharedManager] recordCloseNoticeViewForModel:self.noticeView.model appID:self.uniqueID.appID];
    self.noticeView = nil;
    if ([self navigationBarHidden]) {
        //如果是隐藏的话，是盖在页面上，所以不需要重置frame
        return ;
    }
    self.appPage.bdp_top = 0;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

#pragma mark - leaveComfirm
- (void)addLeaveComfirmTitle:(NSString *)title
                     content:(NSString *)content
                 confirmText:(NSString *)confirmText
                  cancelText:(NSString *)cancelText
                      effect:(NSArray *)effect
                confirmColor:(NSString *)confirmColor
                 cancelColor:(NSString *)cancelColor {
    // 新建的二次弹框模式是valid状态;
    BDPLeaveComfirmModel *leaveComfirm = [[BDPLeaveComfirmModel alloc] initWithTitle:title content:content confirmText:confirmText cancelText:cancelText effect:effect confirmColor:confirmColor cancelColor:cancelColor];
    leaveComfirm.state = BDPLeaveComfirmStateValid;
    
    self.leaveComfirm = leaveComfirm;
    
    [self.toolBarView addLeaveComfirmHandler:self];
}

- (void)cancelLeaveComfirm {
    if (self.leaveComfirm) {
        self.leaveComfirm.state = BDPLeaveComfirmStateCancel;
    }
}

- (BOOL)handleLeaveComfirmAction:(BDPLeaveComfirmAction)action confirmCallback:(void (^)(void))callback {
    if (self.leaveComfirm && self.leaveComfirm.state == BDPLeaveComfirmStateValid && (self.leaveComfirm.effects & action)) {
        // 弹框
        // 宿主应用程序代理插件
        BDPPlugin(modalPlugin, BDPModalPluginDelegate);
        if ([modalPlugin respondsToSelector:@selector(bdp_showModalWithModel:confirmCallback:cancelCallback:inController:)]) {
            //
            dispatch_block_t confirmBlock = ^{
                if (callback) {
                    callback();
                }
            };
            __weak typeof(self) weakSelf = self;
            dispatch_block_t cancelBlock = ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                BDPUniqueID *uniqueID = strongSelf.uniqueID;
                BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
                BDPJSBridgeEngine engine = task.context;
                if ([engine respondsToSelector:@selector(bdp_fireEvent:sourceID:data:)]) {
                    NSInteger sourceID = strongSelf.appPage.appPageID;
                    [engine bdp_fireEvent:@"onLeaveConfirmCancel"
                                 sourceID:sourceID
                                     data:@{}];
                }
            };
            
            BDPModalPluginModel *modalModel = [[BDPModalPluginModel alloc] init];
            modalModel.title = self.leaveComfirm.title;
            modalModel.content = self.leaveComfirm.content;
            modalModel.confirmText = self.leaveComfirm.confirmText;
            modalModel.cancelText = self.leaveComfirm.cancelText;
            modalModel.cancelColor = self.leaveComfirm.cancelColor;
            modalModel.confirmColor = self.leaveComfirm.confirmColor;
            modalModel.showCancel = YES;
            
            [modalPlugin bdp_showModalWithModel:modalModel confirmCallback:confirmBlock cancelCallback:cancelBlock inController:nil];
            
            // 这里视产品需求确定为可以多次弹框
//            self.leaveComfirm.state = BDPLeaveComfirmStateConsumed;
            return YES;
        }
    }
    return NO;
}

#pragma mark - takeover backevent
- (void)takeoverBackEvent {
    // 对页面进行标记，当申请托管返回事件后，控制权全部交给业务
    self.gagdetTakeoverBackEvent = YES;
}

- (BOOL)handleTakeoverBackEventIfRegisted {
    if (self.gagdetTakeoverBackEvent) {
        BDPUniqueID *uniqueID = self.uniqueID;
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
        BDPMicroAppJSRuntimeEngine engine = task.context;
        if ([engine respondsToSelector:@selector(bdp_fireEvent:sourceID:data:)]) {
            NSInteger sourceID = self.appPage.appPageID;
            [engine bdp_fireEvent:@"onNavigateBackListener"
                         sourceID:sourceID
                             data:@{@"scene":@"navibutton"}];
        }
    }
    return self.gagdetTakeoverBackEvent;
}

@end


@implementation BDPAppPageController (XScreen)

- (void)updateXscreenNavigationBarTitle:(NSString *)title {
    [self.XScreenNaviBar setNavigationBarTitle:title];
}

@end
