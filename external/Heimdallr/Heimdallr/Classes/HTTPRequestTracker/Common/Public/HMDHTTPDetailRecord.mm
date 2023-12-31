//
//  HMDHTTPDetailRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/2/2.
//

#import "HMDHTTPDetailRecord.h"
#import "HMDHTTPUtil.h"
#import "HMDNetworkHelper.h"
#import "HMDHTTPRequestRecord.h"
#import "HMDALogProtocol.h"
#import "NSString+HDMUtility.h"
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPTrackerConfig.h"
#import "HMDSessionTracker.h"
#import "HMDHTTPRequestTracker+HMDSampling.h"
#import "HMDMacro.h"
#import "HMDHTTPDetailRecord+Report.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *const kHMDNetworkTrackerName = @"nework";

@interface HMDHTTPDetailRecord()

// 采样前置校验
@property (nonatomic, assign) BOOL isHitSDKURLAllowedListBefore;

@end

@implementation HMDHTTPDetailRecord

+ (instancetype)recordWithRawData:(HMDHTTPRequestRecord *)rawRecord {
    HMDHTTPDetailRecord *record = [HMDHTTPDetailRecord newRecord];
    
    NSHTTPURLResponse *httpResponse = nil;
    if ([rawRecord.response isKindOfClass:[NSHTTPURLResponse class]]) {
        httpResponse = (NSHTTPURLResponse *)rawRecord.response;
    }

    record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
    record.statusCode = httpResponse.statusCode;
    record.isSuccess = !rawRecord.error && record.statusCode >= 0 && record.statusCode <= 399;
    record.connetType = [HMDNetworkHelper connectTypeNameForCellularDataService];
    record.connetCode = [HMDNetworkHelper connectTypeCodeForCellularDataService];
    record.radioAccessType = [[HMDNetworkHelper currentRadioAccessTechnology] mutableCopy]; // // mutable copy to change address pointed;
    record.method = rawRecord.request.HTTPMethod;
    record.host = rawRecord.request.URL.host;
    record.path = rawRecord.response.URL.path ?: rawRecord.request.URL.path;
    record.absoluteURL = rawRecord.request.URL.absoluteString;
    record.startTime = rawRecord.startTime;
    record.endtime = rawRecord.endtime;
    if (record.startTime <= 0) {
        record.duration = -2;
    } else {
        record.duration = record.endtime - record.startTime;
    }
    record.upStreamBytes = [HMDHTTPUtil getRequestLengthForRequest:rawRecord.request streamLength:rawRecord.requestBodyStreamLength];
    record.downStreamBytes = [HMDHTTPUtil getResponseLengthForResponse:httpResponse bodyLength:rawRecord.dataLength];
    record.MIMEType = httpResponse.MIMEType ?: @"unknown";
    record.errCode = rawRecord.error.code;
    record.errDesc = rawRecord.error.description;
    //当发生明确错误的时候，将错误的状态码从http的态码更新为NSError的errCode
    if (rawRecord.error) {
        record.statusCode = record.errCode;
    }
    
    [[HMDHTTPRequestTracker sharedTracker] sampleAllowHeaderToRecord:record withRequestHeader:rawRecord.request.allHTTPHeaderFields andResponseHeader:httpResponse.allHeaderFields];
    

    // serverTiming
    record.serverTiming = [httpResponse.allHeaderFields objectForKey:@"server-timing"];
    record.contentEncoding = [httpResponse.allHeaderFields objectForKey:@"Content-Encoding"];
    record.ttTraceID = [httpResponse.allHeaderFields objectForKey:@"x-tt-trace-id"];
    record.ttTraceHost = [httpResponse.allHeaderFields objectForKey:@"x-tt-trace-host"];
    record.ttTraceTag = [httpResponse.allHeaderFields objectForKey:@"x-tt-trace-tag"];

    record.dnsTime = rawRecord.dnsTime;
    record.connectTime = rawRecord.connectTime;
    record.sslTime = rawRecord.sslTime;
    record.sendTime = rawRecord.sendTime;
    record.waitTime = rawRecord.waitTime;
    record.receiveTime = rawRecord.receiveTime;
    record.protocolName = rawRecord.protocolName;
    record.isSocketReused = rawRecord.isSocketReused;
    record.traceId = rawRecord.traceId;
    record.requestLog = rawRecord.requestLog;
    record.clientType = @"url_session";
    record.isForeground = rawRecord.isForeground;
    record.scene = rawRecord.scene;
    record.requestScene = rawRecord.requestScene;
    record.format = rawRecord.format;
    record.logType = rawRecord.logType;
    record.redirectCount = rawRecord.redirectCount;
    record.redirectList = rawRecord.redirectList;
    record.sessionConnectReuse = rawRecord.sessionConnectReuse;
    record.aid = rawRecord.aid;
    record.sdkAid = rawRecord.sdkAid;
    record.hit_rule_tags = rawRecord.hit_rule_tags;

    record.requestSendTime = rawRecord.requestSendTime;
    record.responseRecTime = rawRecord.responseRecTime;

    record.injectTracelog = rawRecord.injectTracelog;
    record.baseApiAll = rawRecord.baseApiAll;
    record.netLogType = rawRecord.netLogType;
    record.enableUpload = rawRecord.enableUpload;

    if (hmd_log_enable()) {
        unsigned long long responseBodySize = 0;
        if ([rawRecord.responseData isKindOfClass:[NSData class]]) {
            responseBodySize = [(NSData *)rawRecord.responseData length];
        }
        
        NSString *networkLog = [NSString stringWithFormat:@"net_type:NSURLSession, uri:%@, MIMEType：%@, request body size：%lubyte, response body size：%llubyte",record.MIMEType, record.absoluteURL, rawRecord.request.HTTPBody.length,responseBodySize];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@",networkLog);
    }
    
    return record;
}

- (id)copyWithZone:(NSZone *)zone{
    HMDHTTPDetailRecord *model = [[[self class] allocWithZone:zone] init];

    model.isSuccess = self.isSuccess;
    model.connetType = self.connetType ?: @"";
    model.method = self.method ?: @"";
    model.host = self.host;
    model.logType = self.logType;
    model.absoluteURL = self.absoluteURL;
    model.startTime = self.startTime;
    model.endtime = self.endtime;
    model.duration = self.duration;
    model.upStreamBytes = self.upStreamBytes;
    model.downStreamBytes = self.downStreamBytes;
    model.statusCode = self.statusCode;
    model.connetCode = self.connetCode;
    model.radioAccessType = self.radioAccessType;
    model.hasTriedTimes = self.hasTriedTimes;
    
    model.sessionID = self.sessionID;
    model.timestamp = self.timestamp;
    model.isOverThreshold = self.isOverThreshold;
    model.isReported = self.isReported;
    model.MIMEType = self.MIMEType;
    model.errCode = self.errCode;
    model.errDesc = self.errDesc;
    model.requestHeader = self.requestHeader;
    model.requestBody = self.requestBody;
    model.responseHeader = self.responseHeader;
    model.responseBody = self.responseBody;
    model.proxyTime = self.proxyTime;
    model.dnsTime = self.dnsTime;
    model.connectTime = self.connectTime;
    model.sslTime = self.sslTime;
    model.sendTime = self.sendTime;
    model.waitTime = self.waitTime;
    model.receiveTime = self.receiveTime;
    model.isFromProxy = self.isFromProxy;
    model.protocolName = self.protocolName;
    model.isSocketReused = self.isSocketReused;
    model.traceId = self.traceId;
    model.requestLog = self.requestLog;
    model.clientType = self.clientType;
    model.scene = self.scene;
    model.format = self.format;
    model.isForeground = self.isForeground;
    model.sid = self.sid;
    model.redirectCount = self.redirectCount;
    model.redirectList = self.redirectList;
    model.sessionConnectReuse = self.sessionConnectReuse;
    model.aid = self.aid;
    model.sdkAid = self.sdkAid;
    model.hit_rule_tags = self.hit_rule_tags;
    model.appVersion = self.appVersion;
    model.buildVersion = self.buildVersion;
    model.osVersion = self.osVersion;
    model.injectTracelog = self.injectTracelog;
    model.netLogType = self.netLogType;
    model.baseApiAll = self.baseApiAll;
    model.tcpTime = self.tcpTime;
    model.requestSendTime = self.requestSendTime;
    model.responseRecTime = self.responseRecTime;
    model.requestScene = self.requestScene;
    model.customExtraValue = self.customExtraValue;
    model.requestSerializerTimingInfo = self.requestSerializerTimingInfo;
    model.requestFiltersTimingInfo = self.requestFiltersTimingInfo;
    model.responseSerializerTimingInfo = self.responseSerializerTimingInfo;
    model.responseFiltersTimingInfo = self.responseFiltersTimingInfo;
    model.responseAdditionalTimingInfo = self.responseAdditionalTimingInfo;
    model.responseBDTuringTimingInfo = self.responseBDTuringTimingInfo;
    model.concurrentRequest = self.concurrentRequest;
    model.bdwURL = self.bdwURL;
    model.bdwChannel = self.bdwChannel;
    model.doubleUpload = self.doubleUpload;
    model.path = self.path;
    model.isSerializedOnMainThread = self.isSerializedOnMainThread;
    model.isCallbackExecutedOnMainThread = self.isCallbackExecutedOnMainThread;

    return model;
}
- (NSString *)triggerSourceName
{
    return kHMDNetworkTrackerName;
}

- (BOOL)isRawBinary {
    return ([self.MIMEType hasPrefix:@"image"] || [self.MIMEType hasPrefix:@"audio"] || [self.MIMEType hasPrefix:@"video"] || [self.MIMEType isEqual:@"application/octet-stream"] || [self.MIMEType isEqual:@"application/binary"]);
}

- (void)addCustomContextWithKey:(NSString *)key value:(id)value {
    if (!key || key.length == 0) {
        return;
    }
    if (![NSJSONSerialization isValidJSONObject:value]) {
        NSAssert(NO, @"HMDHTTPDetailRecord add extra value exception, the value is invaliad");
        return;
    }
    if (!self.customExtraValue) {
        self.customExtraValue = [NSMutableDictionary dictionary];
    }
    [self.customExtraValue setValue:value forKey:key];
}

+ (NSUInteger)cleanupWeight {
    return 40;
}

+ (NSArray *)bg_ignoreKeys {
    return @[@"path"];
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long time = MilliSecond(self.timestamp);

    if (self.customExtraValue && self.customExtraValue.count > 0) {
        [dataValue addEntriesFromDictionary:self.customExtraValue];
    }
    [dataValue setValue:@(time) forKey:@"timestamp"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];  // new
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];  // new
    [dataValue setValue:self.logType forKey:@"log_type"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    [dataValue setValue:self.appVersion forKey:@"app_version"];
    [dataValue setValue:self.osVersion forKey:@"os_version"];
    [dataValue setValue:self.buildVersion forKey:@"update_version_code"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];

    [dataValue setValue:@(self.isSuccess) forKey:@"isSuccess"]; // new
    [dataValue setValue:self.connetType forKey:@"connetType"];  // new
    [dataValue setValue:@(self.connetCode) forKey:@"network_type"];
    [dataValue setValue:self.radioAccessType forKey:@"network_type_code"];

    [dataValue setValue:@(self.hasTriedTimes) forKey:@"httpIndex"];  // new

    [dataValue setValue:self.method forKey:@"method"];  // new
    [dataValue setValue:self.host forKey:@"host"];  // new
    [dataValue setValue:self.absoluteURL forKey:@"uri"];
    [dataValue setValue:@(self.startTime) forKey:@"startTime"]; // new
    [dataValue setValue:@(self.endtime) forKey:@"endtime"]; // new
    [dataValue setValue:@(self.duration) forKey:@"timing_total"];
    [dataValue setValue:@(self.upStreamBytes) forKey:@"timing_totalSendBytes"]; // new
    [dataValue setValue:@(self.downStreamBytes) forKey:@"timing_totalReceivedBytes"];
    [dataValue setValue:@(self.statusCode) forKey:@"status"];
    [dataValue setValue:self.MIMEType forKey:@"MIMEType"]; // new
    [dataValue setValue:@(self.errCode) forKey:@"errCode"]; // new
    [dataValue setValue:self.errDesc forKey:@"error_desc"]; // new
    [dataValue setValue:self.requestHeader forKey:@"requestHeader"]; // new
    [dataValue setValue:self.responseHeader forKey:@"responseHeader"]; // new
    [dataValue setValue:self.responseBody forKey:@"responseBody"]; // new
    [dataValue setValue:@(self.singlePointOnly) forKey:@"single_point_only"];

    // url_session 中字段和 request_log 重复了
    if (![self.clientType isEqualToString:@"url_session"]) {
        [dataValue setValue:@(self.proxyTime) forKey:@"timing_proxy"];
        [dataValue setValue:@(self.dnsTime) forKey:@"timing_dns"];
        [dataValue setValue:@(self.connectTime) forKey:@"timing_connect"];
        [dataValue setValue:@(self.sslTime) forKey:@"timing_ssl"];
        [dataValue setValue:@(self.sendTime) forKey:@"timing_send"];
        [dataValue setValue:@(self.waitTime) forKey:@"timing_wait"];
        [dataValue setValue:@(self.receiveTime) forKey:@"timing_receive"];
    }
    // timing 相关的
    [dataValue setValue:@(self.isSocketReused) forKey:@"timing_isSocketReused"];
    [dataValue setValue:@(self.isCached) forKey:@"timing_isCached"];
    [dataValue setValue:@(self.isFromProxy) forKey:@"timing_isFromProxy"];
    CLANG_DIAGNOSTIC_PUSH
    CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
    [dataValue setValue:@(self.remotePort) forKey:@"timing_remotePort"];
    CLANG_DIAGNOSTIC_POP
    [dataValue setValue:self.protocolName forKey:@"protocolName"]; // new
    [dataValue setValue:self.traceId forKey:@"ttnet_traceId"];
    if (self.aid) {
        [dataValue setValue:self.aid forKey:@"aid"];
    }
    if (self.sdkAid) {
        [dataValue setValue:self.sdkAid forKey:@"sdk_aid"];
    }

    if (self.requestLog) {
        [dataValue setValue:self.requestLog forKey:@"request_log"];
    } else {
        NSString *log = [self.class getRequestLogWithRecord:self];
        [dataValue setValue:log forKey:@"request_log"];
    }

    // 网络库类型
    [dataValue setValue:self.clientType forKey:@"client_type"];

    // about network_v2
    if (self.baseApiAll) {
        [dataValue setValue:self.baseApiAll forKey:@"enable_base_api_all"];
    }
    if (self.injectTracelog) {
        [dataValue setValue:self.injectTracelog forKey:@"inject_tracelog"];
    }
    if (self.netLogType) {
        [dataValue setValue:self.netLogType forKey:@"net_log_type"];
    }

    // scene
    if(self.scene.length > 0 || self.format.length > 0) {
        NSMutableDictionary *extraStatus = [NSMutableDictionary dictionaryWithCapacity:2];
        if (self.scene.length > 0) {
            [extraStatus setValue:self.scene forKey:@"response_scene"]; // new
        }
        if (self.requestScene.length > 0) {
            [extraStatus setValue:self.requestScene forKey:@"request_scene"];
        }
        if (self.format.length > 0) {
            [extraStatus setValue:self.format forKey:@"format"]; // new
        }
        [dataValue setValue:[extraStatus copy] forKey:@"extra_status"];
    }

    if (self.requestFiltersTimingInfo) {
        [dataValue setValue:self.requestFiltersTimingInfo forKey:@"request_filters_timing"];
        NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:self.requestFiltersTimingInfo];
        [dataValue setValue:array forKey:@"request_filters_timing_v2"];
    }
    if (self.requestSerializerTimingInfo) {
        [dataValue setValue:self.requestSerializerTimingInfo forKey:@"request_serializer_timing"];
        NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:self.requestSerializerTimingInfo];
        [dataValue setValue:array forKey:@"request_serializer_timing_v2"];
    }
    if (self.responseFiltersTimingInfo) {
        [dataValue setValue:self.responseFiltersTimingInfo forKey:@"response_filters_timing"];
        NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:self.responseFiltersTimingInfo];
        [dataValue setValue:array forKey:@"response_filters_timing_v2"];
    }
    if (self.responseSerializerTimingInfo) {
        [dataValue setValue:self.responseSerializerTimingInfo forKey:@"response_serializer_timing"];
        NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:self.responseSerializerTimingInfo];
        [dataValue setValue:array forKey:@"response_serializer_timing_v2"];
    }
    if (self.responseAdditionalTimingInfo) {
        [dataValue setValue:self.responseAdditionalTimingInfo forKey:@"response_additional_timing"];
        NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:self.responseAdditionalTimingInfo];
        [dataValue setValue:array forKey:@"response_additional_timing_v2"];
    }
    if (self.responseBDTuringTimingInfo) {
        [dataValue setValue:self.responseBDTuringTimingInfo forKey:@"response_bdturing_timing"];
    }
    if(self.bdwURL) {
        [dataValue setValue:self.bdwURL forKey:@"webview_url"];
    }
    if(self.concurrentRequest) {
        [dataValue setValue:self.concurrentRequest forKey:@"concurrentRequest"];
    }
    if(self.isSerializedOnMainThread != -1) {
        [dataValue setValue:@(self.isSerializedOnMainThread) forKey:@"serialize_on_main_thread"];
    }
    if(self.isCallbackExecutedOnMainThread != -1) {
        [dataValue setValue:@(self.isCallbackExecutedOnMainThread) forKey:@"callback_on_main_thread"];
    }


    // 流量相关统计字段
    [dataValue setValue:@(self.sid) forKey:@"sid"];
    [dataValue setValue:@(self.isForeground) forKey:@"front"];
    NSInteger hitRules = [HMDHTTPDetailRecord getHitRulesWithInAllowList:self.inWhiteList];
    [dataValue setValue:@(hitRules) forKey:@"hit_rules"];
    [dataValue setValue:self.logType forKey:@"net_consume_type"];

    NSArray *hitRulesTags = [HMDHTTPDetailRecord getHitRulesTagsArrayWithHitRulesTages:self.hit_rule_tags];
    if (hitRulesTags) {
        [dataValue setValue:hitRulesTags forKey:@"hit_rule_tags"];
    }
    
    if(self.doubleUpload) {
        [dataValue setValue:@(self.doubleUpload) forKey:@"double_upload"];
    }
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    return dataValue;
}


@end
