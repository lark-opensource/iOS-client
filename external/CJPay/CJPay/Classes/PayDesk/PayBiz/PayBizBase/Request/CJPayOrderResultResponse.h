//
//  CJPayOrderResultResponse.h
//  Pods
//
//  Created by wangxinhua on 2020/8/23.
//

#import "CJPayIntergratedBaseResponse.h"
#import "CJPayTradeInfo.h"
#import "CJPaySDKDefine.h"
#import "CJPayResultPageInfoModel.h"

NS_ASSUME_NONNULL_BEGIN
@protocol CJPayPaymentInfo;
@interface CJPayOrderResultResponse : CJPayIntergratedBaseResponse
@property (nonatomic, strong) CJPayTradeInfo *tradeInfo;
@property (nonatomic, assign) int64_t remainTime;
@property (nonatomic, copy) NSArray<CJPayPaymentInfo> *paymentInfo;
@property (nonatomic, strong) CJPayResultPageInfoModel *resultPageInfo;
@property (nonatomic, copy) NSString *openSchema;
@property (nonatomic, copy) NSString *openUrl;
@end

NS_ASSUME_NONNULL_END
