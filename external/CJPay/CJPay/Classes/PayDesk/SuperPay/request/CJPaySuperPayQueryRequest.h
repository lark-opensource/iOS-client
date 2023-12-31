//
//  CJPaySuperPayQueryRequest.h
//  Pods
//
//  Created by 易培淮 on 2022/3/29.
//

#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayHintInfo;
@class CJPayPaymentInfoModel;
@interface CJPaySuperPayQueryResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *payStatus;
@property (nonatomic, copy) NSString *loadingMsg;
@property (nonatomic, copy) NSString *loadingSubMsg;
@property (nonatomic, copy) NSString *sdkInfo;//风控加验参数，不加验为空
@property (nonatomic, copy) NSString *payAgainInfo;
@property (nonatomic, strong) CJPayHintInfo *hintInfo;
@property (nonatomic, strong) CJPayPaymentInfoModel *paymentInfo; // 支付信息
@property (nonatomic, assign) BOOL showToast;

@property (nonatomic, copy) NSDictionary *ext;

@end

@interface CJPayPaymentInfoModel : JSONModel

@property (nonatomic, copy) NSString *deductType;
@property (nonatomic, copy) NSString *channelName;
@property (nonatomic, copy) NSString *cardMaskCode;
@property (nonatomic, copy) NSString *cardType;
@property (nonatomic, assign) NSInteger deductAmount;

@end


@interface CJPaySuperPayQueryRequest : CJPayBaseRequest

+ (void)startWithRequestparams:(NSDictionary *)requestParams
                  completion:(void (^)(NSError * _Nonnull, CJPaySuperPayQueryResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
