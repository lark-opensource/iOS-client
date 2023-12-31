//
//  HMDURLProtocolManager.h
//  Heimdallr
//
//  Created by fengyadong on 2018/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDURLProtocolManager : NSObject

@property (nonatomic, strong, readonly) NSURLSession *session;
@property (nonatomic, strong, readonly) dispatch_queue_t session_queue;

+ (instancetype)shared;

- (nullable NSURLSessionDataTask *)generateDataTaskWithURLRequest:(NSURLRequest *)request
                                               underlyingDelegate:(id<NSURLSessionTaskDelegate,NSURLSessionDataDelegate>)deleagte;

@end

NS_ASSUME_NONNULL_END
