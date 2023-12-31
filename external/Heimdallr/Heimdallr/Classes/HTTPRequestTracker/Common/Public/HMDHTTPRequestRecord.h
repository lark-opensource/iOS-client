//
//  HMDHTTPRequestRecord.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/21.
//

#import <Heimdallr/Heimdallr.h>

@interface HMDHTTPRequestRecord : NSObject <NSCopying>

@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, strong, nullable) NSURLRequest *request;
@property (nonatomic, strong, nullable) NSURLResponse *response;
@property (nonatomic, copy, nullable) NSData *responseData;
@property (nonatomic, copy, nullable) NSString *connetType;
@property (nonatomic, copy, readwrite, nullable) NSString *logType;
@property (nonatomic, assign) long long startTime;
@property (nonatomic, assign) long long endtime;
@property (nonatomic, assign) long long requestSendTime;
@property (nonatomic, assign) long long responseRecTime;
@property (nonatomic, assign) unsigned long long dataLength;

@property (nonatomic, assign, readwrite) BOOL inWhiteList;
@property (nonatomic, assign, readwrite) long long dnsTime;
@property (nonatomic, assign, readwrite) long long connectTime;
@property (nonatomic, assign, readwrite) long long tcpTime;
@property (nonatomic, assign, readwrite) long long sslTime;
@property (nonatomic, assign, readwrite) long long sendTime;
// response start - request end
@property (nonatomic, assign, readwrite) long long waitTime;
// response end - response start
@property (nonatomic, assign, readwrite) long long receiveTime;
// Returns true if the response body was served from the cache
@property (nonatomic, assign, readwrite) NSUInteger isCached;

// Returns true if the request was delivered through a proxy
@property (nonatomic, assign, readwrite) NSUInteger isFromProxy;
@property (nonatomic, assign, readwrite) NSUInteger isSocketReused;
@property (nonatomic, assign, readwrite) NSInteger redirectCount;
@property (nonatomic, assign, readwrite) BOOL sessionConnectReuse;
@property (nonatomic, copy, readwrite, nullable) NSString * remoteIP __attribute__((deprecated("Due to security compliance, this field is temporarily discarded")));
@property (nonatomic, copy, readwrite, nullable) NSString * remotePort __attribute__((deprecated("Due to security compliance, this field is temporarily discarded")));
@property (nonatomic, copy, readwrite, nullable) NSString *protocolName;
@property (nonatomic, copy, readwrite, nullable) NSString *traceId;
@property (nonatomic, copy, readwrite, nullable) NSString *requestLog;
@property (nonatomic, copy, readwrite, nullable) NSArray *redirectList;

@property (nonatomic, assign, readwrite) NSInteger isForeground;
@property (nonatomic, copy, readwrite, nullable) NSString *scene;
@property (nonatomic, copy, readwrite, nullable) NSString *format;  // 图片格式

@property (nonatomic, copy, readwrite, nullable) NSString *aid;
@property (nonatomic, copy, readwrite, nullable) NSArray<NSString *> *hit_rule_tags;
// sdk about
@property (nonatomic, copy, readwrite, nullable) NSString *sdkAid;

// network config v2
@property (nonatomic, copy, readwrite, nullable) NSString *injectTracelog;
@property (nonatomic, copy, readwrite, nullable) NSString *netLogType;
@property (nonatomic, copy, readwrite, nullable) NSString *baseApiAll;
@property (nonatomic, assign) NSUInteger enableUpload;
// request scene
@property (nonatomic, copy, readwrite, nullable) NSString *requestScene;

@property (nonatomic, assign) NSInteger requestBodyStreamLength;

@end
