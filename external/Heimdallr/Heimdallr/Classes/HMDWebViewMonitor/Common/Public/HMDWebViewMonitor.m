//
//  HMDWebViewMonitor.m
//  Heimdallr
//
//  Created by zhangyuzhong on 2021/12/2.
//

#import "HMDWebViewMonitor.h"
#import "pthread_extended.h"
#import "HMDDynamicCall.h"
#import <WebKit/WKWebView.h>
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPTrackerConfig.h"
#import "HMDHTTPRequestTracker+Private.h"
#import "HMDHTTPDetailRecord.h"
#import "NSString+HDMUtility.h"
#include "pthread_extended.h"
#import "HMDNetworkHelper.h"
#import "HMDSessionTracker.h"
#import "HMDInjectedInfo.h"
#import "HMDRequestDecorator.h"
#import "HMDHTTPResponseInfo.h"
#import "HMDHTTPRequestInfo.h"
#import "HMDHTTPRequestTracker+HMDSampling.h"
#import "HMDALogProtocol.h"

#define HMD_WEBVIEW_MONITOR_SERIAL_QUEUE "com.heimdallr.HMDWebViewMonitor.sample"


@protocol BDWebURLSchemeTask;
@protocol BDWebURLProtocolTask;

// <BDWebInterceptorMonitor>
@interface HMDWebViewMonitor ()

@property (atomic, assign) BOOL isMonitoring;
@property (nonatomic, strong) dispatch_queue_t webviewQueue;

@end

@implementation HMDWebViewMonitor {
    pthread_mutex_t _mutexLock;
}


- (void)start {
    if(self.isMonitoring) return;
    pthread_mutex_lock(&_mutexLock);
    DC_CL(BDWebInterceptor, addGlobalInterceptorMonitor:, self);
    DC_OB(DC_CL(BDWebInterceptor, sharedInstance), registerCustomRequestDecorator:, [HMDRequestDecorator class]);
    self.isMonitoring = YES;
    pthread_mutex_unlock(&_mutexLock);
}

- (void)stop {
    if (!self.isMonitoring) return;
    pthread_mutex_lock(&_mutexLock);
    DC_CL(BDWebInterceptor, removeGlobalInterceptorMonitor:, self);
    self.isMonitoring = NO;
    pthread_mutex_unlock(&_mutexLock);
}

+ (nonnull instancetype)sharedMonitor {
    static HMDWebViewMonitor *sharedMonitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMonitor = [[HMDWebViewMonitor alloc] init];
    });
    return sharedMonitor;
}

- (nonnull instancetype)init {
    if(self = [super init]) {
        pthread_mutex_init(&_mutexLock, NULL);
        _webviewQueue = dispatch_queue_create(HMD_WEBVIEW_MONITOR_SERIAL_QUEUE, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)bdw_URLSchemeTask:(id<BDWebURLSchemeTask>)schemeTask didReceiveResponse:(NSURLResponse *)response {
    if(!self.isMonitoring) return;
    BOOL taskFinishWithLocalData = DC_IS(DC_OB(schemeTask, taskFinishWithLocalData), NSNumber).boolValue;
    BOOL taskFinishWithTTNet = DC_IS(DC_OB(schemeTask, taskFinishWithTTNet), NSNumber).boolValue;
    NSURLRequest *request = DC_OB(schemeTask, bdw_request);
    if(!taskFinishWithLocalData || taskFinishWithTTNet) {
        return ;
    }
    
    if([[HMDHTTPRequestTracker sharedTracker] checkIfURLInBlockList:request.URL]) {
        return;
    }
    
    NSDictionary *additionalInfo = DC_OB(schemeTask, bdw_additionalInfo);
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:additionalInfo];
    HMDHTTPResponseInfo *responseInfo = [[HMDHTTPResponseInfo alloc] init];
    [dic setObject:responseInfo forKey:@"responseInfo"];
    
    dispatch_async(self.webviewQueue, ^{
        // 生成 record
        HMDHTTPTrackerConfig *netMonitorConfig = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
        HMDHTTPDetailRecord *record = [self recordWithRequest:request response:response additionalInfo:[dic copy] netMonitorConfig:netMonitorConfig];
        [[HMDHTTPRequestTracker sharedTracker] addRecord:record];
    });
}

- (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)schemeTask didReceiveResponse:(NSURLResponse *)response {
    if(!self.isMonitoring) return;
    BOOL taskFinishWithLocalData = DC_IS(DC_OB(schemeTask, taskFinishWithLocalData), NSNumber).boolValue;
    BOOL taskFinishWithTTNet = DC_IS(DC_OB(schemeTask, taskFinishWithTTNet), NSNumber).boolValue;
    NSURLRequest *request = DC_OB(schemeTask, bdw_request);
    if(!taskFinishWithLocalData || taskFinishWithTTNet) {
        return ;
    }
    
    if([[HMDHTTPRequestTracker sharedTracker] checkIfURLInBlockList:request.URL]) {
        return;
    }
    
    NSURLResponse *responseCopy = [response copy];
    NSDictionary *additionalInfo = DC_OB(schemeTask, bdw_additionalInfo);
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:additionalInfo];
    HMDHTTPResponseInfo *responseInfo = [[HMDHTTPResponseInfo alloc] init];
    [dic setObject:responseInfo forKey:@"responseInfo"];
    NSDictionary *info = [dic copy];
    
    dispatch_async(self.webviewQueue, ^{
        // 生成 record
        HMDHTTPTrackerConfig *netMonitorConfig = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
        HMDHTTPDetailRecord *record = [self recordWithRequest:request response:responseCopy additionalInfo:info netMonitorConfig:netMonitorConfig];
        [[HMDHTTPRequestTracker sharedTracker] addRecord:record];
    });
}

- (HMDHTTPDetailRecord *)recordWithRequest:(NSURLRequest *)request
                                  response:(NSURLResponse *)response
                            additionalInfo:(NSDictionary *)additionalInfo
                          netMonitorConfig:(HMDHTTPTrackerConfig *)netMonitorConfig {
    HMDHTTPDetailRecord *record = [HMDHTTPDetailRecord newRecord];
    
    HMDHTTPResponseInfo *responseInfo = [additionalInfo objectForKey:@"responseInfo"];
    HMDHTTPRequestInfo *requestInfo = [additionalInfo objectForKey:@"requestInfo"];
    record.requestScene = requestInfo.requestScene;
    record.startTime = requestInfo.startTime * 1000;
    record.inAppTime = responseInfo.inAppTime;
    record.scene = responseInfo.responseScene;
    record.endtime = responseInfo.endTime * 1000;
    record.duration = record.startTime > 0 ? (record.endtime - record.startTime) : -2;
    record.isForeground = responseInfo.isForeground;
    record.connetType = [HMDNetworkHelper connectTypeNameForCellularDataService];
    record.connetCode = [HMDNetworkHelper connectTypeCodeForCellularDataService];
    record.radioAccessType = [[HMDNetworkHelper currentRadioAccessTechnology] mutableCopy];// mutable copy to change address pointed;
    record.method = request.HTTPMethod;
    record.host = response.URL.host ?: request.URL.host;
    record.path = response.URL.path ?: request.URL.path;
    record.absoluteURL = response.URL.absoluteString ?: request.URL.absoluteString;
    
    // 添加alog，排查crash
    if (hmd_log_enable()) {
        NSString *networkLog = [NSString stringWithFormat:@"net_type:falcon, method:%@, uri:%@, request body size:%lubyte, requestScene %@, responseScene %@, isForeground %ld, response %@",record.method, record.absoluteURL, request.HTTPBody.length, record.requestScene, record.scene, (long)record.isForeground, response];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@", networkLog);
    }
    
    record.clientType = @"falcon";
    record.netLogType = @"api_all_v2";
    record.logType = @"api_all";
    record.aid = [HMDInjectedInfo defaultInfo].appID;
    record.bdwURL = requestInfo.webviewURL;
    record.bdwChannel = requestInfo.webviewChannel;
    
    // V2 过滤 header allowList
    NSDictionary *requestAllowHeader = [netMonitorConfig requestAllowHeaderWithHeader:request.allHTTPHeaderFields];
    if (requestAllowHeader) {
        record.requestHeader = [NSString hmd_stringWithJSONObject:requestAllowHeader];
    }
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        [[HMDHTTPRequestTracker sharedTracker] sampleAllowHeaderToRecord:record withRequestHeader:request.allHTTPHeaderFields andResponseHeader:httpResponse.allHeaderFields];
        record.statusCode = httpResponse.statusCode;
        record.isSuccess = (httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299) || httpResponse.statusCode == 304;
    }
    
    BOOL enableBaseApiAll = netMonitorConfig.baseApiAll.floatValue > 0;
    BOOL enableApiAll = netMonitorConfig.enableAPIAllUpload;
    // 命中 base_api_all 直接返回
    if (enableBaseApiAll) {
        record.baseApiAll = netMonitorConfig.baseApiAll;
        record.injectTracelog = netMonitorConfig.enableTTNetCDNSample ? @"01" : nil;
        return record;
    }
    
    // inject_trace_log
    if (enableApiAll && netMonitorConfig.enableTTNetCDNSample) {
        record.injectTracelog = @"02";
    }
    //
    NSMutableArray *hitRulesTag = [record.hit_rule_tags mutableCopy];
    if (!hitRulesTag) {
        hitRulesTag = [NSMutableArray array];
    }
    // request header 白名单
    if ([netMonitorConfig isHeaderInAllowHeaderList:request.allHTTPHeaderFields]) {
        record.inWhiteList = 1;
        [hitRulesTag addObject:@"api_allow_header"];
    }
    record.hit_rule_tags = hitRulesTag;

    return record;
}

@end
