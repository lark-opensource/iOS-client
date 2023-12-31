//
//  HMDURLProtocol.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/21.
//

#import "HMDURLProtocol.h"
#import "HMDHTTPRequestRecord.h"
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPTrackerConfig.h"
#import "HMDNetworkHelper.h"
#import "NSURLRequest+HMDURLProtocol.h"
#import "HMDNetworkReachability.h"
#import "HMDALogProtocol.h"
#import "HMDURLProtocolManager.h"
#import "Heimdallr+Private.h"
#import "NSURLSessionTask+HMDURLProtocol.h"
#import "HMDSessionTracker.h"
#import "HMDDynamicCall.h"
#import "HMDHTTPTrackerConfig.h"
#import "HMDHTTPDetailRecord.h"
#import "HMDHTTPRequestTracker+HMDSampling.h"

//为了避免 canInitWithRequest 和 canonicalRequestForRequest 出现死循环
static NSString * const HMDHTTPHandledIdentifier = @"HMDHTTPHandledIdentifier";
NSString *const HMDURLProtocolNoFilterIdentifier = @"HMDURLProtocolFilterIdentifier";

@interface HMDURLProtocol () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) HMDHTTPRequestRecord *httpRecord;
@property (nonatomic, strong) NSLock *dataLock;
@property (nonatomic, strong) NSMutableArray *redirectList;
@property (atomic, strong) NSThread *clientThread;
@property (atomic, copy) NSArray *clientModes;


@end

@implementation HMDURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:HMDHTTPHandledIdentifier inRequest:request] ) {
        return NO;
    }

    id protocolProperty = [HMDURLProtocol propertyForKey:HMDURLProtocolNoFilterIdentifier inRequest:request];
    if (protocolProperty && [protocolProperty respondsToSelector:@selector(boolValue)]) {
        BOOL canInit = ![protocolProperty boolValue];
        return canInit;
    }

    if([[HMDHTTPRequestTracker sharedTracker] checkIfURLInBlockList:request.URL]) {
        return NO;
    }
    
    if ([request.URL.scheme isEqualToString:@"http"] ||
        [request.URL.scheme isEqualToString:@"https"]) {
        return YES;
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES
                        forKey:HMDHTTPHandledIdentifier
                     inRequest:mutableReqeust];
    return [mutableReqeust copy];
}

- (void)performOnSessionQueue:(dispatch_block_t)block {
    dispatch_async([HMDURLProtocolManager shared].session_queue, block);
}

- (void)startLoading {
    NSAssert(self.clientThread == nil,@"Not reseting state!");
    NSAssert(self.clientModes == nil,@"Not reseting state!");

    NSMutableArray *calculatedModes = [NSMutableArray array];
    [calculatedModes addObject:NSDefaultRunLoopMode];
    NSString *currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if ((currentMode != nil) && ![currentMode isEqual:NSDefaultRunLoopMode]) {
        [calculatedModes addObject:currentMode];
    }
    self.clientModes = calculatedModes;
    self.clientThread = [NSThread currentThread];
    
    [self performOnSessionQueue:^{
        [self didStartRecording];
    }];
}

- (void)stopLoading {
    NSAssert(self.clientThread != nil,@"Not reseting state!");
    NSAssert([NSThread currentThread] == self.clientThread,@"Thread is inconsistent.");
    
    [self performOnSessionQueue:^{
        [self didFinishRecording];
    }];
}

- (void)didStartRecording {
    self.dataLock = [[NSLock alloc] init];
    self.data = [NSMutableData data];
    self.redirectList = [[NSMutableArray alloc] init];
    
    self.httpRecord = [[HMDHTTPRequestRecord alloc] init];
    self.httpRecord.startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    self.httpRecord.requestScene = DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), scene), NSString);
    self.httpRecord.connetType = [HMDNetworkHelper connectTypeNameForCellularDataService];
    self.httpRecord.isForeground = ![HMDSessionTracker currentSession].isBackgroundStatus;

    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    [mutableRequest hmd_handlePostRequestBody];
    [mutableRequest hmd_handleRequestHeaderFromTraceLogSample];
    NSURLRequest *fixedRequest = [mutableRequest copy];
    fixedRequest.hmdTempDataFilePath = mutableRequest.hmdTempDataFilePath;
    fixedRequest.hmdHTTPBodyStreamLength = mutableRequest.hmdHTTPBodyStreamLength;
    self.httpRecord.request = fixedRequest;
    self.httpRecord.requestBodyStreamLength = fixedRequest.hmdHTTPBodyStreamLength;
    
    NSURLSessionDataTask *task = [[HMDURLProtocolManager shared] generateDataTaskWithURLRequest:fixedRequest underlyingDelegate:self];
    task.hmdThread = self.clientThread;
    task.hmdModes = self.clientModes;
}
                   
- (void)didFinishRecording {
    if ([self.httpRecord.request.hmdTempDataFilePath length] > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:self.httpRecord.request.hmdTempDataFilePath error:nil];
    }

    if([[HMDHTTPRequestTracker sharedTracker] checkIfRequestCanceled:self.httpRecord.request.URL withError:self.httpRecord.error andNetType:@"NSURLSession"]) {
        return ;
    }
    self.httpRecord.scene = DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), scene), NSString);
    [self netMonitorRecordForUrlSession];
    BOOL isSuccess = NO;
    if ([self.httpRecord.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *kResponse = (NSHTTPURLResponse *)self.httpRecord.response;
        // 判断是否成功  2XX || 304
        isSuccess = (kResponse.statusCode >= 200 && kResponse.statusCode <= 299)|| kResponse.statusCode == 304;
    }
    [self netMonitorRecordForSDKWithSuccess:isSuccess];

    HMDHTTPTrackerConfig *config = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].trackerConfig;
    BOOL enableBaseApiAll = config.baseApiAll.floatValue > 0;
    BOOL enableTraceLog =  config.enableTTNetCDNSample;
    BOOL enableApiAll = config.enableAPIAllUpload;
    // 命中基准采样
    if (enableBaseApiAll) {
        self.httpRecord.baseApiAll = config.baseApiAll;
        self.httpRecord.logType = @"api_all";
        self.httpRecord.injectTracelog = enableTraceLog ? @"01" : nil;
        HMDHTTPDetailRecord *record = [HMDHTTPDetailRecord recordWithRawData:self.httpRecord];
        [HMDHTTPRequestTracker.sharedTracker addRecord:record];
        self.httpRecord = nil;
        return;
    }

    NSMutableArray *hitRulesTag = [self.httpRecord.hit_rule_tags mutableCopy];
    //  命中allowList
    if ([[HMDHTTPRequestTracker sharedTracker] checkIfURLInWhiteList:self.httpRecord.request.URL]) {
        [hitRulesTag addObject:@"api_allow"];
    }

    // request header 白名单
    if ([config isHeaderInAllowHeaderList:self.httpRecord.request.allHTTPHeaderFields]) {
        [hitRulesTag addObject:@"api_allow_header"];
    }

    // 上报基准采样 trace_log
    if (enableApiAll && enableTraceLog) {
        self.httpRecord.injectTracelog = @"02";
    }

    self.httpRecord.hit_rule_tags = hitRulesTag;

    self.httpRecord.logType = @"api_all";
    HMDHTTPDetailRecord *record = [HMDHTTPDetailRecord recordWithRawData:self.httpRecord];
    
    if ([HMDHTTPRequestTracker.sharedTracker shouldRecordResponsebBodyForRecord:record rawData:self.httpRecord.responseData]) {
        record.responseBody = [[NSString alloc] initWithData:self.httpRecord.responseData encoding:NSUTF8StringEncoding];
    }

    [HMDHTTPRequestTracker.sharedTracker addRecord:record];
    
    self.httpRecord = nil;
}

- (void)netMonitorRecordForUrlSession {
    self.httpRecord.response = (NSHTTPURLResponse *)self.response;
    //尝试修复可能存在的EXC_BAD_ACCESS的问题
    //https://github.com/rs/SDWebImage/pull/2011/files
    [self.dataLock lock];
    NSData *data = [self.data copy];
    [self.dataLock unlock];
    self.httpRecord.responseData = data;

    self.httpRecord.endtime = [[NSDate date] timeIntervalSince1970] * 1000;
    self.httpRecord.redirectList = [self.redirectList copy];
    self.httpRecord.hit_rule_tags = [NSMutableArray array];
    // HMDInjectedInfo 设置的 aid;
    self.httpRecord.aid = [HMDInjectedInfo defaultInfo].appID;
    self.httpRecord.netLogType = @"api_all_v2";
}

- (void)netMonitorRecordForSDKWithSuccess:(BOOL)isSuccess {
    // sdk
    NSString *sdkAid = [self.httpRecord.request.allHTTPHeaderFields valueForKey:@"sdk_aid"];
    NSMutableArray *hitRulesTag = [self.httpRecord.hit_rule_tags mutableCopy];
    if (!hitRulesTag) {
        hitRulesTag = [NSMutableArray array];
    }

    if (sdkAid && sdkAid.length > 0) {
        HMDHeimdallrConfig *sdkHeimdallrConfig = [[HMDConfigManager sharedInstance] remoteConfigWithAppID:sdkAid];
        HMDModuleConfig *netModuleConfig = [sdkHeimdallrConfig.activeModulesMap valueForKey:@"network"];
        HMDHTTPTrackerConfig *sdkConfig = nil;
        if ([netModuleConfig isKindOfClass:HMDHTTPTrackerConfig.class]) {
            sdkConfig = (HMDHTTPTrackerConfig *)netModuleConfig;
        }
        NSMutableArray *hitRulesTag = [self.httpRecord.hit_rule_tags mutableCopy];
        if (!hitRulesTag) {
            hitRulesTag = [NSMutableArray array];
        }

        if (sdkConfig) {
            BOOL inSDKApiAllow = NO;
            NSURL *sdkURL = self.httpRecord.request.URL;
            if ([sdkConfig isURLInAllowListWithScheme:sdkURL.scheme host:sdkURL.host path:sdkURL.path]) {
                [hitRulesTag addObject:@"sdk_api_allow"];
                inSDKApiAllow = YES;
            }

            BOOL inSDKApiAll = NO;
            if (sdkConfig.enableAPIAllUpload) {
                [hitRulesTag addObject:@"sdk_api_all"];
                inSDKApiAll = YES;
            }

            BOOL enableSDKApiError = !isSuccess && sdkConfig.enableAPIErrorUpload;
            self.httpRecord.sdkAid = sdkAid;
            if (inSDKApiAll || inSDKApiAllow || enableSDKApiError ) {
                self.httpRecord.enableUpload = 1;
                NSString *aid = DC_OB(DC_CL(HMDSDKMonitorManager, sharedInstance), sdkHostAidWithSDKAid:, sdkAid);
                if (aid) {
                    self.httpRecord.aid = aid;
                }
            }
            else {
                self.httpRecord.enableUpload = 0;
            }
        }
    }
    self.httpRecord.hit_rule_tags = hitRulesTag;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSAssert([NSThread currentThread] == self.clientThread,@"Thread is inconsistent.");
    if (!error) {
        [self.client URLProtocolDidFinishLoading:self];
    } else {
        [self.client URLProtocol:self didFailWithError:error];
        [self performOnSessionQueue:^{
            self.httpRecord.error = error;
        }];
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSAssert([NSThread currentThread] == self.clientThread,@"Thread is inconsistent.");
    [self.client URLProtocol:self didLoadData:data];

    [self performOnSessionQueue:^{
        self.httpRecord.dataLength += data.length;
        //判断是否需要记录 response body 以及 response body 大小是否满足阈值要求
        if ([HMDHTTPRequestTracker sharedTracker].trackerConfig.responseBodyEnabled && self.httpRecord.dataLength <= [HMDHTTPRequestTracker sharedTracker].trackerConfig.responseBodyThreshold) {
            [self.dataLock lock];
            [self.data appendData:data];
            [self.dataLock unlock];
        }
    }];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSAssert([NSThread currentThread] == self.clientThread,@"Thread is inconsistent.");
    [self performOnSessionQueue:^{
        self.response = response;
    }];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    NSAssert([NSThread currentThread] == self.clientThread,@"Thread is inconsistent.");
    if (response != nil){
        [self performOnSessionQueue:^{
            if (request && request.URL.absoluteString && request.URL.absoluteString.length > 0) {
                [self.redirectList addObject:request.URL.absoluteString];
            }
            self.response = response;
        }];
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics  API_AVAILABLE(ios(10.0)){
    NSAssert([NSThread currentThread] == self.clientThread,@"Thread is inconsistent.");
    if (@available(iOS 10.0, *)) {
        [self performOnSessionQueue:^{
            for (NSURLSessionTaskTransactionMetrics *metric in metrics.transactionMetrics) {
                if (metric.resourceFetchType != NSURLSessionTaskMetricsResourceFetchTypeNetworkLoad) {
                    continue;
                }
                self.httpRecord.dnsTime = ([metric.domainLookupEndDate timeIntervalSince1970] - [metric.domainLookupStartDate timeIntervalSince1970]) * 1000;
                self.httpRecord.connectTime = ([metric.connectEndDate timeIntervalSince1970] - [metric.connectStartDate timeIntervalSince1970]) * 1000;
                self.httpRecord.sslTime = ([metric.secureConnectionEndDate timeIntervalSince1970] - [metric.secureConnectionStartDate timeIntervalSince1970]) * 1000;
                self.httpRecord.sendTime = ([metric.requestEndDate timeIntervalSince1970] - [metric.requestStartDate timeIntervalSince1970]) * 1000;
                self.httpRecord.waitTime = ([metric.responseStartDate timeIntervalSince1970] - [metric.requestEndDate timeIntervalSince1970]) * 1000;
                self.httpRecord.receiveTime = ([metric.responseEndDate timeIntervalSince1970] - [metric.responseStartDate timeIntervalSince1970]) * 1000;
                self.httpRecord.tcpTime = ([metric.secureConnectionStartDate timeIntervalSince1970] - [metric.connectStartDate timeIntervalSince1970]) * 1000;
                self.httpRecord.requestSendTime = [metric.requestStartDate timeIntervalSince1970] * 1000;
                self.httpRecord.responseRecTime = [metric.responseStartDate timeIntervalSince1970] * 1000;
                self.httpRecord.isFromProxy = metric.isProxyConnection;
                self.httpRecord.protocolName = metric.networkProtocolName;
                self.httpRecord.redirectCount = metrics.redirectCount;
                self.httpRecord.sessionConnectReuse = metric.isReusedConnection;
            }
        }];
    }
}

@end

