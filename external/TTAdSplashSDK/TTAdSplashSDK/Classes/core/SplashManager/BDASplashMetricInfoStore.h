//
//  BDASplashMetricInfoStore.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/10/20.
//

#import <Foundation/Foundation.h>
#import "TTAdSplashHeader.h"

NS_ASSUME_NONNULL_BEGIN

/// 用于临时存储 metric 打点的相关信息，SDK 进行预加载请求的时候，会从这里获取打点信息，获取完之后就删除。
@interface BDASplashMetricInfoStore : NSObject

+ (instancetype)shareInstance;

- (void)storeInfoWithAdId:(NSString *)adId errorCode:(BDASModelStatusCode)code;

- (NSString *)metricInfoStr;

- (void)clearMetricInfo;

@end

NS_ASSUME_NONNULL_END
