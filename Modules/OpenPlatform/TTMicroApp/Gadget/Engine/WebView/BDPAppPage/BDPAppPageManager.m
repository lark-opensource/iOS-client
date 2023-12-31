//
//  BDPAppPageManager.m
//  Timor
//
//  Created by 王浩宇 on 2019/1/7.
//

#import "BDPAppPageManager.h"
#import <OPFoundation/BDPUtils.h>
#import "BDPAppPage.h"
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPAppPageFactory.h"
#import <OPFoundation/BDPNotification.h>
#import "BDPInterruptionManager.h"
#import <OPSDK/OPSDK-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPGadgetLog.h"
#import <OPFoundation/BDPMonitorHelper.h>
#import "BDPPerformanceProfileManager.h"
#import <OPFoundation/BDPMonitorHelper.h>

/** 一般小程序首屏渲染不超过2s, 避开首屏即可 */
#define PRELOAD_VIEW_DELAY 2

@interface BDPAppPageManager ()

@property (nonatomic, strong) BDPUniqueID *uniqueID;
@property (nonatomic, strong) BDPAppPage *preLoadAppPage;
@property (nonatomic, strong) NSMapTable<NSNumber *, BDPAppPage *> *viewsById;
@property (nonatomic, strong) NSMapTable<NSString *, BDPAppPage *> *viewsByStr;

@property (nonatomic, assign) BOOL autoCreateEnable;

@property (nonatomic, assign) NSInteger pageIndex;

@end

@implementation BDPAppPageManager

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
{
    self = [super init];
    if (self) {
        _uniqueID = uniqueID;
        _pageIndex = 0;
        _viewsByStr = [[NSMapTable alloc] initWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory capacity:5];
        _viewsById = [[NSMapTable alloc] initWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory capacity:5];

        [self setupObserver];
    }
    return self;
}

- (void)dealloc
{
    //下面的宏是将一个数组中的对象，分散到主线程的runloop中进行释放，避免集中释放造成卡顿
    NSArray<BDPAppPage *> *appViews = [[self.viewsByStr objectEnumerator] allObjects];
    RELEASE_ARRAY_ELEMENTS_SEPARATE_MAIN_THREADS_DELAY_SECS(appViews, 0.2);

    // 针对page manager 中持有但未消费的预加载对象也上报一次，数据统计时可以过滤
    [self monitorWithPreload:_preLoadAppPage appearOnView:NO];

    // 在appPageManager释放的时候将预加载的AppPage的状态置为预期销毁
    [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedDestroy for:_preLoadAppPage];
}

#pragma mark - Convenience Functions
/*-----------------------------------------------*/
//        Convenience Functions - 便捷方法
/*-----------------------------------------------*/
- (void)addAppPage:(BDPAppPage *)page
{
    if (page) {
        [self.viewsById setObject:page forKey:@(page.appPageID)];
        if (!BDPIsEmptyString(page.bap_path)) {
            [self.viewsByStr setObject:page forKey:page.bap_path];
        }
        BDPGadgetLogInfo(@"BDPAppPageManager addAppPage: page.appPageID:%@, and now self.viewByID:%@, self.viewsByStr:%@",@(page.appPageID), self.viewsById, self.viewsByStr);
    }
}

- (NSArray<BDPAppPage *> *)appPagesWithIDs:(NSArray<NSNumber *> *)ids
{
    if (BDPIsEmptyArray(ids)) return nil;
    
    NSMutableArray *appPages = [[NSMutableArray alloc] init];
    for (NSNumber *ID in ids) {
        if ([ID isKindOfClass:[NSNull class]]) continue;
        BDPAppPage *appPage = [self appPageWithID:ID.integerValue];
        if (appPage) {
            [appPages addObject:appPage];
        }
    }
    return [appPages copy];
}

- (BDPAppPage *)appPageWithID:(NSInteger)ID
{
    return [self.viewsById objectForKey:@(ID)];
}

- (BDPAppPage *)appPageWithPath:(NSString *)path
{
    if (!BDPIsEmptyString(path)) {
        return [self.viewsByStr objectForKey:path];
    }
    return nil;
}
/// 获取所有AppPage
- (NSArray<BDPAppPage *> *)getAllAppPages {
    return self.viewsById.objectEnumerator.allObjects;
}

- (BDPAppPage *)dequeueAppPage
{
    BDPAppPage *resultPage = nil;
    BOOL isPreloadAppPage = self.preLoadAppPage != nil;
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    if([BDPPerformanceProfileManager.sharedInstance enableProfileForCommon:common] && !BDPPerformanceProfileManager.sharedInstance.isDomready){
        ///如果是性能场景，首次直接创建，domready则进入原有逻辑，有预加载则用，没有则不用
        resultPage = [self createAppPage];
    } else if (isPreloadAppPage) {
        // 如果有预加载的WebView则直接使用，使用后将preloadView指针置空
        resultPage = self.preLoadAppPage;
        self.preLoadAppPage = nil;
    } else {
        // 如果没有preloadView，则创建页面
        resultPage = [self createAppPage];
    }
    BDPGadgetLogInfo(@"dequeueAppPage, isPreloadAppPage=%@", @(isPreloadAppPage));

    // 预加载对象finishedInitTime 会设置初始化完成时间
    _pageIndex ++;
    [self monitorWithPreload:resultPage appearOnView:YES];
    
    // 创建新的预加载WebView
    [self createBackupAppPageIfNeeded];
    
    // 将被通过统一入口取出的appPage的状态标记为预期持有
    [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedRetain for:resultPage];

    return resultPage;
}

- (void)createBackupAppPageIfNeeded
{
    if (!self.autoCreateEnable) {
        return;
    }

    WeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PRELOAD_VIEW_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        StrongSelfIfNilReturn;
        // 这里判断一下self，因为有可能关闭的快，已经销毁了。
        if (!self.preLoadAppPage && ![BDPInterruptionManager sharedManager].didEnterBackground) {
            // 增加App Page 的复用率，不需要提前持有，只需要从预加载队列中获取就行；持有后带有UniqueId 信息不能复用；
            if (OPSDKFeatureGating.disablePrecacheNextAppPage) {
                BDPAppPageFactory *pageFactory = [BDPAppPageFactory sharedManager];
                BOOL needPreload = NO;
                if (!pageFactory.preloadAppPage){
                    needPreload = YES;
                    // 这个preloadFrom 是为了跟consumed 导致的预加载做区分
                    [pageFactory updatePreloadFrom:@"backup_apppage"];
                    [pageFactory tryPreloadAppPage];
                }
                BDPGadgetLogInfo(@"New preload AppPage,Disable Precache Next AppPage, NeedPreload:%@",@(needPreload));
            }else {
                self.preLoadAppPage = [self createAppPage];
            }
            BDPGadgetLogInfo(@"New preload AppPage");
        }
    });
}

#pragma mark - Handle Preload AppPage

/// 重写preLoadAppPage属性的setter，将objectState变更为预期状态
- (void)setPreLoadAppPage:(BDPAppPage *)preLoadAppPage {
    if (preLoadAppPage != _preLoadAppPage) {
        // 旧page变为预期销毁状态，新page取代旧page变为预期持有状态
        [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedDestroy for:_preLoadAppPage];
        [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedRetain for:preLoadAppPage];
        _preLoadAppPage = preLoadAppPage;
    }
}

- (BDPAppPage *)createAppPage
{
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    if (!common || !self.uniqueID) {
        return nil;
    }
    BDPAppPage * appPage = [[BDPAppPageFactory sharedManager] appPageWithUniqueID:self.uniqueID];

    return appPage;
}

- (void)preparePreloadAppPageIfNeed
{
    if (!self.preLoadAppPage) {
        self.preLoadAppPage = [self createAppPage];
    }
}

- (void)releaseTerminatedPreloadAppPage:(BDPAppPage *)page
{
    BDPExecuteOnMainQueue(^{
        if (page == self.preLoadAppPage) {
            self.preLoadAppPage = nil;
        }
    });
}

- (void)releaseAllPreloadAppPage {
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        self.preLoadAppPage = nil;
    });
}

- (void)setAutoCreateAppPageEnable:(BOOL)enable
{
    self.autoCreateEnable = enable;
    
    [self createBackupAppPageIfNeeded];
}

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
- (void)setupObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleReloadAppPageNotification)
                                                 name:kBDPAppPageFactoryReloadNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePreloadAppPageTerminated:)
                                                 name:kBDPAppPageTerminatedNotification
                                               object:nil];
}

- (void)handleReloadAppPageNotification
{
    if (self.preLoadAppPage) {
        self.preLoadAppPage = [self createAppPage];
    }
}

- (void)handlePreloadAppPageTerminated:(NSNotification *)notification
{
    [self releaseTerminatedPreloadAppPage:notification.userInfo[kBDPAppPageTerminatedUserInfoTypeKey]];
}

#pragma mark - ContainerVC Update
/*-----------------------------------------------*/
//         ContainerVC Update - 容器更新
/*-----------------------------------------------*/
- (void)updateContainerVC:(UIViewController<BDPlatformContainerProtocol> *)containerVC
{
    // 预加载AppPage ContainerVC更新
    self.preLoadAppPage.appPageDelegate = (id<BDPAppPageProtocol>)containerVC;

    // AppPage(已经存在Path) ContainerVC更新
    [[[self.viewsById objectEnumerator] allObjects] enumerateObjectsUsingBlock:^(BDPAppPage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.appPageDelegate = (id<BDPAppPageProtocol>)containerVC;
    }];
}

#pragma mark - Preload App Page Track

- (void)monitorWithPreload:(BDPAppPage *)preloadPage appearOnView:(BOOL)isOnView {
    if(preloadPage.finishedInitTime > 0){
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
        [params setValue:@(1) forKey:@"state"];
        // preload view如果没有展示到屏幕上，索引+1
        NSInteger viewPageIndex = isOnView ? _pageIndex : (_pageIndex + 1);
        [params setValue:@(viewPageIndex) forKey:@"page_index"];
        // 是否展示到屏幕上
        [params setValue:@(isOnView) forKey:@"is_on_window"];
        [params setValue:_uniqueID.appID forKey:kEventKey_app_id];
        [BDPWebViewRuntimePreloadManager monitorEvent:@"render_consumed" params:params];
    }
}

@end
