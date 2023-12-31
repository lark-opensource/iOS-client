//
//  CJPayQueryPayOrderInfoRequest.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/4.
//

#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayLoginOrderStatus) {
    CJPayLoginOrderStatusSuccess,
    CJPayLoginOrderStatusProcess,
    CJPayLoginOrderStatusWarning,
    CJPayLoginOrderStatusError
};

@interface CJPayLoginTradeInfo : JSONModel

@property (nonatomic, copy) NSString *currency;
@property (nonatomic, copy) NSString *payAmount;
@property (nonatomic, copy) NSString *tradeAmount;
@property (nonatomic, copy) NSString *tradeName;
@property (nonatomic, copy) NSString *tradeDesc;

@end

@interface CJPayLoginMerchantInfo : JSONModel

@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *merchantName;
@property (nonatomic, copy) NSString *merchantShortToCustomer;

@end

@interface CJPayQueryPayOrderInfoResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayLoginTradeInfo *tradeInfo;
@property (nonatomic, strong) CJPayLoginMerchantInfo *merchantInfo;

- (CJPayLoginOrderStatus)resultStatus;

@end

@interface CJPayQueryPayOrderInfoRequest : CJPayBaseRequest

+ (void)startWithRequestParams:(NSDictionary *)requestParams
                  completion:(void (^)(NSError * _Nonnull, CJPayQueryPayOrderInfoResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
