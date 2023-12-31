//
//  BDTTNetPrefetch.h
//  AsheImpl
//
//  Created by luoqisheng on 2020/3/11.
//

#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const BDTTNetPrefetchIdentifier;
FOUNDATION_EXTERN NSString * const BDTTNetPrefetchResponseTimeStampKey;

@interface NSURLRequest (BDTTNetPrefetch)
- (NSString *)prefetchID;
@end

@interface NSHTTPURLResponse (BDTTNetPrefetch)
- (NSUInteger)prefetchResponseTimeStamp;
- (BOOL)isPrefetch;
@end

@interface BDTTNetPrefetchTask : NSObject

@property (copy) TTNetworkChunkedDataHeaderBlock headerCallback;
@property (copy) TTNetworkChunkedDataReadBlock dataCallback;
@property (copy) TTNetworkObjectFinishBlockWithResponse callbackWithResponse;
@property (copy) TTNetworkURLRedirectBlock redirectCallback;
@property (strong) NSURLRequest *request;
@property (strong) TTHttpResponse *response;
@property (strong) NSDate *responseDate;
@property (nonatomic, assign) NSUInteger cacheTime; // 预取有效时间，单位为秒
@property (nonatomic, assign) BOOL hitPrefetch; // 当前的 Task 是否被 BDWebViewSchemeTaskHandler 命中

- (instancetype)initWithRequest:(NSURLRequest *)request;
- (void)resume;
- (void)cancel;

- (uint64_t)opitimizeMillSecond;

@end

@protocol BDTTNetPrefetchObserver <NSObject>

@optional
/*
 预取收到 response 的时候回调
 */
- (void)prefetchDidReceiveResponse:(TTHttpResponse *)response withPrefetchId:(NSString *)prefetchId;
/*
 当 pre_request = 2 && pre-reject != 0 的时，预取 response 没回来的时候发起搜索，当前的预取被拒绝，会重新发起一次没有预取标记的请求
 */
- (void)didResendRequestWithResponse:(TTHttpResponse *)response;

@end

@interface BDTTNetPrefetch : NSObject

+ (instancetype)shared;
- (nullable BDTTNetPrefetchTask *)dequeuePrefetchTaskWithRequest:(NSURLRequest *)request;
- (void)prefetchWithRequest:(NSURLRequest *)request;
- (BOOL)containsRequest:(NSURLRequest *)request;
- (nullable BDTTNetPrefetchTask *)prefetchTaskWithPrefetchId:(NSString *)prefetchId;
- (void)addPrefetchObserver:(id<BDTTNetPrefetchObserver>)observer;
@end


NS_ASSUME_NONNULL_END
