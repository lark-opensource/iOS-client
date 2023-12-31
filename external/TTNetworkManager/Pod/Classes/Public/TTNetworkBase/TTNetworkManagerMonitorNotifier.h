//
//  TTNetworkManagerMonitorNotifier.h
//  Pods
//
//  Created by ZhangLeonardo on 16/3/24.
//
//

#import <Foundation/Foundation.h>

#import "TTHttpRequest.h"
#import "TTHttpResponse.h"

/**
 *  Callback for monitoring, notification will be sent when there is a request
 */
extern NSString * const kTTNetworkManagerMonitorStartNotification;
/**
 *  Callback for monitoring, it will be notified when the request is completed, including success and failure
 */
extern NSString * const kTTNetworkManagerMonitorFinishNotification;//contain fail and done
/**
 *  Business monitoring callback, cdn response check point
 */
extern NSString * const kTTNetworkManagerMonitorCdnCacheVerify;

extern NSString * const kTTNetworkManagerMonitorRequestKey;
extern NSString * const kTTNetworkManagerMonitorResponseKey;
extern NSString * const kTTNetworkManagerMonitorErrorKey;
extern NSString * const kTTNetworkManagerMonitorResponseDataKey;
extern NSString * const kTTNetworkManagerMonitorRequestTriedTimesKey;


@interface TTNetworkManagerMonitorNotifier : NSObject

+ (instancetype)defaultNotifier;

/**
 *  Start monitoring, invalid by default
 *
 *  @param enable YES : valid, NO : invalid
 */
- (void)setEnable:(BOOL)enable;

/**
 *  Called when the request starts
 */
- (void)notifyForMonitorStartRequest:(TTHttpRequest *)request hasTriedTimes:(NSInteger)triedTimes;

/**
 *  Called when the request ends
 *
 *  @param error       error returned
 *  @param responseObj body returned,  maybe data，maybe dict ...
 */
- (void)notifyForMonitorFinishResponse:(TTHttpResponse *)response
                            forRequest:(TTHttpRequest *)request
                                 error:(NSError *)error
                              response:(id)responseObj;
/**
 *  verification monitoring and buried point statistics of cdn cache
 *  @param errorState  errorState of response
 */
- (void)notifyCdnCacheVerifyResponse:(TTHttpResponse *)response
                          forRequest:(TTHttpRequest *)request
                          errorState:(NSError*)errorState;

@end
