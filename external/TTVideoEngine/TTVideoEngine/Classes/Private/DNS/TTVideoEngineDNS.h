//
//  TTVideoEngineDNS.h
//  Pods
//
//  Created by guikunzhi on 16/12/5.
//
//

#ifndef TTVideoEngineDNS_h
#define TTVideoEngineDNS_h

#import "TTVideoEngineUtil.h"

@protocol TTVideoEngineDNSProtocol <NSObject>

@required
// ipAddress array
- (void)parser:(id)dns didFinishWithAddress:(NSString *)ipAddress error:(NSError *)error;

@optional
- (void)parser:(id)dns didFailedWithError:(NSError *)error;
- (void)parserDidCancelled;

@end

@protocol TTVideoEngineDNSBaseProtocol <NSObject>

- (instancetype)initWithHostname:(NSString *)hostname;


- (void)start;

- (void)cancel;

@optional
- (instancetype)initWithHostname:(NSString *)hostname andType:(TTVideoEngineRetryStrategy)type;

@end

#endif /* TTVideoEngineDNS_h */
