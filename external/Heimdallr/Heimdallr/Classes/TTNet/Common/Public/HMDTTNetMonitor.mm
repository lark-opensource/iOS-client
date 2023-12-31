
//
//  HMDTTNetMonitor.m
//  Heimdallr
//
//  Created by fengyadong on 2018/1/29.
//

#import "HMDTTNetMonitor.h"
#import <objc/runtime.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTNetworkManagerMonitorNotifier.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>
#import <TTNetworkManager/TTHttpRequestChromium.h>
#import "HMDHTTPDetailRecord.h"
#import "HMDNetworkHelper.h"
#import "HMDTTNetHelper.h"
#import "HeimdallrUtilities.h"
#import "HMDALogProtocol.h"
#import "NSString+HDMUtility.h"
#import "Heimdallr+Private.h"
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPTrackerConfig.h"
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#include "pthread_extended.h"
#import "HMDHTTPRequestTracker+Private.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "HMDUITrackerManagerSceneProtocol.h"
#import "HMDHTTPResponseInfo.h"
#import "HMDHTTPRequestInfo.h"
#import "HMDHTTPRequestTracker+HMDSampling.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDInjectedInfo+NetMonitorConfig.h"
#import "NSString+HMDSafe.h"
#import "HMDHTTPRequestInfo+Private.h"
#import "HMDHTTPDetailRecord+Private.h"

#define HMD_TTNETMONITOR_CONCURRENT_QUEUE "com.heimdallr.HMDTTNetMonitor.sample"

static NSString *const kHMDTTeNetImpChangeNotification = @"kHMDTTeNetImpChangeNotification";
static NSString *const kHMDSwizzleTTNetRequsetFilterBlockKey = @"kHMDSwizzleTTNetRequsetFilterBlockKey";
static NSString *const kHMDNetworkMonitorResponseInfoKey = @"kHMDNetworkMonitorResponseInfoKey";
static NSString *const kHMDNetworkManagerMonitorSampleNotification = @"kTTNetworkManagerMonitorSampleNotification";

static NSString *const kHMDNetworkMonitorApiAllSample = @"slardar_ios_api_all_sample";

static IMP hmd_originRequestFilterIMP;
static NSLock *hmd_TTNetSwizzleLock;
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

NSString *const kHMDTraceParentKeyStr = @"traceparent";

@interface TTNetworkManager (IMPSwitchMonitor)

@property (nonatomic, strong) NSNumber *hmdInjectedTraceLog;

+ (void)changeTTNetImpSwitch;
+ (void)hmdStartExchangeTTNetRequestFilterBlock;
+ (void)hmdStopExchangeTTNetRequestFilterBlock;
+ (void)hmd_setLibraryImpl:(TTNetworkManagerImplType)impl;

@end

@implementation TTNetworkManager (IMPSwitchMonitor)

+ (void)changeTTNetImpSwitch {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmd_swizzle_class_method([TTNetworkManager class], @selector(setLibraryImpl:), @selector(hmd_setLibraryImpl:));
    });
}

+ (void)hmd_setLibraryImpl:(TTNetworkManagerImplType)impl {
    [self hmd_setLibraryImpl:impl];
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDTTeNetImpChangeNotification object:nil];
}

+ (void)hmdStartExchangeTTNetRequestFilterBlock {
    [hmd_TTNetSwizzleLock lock];
    if ([[TTNetworkManager class] instancesRespondToSelector:@selector(setRequestFilterBlock:)]) {
        IMP currentFilterSetterIMP = class_getMethodImplementation([TTNetworkManager class], @selector(setRequestFilterBlock:));
        if (currentFilterSetterIMP!= NULL && currentFilterSetterIMP == hmd_originRequestFilterIMP) {
            hmd_swizzle_instance_method([TTNetworkManager class], @selector(setRequestFilterBlock:), @selector(hmd_setRequestFilterBlock:));
        }
    }
    [hmd_TTNetSwizzleLock unlock];
}

+ (void)hmdStopExchangeTTNetRequestFilterBlock {
     [hmd_TTNetSwizzleLock lock];
    if ([[TTNetworkManager class] instancesRespondToSelector:@selector(setRequestFilterBlock:)]) {
        IMP currentFilterSetterIMP = class_getMethodImplementation([TTNetworkManager class], @selector(setRequestFilterBlock:));
        if (currentFilterSetterIMP != NULL && currentFilterSetterIMP != hmd_originRequestFilterIMP) {
            hmd_swizzle_instance_method([TTNetworkManager class], @selector(setRequestFilterBlock:), @selector(hmd_setRequestFilterBlock:));
        }
    }
    [hmd_TTNetSwizzleLock unlock];
}

- (void)hmd_setRequestFilterBlock:(RequestFilterBlock)requestFilterBlock {
    RequestFilterBlock originRequestBlock = requestFilterBlock;
    RequestFilterBlock exhangeBlock = ^(TTHttpRequest *request) {
        HMDHTTPTrackerConfig *netMonitorConfig = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
        BOOL enableTraceLog = netMonitorConfig.enableTTNetCDNSample;
        BOOL enableApiAll = netMonitorConfig.enableAPIAllUpload;
        BOOL enableBaseApiAll = netMonitorConfig.baseApiAll.floatValue > 0;
        if (enableTraceLog && enableBaseApiAll) {
            [request setValue:@"01" forHTTPHeaderField:@"x-tt-trace-log"];
        } else if (enableTraceLog && enableApiAll) {
            [request setValue:@"02" forHTTPHeaderField:@"x-tt-trace-log"];
        }
        if (originRequestBlock) {
            originRequestBlock(request);
        }
    };
    self.hmdInjectedTraceLog = @(YES);
    //防止多线程问题会造成递归调用
    void (*ori_imp)(id,SEL,RequestFilterBlock) = (void (*)(id, SEL, RequestFilterBlock))hmd_originRequestFilterIMP;
    if (ori_imp) {
        ori_imp(self,@selector(setRequestFilterBlock:), exhangeBlock);
    };
}

- (void)setHmdInjectedTraceLog:(NSNumber *)hmdInjectedTraceLog {
    objc_setAssociatedObject(self, &kHMDSwizzleTTNetRequsetFilterBlockKey, hmdInjectedTraceLog, OBJC_ASSOCIATION_RETAIN);
}

- (NSNumber *)hmdInjectedTraceLog {
    return  objc_getAssociatedObject(self, &kHMDSwizzleTTNetRequsetFilterBlockKey);
}

@end

@interface HMDTTNetMonitor ()

@property (atomic, assign) BOOL isMonitoring;
@property (atomic, assign) BOOL isExchangeRequestFilter;
@property (nonatomic, strong) dispatch_queue_t ttnetMonitorQueue;

@end

@implementation HMDTTNetMonitor

+ (instancetype)sharedMonitor {
    static HMDTTNetMonitor *sharedMonitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMonitor = [[HMDTTNetMonitor alloc] init];
    });
    return sharedMonitor;
}

- (instancetype)init {
    if (self = [super init]) {
        _ttnetMonitorQueue = dispatch_queue_create(HMD_TTNETMONITOR_CONCURRENT_QUEUE, DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)start {
    if(self.isMonitoring) return;
    
    [[TTNetworkManagerMonitorNotifier defaultNotifier] setEnable:YES];
    [self registNotification];
    [self handleTTNetRequstFilter];
    self.isMonitoring = YES;
}

- (void)stop {
    if (!self.isMonitoring) return;
    [[TTNetworkManagerMonitorNotifier defaultNotifier] setEnable:NO];
    [self unregistNotification];
    [self stopHandleRequestFilter];
    self.isMonitoring = NO;
}

- (void)updateTTNetConfig {
    if (self.isMonitoring) {
        [self handleTTNetRequstFilter];
    }
}

+ (void)changeMonitorTTNetImpSwitch {
    [TTNetworkManager changeTTNetImpSwitch];
}

/// 开始设置 TTNet 的 request 拦截
- (void)handleTTNetRequstFilter {
    HMDHTTPTrackerConfig *netMonitorConfig = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
    BOOL enableTraceLog = netMonitorConfig.enableTTNetCDNSample;
    BOOL enableApiAll = netMonitorConfig.enableAPIAllUpload;
    BOOL enableBaseApiAll = netMonitorConfig.baseApiAll.floatValue > 0;

    if (self.isExchangeRequestFilter) { // 如果正在hook网络请求, 此时配置更新成关闭网路请求注入或者对当前用户不标记采样了,执行停止hook操作
        if (!enableTraceLog || (!enableBaseApiAll && !enableApiAll)) {
            [self stopHandleRequestFilter];
        }
        return;
    };
    if (!enableTraceLog) return;
    if (!enableBaseApiAll && !enableApiAll) return; // CDN采样率对齐 api_all 基准采样率

    // start 的时候获取 setRequestFilterBlock 的初始实现
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmd_originRequestFilterIMP = class_getMethodImplementation([TTNetworkManager class], @selector(setRequestFilterBlock:));
        hmd_TTNetSwizzleLock = [[NSLock alloc] init];
    });
    // 如果有TTNet 有 requestFilterBlock 设置 requestFilterBlock (拓展优先级最低, 如果 TTNet 提供的 API 都不能满足拦截需求但是现在有 requestFilterBlock 的话 设置 requestFilterBlock, 这个因为可能有多个项目在用所以可能会被覆盖)
    if ([[TTNetworkManager shareInstance] respondsToSelector:@selector(setRequestFilterBlock:)]) {
        pthread_mutex_lock(&mutex);
        [self startExchangeTTNetRequestFilterBlockSetter];
        pthread_mutex_unlock(&mutex);
    }
}

/// 停止设置 TTNet 的 request 拦截
- (void)stopHandleRequestFilter {
    pthread_mutex_lock(&mutex);
    if (self.isExchangeRequestFilter) {
        [self stopExchangeTTNetRequestFilterBlockSetter];
    }
    pthread_mutex_unlock(&mutex);
}

/// Hook RequestFilterBlock 的 setter, 把其他项目设置的存起来 然后执行完注入的 block 然后转发其他的block
- (void)startExchangeTTNetRequestFilterBlockSetter {
    if (self.isExchangeRequestFilter) { return;}
    // 如果ttnet没有 requestFilterBlock, TTNet的requestFilterBlock先指向HMD的
    if (![TTNetworkManager shareInstance].requestFilterBlock) {
        [TTNetworkManager shareInstance].requestFilterBlock = ^(TTHttpRequest *request) {
            HMDHTTPTrackerConfig *netMonitorConfig = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
            BOOL enableTraceLog = netMonitorConfig.enableTTNetCDNSample;
            BOOL enableApiAll = netMonitorConfig.enableAPIAllUpload;
            BOOL enableBaseApiAll = netMonitorConfig.baseApiAll.floatValue > 0;

            if (enableTraceLog && enableBaseApiAll) {
                [request setValue:@"01" forHTTPHeaderField:@"x-tt-trace-log"];
            } else if (enableTraceLog && enableApiAll) {
                [request setValue:@"02" forHTTPHeaderField:@"x-tt-trace-log"];
            }
        };
    } else if(![TTNetworkManager shareInstance].hmdInjectedTraceLog.boolValue) {
        // 如果这时候已经存在了 requsetFilter 但是 hmdOriginRequestFilterBlock 为空,说明没有hmd没有设置拦截的 block 这时候把拦截器设置成自己的
        TTNetworkManager *ttNetManager = [TTNetworkManager shareInstance];
        RequestFilterBlock originRequestBlock = [ttNetManager.requestFilterBlock copy] ;
        ttNetManager.requestFilterBlock = ^(TTHttpRequest *request) {
            HMDHTTPTrackerConfig *netMonitorConfig = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
            BOOL enableTraceLog = netMonitorConfig.enableTTNetCDNSample;
            BOOL enableApiAll = netMonitorConfig.enableAPIAllUpload;
            BOOL enableBaseApiAll = netMonitorConfig.baseApiAll.floatValue > 0;

            if (enableTraceLog && enableBaseApiAll) {
                [request setValue:@"01" forHTTPHeaderField:@"x-tt-trace-log"];
            } else if (enableTraceLog && enableApiAll) {
                [request setValue:@"02" forHTTPHeaderField:@"x-tt-trace-log"];
            }
            if (originRequestBlock) {
                originRequestBlock(request);
            }
        };
        [TTNetworkManager shareInstance].hmdInjectedTraceLog = @(YES);
    }
    // hook set 方法
    [TTNetworkManager hmdStartExchangeTTNetRequestFilterBlock];
    self.isExchangeRequestFilter = YES;
}

- (void)stopExchangeTTNetRequestFilterBlockSetter {
    if (!self.isExchangeRequestFilter) return;
    [TTNetworkManager hmdStopExchangeTTNetRequestFilterBlock];
    self.isExchangeRequestFilter = NO;
}

- (NSNumber *)isTTNetChromiumCore {
    BOOL isChromium = [HMDTTNetHelper isTTNetChromium];
    
    return [NSNumber numberWithBool:isChromium];
}

- (void)registNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNetworkStartNotification:) name:kTTNetworkManagerMonitorStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNetworkFinishNotification:) name:kTTNetworkManagerMonitorFinishNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNetworkSampleNotification:) name:kHMDNetworkManagerMonitorSampleNotification object:nil];
}

- (void)unregistNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)receiveNetworkSampleNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    TTHttpRequest *request = [userInfo objectForKey:kTTNetworkManagerMonitorRequestKey];
    
    HMDHTTPTrackerConfig *netMonitorConfig = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
    BOOL enableBaseApiAll = netMonitorConfig.baseApiAll.floatValue > 0;
    NSString *apiAllStr = enableBaseApiAll ? @"1" : @"0";
    
    [request setValue:apiAllStr forHTTPHeaderField:kHMDNetworkMonitorApiAllSample];
}

- (void)receiveNetworkStartNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    TTHttpRequest *request = [userInfo objectForKey:kTTNetworkManagerMonitorRequestKey];
    
    
    NSInteger hasTriedTimes = [[userInfo objectForKey:kTTNetworkManagerMonitorRequestTriedTimesKey] integerValue];

    HMDHTTPRequestInfo *requestInfo = [[self class] requestInfoForURLRequest:request];
    
    if (!requestInfo) {
        requestInfo = [[HMDHTTPRequestInfo alloc] init];
        requestInfo.hasTriedTimes = hasTriedTimes;
        [[self class] setRequestInfo:requestInfo forURLRequest:request];
    }
}

- (void)sampleWithRequest:(TTHttpRequest *)request AndRequestInfo:(HMDHTTPRequestInfo *)requestInfo{

    BOOL enableBaseApiAll = NO;
    BOOL enableApiAll = NO;
    BOOL enableApiError = NO;
    BOOL isHeaderInAllowedList = NO;
    BOOL isUrlInAllowedList = NO;
    BOOL isSDKUrlInAllowedList = NO;

    // moving line
    BOOL isHitMovingLine = NO;
    if ([request.allHTTPHeaderFields hmd_hasKey:kHMDTraceParentKeyStr]) {
        NSString *traceParent = [request.allHTTPHeaderFields hmd_stringForKey:kHMDTraceParentKeyStr];
        if (traceParent.length >= 2) {
            NSString *flag = [traceParent substringFromIndex:traceParent.length - 2];
            if ([flag isEqualToString:@"01"]) {
                isHitMovingLine = 1;
            }
        }
    }

    // block list
    if([[HMDHTTPRequestTracker sharedTracker] checkIfURLInBlockList:request.URL] && !isHitMovingLine) {

        requestInfo.isURLInBlockList = YES;
        requestInfo.isHitMovingLine = isHitMovingLine;
        return;;
    }

    // api_all_upload || base_api_all  || move line || allowed header
    HMDHTTPTrackerConfig *netMonitorConfig = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
    // api base
    enableBaseApiAll = netMonitorConfig.baseApiAll.floatValue > 0;

    // header allowed list
    isHeaderInAllowedList = [netMonitorConfig isHeaderInAllowHeaderList:request.allHTTPHeaderFields];

    NSString *sdkAid = [request.allHTTPHeaderFields valueForKey:@"sdk_aid"];
    if (sdkAid && sdkAid.length > 0) {
        // SDK监控
        HMDHeimdallrConfig *sdkHeimdallrConfig = [[HMDConfigManager sharedInstance] remoteConfigWithAppID:sdkAid];
        HMDModuleConfig *netModuleConfig = [sdkHeimdallrConfig.activeModulesMap valueForKey:@"network"];
        HMDHTTPTrackerConfig *sdkConfig = nil;
        if ([netModuleConfig isKindOfClass:HMDHTTPTrackerConfig.class]) {
            sdkConfig = (HMDHTTPTrackerConfig *)netModuleConfig;
        }
        if (sdkConfig) {
            enableApiAll = sdkConfig.enableAPIAllUpload;
            isSDKUrlInAllowedList = [sdkConfig isURLInAllowListWithScheme:request.URL.scheme host:request.URL.host path:request.URL.path];
            enableApiError = sdkConfig.enableAPIErrorUpload;
        }
    } else {
        // 宿主监控
        enableApiAll = netMonitorConfig.enableAPIAllUpload;
    }

    // url allowed list
    NSURL *url = request.URL;
    NSString *urlString = url.absoluteString;
    if (urlString && urlString.length > 0) {
        NSRange range = [urlString rangeOfString:@"?"];
        if (range.location != NSNotFound && (range.location + range.length) <= urlString.length) {
            @try {
                NSString *mainURL = [urlString substringToIndex:(range.location + range.length)];
                isUrlInAllowedList = [netMonitorConfig isURLInAllowListWithMainURL:mainURL];
            } @catch (NSException *exception) {
                isUrlInAllowedList = NO;
            }
        } else {
            isUrlInAllowedList = [netMonitorConfig isURLInAllowListWithMainURL:urlString];
        }
    }

    requestInfo.isURLInAllowedList = isUrlInAllowedList;
    requestInfo.isSDKURLInAllowedList = isSDKUrlInAllowedList;
    requestInfo.isHeaderInAllowedList = isHeaderInAllowedList;
    requestInfo.isHitMovingLine = isHitMovingLine;

}

- (void)receiveNetworkFinishNotification:(NSNotification *)notification {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo];
    HMDHTTPResponseInfo *responseInfo = [[HMDHTTPResponseInfo alloc] init];
    [userInfo setObject:responseInfo forKey:kHMDNetworkMonitorResponseInfoKey];
    
    dispatch_async(self.ttnetMonitorQueue, ^{
        [self ttnetworkMonitorWithTTNetUserInfo:[userInfo copy]];
    });
}

- (void)ttnetworkMonitorWithTTNetUserInfo:(NSDictionary *)userInfo {
    TTHttpRequest *request = [userInfo objectForKey:kTTNetworkManagerMonitorRequestKey];
    // ignore error
    NSError *error = [userInfo objectForKey:kTTNetworkManagerMonitorErrorKey];
    
    TTHttpResponse *response = [userInfo objectForKey:kTTNetworkManagerMonitorResponseKey];
    
    HMDHTTPRequestInfo *requestInfo = [[self class] requestInfoForURLRequest:request];
    [self sampleWithRequest:request AndRequestInfo:requestInfo];

    // 用户动线
    BOOL isMovingLine = requestInfo.isMovingLine;
    BOOL isHitMovingLine = requestInfo.isHitMovingLine;
    
    // 判断请求是否被取消，若被取消打印相应的alog
    if ([[HMDHTTPRequestTracker sharedTracker] checkIfRequestCanceled:request.URL withError:error andNetType:@"TTNet"]) {
        return;
    }

    /*  network_v2 的判定逻辑:
       上报判定逻辑
       - 判定基准采样标记，如果命中上报请求，返回。
       - 判定是否满足 blockList 配置，如果满足过滤请求，返回。
       - 判定是否满足全采样标记，如果命中上报请求，返回。
       - 判定是否满足  allowList 配置，如果满足上报请求，返回。
       - 如果是失败请求，判定是否满足错误日志采样标记，如果命中上报api_error，返回。
    */
    
    // 根据URL判断是否需要采集本次请求
    // checkIfURLInBlockList内部判断是否命中enable_base_api_all
    if(requestInfo.isURLInBlockList && !isHitMovingLine) {
        return;
    }

    HMDHTTPTrackerConfig *netMonitorConfig = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
    BOOL enableBaseApiAll = netMonitorConfig.baseApiAll.floatValue > 0;
    BOOL enableApiAll = netMonitorConfig.enableAPIAllUpload;
    
    BOOL isApiAllowedHeader = requestInfo.isHeaderInAllowedList;
    BOOL isInAllowedListBefore = requestInfo.isURLInAllowedList;
    // If there is no hit, the moving line/api all/api allowed list/sdk request/error log will be reported, and the log does not need to be created, and will be returned directly to avoid the time-consuming;
    if (HMDInjectedInfo.defaultInfo.stopWriteToDiskWhenUnhit &&
        HMDInjectedInfo.defaultInfo.notProductHTTPRecordUnHitEnabled && !isMovingLine) {
        // api_all_upload || base_api_all  || move line || allowed header
        BOOL isHitUploadBefore = enableApiAll || enableBaseApiAll || isHitMovingLine || isApiAllowedHeader;
        if (!isHitUploadBefore) {
            BOOL isSuccess = (response.statusCode >= 200 && response.statusCode <= 299) || response.statusCode == 304;
            BOOL needUploadError = netMonitorConfig.enableAPIErrorUpload && !isSuccess;
            // Whether it is an sdk request.
            NSString *sdkAid = [request.allHTTPHeaderFields valueForKey:@"sdk_aid"];
            // not hit any upload rule
            if (!isInAllowedListBefore && !sdkAid && !needUploadError) {
                return;
            }
        }
    }
    
    id responseData = [userInfo objectForKey:kTTNetworkManagerMonitorResponseDataKey];
    HMDHTTPResponseInfo *responseInfo = [userInfo objectForKey:kHMDNetworkMonitorResponseInfoKey];

    // 生成 record
    HMDHTTPDetailRecord *record = [self recordWithRequest:request
                                              requestInfo:requestInfo
                                                 response:response
                                             responseInfo:responseInfo
                                             responseData:responseData
                                                    error:error
                                          isHitMovingLine:isHitMovingLine];
    record.isMovingLine = isMovingLine;
    record.netLogType = @"api_all_v2";
    
    [[HMDHTTPRequestTracker sharedTracker] sampleAllowHeaderToRecord:record withRequestHeader:request.allHTTPHeaderFields andResponseHeader:response.allHeaderFields isMovingLine:isHitMovingLine];

    // 是否记录 record data
    if (responseData &&
        netMonitorConfig.responseBodyEnabled &&
        [[HMDHTTPRequestTracker sharedTracker] shouldRecordResponsebBodyForRecord:record rawData:responseData]) {
        record.responseBody = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    }

    // 命中 base_api_all 直接返回
    if (enableBaseApiAll) {
        record.baseApiAll = netMonitorConfig.baseApiAll;
        record.injectTracelog = netMonitorConfig.enableTTNetCDNSample ? @"01" : nil;
        record.logType = @"api_all";
        [[HMDHTTPRequestTracker sharedTracker] addRecord:record];
        return;
    }

    // inject_trace_log
    if (enableApiAll && netMonitorConfig.enableTTNetCDNSample) {
        record.injectTracelog = @"02";
    }

    NSMutableArray *hitRulesTag = [record.hit_rule_tags mutableCopy];
    if (!hitRulesTag) {
        hitRulesTag = [NSMutableArray array];
    }
    
    // request header 白名单
    if (isApiAllowedHeader) {
        record.inWhiteList = 1;
        [hitRulesTag addObject:@"api_allow_header"];
    }
    
    record.hit_rule_tags = hitRulesTag;

    // api all && debugReal
    record.logType = @"api_all";
    [[HMDHTTPRequestTracker sharedTracker] addRecord:record];
}

- (HMDHTTPDetailRecord *)recordWithRequest:(TTHttpRequest *)request
                               requestInfo:(HMDHTTPRequestInfo *)requestInfo
                                  response:(TTHttpResponse *)response
                              responseInfo:(HMDHTTPResponseInfo *)responseInfo
                              responseData:(id)data
                                     error:(NSError *)error
                              isHitMovingLine:(BOOL)isHitMovingLine{
    // 将ttnet透传的webview信息保存在 HMDHTTPRequestInfo 中
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNDECLARED_SELECTOR
    if([request respondsToSelector:@selector(webviewInfo)]) {
        NSDictionary *webviewInfo = DC_OB(request, webviewInfo);
        if(webviewInfo && webviewInfo.count) {
            HMDHTTPRequestInfo *requestWebviewInfo = [webviewInfo objectForKey:@"requestInfo"];
            requestInfo.webviewURL = requestWebviewInfo.webviewURL;
            requestInfo.webviewChannel = requestWebviewInfo.webviewChannel;
        }
    }
CLANG_DIAGNOSTIC_POP
    HMDHTTPDetailRecord *record = [HMDHTTPDetailRecord newRecord];
    record.isHitMovingLine = isHitMovingLine;
    record.inAppTime = responseInfo.inAppTime;
    record.isSuccess = (response.statusCode >= 200 && response.statusCode <= 299) || response.statusCode == 304;
    record.connetType = [HMDNetworkHelper connectTypeNameForCellularDataService];
    record.connetCode = [HMDNetworkHelper connectTypeCodeForCellularDataService];
    record.radioAccessType = [[HMDNetworkHelper currentRadioAccessTechnology] mutableCopy];// mutable copy to change address pointed;
    record.method = request.HTTPMethod;
    record.host = response.URL.host ?: request.URL.host;
    record.path = response.URL.path ?: request.URL.path;
    record.absoluteURL = response.URL.absoluteString ?: request.URL.absoluteString;
    record.scene = responseInfo.responseScene;
    record.requestScene = requestInfo.requestScene;
    record.startTime = requestInfo.startTime * 1000;
    record.endtime = responseInfo.endTime * 1000;
    record.duration = record.startTime > 0 ? (record.endtime - record.startTime) : -2;
    record.upStreamBytes = [HMDTTNetHelper getRequestLengthForRequest:request];
    record.statusCode = response.statusCode;
    record.MIMEType = response.MIMEType ?: @"unknown";
    record.errCode = error.code;
    record.errDesc = [NSString stringWithFormat:@"%@",error.userInfo];
    record.isForeground = responseInfo.isForeground;
    record.hasTriedTimes = requestInfo.hasTriedTimes;
    record.bdwURL = requestInfo.webviewURL;
    record.bdwChannel = requestInfo.webviewChannel;
    record.inWhiteList = requestInfo.isURLInAllowedList;
    record.isHitSDKURLAllowedListBefore = requestInfo.isSDKURLInAllowedList;
    //当发生明确错误的时候，将错误的状态码从http的状态码更新为NSError的errCode
    if (error) {
        record.statusCode = record.errCode;
    }
    // HMDInjectedInfo 设置的 aid;
    record.aid = [HMDInjectedInfo defaultInfo].appID;

    // 内核类型判断; 当 cornet 发生错误时,reponse可能无法构建出 corent 对应的 reponse,所以改为通过 request 判断
    if ([request isKindOfClass:[TTHttpRequestChromium class]] ||
        [response isKindOfClass:[TTHttpResponseChromium class]]) {
        record.clientType = @"cronet";
    } else {
        record.clientType = @"afn";
    }

    if ([response isKindOfClass:[TTHttpResponseChromium class]]) {
        TTHttpResponseChromium *targetResponse = (TTHttpResponseChromium *)response;
        TTHttpResponseChromiumTimingInfo *timingInfo = targetResponse.timingInfo;
        record.proxyTime = timingInfo.proxy;
        record.dnsTime = timingInfo.dns;
        record.connectTime = timingInfo.connect;
        record.sslTime = timingInfo.ssl;
        record.sendTime = timingInfo.send;
        record.waitTime = timingInfo.wait;
        record.receiveTime = timingInfo.receive;
        record.duration = timingInfo.total;
        record.isSocketReused = timingInfo.isSocketReused;
        record.isCached = timingInfo.isCached;
        record.isFromProxy = timingInfo.isFromProxy;
        record.downStreamBytes = timingInfo.totalReceivedBytes;

        TTCaseInsenstiveDictionary *allHeaders = targetResponse.allHeaderFields;
        record.traceId = [allHeaders objectForKey:@"TT-Request-Traceid"];

        if (class_getProperty([TTHttpResponseChromium class], "requestLog")) {
            Ivar ivar = class_getInstanceVariable([TTHttpResponseChromium class], "_requestLog");
                record.requestLog = object_getIvar(targetResponse, ivar);
        }
    }
    else {
        record.downStreamBytes = [HMDTTNetHelper getResponseLengthForResponse:response body:data];
    }
    
    // 请求线程信息打点
    [self collectTTNetThreadInfoWithRequest:request response:response record:record];
    
    // 复合请求日志打点
    [self collectTTNetConcurrentRequestInfo:response record:record];

    // 全链路监控
    [self collectTTNetBizTimingInfo:request response:response record:record];
    
    [self collectBizExtraRequestInfo:response record:record];
    
    // sdk监控
    NSString *sdkAid = [request.allHTTPHeaderFields valueForKey:@"sdk_aid"];
    if (sdkAid && sdkAid.length > 0) {
        [self dealSDKNetworkMonitorWithRecord:record request:request sdkAid:sdkAid];
    }

    // alog
    if (hmd_log_enable()) {
        NSString *simpleURL = record.absoluteURL;
        
        NSRange range = [record.absoluteURL rangeOfString:@"?"];
        if(range.length > 0 && range.location != NSNotFound && (range.length + range.location) <= [record.absoluteURL length]){
            simpleURL = [record.absoluteURL hmd_substringToIndex:range.location];
        }
        
        NSString *networkLog = [NSString stringWithFormat:@"net_type:TTNet, uri:%@, MIMEType：%@, request body size:%lubyte, response body size:%llubyte", simpleURL, record.MIMEType, request.HTTPBody.length,record.downStreamBytes];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@",networkLog);
    }

    return record;
}

- (void)collectTTNetConcurrentRequestInfo:(TTHttpResponse *)response
                                   record:(HMDHTTPDetailRecord *)record {
    NSDictionary *logInfo;
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNDECLARED_SELECTOR
    if([response respondsToSelector:@selector(concurrentRequestLogInfo)]) {
        logInfo = DC_OB(response, concurrentRequestLogInfo);
        if(!HMDIsEmptyDictionary(logInfo) && [logInfo hmd_isValidJSONObject]) {
            record.concurrentRequest = [logInfo copy];
        }
    }
CLANG_DIAGNOSTIC_POP
}

- (void)collectBizExtraRequestInfo:(TTHttpResponse *)response
                                   record:(HMDHTTPDetailRecord *)record {
    if([response respondsToSelector:@selector(extraBizInfo)]) {
        NSDictionary *logInfo = DC_OB(response, extraBizInfo);
        if(!HMDIsEmptyDictionary(logInfo)) {
            record.extraBizInfo = [logInfo copy];
        }
    }
}

- (void)collectTTNetThreadInfoWithRequest:(TTHttpRequest *)request
                                 response:(TTHttpResponse *)response
                                   record:(HMDHTTPDetailRecord *)record {
    record.isSerializedOnMainThread = -1;
    record.isCallbackExecutedOnMainThread = -1;
    if([request respondsToSelector:@selector(isSerializedOnMainThread)]) {
        record.isSerializedOnMainThread = DC_IS(DC_OB(request, isSerializedOnMainThread), NSNumber).intValue;
    }
    if([response respondsToSelector:@selector(isCallbackExecutedOnMainThread)]) {
        record.isCallbackExecutedOnMainThread = DC_IS(DC_OB(response, isCallbackExecutedOnMainThread), NSNumber).intValue;
    }
}

- (void)collectTTNetBizTimingInfo:(TTHttpRequest *)request
                         response:(TTHttpResponse *)response
                           record:(HMDHTTPDetailRecord *)record {

    NSDictionary *requestSerializerInfo = [self getPropertyDictCopyFrom:request
                                                             cls:[TTHttpRequest class]
                                                    propertyName:"serializerTimeInfo"
                                                     instanceVar:"_serializerTimeInfo"];
    if (requestSerializerInfo) {
        record.requestSerializerTimingInfo = requestSerializerInfo;
    }

    NSDictionary *requestFiltersInfo = [self getPropertyDictCopyFrom:request
                                                                 cls:[TTHttpRequest class]
                                                        propertyName:"filterObjectsTimeInfo"
                                                         instanceVar:"_filterObjectsTimeInfo"];
    if (requestFiltersInfo) {
        record.requestFiltersTimingInfo = requestFiltersInfo;
    }

    NSDictionary *responseSerializerInfo = [self getPropertyDictCopyFrom:response
                                                                     cls:[TTHttpResponse class]
                                                            propertyName:"serializerTimeInfo" instanceVar:"_serializerTimeInfo"];
    if (responseSerializerInfo) {
        record.responseSerializerTimingInfo = responseSerializerInfo;
    }

    NSDictionary *reponseFiltersInfo = [self getPropertyDictCopyFrom:response
                                                                cls:[TTHttpResponse class]
                                                       propertyName:"filterObjectsTimeInfo"
                                                        instanceVar:"_filterObjectsTimeInfo"];
    if (reponseFiltersInfo) {
        record.responseFiltersTimingInfo = reponseFiltersInfo;
    }

    id additionalTiming = [self getPropertyValueCopyFrom:response
                                                     cls:[TTHttpResponse class]
                                            propertyName:"additionalTimeInfo"
                                             instanceVar:"_additionalTimeInfo"];

    if (additionalTiming) {
        NSDictionary *additionalDict = DC_OB(additionalTiming, completionBlockTime);
        if (additionalDict && [additionalDict isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *additionalTimingInfo = [NSMutableDictionary dictionary];
            [additionalDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([key isKindOfClass:[NSString class]] &&
                    [obj isKindOfClass:[NSNumber class]]) {
                    [additionalTimingInfo hmd_setObject:obj forKey:key];
                }
            }];
            record.responseAdditionalTimingInfo = [additionalTimingInfo copy];
        }
    }

    id turingTiming = [self getPropertyValueCopyFrom:response
                                                 cls:[TTHttpResponse class]
                                        propertyName:"turingCallbackinfo"
                                         instanceVar:"_turingCallbackinfo"];
    if (turingTiming) {
        id timingNumber = DC_OB(turingTiming, bdTuringCallbackDuration);
        id retryCountNumber = DC_OB(turingTiming, bdTuringRetry);

        NSInteger timing = 0;
        if (timingNumber && [timingNumber isKindOfClass:[NSNumber class]]) {
            timing = [timingNumber doubleValue];
        }

        NSTimeInterval retryCount = 0;
        if (retryCountNumber && [retryCountNumber isKindOfClass:[NSNumber class]]) {
            retryCount = [retryCountNumber integerValue];
        }

        if (timing > 0 || retryCount > 0) {
            NSDictionary *timingDict = @{
                @"bdturing_retry": @(retryCount),
                @"turing_callback_duration": @(timing)
            };
            record.responseBDTuringTimingInfo = [timingDict copy];
        }
    }
}

- (NSDictionary *)getPropertyDictCopyFrom:(id)instance
                                      cls:(Class)targerCls
                             propertyName:(const char * _Nonnull)name
                              instanceVar:(const char * _Nonnull)instanceVar {
    NSDictionary *propertyDict = [self getPropertyValueCopyFrom:instance
                                                            cls:targerCls
                                                   propertyName:name
                                                    instanceVar:instanceVar];
    if (propertyDict && [propertyDict isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dictMutCpy = [NSMutableDictionary dictionary];
        [propertyDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isKindOfClass:[NSString class]] &&
                [obj isKindOfClass:[NSNumber class]]) {
                [dictMutCpy hmd_setObject:obj forKey:key];
            }
        }];
        return [dictMutCpy copy];
    }
    return nil;
}

- (id)getPropertyValueCopyFrom:(id)instance
                           cls:(Class)targerCls
                  propertyName:(const char * _Nonnull)name
                   instanceVar:(const char * _Nonnull)instanceVar {
    if (instance &&
        [instance isKindOfClass:targerCls] &&
        class_getProperty(targerCls, name)) {
        Ivar ivar = class_getInstanceVariable([targerCls class], instanceVar);
        if (ivar) {
            id propertyValue = object_getIvar(instance, ivar);
            return propertyValue;
        }
    }
    return nil;
}

- (void)dealSDKNetworkMonitorWithRecord:(HMDHTTPDetailRecord *)record
                                request:(TTHttpRequest *)request
                                 sdkAid:(NSString *)sdkAid {
    if (sdkAid && sdkAid.length > 0) {
        record.isSDK = YES;
        HMDHeimdallrConfig *sdkHeimdallrConfig = [[HMDConfigManager sharedInstance] remoteConfigWithAppID:sdkAid];
        HMDModuleConfig *netModuleConfig = [sdkHeimdallrConfig.activeModulesMap valueForKey:@"network"];
        HMDHTTPTrackerConfig *sdkConfig = nil;
        if ([netModuleConfig isKindOfClass:HMDHTTPTrackerConfig.class]) {
            sdkConfig = (HMDHTTPTrackerConfig *)netModuleConfig;
        }
        NSMutableArray *hitRulesTag = nil;
        if (record.hit_rule_tags) {
            hitRulesTag = [record.hit_rule_tags mutableCopy];
        } else {
            hitRulesTag = [NSMutableArray array];
        }
        if (sdkConfig) {
           BOOL inSDKWhiteList = NO;
           if (record.isHitSDKURLAllowedListBefore) {
               [hitRulesTag addObject:@"sdk_api_allow"];
               inSDKWhiteList = YES;
           }

           BOOL inSDKApiAll = NO;
           if ([sdkConfig enableAPIAllUpload]) {
               [hitRulesTag addObject:@"sdk_api_all"];
               inSDKApiAll = YES;
           }

           BOOL enableSDKApiError = !record.isSuccess && sdkConfig.enableAPIErrorUpload;
           // request header中有sdk_aid字段，并且能够拉到sdk网络监控的config，标记这条日志
           record.sdkAid = sdkAid;
           BOOL enableUpload = inSDKWhiteList || inSDKApiAll || enableSDKApiError;
           if (enableUpload || record.isHitMovingLine) {
               record.enableUpload = 1;
               record.sdkAid = sdkAid;
               NSString *aid = DC_OB(DC_CL(HMDSDKMonitorManager, sharedInstance), sdkHostAidWithSDKAid:, sdkAid);
               if (aid) {
                   record.aid = aid;
               }
           } else {
               record.enableUpload = 0;
           }
            
            if (!enableUpload && record.isHitMovingLine) {
                record.singlePointOnly = 1;
            }
        }
        record.hit_rule_tags = hitRulesTag;
    }
}

static char const * const kHMDNetworkMonitorRequestInfoKey = "kHMDNetworkMonitorRequestInfoKey";

+ (HMDHTTPRequestInfo *)requestInfoForURLRequest:(TTHttpRequest *)request {
    if (!request) {
        return nil;
    }
    
    HMDHTTPRequestInfo *requestInfo = objc_getAssociatedObject(request, kHMDNetworkMonitorRequestInfoKey);
    
    return requestInfo;
    
}

+ (void)setRequestInfo:(HMDHTTPRequestInfo *)requestInfo forURLRequest:(TTHttpRequest *)request {
    if (!request || !requestInfo) {
        return;
    }
    objc_setAssociatedObject(request, kHMDNetworkMonitorRequestInfoKey, requestInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
