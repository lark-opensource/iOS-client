//
//  CJPayBaseRequest+CJPayCustomHost.h
//  CJPay
//
//  Created by wangxinhua on 2020/4/28.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBaseRequest(CJPayCustomHost)

// 优先走settings的host, 没有则走兜底
+ (NSString *)customDeskServerUrlString;

// 只需要https:// + 聚合host，没有走兜底
+ (NSString *)jhHostString;

// 极速付域名URL
+ (NSString *)superPayServerUrlString;

// settings 配置域名
+ (NSString *)intergratedConfigHost;

@end

NS_ASSUME_NONNULL_END
