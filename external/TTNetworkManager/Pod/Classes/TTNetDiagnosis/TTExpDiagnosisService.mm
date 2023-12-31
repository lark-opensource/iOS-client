//
//  TTExpDiagnosisService.m
//  TTNetworkManager
//
//  Created by zhangzeming on 2021/6/14.
//  Copyright © 2021 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TTExpDiagnosisRequest.h"
#import "TTExpDiagnosisService.h"
#import "TTNetworkManagerChromium.h"
#import "TTNetworkManagerLog.h"

#include "components/cronet/ios/cronet_environment.h"
#include "net/net_buildflags.h"
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NET_EXP)
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager.h"
#endif

@interface TTExpDiagnosisService ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSObject<TTExpDiagnosisRequestProtocol>*> *reqMap;
// Called by user's thread.
@property (nonatomic, strong) dispatch_queue_t requestQueue;
@property (nonatomic, strong) dispatch_queue_t userLogQueue;
// Called by Network thread.
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

@property (nonatomic, strong) NSLock *request_id_lock;

@property (atomic, assign) UInt64 next_request_id;

@end

@interface TTExpDiagnosisRequest ()

- (instancetype)initWithRequestQueue:(dispatch_queue_t)requestQueue
                             reqType:(int)reqType
                              target:(NSString*)target
                       netDetectType:(int)netDetectType
                      multiNetAction:(int)multiNetAction
                           timeoutMs:(int64_t)timeoutMs
                               reqId:(UInt64)reqId
                            callback:(DiagnosisCallback)callback;

- (instancetype)initWithRequestQueue:(dispatch_queue_t)requestQueue
                             reqType:(int)reqType
                             targets:(NSArray<NSString*>*)targets
                       netDetectType:(int)netDetectType
                      multiNetAction:(int)multiNetAction
                           timeoutMs:(int64_t)timeoutMs
                               reqId:(UInt64)reqId
                            callback:(DiagnosisCallback)callback;

@end

@implementation TTExpDiagnosisService

- (UInt64)nextRequestId {
    UInt64 new_id;
    new_id = self.next_request_id++;
    return new_id;
}

- (void)addRequestWithId:(UInt64)reqId request:(NSObject<TTExpDiagnosisRequestProtocol>*)request {
    [self.request_id_lock lock];
    [self.reqMap setValue:request forKey:[@(reqId) stringValue]];
    [self.request_id_lock unlock];
}

- (void)removeRequestWithId:(UInt64)reqId {
    [self.request_id_lock lock];
    [self.reqMap removeObjectForKey:[@(reqId) stringValue]];
    [self.request_id_lock unlock];
}

+ (instancetype)shareInstance {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.reqMap = [[NSMutableDictionary alloc] init];
        self.requestQueue = dispatch_queue_create("ttnet_net_exp_request_queue", DISPATCH_QUEUE_SERIAL);
        self.userLogQueue = dispatch_queue_create("game_network_user_log_queue", DISPATCH_QUEUE_SERIAL);
        self.callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.request_id_lock = [NSLock new];
        self.next_request_id = 0;
    }
    return self;
}

+ (Boolean)isOneTargetRequestType:(TTExpRequestType)reqType {
    switch (reqType) {
        case DNS_RESOLVE_TARGET:
        case ACCELERATE_TARGET:
        case DIAGNOSE_TARGET:
        case DIAGNOSE_V2_TARGET:
            return true;
        case RACE_TARGETS:
        case RAW_DETECT_TARGETS:
            return false;
        default:
            return false;
    }
}

+ (Boolean)isValidNetDetect:(TTExpRequestType)reqType
              netDetectType:(TTExpNetDetectType)netDetectType {
    switch (reqType) {
        case DNS_RESOLVE_TARGET:
            // Ignore netDetectType.
            return true;
        case ACCELERATE_TARGET:
            if (netDetectType == NET_DETECT_HTTP_GET || netDetectType == NET_DETECT_ICMP_PING
                    || netDetectType == NET_DETECT_UDP_PING) {
                return true;
            }
            return false;
        case DIAGNOSE_TARGET:
        case DIAGNOSE_V2_TARGET:
            // Ignore netDetectTYPE. Because, diagnosis only use ICMP ping.
            return true;
        case RACE_TARGETS:
        case RAW_DETECT_TARGETS:
            if (((netDetectType & NET_DETECT_ALL) != 0) && ((netDetectType & ~NET_DETECT_ALL) == 0)) {
                return true;
            }
            return false;
        default:
            return false;
    }
}

+ (Boolean)checkTTNetIsInitialized {
    TTNetworkManagerChromium *networkManager = (TTNetworkManagerChromium *)[TTNetworkManager shareInstance];
    if ([networkManager ensureEngineStarted]) {
      LOGE(@"TTNet is not initalized");
      return NO;
    }
    return YES;
}

- (NSObject<TTExpDiagnosisRequestProtocol>*)createRequestWithReqestType:(TTExpRequestType)reqType
                                                                 target:(NSString*)target
                                                          netDetectType:(TTExpNetDetectType)netDetectType
                                                              timeoutMs:(int64_t)timeoutMs
                                                               callback:(DiagnosisCallback)callback {
    return [self createRequestWithReqestType:reqType
                                          target:target
                                   netDetectType:netDetectType
                                  multiNetAction:ACTION_UNSPECIFIED
                                       timeoutMs:timeoutMs
                                        callback:callback];
}

- (NSObject<TTExpDiagnosisRequestProtocol>*)createRequestWithReqestType:(TTExpRequestType)reqType
                                                                 target:(NSString*)target
                                                          netDetectType:(TTExpNetDetectType)netDetectType
                                                         multiNetAction:(TTExpMultiNetAction)multiNetAction
                                                              timeoutMs:(int64_t)timeoutMs
                                                               callback:(DiagnosisCallback)callback {
    if (![self.class checkTTNetIsInitialized]) {
        return nil;
    }
    if (![self.class isOneTargetRequestType:reqType]) {
        LOGD(@"Type %d of request should be created with multiple targets.", reqType);
        return nil;
    }
    if (![self.class isValidNetDetect:reqType netDetectType:netDetectType]) {
        LOGD(@"Illegal netDetectType: %d", netDetectType);
        return nil;
    }
    if (target == nil) {
        LOGD(@"Target is nil.");
        return nil;
    }
    UInt64 reqId = [self nextRequestId];
    __weak typeof(self) wself = self;
    DiagnosisCallback removeReqWithIdCallbackBlock = ^(NSString* report){
        __strong typeof(wself) sself = wself;
        dispatch_async(sself.callbackQueue, ^{
            if (callback) {
                callback(report);
            }
        });
        [sself removeRequestWithId:reqId];
    };
    NSObject<TTExpDiagnosisRequestProtocol>* request = nil;
    switch (reqType) {
        case DNS_RESOLVE_TARGET:
        case ACCELERATE_TARGET:
        case DIAGNOSE_TARGET:
        case DIAGNOSE_V2_TARGET:
            request = [[TTExpDiagnosisRequest alloc] initWithRequestQueue:self.requestQueue
                                                                  reqType:reqType
                                                                   target:target
                                                            netDetectType:netDetectType
                                                           multiNetAction:multiNetAction
                                                                timeoutMs:timeoutMs
                                                                    reqId:reqId
                                                                 callback:removeReqWithIdCallbackBlock];
            [self addRequestWithId:reqId request:request];
            break;
        default:
            return nil;
    }
    return request;
}

- (NSObject<TTExpDiagnosisRequestProtocol>*)createRequestWithReqestType:(TTExpRequestType)reqType
                                                                targets:(NSArray<NSString*>*)targets
                                                          netDetectType:(TTExpNetDetectType)netDetectType
                                                              timeoutMs:(int64_t)timeoutMs
                                                               callback:(DiagnosisCallback)callback {
    if (![self.class checkTTNetIsInitialized]) {
        return nil;
    }
    if ([self.class isOneTargetRequestType:reqType]) {
        LOGD(@"Type %d of request should be created with only one target.", reqType);
        return nil;
    }
    if (![self.class isValidNetDetect:reqType netDetectType:netDetectType]) {
        LOGD(@"Illegal netDetectType: %d", netDetectType);
        return nil;
    }
    if (targets == nil || [targets count] == 0) {
        LOGD(@"Illegal targets.");
        return nil;
    }
    UInt64 reqId = [self nextRequestId];
    __weak typeof(self) wself = self;
    DiagnosisCallback removeReqWithIdCallbackBlock = ^(NSString* report){
        __strong typeof(wself) sself = wself;
        dispatch_async(sself.callbackQueue, ^{
            if (callback) {
                callback(report);
            }
        });
        [sself removeRequestWithId:reqId];
    };
    NSObject<TTExpDiagnosisRequestProtocol>* request = nil;
    switch (reqType) {
        case RACE_TARGETS:
        case RAW_DETECT_TARGETS:
            request = [[TTExpDiagnosisRequest alloc] initWithRequestQueue:self.requestQueue
                                                                  reqType:reqType
                                                                  targets:targets
                                                            netDetectType:netDetectType
                                                           multiNetAction:ACTION_UNSPECIFIED
                                                                timeoutMs:timeoutMs
                                                                    reqId:reqId
                                                                 callback:removeReqWithIdCallbackBlock];
            [self addRequestWithId:reqId request:request];
            break;
        default:
            return nil;
    }
    return request;
}

- (void)reportUserLog:(NSString*)log {
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NET_EXP)
    if (log == nil || [log length] == 0) {
        return;
    }
    __weak typeof(self) wself = self;
    dispatch_sync(self.userLogQueue, ^{
        __strong typeof(wself) sself = wself;
        if (sself) {
            std::string log_str = [log cStringUsingEncoding:NSUTF8StringEncoding];
            const auto task = base::Bind(&net::tt_exp::TTNetExperienceManager::ReportNetworkEnvironment,
                    base::Unretained(net::tt_exp::TTNetExperienceManager::GetInstance()), log_str);
            [sself postTaskToNetworkThread:FROM_HERE task:task];
        }
    });
#endif
}

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NET_EXP)
- (void)postTaskToNetworkThread:(const base::Location&)from_here
                           task:(const base::Closure&)task {
    cronet::CronetEnvironment* engine = (cronet::CronetEnvironment*)[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] getEngine];
    if (!engine || !engine->GetURLRequestContextGetter() || !engine->GetURLRequestContextGetter()->GetNetworkTaskRunner()) {
        LOGE(@"engine in bad state");
        return;
    }
    engine->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(from_here, task);
}
#endif

@end
