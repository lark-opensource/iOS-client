//
//  CJPayMemBankSupportListRequest.h
//  Pods
//
//  Created by 尚怀军 on 2020/2/19.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemBankSupportListResponse;
@interface CJPayMemBankSupportListRequest : CJPayBaseRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
     specialMerchantId:(NSString *)specialMerchantId
           signOrderNo:(NSString *)signOrderNo
            completion:(void(^)(NSError * _Nullable error, CJPayMemBankSupportListResponse *response))completionBlock;

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
     specialMerchantId:(NSString *)specialMerchantId
           signOrderNo:(NSString *)signOrderNo
                  exts:(NSDictionary *)exts
            completion:(void (^)(NSError * _Nullable, CJPayMemBankSupportListResponse * _Nonnull))completionBlock;

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
     specialMerchantId:(NSString *)specialMerchantId
           signOrderNo:(NSString *)signOrderNo
             queryType:(NSString *)queryType
            completion:(void (^)(NSError * _Nullable, CJPayMemBankSupportListResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
