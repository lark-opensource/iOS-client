//
//  IESLynxMonitor.m
//  IESLiveKit
//
//  Created by 小阿凉 on 2020/2/26.
//

#import "IESLynxMonitor.h"
#import "IESLynxMonitorConfig.h"
#import "IESLynxPerformanceDictionary.h"
#import <Lynx/LynxView.h>
#import <Lynx/LynxVersion.h>
#import <Lynx/LynxError.h>
#import <Heimdallr/HMDTTMonitor.h>
#import "LynxView+Monitor.h"
#import "IESLiveMonitorUtils.h"
#import <objc/runtime.h>
#import "IESLiveDefaultSettingModel.h"
#import "BDHybridBaseMonitor.h"

typedef NS_ENUM(NSInteger, IESLynxMonitorStatus) {
    IESLynxMonitorStatusSucceed,
    IESLynxMonitorStatusFailed,
};

@interface IESLynxMonitor ()

@property (nonatomic) IESLynxMonitorConfig *config;
@property (nonatomic, weak) LynxView *lynxView;
@property (nonatomic) IESLynxPerformanceDictionary *performanceDic;

@property (nonatomic) NSDictionary *perf;
@property (nonatomic) BOOL isFirstTime;

// Hybrid Monitor
@property (nonatomic, assign) CFTimeInterval pageStartTime;     // 页面开始
@property (nonatomic, assign) CFTimeInterval startLoadTime;     // 开始加载或刷新
@property (nonatomic, assign) CFTimeInterval loadFinishTime;    // 加载完成
@property (nonatomic, assign) CFTimeInterval firstScreenTime;   // 首屏时间

@property (nonatomic, strong) NSMutableDictionary *classSettingMap; //class和setting的映射表，由sharedMonitor维护

@end

@implementation IESLynxMonitor

+ (void)startMonitor {
    [self startMonitorWithSettingModel:[IESLiveDefaultSettingModel defaultModel]];
}

+ (void)startMonitorWithSettingModel:(IESLiveDefaultSettingModel *)settingModel {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [LynxView class];
        IMP imp = class_getMethodImplementation(cls, @selector(bdlm_initWithBuilderBlock:));
        if (imp) {
            [IESLiveMonitorUtils hookMethod:cls fromSelStr:@"initWithBuilderBlock:" toSelStr:@"bdlm_initWithBuilderBlock:" targetIMP:imp];
        }

        IMP clearIMP = class_getMethodImplementation(cls, @selector(bdlm_clearForDestroy));
        if (clearIMP) {
            [IESLiveMonitorUtils hookMethod:cls fromSelStr:@"clearForDestroy" toSelStr:@"bdlm_clearForDestroy" targetIMP:clearIMP];
        }

        IMP moveWindowIMP = class_getMethodImplementation(cls, @selector(bdlm_willMoveToWindow:));
        if (moveWindowIMP) {
            [IESLiveMonitorUtils hookMethod:cls fromSelStr:@"willMoveToWindow:" toSelStr:@"bdlm_willMoveToWindow:" targetIMP:moveWindowIMP];
        }
        
//        imp = class_getMethodImplementation(cls, @selector(bdlm_removeFromSuperview));
//        if (imp) {
//            [IESLiveMonitorUtils hookMethod:cls fromSelStr:@"removeFromSuperview" toSelStr:@"bdlm_removeFromSuperview" targetIMP:imp];
//        }
        
        [[IESLynxMonitor sharedMonitor].classSettingMap setValue:settingModel forKey:NSStringFromClass(cls)];
    });
    [self startWithSetting:settingModel];
}

+ (void)startWithSetting:(IESLiveDefaultSettingModel *)settingModel {
    [self startMonitorItem:@"BDLynxCustomErrorMonitor" setting:[settingModel toDic]];
    [self startMonitorItem:@"BDLynxJSBMonitor" setting:[settingModel toDic]];
}

+ (void)startMonitorItem:(NSString *)monitorName setting:(NSDictionary *)setting {
    Class monitorClass = NSClassFromString(monitorName);
    if (monitorClass && [monitorClass respondsToSelector:@selector(startMonitorWithSetting:)]) {
        [monitorClass startMonitorWithSetting:setting];
    }
}

+ (instancetype)sharedMonitor {
    static IESLynxMonitor *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[IESLynxMonitor alloc] init];
        s.classSettingMap = [[NSMutableDictionary alloc] init];
    });
    return s;
}

- (instancetype)initWithConfig:(IESLynxMonitorConfig *)config {
    if (self = [super init]) {
        self.config = config;
        _isFirstTime = YES;
    }
    
    return self;
}

- (void)dealloc
{
    if (self.config) {
        [self trackLynxService:@"lynx_overview_service" status:IESLynxMonitorStatusSucceed duration:0 extra:@{}];
    }
}

- (IESLynxPerformanceDictionary *)performanceDic {
    if (!_performanceDic) {
        _performanceDic = [[IESLynxPerformanceDictionary alloc] initWithConfig:self.config];
    }
    
    return _performanceDic;
}

#pragma mark - Public
// Lynx JS上报的Lynx监控(旧)
- (void)lynxMonitor:(NSDictionary *)data {
    if (self.config) {
        [self.performanceDic reportCustomWithDic:data];
    }
}
// Lynx JS上报的Lynx监控(新)
- (void)lynxMonitor:(NSDictionary *)data lynxView:(LynxView *)view
{
    if (view.performanceDic && [data count] > 0) {
        [view.performanceDic reportCustomWithDic:data];
    }
}

// Lynx JS 抛出异常（旧）
- (void)sendJSError:(NSString *)jsError {
    // 空实现，兼容旧接口
}

#pragma mark - LynxViewClient

- (void)trackStart:(LynxView *)view {
    if (![[IESLynxMonitor sharedMonitor] isEqual:self]) {
        self.lynxView = view;
    }

    long long ts = [IESLiveMonitorUtils formatedTimeInterval];
    view.performanceDic.isFirstLoad = YES;
    view.performanceDic.pageStartTs = ts;
    // 兼容ies已有的使用monitor的方式（new一个新对象并配置一个config）
    if (self.config && view == self.lynxView) {
        _pageStartTime = ts;
        [self trackLynxService:@"lynx_initial_all" status:IESLynxMonitorStatusSucceed duration:0 extra:@{}];
        [self trackLynxService:@"lynx_offline" status:(!self.config.isOffline ? IESLynxMonitorStatusSucceed : IESLynxMonitorStatusFailed) duration:0 extra:@{}];
    }
}

- (void)lynxViewDidStartLoading:(LynxView *)view
{
    // 1 Lynx模板开始加载 + 刷新
    long long ts = [IESLiveMonitorUtils formatedTimeInterval];
    [view.performanceDic updateNavigationID:[NSUUID UUID].UUIDString url:view.url needUpdateCS:YES startLoadTs:ts loadFinishTs:0 firstScreenTs:0];
    [view.performanceDic coverWithDic:@{kLynxMonitorLoadStart : @(ts)}];
    [view.performanceDic reportNavigationStart];
    [self bdhmResetLynxPerfUploadState:view];
    if (!view.performanceDic.hasDidLoad) {
        view.performanceDic.hasDidLoad = YES;
    } else {
        [view.performanceDic setContainerReuse:YES];
    }
    // 兼容ies已有的使用monitor的方式（new一个新对象并配置一个config）
    if (self.config && view == self.lynxView) {
        _startLoadTime = ts;
        CFTimeInterval duration = self.isFirstTime ? _startLoadTime - _pageStartTime : 0;
        [self trackLynxService:@"lynx_page_start"
                        status:IESLynxMonitorStatusSucceed
                      duration:duration
                         extra:@{}];
    }
}

- (void)bdhmResetLynxPerfUploadState:(LynxView *)lynxView {
    lynxView.performanceDic.hasReportPerf = NO;
    lynxView.performanceDic.onFirstLoadPefEnd = NO;
    lynxView.performanceDic.onRuntimeReadyEnd = NO;
    lynxView.performanceDic.onFirstScreenEnd = NO;
}

- (void)lynxView:(LynxView *)view didLoadFinishedWithUrl:(NSString *)url
{
    // 2 完成加载 + 刷新
    long long ts = [IESLiveMonitorUtils formatedTimeInterval];
    view.performanceDic.loadFinishTs = ts;
    [self updatePageVersionFromLynxView:view];
    [view.performanceDic coverWithDic:@{kLynxMonitorLoadFinish : @(ts)}];
    // 兼容ies已有的使用monitor的方式（new一个新对象并配置一个config）
    if (self.config && view == self.lynxView) {
        _loadFinishTime = ts;
        CFTimeInterval duration = _loadFinishTime - _startLoadTime;
        [self trackLynxService:@"lynx_page_load_all"
                        status:IESLynxMonitorStatusSucceed
                      duration:duration
                         extra:@{}];
    }
}

- (void)lynxView:(LynxView*)view didReceiveFirstLoadPerf:(LynxPerformance*)perf
{
    // 3 第一次加载完成 + perf + 刷新
    view.performanceDic.perf = perf.toDictionary;
    // 新版本的lynx性能数据中已经带上了fp，无需自己计算
    id fp = view.performanceDic.perf[@"first_page_layout"];
    if (fp) {
        [view.performanceDic coverWithDic:@{@"fp": fp, @"fmp": fp}];
    }
    [view.performanceDic coverWithDic:@{kLynxMonitorState : @(0)}];
    [view.performanceDic coverWithDic:view.performanceDic.perf];
    view.performanceDic.onFirstLoadPefEnd = YES;
    [self checkAvailableUploadPerf:view];
    // 兼容ies已有的使用monitor的方式（new一个新对象并配置一个config）
    if (self.config && view == self.lynxView) {
        _perf = perf.toDictionary;
        [view sendGlobalEvent:@"perf" withParams:@[@{
            @"perfBaseTimeStamp" : @([IESLiveMonitorUtils formatedTimeInterval]),
            @"perf" : _perf ? : @{}
        }]];
    }
}

- (void)lynxViewDidFirstScreen:(LynxView *)view
{
    // 4 Lynx完成首屏渲染 + 刷新
    long long ts = [IESLiveMonitorUtils formatedTimeInterval];
    view.performanceDic.firstScreenTs = ts;
    view.performanceDic.isFirstLoad = NO;
    view.performanceDic.firstScreenTs = ts;
    [view.performanceDic coverWithDic:@{kLynxMonitorFirstScreen : @(ts)}];
    view.performanceDic.onFirstScreenEnd = YES;
    [self checkAvailableUploadPerf:view];
    // 兼容ies已有的使用monitor的方式（new一个新对象并配置一个config）
    if (self.config && view == self.lynxView) {
        _firstScreenTime = ts;
        CFTimeInterval duration = _firstScreenTime - _startLoadTime;
        [self trackLynxService:@"lynx_first_screen"
                        status:IESLynxMonitorStatusSucceed
                      duration:duration
                         extra:@{}];
        _isFirstTime = NO;
    }
}

- (void)lynxViewDidConstructRuntime:(LynxView*)view {
    [view.performanceDic coverWithDic:@{kLynxMonitorRuntimeReady : @([IESLiveMonitorUtils formatedTimeInterval])}];
    view.performanceDic.onRuntimeReadyEnd = YES;
    [self checkAvailableUploadPerf:view];
}

- (void)checkAvailableUploadPerf:(LynxView *)view {
    IESLynxPerformanceDictionary *lynxPerfDict = view.performanceDic;
    BOOL isAllEnvReady = lynxPerfDict.onFirstScreenEnd && lynxPerfDict.onFirstLoadPefEnd && lynxPerfDict.onRuntimeReadyEnd;
    if (isAllEnvReady) {
        [lynxPerfDict reportPerformance];
    }
}

- (void)lynxView:(LynxView*)view didReceiveUpdatePerf:(LynxPerformance *)perf
{
    // 刷新perf
    NSMutableDictionary *dict = [view.performanceDic.perf mutableCopy];
    [dict addEntriesFromDictionary:perf.toDictionary];
    view.performanceDic.perf = [dict copy];

    // 兼容ies已有的使用monitor的方式（new一个新对象并配置一个config）
    if (self.config && view == self.lynxView) {
        NSMutableDictionary *dict = [_perf mutableCopy];
        [dict addEntriesFromDictionary:perf.toDictionary];
        _perf = [dict copy];
        [self trackLynxService:@"lynx_update_page" status:IESLynxMonitorStatusSucceed duration:0 extra:@{}];
    }
}

- (void)lynxView:(LynxView *)view didRecieveError:(NSError *)error
{
    [view.performanceDic reportRequestError:error];
    
    NSInteger errCode = error.code;
    long long ts = [IESLiveMonitorUtils formatedTimeInterval];
    [self updatePageVersionFromLynxView:view];
    // 新版本 didLoadFailedWithUrl 已经废弃，该错误会以 LynxErrorCodeLoadTemplate 作为错误码落在此方法中
    if (errCode == LynxErrorCodeLoadTemplate || errCode == LynxErrorCodeTemplateProvider) {
        // 兼容ies已有的使用monitor的方式（new一个新对象并配置一个config）
        if (self.config && view == self.lynxView) {
            [self trackLynxService:@"lynx_page_load_all" status:IESLynxMonitorStatusFailed duration:0 extra:@{
                @"err_log": error.userInfo ? : @{}
            }];
            [self trackLynxService:@"lynx_page_load_error" status:IESLynxMonitorStatusFailed duration:0 extra:@{
                @"err_log": error.userInfo ? : @{}
            }];
        }
        
        [view.performanceDic coverWithDic:@{kLynxMonitorLoadFailed : @(ts), kLynxMonitorState : @(1)}];
        [view.performanceDic reportPerformance];
    } else {
        // 兼容ies已有的使用monitor的方式（new一个新对象并配置一个config）
        if (self.config && view == self.lynxView) {
            [self trackLynxService:@"lynx_error" status:IESLynxMonitorStatusFailed duration:0 extra:@{
                @"err_log": error.userInfo ? : @{}
            }];
        }
    }
}

- (void)lynxView:(LynxView *)view didLoadFailedWithUrl:(NSString *)url error:(NSError *)error
{
    // 兼容ies已有的使用monitor的方式（new一个新对象并配置一个config）
    if (self.config && view == self.lynxView) {
        // 加载失败
        [self trackLynxService:@"lynx_page_load_all" status:IESLynxMonitorStatusFailed duration:0 extra:@{
            @"err_log": error.userInfo ? : @{}
        }];
        [self trackLynxService:@"lynx_page_load_error" status:IESLynxMonitorStatusFailed duration:0 extra:@{
            @"err_log": error.userInfo ? : @{}
        }];
    }
    
    [view.performanceDic coverWithDic:@{kLynxMonitorLoadFailed : @([IESLiveMonitorUtils formatedTimeInterval]) , kLynxMonitorState : @(1)}];
    [view.performanceDic reportPerformance];
}
// 旧接口，兼容老的调用方式
- (void)trackLynxService:(NSString *)service status:(NSInteger)status duration:(CFTimeInterval)duration extra:(NSDictionary *)extraInfo {
    if ([[IESLynxMonitor sharedMonitor] isEqual:self]) {
        [self trackLynxService:service status:status duration:duration extra:extraInfo config:self.config lynxView:self.lynxView];
    } else if (self.config) {
        NSMutableDictionary *extra = [NSMutableDictionary dictionaryWithDictionary:extraInfo];
        [extra addEntriesFromDictionary:self.config.commonParams ? : @{}];
        [extra setValue:@(self.isFirstTime) forKey:@"isFirstTime"];
        [extra setValue:@"perfomance" forKey:kLynxMonitorEventType];
        [extra setValue:@{
            @"perfomance" : self.perf ? : @{},
            @"performance" : self.perf ? : @{},
            @"navigation" : @{
                    @"initStart" : @(_pageStartTime),
                    @"pageStart" : @(_startLoadTime),
                    @"loadEnd" : @(_loadFinishTime),
                    @"firstScreen" : @(_firstScreenTime)
            }
        } forKey:@"event"];
        
        NSDictionary *category = @{ @"status" : @(status) };
        NSDictionary *metric = @{ @"duration": @(duration) };
        NSString *realService = [NSString stringWithFormat:@"%@_%@", self.config.channel, service];
        
        [[HMDTTMonitor defaultManager] hmdTrackService:realService
                                                metric:metric
                                              category:category
                                                 extra:extra];

    }
}
// 新接口，给单例使用
- (void)trackLynxService:(NSString *)service status:(NSInteger)status duration:(CFTimeInterval)duration extra:(NSDictionary *)extraInfo config:(IESLynxMonitorConfig *)config lynxView:(LynxView *)view {
    // 兼容ies已有的使用monitor的方式（一个config就能上报数据）因为使用方有可能view还没创建就调用这接口进行上报
    if (config) {
        NSMutableDictionary *extra = [NSMutableDictionary dictionaryWithDictionary:extraInfo];
        [extra addEntriesFromDictionary:config.commonParams];
        [extra setValue:@(view.performanceDic.isFirstLoad ?: 0) forKey:@"isFirstTime"];
        [extra setValue:@"perfomance" forKey:kLynxMonitorEventType];
        [extra setValue:@{
            @"performance" : view.performanceDic.perf ? : @{},
            @"navigation" : @{
                    @"initStart" : @(view.performanceDic.pageStartTs ?: 0),
                    @"pageStart" : @(view.performanceDic.startLoadTs ?: 0),
                    @"loadEnd" : @(view.performanceDic.loadFinishTs ?: 0),
                    @"firstScreen" : @(view.performanceDic.firstScreenTs ?: 0)
            }
        } forKey:@"event"];
        
        NSDictionary *category = @{ @"status" : @(status) };
        NSDictionary *metric = @{ @"duration": @(duration) };
        NSString *realService = [NSString stringWithFormat:@"%@_%@", config.channel, service];
        
        [[HMDTTMonitor defaultManager] hmdTrackService:realService
                                                metric:metric
                                              category:category
                                                 extra:extra];
    }
}

#pragma mark --- page version
- (void)updatePageVersionFromLynxView:(LynxView *)view {
    NSString *lynxVersion = [LynxVersion versionString];
    float fixVersionNumber = 2.1;
    float curVersionNumber = [lynxVersion floatValue];
    if (curVersionNumber < fixVersionNumber) { return; }
    if ([view respondsToSelector:@selector(lynxConfigInfo)]) {
        id configInfo = [view performSelector:@selector(lynxConfigInfo)];
        Class ConfigCls = NSClassFromString(@"LynxConfigInfo");
        if (ConfigCls && [configInfo isKindOfClass:ConfigCls]) {
            if ([configInfo respondsToSelector:@selector(pageVersion)]) {
                id pageVersion = [configInfo performSelector:@selector(pageVersion)];
                if ([pageVersion isKindOfClass:[NSString class]]) {
                    [view.performanceDic updateLynxCardVersion:pageVersion];
                }
            }
        }
    }
    else if ([view respondsToSelector:@selector(cardVersion)]) {
        NSString *cardVersion = [view performSelector:@selector(cardVersion)];
        if ([cardVersion isKindOfClass:[NSString class]]) {
            [view.performanceDic updateLynxCardVersion:cardVersion];
        }
    }
}

@end
