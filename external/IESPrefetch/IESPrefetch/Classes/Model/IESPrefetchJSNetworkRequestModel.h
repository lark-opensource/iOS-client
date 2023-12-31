//
//  IESPrefetchJSNetworkRequestModel.h
//  IESPrefetch
//
//  Created by Hao Wang on 2019/8/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchJSNetworkRequestModel : NSObject

/// 要请求的url key: url
@property (nonatomic, copy) NSString *url;
/// GET/POST key: method
@property (nonatomic, copy) NSString *method;
/// 请求Headers key: headers
@property (nonatomic, copy) NSDictionary *headers;
/// 请求参数 key: params
@property (nonatomic, copy) id params;
/// 请求body key: data
@property (nonatomic, copy) NSDictionary *data;
/// traceId，不用作请求，仅用于本地日志
@property (nonatomic, copy) NSString *traceId;
/// 请求是否需要通参 key: needCommonParams
@property (nonatomic, assign) BOOL needCommonParams;
/// 即使命中缓存，仍然发出请求。确保下次是上一次最新的数据（Android此行为是默认的）
@property (nonatomic, assign) BOOL doRequestEvenInCache;
/// 忽略缓存直接走网络 key: ignore_cache
@property (nonatomic, assign) BOOL ignoreCache;
/// 请求的额外配置，不参与description/hash运算！
@property (nonatomic, copy) NSDictionary *extras;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;

- (NSString *)hashValue;

@end

NS_ASSUME_NONNULL_END
