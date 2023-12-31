//
//  BDXLynxView.m
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import "BDXLynxView.h"
#import "BDXLazyLoadProxy.h"

#import <Lynx/BDLynxBridge.h>
#import <Lynx/LynxError.h>
#import <Lynx/LynxGroup.h>
#import <Lynx/LynxTemplateProvider.h>
#import <Lynx/LynxVersion.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxViewClient.h>
#import <Lynx/LynxWeakProxy.h>
#import <Lynx/NavigationModule.h>

#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDXBridgeKit/BDXBridge.h>
#import <BDXBridgeKit/BDXBridgeContainerPool.h>
#import <BDXBridgeKit/BDXBridgeMethod.h>
#import <BDXBridgeKit/LynxView+BDXBridgeContainer.h>
#import <BDXBridgeKit/NSObject+BDXBridgeContainer.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/UIApplication+BTDAdditions.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXMonitorProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXContext.h>
#import <mach/mach_time.h>
#import <objc/runtime.h>
#import "BDXLynxResourceProvider.h"
#import <IESWebViewMonitor/IESLynxMonitor.h>
#import <IESWebViewMonitor/IESLiveDefaultSettingModel.h>

#if BDLynxGeckoEnable
#endif

static NSString *const kBDLynxTempleteUrlDomain = @"kBDLynxTempleteUrlDomain";

static inline void dispatch_main_safe(dispatch_block_t block)
{
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@interface BDXLynxView () <LynxViewLifecycle, BDXLynxResourceProviderDelegate>

@property(nonatomic, strong) LynxConfig *lynxConfig;
@property(nonatomic, strong) BDXLynxResourceProvider *internalResourceProvider;

@property(nonatomic, copy) NSString *channel;
@property(nonatomic, copy) NSString *sessionID;
@property(nonatomic, copy) NSString *containerID;
@property(nonatomic, strong) LynxView *lynxView;
@property(nonatomic, strong) NSData *resData;
@property(nonatomic, strong) BDXLynxKitParams *params;

@property(nonatomic, assign) BDXLynxViewSizeMode widthMode;
@property(nonatomic, assign) BDXLynxViewSizeMode heightMode;

@property(nonatomic, strong) LynxTemplateData *globalProps;
@property(nonatomic, strong) BDXLazyLoadProxy* bridgeProxy;
@property(nonatomic, strong) BDXLazyLoadProxy* lynxViewProxy;

@end

@implementation BDXLynxView

@synthesize lifecycleDelegate;

+ (LynxGroup *)defaultGroup
{
    static LynxGroup *_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _group = [[LynxGroup alloc] initWithName:@"_default"];
    });
    return _group;
}

- (instancetype)initWithFrame:(CGRect)frame params:(BDXKitParams *)params
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configWithParams:params];
    }
    return self;
}

#pragma mark - load methods

- (void)configWithParams:(BDXKitParams *)params
{
    _params = (BDXLynxKitParams *)params;
    _widthMode = _params.widthMode;
    _heightMode = _params.heightMode;
    _globalProps = [[LynxTemplateData alloc] initWithDictionary:[self defaultGlobalProps]];
    if (_params.globalProps) {
        [self configGlobalProps:_params.globalProps];
    }
    [self setupMonitor];
}

- (void)load
{
    LynxTemplateData *initialData = nil;

    BDXLynxKitParams *params = self.params;

    if (params.initialProperties) {
        if ([params.initialProperties isKindOfClass:[NSString class]]) {
            initialData = [[LynxTemplateData alloc] initWithJson:params.initialProperties];
        } else if ([params.initialProperties isKindOfClass:[NSDictionary class]]) {
            initialData = [[LynxTemplateData alloc] initWithDictionary:params.initialProperties];
        } else if ([params.initialProperties isKindOfClass:LynxTemplateData.class]) {
            initialData = params.initialProperties;
        }
    } else if ([[_params.context getObjForKey:kBDXContextKeyPrefetchInitData] isKindOfClass:NSDictionary.class]) {
        initialData = [[LynxTemplateData alloc] initWithDictionary:[_params.context getObjForKey:kBDXContextKeyPrefetchInitData]];
    }

    if([params.initialPropertiesState isKindOfClass:[NSString class]]){
        [initialData markState:params.initialPropertiesState];
    }
    
    self.lynxView.bridge.globalPropsData = self.globalProps;
    
    self.lynxView.imageFetcher = params.imageFetcher ?: self.internalResourceProvider;
    self.lynxView.resourceFetcher = params.resourceFetcher ?: self.internalResourceProvider;
    self.internalResourceProvider.customTemplateProvider = params.templateProvider;

    if (params.templateData) {
        [self.lynxView loadTemplate:params.templateData withURL:params.localUrl ?: params.sourceUrl initData:initialData];
    } else if (params.sourceUrl) {
        [self.lynxView loadTemplateFromURL:params.sourceUrl initData:initialData];
    }

    [self insertSubview:self.lynxView atIndex:0];
}

- (void)reloadWithContext:(BDXContext *)context
{
    NSDictionary *initialData = [context getObjForKey:kBDXContextKeyInitialData];
    self.params.initialProperties = initialData;
    [self load];
}

- (void)updateData:(id)data processorName:(NSString *)processor
{
    if (!data) return;
    if ([data isKindOfClass:[NSDictionary class]]) {
        [_lynxView updateDataWithDictionary:data processorName:processor];
    } else if ([data isKindOfClass:[LynxTemplateData class]]) {
        [_lynxView updateDataWithTemplateData:data];
    } else if ([data isKindOfClass:[NSString class]]) {
        [_lynxView updateDataWithString:data processorName:processor];
    }
}

- (void)updateWithData:(id)data
{
    [self updateData:data processorName:nil];
}

#pragma mark - register
- (void)registerModule:(Class<LynxModule>)module
{
    [self.lynxConfig registerModule:module];
}

- (void)registerModule:(Class<LynxModule>)module param:(id)param
{
    [self.lynxConfig registerModule:module param:param];
}

- (void)registerUI:(Class)ui withName:(NSString *)name
{
    [self.lynxConfig registerUI:ui withName:name];
}

- (void)registerShadowNode:(Class)node withName:(NSString *)name
{
    [self.lynxConfig registerShadowNode:node withName:name];
}

- (void)registerXBridgeMethod:(NSArray<Class> *)bridgeMethods
{
    id<BDXBridgeContainerProtocol> container = self.lynxView;
    if (container) {
        for (Class methodClass in bridgeMethods) {
            if (![methodClass isSubclassOfClass:BDXBridgeMethod.class]) {
                NSAssert(NO, @"%@ must be kind of BDXBridgeMethod", NSStringFromClass(methodClass));
                return;
            }
            BDXBridgeMethod *method = (BDXBridgeMethod *)[[methodClass alloc] init];
            [container.bdx_bridge registerLocalMethod:method];
        }
    }
}

- (void)registerXBridgeMethodInstance:(NSArray<BDXBridgeMethod *> *)bridgeMethods
{
    id<BDXBridgeContainerProtocol> container = self.lynxView;
    ;
    if (container) {
        for (BDXBridgeMethod *method in bridgeMethods) {
            if ([method isKindOfClass:BDXBridgeMethod.class]) {
                [container.bdx_bridge registerLocalMethod:method];
            } else {
                NSAssert(NO, @"bridge methods should be kind of type: BDXBridgeMethod");
            }
        }
    }
}

#pragma mark - Optional
- (nullable UIView*)findViewWithName:(nonnull NSString*)name
{
    return [self.lynxView findViewWithName:name];
}

- (void)updateAppThemeWithKey:(NSString *)themeKey value:(NSString *)appTheme
{
    if (BTD_isEmptyString(themeKey) || BTD_isEmptyString(appTheme)) {
        return;
    }
    // 以下两种方式均可以实现主题切换，前端任意选择用哪种方式，
    // 方案1，抖音搜索目前使用的方案，通过globalProps设置
    if (![appTheme isEqualToString:[self.lynxView.bridge.globalProps btd_stringValueForKey:themeKey]]) {
        NSMutableDictionary *globalPropsM = [NSMutableDictionary dictionaryWithDictionary:self.lynxView.bridge.globalProps ?: @{}];
        globalPropsM[themeKey] = appTheme;
        self.lynxView.bridge.globalProps = globalPropsM;

        LynxTemplateData *data = [[LynxTemplateData alloc] initWithDictionary:@{@"__globalProps" : globalPropsM}];
        [data markState:@"__appTheme"];
        [self.lynxView updateDataWithTemplateData:data];
        [self.lynxView triggerLayout];
    }
    
    // 方案2
    LynxTheme *theme = [self.lynxView theme];
    if (theme == nil) {
        theme = [[LynxTheme alloc] init];
    }
    if (![[theme valueForKey:themeKey] isEqualToString:appTheme]) {
        [theme updateValue:appTheme forKey:themeKey];
        [self.lynxView setTheme:theme];
    }
}

#pragma mark - Bridge Handler

- (void)registerHandler:(BDXLynxBridgeHandler)handler forMethod:(NSString *)method
{
    [self.kitBridge registerHandler:handler forMethod:method];
}

- (void)sendEvent:(NSString *)event params:(nullable NSDictionary *)params
{
    [self sendEvent:event params:params callback:nil];
}

- (void)sendEvent:(NSString *)event params:(nullable NSDictionary *)params callback:(nullable void (^)(id _Nullable))callback
{
    [self.kitBridge callEvent:event params:params ?: @{}];
    !callback ?: callback(@YES);
}

- (void)onShow:(NSDictionary *)params
{
    NSString *event = [params btd_stringValueForKey:@"event" default:kBDXKitEventViewDidAppear];
    [self.proxyLynxView onEnterForeground];
    if (event) {
        [self sendEvent:event params:nil];
    }
}

// 触发前端的onHide
- (void)onHide:(NSDictionary *)params
{
    NSString *event = [params btd_stringValueForKey:@"event" default:kBDXKitEventViewDidDisappear];
    [self.proxyLynxView onEnterBackground];
    if (event) {
        [self sendEvent:event params:nil];
    }
}

- (NSDictionary *)defaultGlobalProps
{
    // @"containerID" will be set when lynxview has been created
    return @{
        @"screenWidth": @(UIScreen.mainScreen.bounds.size.width),
        @"screenHeight": @(UIScreen.mainScreen.bounds.size.height),
        @"statusBarHeight": @([UIDevice btd_isIPhoneXSeries] ? 44.0f : 20.0f),
        @"os": @"ios",
        @"osVersion": [UIDevice btd_OSVersion] ?: @"",
        @"channel": [UIApplication btd_currentChannel] ?: @"",
        @"appName": [UIApplication btd_appName] ?: @"",
        @"aid": [UIApplication btd_appID] ?: @"",
        @"appVersion": [UIApplication btd_versionName] ?: @"",
        @"language": [NSLocale preferredLanguages].firstObject ?: @"",
        @"lynxSdkVersion": [LynxVersion versionString] ?: @"",
        @"deviceId": [BDTrackerProtocol deviceID] ?: @"",
        @"queryItems": self.params.queryItems ?: @{},
        @"isIPhoneX": [UIDevice btd_isIPhoneXSeries] ? @1 : @0,
        @"isIPhoneXMax": [UIDevice btd_isIPhoneXSeries] ? @1 : @0,
        @"safeAreaHeight": [UIDevice btd_isIPhoneXSeries] ? @(34) : @(0),
    };
}

- (NSDictionary *)queryItems
{
    NSMutableDictionary *dic = [(self.params.queryItems ?: @{}) mutableCopy];

    id<BDXMonitorProtocol> monitor = [self.params.context getObjForKey:@"lifeCycleTracker"];
    if (monitor) {
        NSNumber *initTimeStamp = monitor.lifeCycleDictionary[@"view_did_initialized"];
        if (initTimeStamp) {
            dic[@"containerInitTime"] = [initTimeStamp stringValue];
        }
    }
    return [dic copy];
}

#pragma mark - LynxViewLifecycle

- (void)lynxViewDidStartLoading:(LynxView *)view
{
    [self trackLifeCycleEvent:@"lynxview_did_start_loading" withParam:self.params];
    dispatch_main_safe(^{
        if ([self.lifecycleDelegate respondsToSelector:@selector(viewDidStartLoading:)]) {
            [self.lifecycleDelegate viewDidStartLoading:self];
        }
    });
}

- (void)lynxView:(LynxView *)view didLoadFinishedWithUrl:(NSString *)url
{
    if(!CGRectEqualToRect(self.frame, CGRectZero)){
        [_lynxView updateScreenMetricsWithWidth:self.frame.size.width height:self.frame.size.height];
    }

    [self trackLifeCycleEvent:@"lynxview_did_finished" withParam:self.params];
    dispatch_main_safe(^{
        [self.lynxView triggerLayout];
        self.lynxView.frame = CGRectMake(0, 0, self.lynxView.intrinsicContentSize.width, self.lynxView.intrinsicContentSize.height);
        if ([self.lifecycleDelegate respondsToSelector:@selector(view:didFinishLoadWithURL:)]) {
            [self.lifecycleDelegate view:self didFinishLoadWithURL:url];
        };
    });
}

- (void)lynxViewDidUpdate:(LynxView *)view
{
    dispatch_main_safe(^{
        if ([self.lifecycleDelegate respondsToSelector:@selector(viewDidUpdate:)]) {
            [self.lifecycleDelegate viewDidUpdate:self];
        }
    });
}

- (void)lynxViewDidChangeIntrinsicContentSize:(LynxView *)view
{
    //    self.lynxView.frame = CGRectMake(0, 0, view.intrinsicContentSize.width,
    //    view.intrinsicContentSize.height);
    if ([self.lifecycleDelegate respondsToSelector:@selector(view:didChangeIntrinsicContentSize:)]) {
        [self.lifecycleDelegate view:self didChangeIntrinsicContentSize:view.intrinsicContentSize];
    };
}

- (void)lynxView:(LynxView *)view didRecieveError:(NSError *)error
{
    dispatch_main_safe(^{
        if ([self.lifecycleDelegate respondsToSelector:@selector(view:didRecieveError:)]) {
            [self.lifecycleDelegate view:self didRecieveError:error];
        }

        // code in [100, 200] stands for load failed
        // LynxErrorCodeLoadTemplate = 100, LynxErrorCodeJavaScript = 201
        if (error.code >= LynxErrorCodeLoadTemplate && error.code < LynxErrorCodeJavaScript) {
            if ([self.lifecycleDelegate respondsToSelector:@selector(view:didLoadFailedWithUrl:error:)]) {
                [self.lifecycleDelegate view:self didLoadFailedWithUrl:self.params.sourceUrl ?: self.params.localUrl error:error];
            }
        }
    });
}

- (void)lynxViewDidFirstScreen:(LynxView *)view
{
    dispatch_main_safe(^{
        if ([self.lifecycleDelegate respondsToSelector:@selector(viewDidFirstScreen:)]) {
            [self.lifecycleDelegate viewDidFirstScreen:self];
        }
    });

    // monitor
    CFAbsoluteTime current = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    id<BDXMonitorProtocol> monitor = [self.params.context getObjForKey:@"lifeCycleTracker"];
    if (monitor) {
        NSNumber *initTimeStamp = monitor.lifeCycleDictionary[@"view_did_initialized"];
        [monitor trackLifeCycleWithEvent:@"lynx_view_did_first_screen"];
        if (initTimeStamp) {
            NSString *aid = [self.params.context getObjForKey:kBDXContextKeyAid];
            CFTimeInterval duration = current - [initTimeStamp doubleValue];
            [monitor reportWithEventName:@"hybrid_app_monitor_lynx_container_first_screen_duration" bizTag:nil commonParams:@{@"url": self.params.sourceUrl} metric:@{@"duration": @(duration)} category:nil extra:nil platform:BDXMonitorReportPlatformLynx aid:aid maySample:NO];
        }
    }
}

- (void)lynxView:(LynxView *)view didReceiveFirstLoadPerf:(LynxPerformance *)perf
{
    dispatch_main_safe(^{
        if ([self.lifecycleDelegate respondsToSelector:@selector(view:didReceivePerformance:)]) {
            NSDictionary *perfDict = [perf toDictionary];
            if (perfDict) {
                [self.lifecycleDelegate view:self didReceivePerformance:perfDict];
            }
        }
    });
}

- (void)lynxView:(LynxView *)view didReceiveUpdatePerf:(LynxPerformance *)perf
{
    dispatch_main_safe(^{
        if ([self.lifecycleDelegate respondsToSelector:@selector(view:didReceivePerformance:)]) {
            NSDictionary *perfDict = [perf toDictionary];
            if (perfDict) {
                [self.lifecycleDelegate view:self didReceivePerformance:perfDict];
            }
        }
    });
}

#pragma mark - Accessors

- (BDXLynxResourceProvider *)internalResourceProvider
{
    if (!_internalResourceProvider) {
        _internalResourceProvider = [BDXLynxResourceProvider new];
        _internalResourceProvider.templateSourceURL = self.params.sourceUrl;
        _internalResourceProvider.dynamic = @(self.params.dynamic);
        _internalResourceProvider.accessKey = self.params.accessKey;
        _internalResourceProvider.channel = self.params.channel;
        _internalResourceProvider.bundle = self.params.bundle;
        _internalResourceProvider.disableBuildin = self.params.disableBuildin;
        _internalResourceProvider.disableGurd = self.params.disableGurd;
        _internalResourceProvider.context = self.params.context;
        _internalResourceProvider.delegate = self;
    }

    return _internalResourceProvider;
}

- (LynxConfig *)lynxConfig
{
    if (!_lynxConfig) {
        _lynxConfig = [[LynxConfig alloc] initWithProvider:self.params.templateProvider ?: self.internalResourceProvider];
    }
    return _lynxConfig;
}

- (void)triggerLayout
{
    if (!_lynxView) {
        return;
    }

    switch (_widthMode) {
        case BDXLynxViewSizeModeUndefined:
            _lynxView.layoutWidthMode = LynxViewSizeModeUndefined;
            _lynxView.preferredMaxLayoutWidth = self.frame.size.width;
            break;
        case BDXLynxViewSizeModeExact:
            _lynxView.layoutWidthMode = LynxViewSizeModeExact;
            _lynxView.preferredLayoutWidth = self.frame.size.width;
            break;
        case BDXLynxViewSizeModeMax:
            _lynxView.layoutWidthMode = LynxViewSizeModeMax;
            _lynxView.preferredMaxLayoutWidth = self.frame.size.width;
            break;
        default:
            _lynxView.layoutWidthMode = LynxViewSizeModeUndefined;
            _lynxView.preferredMaxLayoutWidth = self.frame.size.width;
            break;
    }

    switch (_heightMode) {
        case BDXLynxViewSizeModeUndefined:
            _lynxView.layoutHeightMode = LynxViewSizeModeUndefined;
            _lynxView.preferredMaxLayoutHeight = self.frame.size.height;
            break;
        case BDXLynxViewSizeModeExact:
            _lynxView.layoutHeightMode = LynxViewSizeModeExact;
            _lynxView.preferredLayoutHeight = self.frame.size.height;
            break;
        case BDXLynxViewSizeModeMax:
            _lynxView.layoutHeightMode = LynxViewSizeModeMax;
            _lynxView.preferredMaxLayoutHeight = self.frame.size.height;
            break;
        default:
            _lynxView.layoutHeightMode = LynxViewSizeModeUndefined;
            _lynxView.preferredMaxLayoutHeight = self.frame.size.height;
            break;
    }
    
    if(!CGRectEqualToRect(self.frame, CGRectZero) && self.btd_viewController.modalPresentationStyle == UIModalPresentationFormSheet){
        [_lynxView updateScreenMetricsWithWidth:self.frame.size.width height:self.frame.size.height];
    }

    [_lynxView triggerLayout];
}

- (LynxView *)lynxView
{
    if (!_lynxView) {
        _lynxView = [[LynxView alloc] initWithContainerBuilderBlock:^(LynxViewBuilder *builder, NSString *containerID) {
            [builder setThreadStrategyForRender:LynxThreadStrategyForRenderAllOnUI];
            builder.config = self.lynxConfig;
            [builder.config registerModule:[NavigationModule class] param:nil];
            
            if (self.params.groupContext || self.params.disableShare || self.params.enableCanvas || self.params.extraJSPaths) {
                NSMutableArray *preloadScirpt = [[NSMutableArray alloc] init];
                if (self.params.extraJSPaths) {
                    [preloadScirpt addObjectsFromArray:self.params.extraJSPaths];
                }
                
                NSString* groupName = @"_default";
                if(self.params.disableShare){
                    groupName = [LynxGroup singleGroupTag];
                }
                else if(self.params.groupContext){
                    groupName = self.params.groupContext;
                }
                else{
                    if(self.params.enableCanvas){
                        groupName = @"_default_canvas";
                    }
                    else{
                        groupName = @"_default";
                    }
                }
                
                builder.group = [[LynxGroup alloc] initWithName:groupName withPreloadScript:preloadScirpt useProviderJsEnv:NO enableCanvas:self.params.enableCanvas];
            }
            else{
                builder.group = [BDXLynxView defaultGroup];
            }
        }];
        
        if(_lynxViewProxy){
            [_lynxViewProxy applyToTarget:_lynxView];
            _lynxViewProxy = nil;
        }
        
        [self trackLifeCycleEvent:@"lynxview_did_initialied" withParam:self.params];
        
        // make sure containerID always from lynxview.containerID
        [self.globalProps updateObject:self.containerID forKey:@"containerID"];
        
        [_lynxView bdx_setUpBridgeWithContainerID:self.containerID];
        if(_bridgeProxy){
            [_bridgeProxy applyToTarget:_lynxView.bridge];
            _bridgeProxy =  nil;
        }
        self.internalResourceProvider.lynxview = _lynxView;
        [_lynxView addLifecycleClient:self];
        NSString *aid = [self.params.context getObjForKey:kBDXContextKeyAid];
        [BDXSERVICE(BDXMonitorProtocol, nil) attachVirtualAid:aid toView:_lynxView];
        
        // 兼容老代码直接使用BDLynxBridge的时候，能通过LynxView获取上下文
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([_lynxView respondsToSelector:@selector(setBdx_params:)]) {
            [_lynxView performSelector:@selector(setBdx_params:) withObject:self.params];
        }
#pragma clang diagnostic pop
        [self triggerLayout];
    }
    return _lynxView;
}

- (UIView *)rawView
{
    return _lynxView;
}

- (LynxView *)proxyLynxView
{
    // use proxyLynxView inside BDLynxView.m to prevent lynxview from being created unexpectedly.
    if(_lynxView){
        return _lynxView;
    }
    
    return (LynxView*)self.lynxViewProxy;
}


- (NSString *)containerID
{
    NSAssert(_lynxView != nil, @"lynxview has not been created");
    return _lynxView.containerID;
}

- (id)kitBridge
{
    if(_lynxView.bridge){
        return _lynxView.bridge;
    }
    
    return self.bridgeProxy;
}

- (void)setSourceData:(NSData *)sourceData
{
    _resData = sourceData;
}

- (NSData *)sourceData
{
    if (_resData) {
        return _resData;
    }
    return nil;
}

- (void)configGlobalProps:(nonnull id)globalProps
{
    if ([globalProps isKindOfClass:NSDictionary.class]) {
        [self.globalProps updateWithDictionary:globalProps];
    } else if ([globalProps isKindOfClass:LynxTemplateData.class]) {
        [self.globalProps updateWithTemplateData:globalProps];
    }
}

- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event
{
    UIView *res = [super hitTest:point withEvent:event];
    if (res && [res isEqual:_lynxView]) {
        return [_lynxView hitTest:point withEvent:event];
    }
    return res;
}

-(BDXLazyLoadProxy*)bridgeProxy{
    if(!_bridgeProxy){
        _bridgeProxy = [[BDXLazyLoadProxy alloc] initWithTargetClass:[BDLynxBridge class]];
    }
    return _bridgeProxy;
}

- (BDXLazyLoadProxy*)lynxViewProxy{
    if(!_lynxViewProxy){
        _lynxViewProxy = [[BDXLazyLoadProxy alloc] initWithTargetClass:[LynxView class]];
    }
    return _lynxViewProxy;
}

#pragma mark - life cycle monitor
- (void)trackLifeCycleEvent:(NSString *)event withParam:(BDXKitParams *)param
{
    id<BDXMonitorProtocol> tracker = [param.context getObjForKey:@"lifeCycleTracker"];
    [tracker trackLifeCycleWithEvent:event];
}

#pragma mark - Monitor
- (void)setupMonitor {
    id monitorSettingModel = [self.params.context getObjForKey:kBDXContextKeyMonitorSettingModel];
    if ([monitorSettingModel isKindOfClass:[IESLiveDefaultSettingModel class]]) {
        [IESLynxMonitor startMonitorWithSettingModel:monitorSettingModel];
    }
    else {
        IESLiveDefaultSettingModel *monitorSettingModel = [IESLiveDefaultSettingModel defaultModel];
        [IESLynxMonitor startMonitorWithSettingModel:monitorSettingModel];
    }
}

#pragma mark - BDXLynxResourceProviderDelegate

- (void)resourceProviderDidStartLoadWithURL:(NSString *)url
{
    if ([self.lifecycleDelegate respondsToSelector:@selector(view:didStartFetchResourceWithURL:)]) {
        [self.lifecycleDelegate view:self didStartFetchResourceWithURL:url];
    }
}

- (void)resourceProviderDidFinsihLoadWithURL:(NSString *)url resource:(nullable id<BDXResourceProtocol>)resource error:(nullable NSError *)error
{
    if ([self.lifecycleDelegate respondsToSelector:@selector(view:didFetchedResource:error:)]) {
        [self.lifecycleDelegate view:self didFetchedResource:resource error:error];
    }
}

@end
