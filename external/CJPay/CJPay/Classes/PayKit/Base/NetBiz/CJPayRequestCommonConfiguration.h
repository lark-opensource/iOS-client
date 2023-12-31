//
//  CJPayRequestCommonConfiguration.h
//  Pods
//
//  Created by 王新华 on 2021/9/22.
//

#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN


@protocol CJPayRequestInterceptionProtocol <NSObject>

//
+ (BOOL)interceptResponseCallback:(NSDictionary *)obj requestParams:(NSDictionary *)requestParams retryRequestBlock:(void(^)(void))retryRequestBlock completionBlock:(void(^)(void))completionBlock;

@end

@protocol CJPaySDKHTTPRequestCustomHeaderProtocol <NSObject>

+ (void)appendCustomRequestHeaderFor:(TTHttpRequest *)httpRequest;

@end

@interface CJPayRequestCommonConfiguration : NSObject

+ (void)setRequestInterceptProtocol:(Class<CJPayRequestInterceptionProtocol>)requestInterceptProtocol;

+ (void)appendCustomHeaderProtocol:(Class<CJPaySDKHTTPRequestCustomHeaderProtocol>) protocol;

@end

@interface CJPayRequestCommonConfiguration(Read)

+ (nullable Class<CJPayRequestInterceptionProtocol>)requestInterceptProtocol;

+ (nullable NSHashTable<Class<CJPaySDKHTTPRequestCustomHeaderProtocol>> *)httpRequestHeaderProtocols;

@end

NS_ASSUME_NONNULL_END
