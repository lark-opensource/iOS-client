//
//  HMDHTTPDetailRecord.h
//  Heimdallr
//
//  Created by fengyadong on 2018/2/2.
//

#import "HMDTrackerRecord.h"

extern NSString * _Nonnull const kHMDNetworkTrackerName;
@class HMDHTTPRequestRecord;

@interface HMDHTTPDetailRecord : HMDTrackerRecord <NSCopying>

@property (nonatomic, assign, readwrite) NSUInteger isReported;
@property (nonatomic, assign, readwrite) NSUInteger isSuccess;
@property (nonatomic, assign, readwrite) NSUInteger connetCode;
@property (nonatomic, assign, readwrite) long long startTime;
@property (nonatomic, assign, readwrite) long long endtime;
@property (nonatomic, assign, readwrite) long long duration;
@property (nonatomic, assign, readwrite) unsigned long long upStreamBytes;
@property (nonatomic, assign, readwrite) unsigned long long downStreamBytes;
@property (nonatomic, assign, readwrite) NSInteger statusCode;
@property (nonatomic, assign, readwrite) NSUInteger inWhiteList;
@property (nonatomic, assign, readwrite) NSInteger errCode;
@property (nonatomic, copy, readwrite, nullable) NSString *connetType;
@property (nonatomic, copy, readwrite, nullable) NSString *logType;
@property (nonatomic, copy, readwrite, nullable) NSString *method;
@property (nonatomic, copy, readwrite, nullable) NSString *host;
@property (nonatomic, copy, readwrite, nullable) NSString *absoluteURL;
@property (nonatomic, copy, readwrite, nullable) NSString *MIMEType;
@property (nonatomic, copy, readwrite, nullable) NSString *errDesc;
@property (nonatomic, copy, readwrite, nullable) NSString *requestHeader;
@property (nonatomic, copy, readwrite, nullable) NSString *requestBody;
@property (nonatomic, copy, readwrite, nullable) NSString *responseHeader;
@property (nonatomic, copy, readwrite, nullable) NSString *responseBody;
// The time spent determing which proxy to use
// proxy_resolve_end - proxy_resolve_start
@property (nonatomic, assign, readwrite) long long proxyTime;
@property (nonatomic, assign, readwrite) long long dnsTime;
@property (nonatomic, assign, readwrite) long long connectTime;
@property (nonatomic, assign, readwrite) long long sslTime;
@property (nonatomic, assign, readwrite) long long sendTime;
@property (nonatomic, assign, readwrite) long long tcpTime;
// wait = receive_headers_end - send_end
@property (nonatomic, assign, readwrite) long long waitTime;
// now - receive_headers_end
@property (nonatomic, assign, readwrite) long long receiveTime;
@property (nonatomic, assign, readwrite) long long requestSendTime;
@property (nonatomic, assign, readwrite) long long responseRecTime;

// True if the socket was reused.  When true, DNS, connect, and SSL times
// will all be null
@property (nonatomic, assign, readwrite) NSUInteger isSocketReused;

// Returns true if the response body was served from the cache
@property (nonatomic, assign, readwrite) NSUInteger isCached;

// Returns true if the request was delivered through a proxy
@property (nonatomic, assign, readwrite) NSUInteger isFromProxy;
@property (nonatomic, assign, readwrite) long long remotePort __attribute__((deprecated("Due to security compliance, the change field is temporarily discarded")));
@property (nonatomic, assign, readwrite) NSUInteger hasTriedTimes;
@property (nonatomic, assign, readwrite) NSInteger isForeground;
@property (nonatomic, assign, readwrite) BOOL isOverThreshold;
@property (nonatomic, assign) NSUInteger enableRandomSampling;
@property (nonatomic, assign, readwrite) NSInteger sid;
@property (nonatomic, assign, readwrite) NSInteger redirectCount;
@property (nonatomic, assign, readwrite) BOOL sessionConnectReuse;
@property (nonatomic, copy, readwrite, nullable) NSString *remoteIP __attribute__((deprecated("Due to security compliance, the change field is temporarily discarded")));
@property (nonatomic, copy, readwrite, nullable) NSString *protocolName;
@property (nonatomic, copy, readwrite, nullable) NSString *traceId;
@property (nonatomic, copy, readwrite, nullable) NSString *requestLog;
@property (nonatomic, copy, readwrite, nullable) NSString *clientType;
@property (nonatomic, copy, readwrite, nullable) NSString *radioAccessType;
@property (nonatomic, copy, readwrite, nullable) NSString *scene;
@property (nonatomic, copy, readwrite, nullable) NSString *format;  // 图片格式
@property (nonatomic, copy, readwrite, nullable) NSString *serverTiming;
@property (nonatomic, copy, readwrite, nullable) NSString *ttTraceID;
@property (nonatomic, copy, readwrite, nullable) NSString *ttTraceHost;
@property (nonatomic, copy, readwrite, nullable) NSString *ttTraceTag;
@property (nonatomic, copy, readwrite, nullable) NSString *contentEncoding;
@property (nonatomic, copy, readwrite, nullable) NSArray *redirectList;
@property (nonatomic, copy, readwrite, nullable) NSString *aid;
@property (nonatomic, copy, readwrite, nullable) NSArray<NSString *> *hit_rule_tags;
// sdk about
@property (nonatomic, copy, readwrite, nullable) NSString *sdkAid;
@property (nonatomic, assign) BOOL isSDK;
// network config v2
@property (nonatomic, copy, readwrite, nullable) NSString *injectTracelog;
@property (nonatomic, copy, readwrite, nullable) NSString *netLogType;
@property (nonatomic, copy, readwrite, nullable) NSString *baseApiAll;
// request scene
@property (nonatomic, copy, readwrite, nullable) NSString *requestScene;
@property (nonatomic, strong, readwrite, nullable) NSMutableDictionary * customExtraValue;

// 全链路打点相关新增
@property (nonatomic, copy, readwrite, nullable) NSDictionary *requestSerializerTimingInfo;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *requestFiltersTimingInfo;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *responseSerializerTimingInfo;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *responseFiltersTimingInfo;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *responseAdditionalTimingInfo;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *responseBDTuringTimingInfo;

// 复合请求打点
@property (nonatomic, copy, readwrite, nullable) NSDictionary *concurrentRequest;

// webview相关新增
@property (nonatomic, copy, readwrite, nullable) NSString *bdwURL; // webview的url
@property (nonatomic, copy, readwrite, nullable) NSString *bdwChannel; // webview的channel

+ (nonnull instancetype)recordWithRawData:(nonnull HMDHTTPRequestRecord *)rawRecord;

- (BOOL)isRawBinary;

// 该网络日志是否需要双发
@property (nonatomic, assign, readwrite)BOOL doubleUpload;
// 增加path字段，主要判断是否需要双发
@property (nonatomic, copy, readwrite, nullable)NSString *path;

// 请求线程相关新增
@property (nonatomic, assign, readwrite) NSInteger isSerializedOnMainThread;
@property (nonatomic, assign, readwrite) NSInteger isCallbackExecutedOnMainThread;

// 业务自定义字段
@property (nonatomic, copy, readwrite, nullable) NSDictionary *extraBizInfo;

// 命中动线
@property (nonatomic, assign) BOOL isMovingLine;
@property (nonatomic, assign) NSInteger isHitMovingLine;
@property (nonatomic, assign) NSInteger singlePointOnly;

// 白名单前置校验
@property (nonatomic, assign) BOOL isCheckAllowedBefore __attribute__((deprecated("Historical experiment plan.")));
@property (nonatomic, assign) BOOL isHitAllowedListBefore __attribute__((deprecated("Historical experiment plan.")));
@end
