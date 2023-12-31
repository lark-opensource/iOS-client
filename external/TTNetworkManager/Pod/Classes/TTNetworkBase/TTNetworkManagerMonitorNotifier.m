//
//  TTNetworkManagerMonitorNotifier.m
//  Pods
//
//  Created by ZhangLeonardo on 16/3/24.
//
//

#import "TTNetworkManagerMonitorNotifier.h"


@interface TTHttpRequest()
@property (atomic, readwrite, assign) BOOL isSerializedOnMainThread;
@end

@interface TTHttpResponse()
@property (atomic, readwrite, assign) BOOL isCallbackExecutedOnMainThread;
@end

/**
 *  Callback for monitoring, notification will be sent when requested
 */
NSString * const kTTNetworkManagerMonitorStartNotification = @"kTTNetworkManagerMonitorStartNotification";
/**
 *  Callback for monitoring, it will be notified when the request is completed, including success and failure */
NSString * const kTTNetworkManagerMonitorFinishNotification = @"kTTNetworkManagerMonitorFinishNotification";
NSString * const kTTNetworkManagerMonitorRequestKey = @"kTTNetworkManagerMonitorRequestKey";
NSString * const kTTNetworkManagerMonitorResponseKey = @"kTTNetworkManagerMonitorResponseKey";
NSString * const kTTNetworkManagerMonitorErrorKey = @"kTTNetworkManagerMonitorErrorKey";
NSString * const kTTNetworkManagerMonitorResponseDataKey = @"kTTNetworkManagerMonitorResponseDataKey";
NSString * const kTTNetworkManagerMonitorRequestTriedTimesKey = @"kTTNetworkManagerMonitorRequestTriedTimesKey";
/**
 *  Business monitoring callback, cdn response check point
 */
NSString * const kTTNetworkManagerMonitorCdnCacheVerify = @"kTTNetworkManagerMonitorCdnCacheVerify";

@interface TTNetworkManagerMonitorNotifier()
@property(nonatomic, assign)BOOL enable;
@end

@implementation TTNetworkManagerMonitorNotifier

+ (instancetype)defaultNotifier
{
    static TTNetworkManagerMonitorNotifier * s_notifier;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_notifier = [[TTNetworkManagerMonitorNotifier alloc] init];
    });
    return s_notifier;
}

- (void)setEnable:(BOOL)enable
{
    _enable = enable;
}

- (void)notifyForMonitorStartRequest:(TTHttpRequest *)request hasTriedTimes:(NSInteger)triedTimes
{
    if (!_enable) {
        return;
    }
    
    request.isSerializedOnMainThread = [NSThread isMainThread];
    
    NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:10];
    [userInfo setValue:request forKey:kTTNetworkManagerMonitorRequestKey];
    [userInfo setValue:@(triedTimes) forKey:kTTNetworkManagerMonitorRequestTriedTimesKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetworkManagerMonitorStartNotification object:nil userInfo:userInfo];
}

- (void)notifyForMonitorFinishResponse:(TTHttpResponse *)response
                            forRequest:(TTHttpRequest *)request
                                 error:(NSError *)error
                              response:(id)responseObj
{
    NSAssert([request isKindOfClass:TTHttpRequest.class] && (response == nil || [response isKindOfClass:TTHttpResponse.class]), @"must be TTHttpResponse and TTHttpRequest");
    if (!_enable) {
        return;
    }
    
    if (!request.shouldReportLog) {
        //concurrent request may shutdown this notification switch to send only one log during the request time
        return;
    }
    
    //construct req_comp
    NSString *reqContentEncoding = [request valueForHTTPHeaderField:@"content-encoding"];
    if (reqContentEncoding) {
        [response.extraBizInfo setValue:reqContentEncoding forKey:@"req_comp"];
    }
    //construct resp_comp
    NSString *resContentEncoding = [response.allHeaderFields objectForKey:@"content-encoding"];
    if (resContentEncoding) {
        [response.extraBizInfo setValue:resContentEncoding forKey:@"resp_comp"];
    }
    //construct biz_total_time
    NSDate *startBizTime = request.startBizTime;
    NSNumber *elapsedBizTime = [NSNumber numberWithDouble:(-[startBizTime timeIntervalSinceNow]) * 1000];
    //calculate duration as biz_total_time for concurrent request
    if (response.concurrentRequestLogInfo) {
        elapsedBizTime = [response.concurrentRequestLogInfo objectForKey:@"duration"];
    }
    [response.extraBizInfo setValue:elapsedBizTime forKey:@"biz_total_time"];
    
    response.isCallbackExecutedOnMainThread = [NSThread isMainThread];
    
    NSMutableDictionary * responseUserInfo = [NSMutableDictionary dictionaryWithCapacity:10];
    [responseUserInfo setValue:request forKey:kTTNetworkManagerMonitorRequestKey];
    [responseUserInfo setValue:response forKey:kTTNetworkManagerMonitorResponseKey];
    [responseUserInfo setValue:error forKey:kTTNetworkManagerMonitorErrorKey];
    [responseUserInfo setValue:responseObj forKey:kTTNetworkManagerMonitorResponseDataKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetworkManagerMonitorFinishNotification object:nil userInfo:responseUserInfo];
}

- (void)notifyCdnCacheVerifyResponse:(TTHttpResponse *)response
                          forRequest:(TTHttpRequest *)request
                          errorState:(NSError*)errorState {
    if (!_enable) {
        return;
    }
    NSMutableDictionary * responseUserInfo = [NSMutableDictionary dictionaryWithCapacity:10];
    [responseUserInfo setValue:request forKey:kTTNetworkManagerMonitorRequestKey];
    [responseUserInfo setValue:response forKey:kTTNetworkManagerMonitorResponseKey];
    [responseUserInfo setValue:errorState forKey:kTTNetworkManagerMonitorErrorKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetworkManagerMonitorCdnCacheVerify object:nil userInfo:responseUserInfo];
}

@end
