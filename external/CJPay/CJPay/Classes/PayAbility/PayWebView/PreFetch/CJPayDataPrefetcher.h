//
//  CJPayDataPrefetcher.h
//  CJPay
//
//  Created by wangxinhua on 2020/5/13.
//

#import <Foundation/Foundation.h>
#import "CJPayPrefetchConfig.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayPrefetcherProtocol <NSObject>

- (void)startRequest;
- (void)fetchData:(void(^)(id data, NSError *error))callback;

@end

@interface CJPayDataPrefetcher : NSObject<CJPayPrefetcherProtocol>

- (instancetype)initWith:(NSString *)requestUrl prefetchConfig:(CJPayPrefetchConfig *)config;

@end

NS_ASSUME_NONNULL_END
