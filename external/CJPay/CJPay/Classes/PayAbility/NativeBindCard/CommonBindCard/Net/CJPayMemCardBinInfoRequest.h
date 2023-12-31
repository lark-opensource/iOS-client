//
//  CJPayMemCardBinInfoRequest.h
//  Pods
//
//  Created by 尚怀军 on 2020/2/20.
//

#import "CJPayBaseRequest.h"
#import "CJPayBankCardAddRequest.h"
#import "CJPayMemCardBinResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMemCardBinInfoRequest : CJPayBaseRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
     specialMerchantId:(NSString *)specialMerchantId
           signOrderNo:(NSString *)signOrderNo
               cardNum:(NSString *)cardNum
          isFuzzyMatch:(BOOL)isFuzzyMatch
        cardBindSource:(CJPayCardBindSourceType)cardBindSource
            completion:(void(^)(NSError * _Nullable error,CJPayMemCardBinResponse  *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
