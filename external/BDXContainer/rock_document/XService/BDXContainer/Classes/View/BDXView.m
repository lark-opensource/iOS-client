//
//  BDXViewContainer.m
//  AFgzipRequestSerializer
//
//  Created by bytedance on 2021/3/3.
//

#import "BDXView.h"
#import <objc/runtime.h>
#include <pthread/pthread.h>

#import "BDXKitApi.h"
#import "BDXLynxKitApi.h"
#import "BDXWebKitApi.h"

#import <Lynx/LynxError.h>

#import <BDXResourceLoader/BDXResourceProvider.h>
#import <BDXServiceCenter/BDXContext.h>
#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXGlobalContext.h>
#import <BDXServiceCenter/BDXLynxKitProtocol.h>
#import <BDXServiceCenter/BDXSchemaProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXServiceRegister.h>
#import <BDXServiceCenter/BDXWebKitProtocol.h>

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>

#import <BDXBridgeKit/BDXBridge.h>
#import <BDXBridgeKit/NSObject+BDXBridgeContainer.h>

#import "BDXViewSchemaParam.h"

@BDXSERVICE_REGISTER(BDXViewContainerSerivce)

@implementation BDXViewContainerSerivce

+ (BDXServiceScope)serviceScope
{
    return BDXServiceScopeGlobalDefault;
}

+ (BDXServiceType)serviceType
{
    return BDXServiceTypeContainerView;
}

+ (NSString *)serviceBizID
{
    return DEFAULT_SERVICE_BIZ_ID;
}

- (nullable UIView<BDXViewContainerProtocol> *)createViewContainerWithFrame:(CGRect)frame
{
    UIView<BDXViewContainerProtocol> *container = [[BDXView alloc] initWithFrame:frame];
    return container;
}

@end

@interface BDXView () <BDXKitViewLifecycleProtocol>

@property(nonatomic, strong) NSURL *url;
@property(nonatomic, readwrite, assign) CGSize contentSize;

@property(nonatomic, readwrite, strong) UIView<BDXKitViewProtocol> *kitView;
@property(nonatomic, strong) BDXViewSchemaParam *config;

@property(nonatomic, assign) BOOL hasHandleFallback;
@property(nonatomic, assign) BOOL isFirstDraw;
@property(nonatomic, assign) BOOL isFirstLoad;
@property(nonatomic, strong) id<BDXMonitorProtocol> lifeCycleTracker;
@property(nonatomic, assign) NSTimeInterval initTimeStamp;
@property(nonatomic, assign) NSTimeInterval beginLoadTimeStamp;

@property(nonatomic, strong) UIView<BDXLoadErrorViewProtocol> *loadFailedView;
@property(nonatomic, strong) UIView<BDXLoadingViewProtocol> *loadingView;

@end

// TODO: 容器将autoExpose设置为false，减少前端开发成本。对于view提供接口给业务方来设置？
@implementation BDXView

@synthesize hybridInBackground;
@synthesize hybridAppeared;
@synthesize bdxContentMode;
@synthesize context = _context;
// containerLifecycle
@synthesize containerLifecycleDelegate;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.isFirstDraw = YES;
        self.isFirstLoad = YES;
        self.initTimeStamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    }
    return self;
}

- (UIView *)rawView
{
    return self.kitView;
}

#pragma mark - BDXContainerProtocol

- (void)handleViewDidAppear
{
    [self.kitView onShow:@{@"event": kBDXKitEventViewDidAppear}];
}

- (void)handleViewDidDisappear
{
    [self.kitView onHide:@{@"event": kBDXKitEventViewDidDisappear}];
}

- (void)handleBecomeActive
{
    [self.kitView onShow:@{@"event": kBDXKitEventAppDidBecomeActive}];
}

- (void)handleResignActive
{
    [self.kitView onHide:@{@"event": kBDXKitEventAppResignActive}];
}

- (NSString *)containerID
{
    return self.kitView.containerID;
}

- (BDXEngineType)viewType
{
    if (self.kitView && [self.kitView conformsToProtocol:@protocol(BDXLynxViewProtocol)]) {
        return BDXEngineTypeLynx;
    } else if (self.kitView && [self.kitView conformsToProtocol:@protocol(BDXWebViewProtocol)]) {
        return BDXEngineTypeWeb;
    }
    return BDXEngineTypeUnknown;
}

- (id)kitBridge
{
    return self.kitView.kitBridge;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (!self.kitView) {
        return;
    }

    if (CGRectEqualToRect(self.kitView.frame, self.bounds)) {
        return;
    }

    self.kitView.frame = self.bounds;
    [self.kitView triggerLayout];
}

- (void)loadWithURL:(nullable NSString *)url context:(nullable BDXContext *)context
{
    if (!context) {
        context = [BDXContext new];
        context = [BDXGlobalContext mergeContext:context withBid:nil];
    }

    NSString *bid = [context getObjForKey:kBDXContextKeyBid];
    Class<BDXSchemaProtocol> schemaService = BDXSERVICE_CLASS_WITH_DEFAULT(BDXSchemaProtocol, bid);
    BDXSchemaParam *param = [schemaService resolverWithSchema:[NSURL URLWithString:url] contextInfo:context paramClass:BDXViewSchemaParam.class];
    [self loadWithParam:param context:context];
}

- (void)loadWithParam:(BDXSchemaParam *)param context:(BDXContext *)context
{
    self.config = (BDXViewSchemaParam *)param;
    self.context = context;
    // 因为lifeCycleTracker依赖于self.context，所以view_did_initialized不能放在initWithFrame里
    [self.lifeCycleTracker trackLifeCycleWithEvent:@"view_did_initialized" timeStamp:self.initTimeStamp];

    [self.lifeCycleTracker trackLifeCycleWithEvent:@"view_will_load_url"];
    self.beginLoadTimeStamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    BOOL forceH5 = self.config.forceH5 ? self.config.forceH5.boolValue : NO;
    if (forceH5 && self.config.fallbackURL) {
        self.url = [NSURL URLWithString:self.config.fallbackURL];
    } else {
        self.url = self.config.resolvedURL;
    }

    if ([NSThread currentThread].isMainThread) {
        [self internalLoad];
    } else {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf internalLoad];
        });
    }

    if (self.isFirstLoad) {
        self.isFirstLoad = NO;
        [self trackEvent:@"bdx_view_did_create" metric:nil category:nil];
    }
}

- (NSURL *)originURL
{
    return self.config.originURL;
}

- (void)internalLoad
{
    [self.context registerStrongObj:@(self.bounds.size.width) forKey:@"__kit_frame_width"];
    [self.context registerStrongObj:@(self.bounds.size.height) forKey:@"__kit_frame_height"];

    NSURL *url = self.url;
    // bullet://bullet?url=encode(lynxview://url=https://xxxx/template.js)
    // bullet://bullet?url=encode(webview://url=https://xxxx/index.html)
    if ([url.scheme isEqualToString:@"bullet"]) {
        NSDictionary *queries = [url btd_queryItemsWithDecoding];
        NSString *urlString = [queries btd_stringValueForKey:@"url"];
        if (BTD_isEmptyString(urlString)) {
            return;
        }

        url = [NSURL URLWithString:urlString];
    }

    UIView<BDXKitViewProtocol> *kitView = nil;
    NSString *targetSchema = url.scheme;

    [self.lifeCycleTracker trackLifeCycleWithEvent:@"view_will_init_kit_view"];

    if ([targetSchema isEqualToString:@"lynxview"]) {
        switch (self.bdxContentMode) {
            case BDXViewContentModeFitSize:
                [self.context registerCopyObj:@(BDXLynxViewSizeModeUndefined) forKey:kBDXContextKeyWidthMode];
                [self.context registerCopyObj:@(BDXLynxViewSizeModeUndefined) forKey:kBDXContextKeyHeightMode];
                break;
            default:
                break;
        }
        kitView = [[[BDXLynxKitApi alloc] initWithContext:self.context] provideKitViewWithURL:url];
    } else if ([@[@"webview", @"https", @"http"] containsObject:targetSchema]) {
        kitView = [[[BDXWebKitApi alloc] initWithContext:self.context] provideKitViewWithURL:url];
    }

    [self.lifeCycleTracker trackLifeCycleWithEvent:@"view_did_init_kit_view"];

    if (kitView) {
        kitView.lifecycleDelegate = self;
        [self setupKitView:kitView];
        if ([self.containerLifecycleDelegate respondsToSelector:@selector(containerWillStartLoading:)]) {
            [self.containerLifecycleDelegate containerWillStartLoading:self];
        }
        [kitView load];
    }
}

- (void)setupKitView:(UIView<BDXKitViewProtocol> *)kitView
{
    // add view
    [self.lifeCycleTracker trackLifeCycleWithEvent:@"view_will_setup_kit_view"];

    [self attachKitView:kitView];

    NSArray<Class> *xbridgeMethods = [self.context getObjForKey:kBDXContextKeyXBridgeMethods];
    [kitView registerXBridgeMethod:xbridgeMethods];

    // for old bridge
    NSArray *bridgeProviderClasses = [self.context getObjForKey:kBDXContextKeyBridgeProviderClasses];
    for (id bridgeProviderClass in bridgeProviderClasses) {
        id<BDXBridgeProviderProtocol> bridgeProvider = [[bridgeProviderClass alloc] init];
        if (bridgeProvider) {
            [bridgeProvider registerMethodsWithBridge:kitView.kitBridge inContainer:self];
        }
    }

    [self.lifeCycleTracker trackLifeCycleWithEvent:@"view_did_setup_kit_view"];
}

- (void)attachKitView:(UIView<BDXKitViewProtocol> *)kitView
{
    if (self.kitView == kitView) {
        return;
    }
    if (self.kitView) {
        [self.kitView removeFromSuperview];
    }
    self.kitView = kitView;
    if (!kitView) {
        return;
    }
    [self addSubview:kitView];

    [self addLoadingView];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)addLoadingView
{
    UIView<BDXLoadingViewProtocol> *view = [self.context getObjForKey:kBDXContextKeyLoadingView];
    if (!view || !self.config.showLoading) {
        return;
    }
    self.loadingView = view;
    if (self.loadingView) {
        [self addSubview:self.loadingView];
        self.loadingView.frame = self.bounds;
        [self.loadingView setNeedsLayout];
        [self.loadingView layoutIfNeeded];
        if ([self.loadingView respondsToSelector:@selector(startLoadingAnimation)]) {
            [self.loadingView startLoadingAnimation];
        }
    }
}

- (void)removeLoadingView
{
    if (self.loadingView.superview) {
        if ([self.loadingView respondsToSelector:@selector(stopLoadingAnimation)]) {
            [self.loadingView stopLoadingAnimation];
        }
        [self.loadingView removeFromSuperview];
    }
}

- (void)addLoadFailedView:(NSError *)error
{
    UIView<BDXLoadErrorViewProtocol> *view = [self.context getObjForKey:kBDXContextKeyLoadFailedView];
    if (!view || !self.config.showError) {
        return;
    }

    self.loadFailedView = view;
    if ([self.loadFailedView respondsToSelector:@selector(container:didReceiveError:)]) {
        [self.loadFailedView container:self didReceiveError:error];
    }
    self.loadFailedView.frame = self.bounds;
    [self addSubview:self.loadFailedView];
}

#pragma mark BDXKitLifecycleDelegate

- (void)view:(id<BDXKitViewProtocol>)view didStartFetchResourceWithURL:(NSString *_Nullable)url
{
    if ([self.containerLifecycleDelegate respondsToSelector:@selector(container:didStartFetchResourceWithURL:)]) {
        [self.containerLifecycleDelegate container:self didStartFetchResourceWithURL:url];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didFetchedResource:(nullable id<BDXResourceProtocol>)resource error:(nullable NSError *)error
{
    if ([self.containerLifecycleDelegate respondsToSelector:@selector(container:didFetchedResource:error:)]) {
        [self.containerLifecycleDelegate container:self didFetchedResource:resource error:error];
    }
}

- (void)viewDidFirstScreen:(id<BDXKitViewProtocol>)view
{
    if ([self.containerLifecycleDelegate respondsToSelector:@selector(containerDidFirstScreen:)]) {
        [self.containerLifecycleDelegate containerDidFirstScreen:self];
    }
}

- (void)viewDidUpdate:(id<BDXKitViewProtocol>)view
{
    if ([self.containerLifecycleDelegate respondsToSelector:@selector(containerDidUpdate:)]) {
        [self.containerLifecycleDelegate containerDidUpdate:self];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didRecieveError:(NSError *_Nullable)error
{
    if ([self.containerLifecycleDelegate respondsToSelector:@selector(container:didReceiveError:)]) {
        [self.containerLifecycleDelegate container:self didRecieveError:error];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didReceivePerformance:(NSDictionary *)perfDict
{
    if ([self.containerLifecycleDelegate respondsToSelector:@selector(container:didReceivePerformance:)]) {
        [self.containerLifecycleDelegate container:self didReceivePerformance:perfDict];
    }
}

- (void)viewDidStartLoading:(id<BDXKitViewProtocol>)view
{
    self.isLoading = YES;
    if ([self.containerLifecycleDelegate respondsToSelector:@selector(containerDidStartLoading:)]) {
        [self.containerLifecycleDelegate containerDidStartLoading:self];
    }
}

// TODO: 如果是模版解析错误，需要把错误的模版文件删除
- (void)view:(id<BDXKitViewProtocol>)view didLoadFailedWithUrl:(NSString *_Nullable)url error:(NSError *_Nullable)error
{
    if (!self.hasHandleFallback) {
        self.hasHandleFallback = YES;
        if (!BTD_isEmptyString(self.config.fallbackURL)) {
            [self loadWithURL:self.config.fallbackURL context:self.context];
            [self trackEvent:@"bdx_view_load_fallback" metric:nil category:nil];
            return;
        }
    }

    self.isLoading = NO;
    [self removeLoadingView];

    BOOL isLynxError = [error.domain isEqualToString:LynxErrorDomain];
    BOOL isLynxLoadError = isLynxError && (error.code == LynxErrorCodeTemplateProvider || error.code == LynxErrorCodeLoadTemplate || error.code == LynxErrorCodeLayout);

    // lynx 加载错误 或者 其它非 lynx 错误
    if (isLynxLoadError || !isLynxError) {
        if (self.config.showError) {
            [self addLoadFailedView:error];
        }
    }
    [self trackEvent:@"bdx_view_load_failed" metric:nil category:nil];

    if ([self.containerLifecycleDelegate respondsToSelector:@selector(container:didLoadFailedWithUrl:error:)]) {
        [self.containerLifecycleDelegate container:self didLoadFailedWithUrl:url error:error];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didFinishLoadWithURL:(NSString *_Nullable)url
{
    self.isLoading = NO;
    [self removeLoadingView];

    // 加载成功，移除兜底view
    if (self.loadFailedView.superview) {
        [self.loadFailedView removeFromSuperview];
    }

    if ([self.containerLifecycleDelegate respondsToSelector:@selector(container:didFinishLoadWithURL:)]) {
        [self.containerLifecycleDelegate container:self didFinishLoadWithURL:url];
    }

    [self trackViewDidLoadSuccess];
}

- (void)view:(id<BDXKitViewProtocol>)view didChangeIntrinsicContentSize:(CGSize)size
{
    CGFloat width = size.width > 0 ? size.width : self.frame.size.width;
    CGFloat height = size.height > 0 ? size.height : self.frame.size.height;
    CGRect frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, height);
    if (self.bdxContentMode == BDXViewContentModeFitSize) {
        self.frame = frame;
    } else if (self.bdxContentMode == BDXViewContentModeFixedWidth) {
        self.frame = CGRectMake(frame.origin.x, frame.origin.y, self.frame.size.width, frame.size.height);
    } else if (self.bdxContentMode == BDXViewContentModeFixedHeight) {
        self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, self.frame.size.height);
    } else if (self.bdxContentMode == BDXViewContentModeFixedSize) {
        //  when mode is BDXViewContentModeFixedSize , no need to set frame to content size
    }

    self.contentSize = size;
    [self invalidateIntrinsicContentSize];
    if ([self.containerLifecycleDelegate respondsToSelector:@selector(container:didChangeIntrinsicContentSize:)]) {
        [self.containerLifecycleDelegate container:self didChangeIntrinsicContentSize:size];
    }
}

- (CGSize)intrinsicContentSize
{
    if (self.bdxContentMode == BDXViewContentModeFitSize) {
        return self.contentSize;
    }
    if (self.bdxContentMode == BDXViewContentModeFixedWidth) {
        return CGSizeMake(self.frame.size.width, self.contentSize.height);
    }
    if (self.bdxContentMode == BDXViewContentModeFixedHeight) {
        return CGSizeMake(self.contentSize.width, self.frame.size.height);
    }

    return self.frame.size;
}

- (id<BDXMonitorProtocol>)lifeCycleTracker
{
    // 因为要到load里面才有self.context，因此在load以前不能调用lifeCycleTracker
    NSAssert(self.context, @"self.context is nil");
    id<BDXMonitorProtocol> lifeCycleTracker = [self.context getObjForKey:@"lifeCycleTracker"];
    if (!lifeCycleTracker) {
        // every bdxview has its own tracker , thus init tracker manually.
        Class monitorClass = BDXSERVICE_CLASS(BDXMonitorProtocol, nil);
        lifeCycleTracker = [[monitorClass alloc] init];
        [self.context registerStrongObj:lifeCycleTracker forKey:@"lifeCycleTracker"];
    }

    return lifeCycleTracker;
}

- (void)dealloc
{
    // Send dealloc notification
    NSDictionary *params = @{@"eventName": @"dealloc", @"data": @{@"containerID": self.containerID ?: @""}};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BDXContainerNotification" object:nil userInfo:params];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    NSMutableDictionary *lifeCycleMetric = [NSMutableDictionary dictionary];
    CFAbsoluteTime baseline = [self.lifeCycleTracker.lifeCycleDictionary[@"baseline"] doubleValue];
    [self.lifeCycleTracker.lifeCycleDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSNumber *timeStamp, BOOL *_Nonnull stop) {
        if ([key isEqualToString:@"baseline"]) {
            return;
        }
        lifeCycleMetric[key] = @([timeStamp doubleValue] - baseline);
    }];
    [self.lifeCycleTracker clearLifeCycleEventDic];

    NSTimeInterval current = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    lifeCycleMetric[@"stay_duration"] = @(current - self.initTimeStamp);
    [self trackEvent:@"bdx_detail_life_cycle" metric:lifeCycleMetric category:@{@"loading_status": self.isLoading ? @"1" : @"0"}];
    [self.lifeCycleTracker clearLifeCycleEventDic];
}

#pragma mark - BDXKitViewProtocol/BDXContainerProtocol
- (void)registerUI:(Class)ui withName:(NSString *)name
{
    if (self.kitView && [self.kitView respondsToSelector:@selector(registerUI:withName:)]) {
        [self.kitView registerUI:ui withName:name];
    }
}


- (void)reload
{
    [self.kitView reloadWithContext:self.context];
}
- (void)reloadWithContext:(BDXContext *)context
{
    if (self.loadFailedView) {
        [self.loadFailedView removeFromSuperview];
    }

    [self addLoadingView];

    if (self.kitView) {
        [self.kitView reloadWithContext:context];
    }
}

- (void)updateData:(id)data processorName:(nonnull NSString *)processor
{
    if (self.kitView && [self.kitView respondsToSelector:@selector(updateData:processorName:)]) {
        [self.kitView updateData:data processorName:processor];
    }
}

- (void)sendEvent:(NSString *)event params:(NSDictionary *)data
{
    if ([self.kitView respondsToSelector:@selector(sendEvent:params:)]) {
        [self.kitView sendEvent:event params:data];
    }
}

- (void)trackEvent:(nonnull NSString *)eventName metric:(nullable NSDictionary *)metric category:(nullable NSDictionary *)category
{
    // 因为lifeCycleTracker依赖于self.context，要到load里面才有self.context，因此在load以前不能调用lifeCycleTracker
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSDictionary *queries = [self.url btd_queryItemsWithDecoding];
    params[@"url"] = self.originURL.absoluteString;
    params[@"bid"] = [queries btd_stringValueForKey:@"report_bid" default:@"bullet_lynx_biz"];
    params[@"pid"] = [queries btd_stringValueForKey:@"report_pid" default:@"/bullet_lynx_page"];

    NSMutableDictionary *categoryNew = [[NSMutableDictionary alloc] initWithDictionary:category];
    NSArray *popupHosts = @[@"lynx_popup", @"lynxview_popup", @"webview_popup"];
    BOOL isPopup = [popupHosts containsObject:self.originURL.host];
    categoryNew[@"containerType"] = isPopup ? @"1" : @"0";

    BOOL isLynx = [self.kitView conformsToProtocol:@protocol(BDXLynxViewProtocol)];
    __auto_type platform = isLynx ? BDXMonitorReportPlatformLynx : BDXMonitorReportPlatformWebView;
    NSString *aid = [self.context getObjForKey:kBDXContextKeyAid];
    [self.lifeCycleTracker reportWithEventName:eventName bizTag:nil commonParams:params metric:metric category:categoryNew extra:nil platform:platform aid:aid maySample:YES];
}

- (void)trackViewDidLoadSuccess
{
    // track bdx_view_load_success evnet
    NSTimeInterval current = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    NSMutableDictionary *metric = [[NSMutableDictionary alloc] init];
    metric[@"init_to_render_duration"] = @(current - self.initTimeStamp);
    metric[@"load_to_render_duration"] = @(current - self.beginLoadTimeStamp);
    [self trackEvent:@"bdx_view_load_success" metric:metric category:@{@"is_first_draw": self.isFirstDraw ? @"1" : @"0"}];
    self.isFirstDraw = NO;
}

@end
