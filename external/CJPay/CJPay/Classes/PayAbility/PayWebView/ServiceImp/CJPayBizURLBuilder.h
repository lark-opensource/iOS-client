//
//  CJPayBizURLBuilder.h
//  Pods
//
//  Created by 王新华 on 2021/9/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayURLSceneType) {
    CJPayURLSceneWebCardList,
    CJPayURLSceneWebBalanceWithdraw,
    CJPayURLSceneWebTradeRecord,
};

@interface CJPayBizURLBuilder : NSObject

+ (NSString *)generateURLForType:(CJPayURLSceneType) urlSceneType withAppId:(NSString *)appId withMerchantId:(NSString *)merchantId otherParams:(NSDictionary *)otherParams;

@end

NS_ASSUME_NONNULL_END
