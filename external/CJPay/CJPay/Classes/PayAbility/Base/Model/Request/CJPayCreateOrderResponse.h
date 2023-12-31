//
//  CJPayCreateOrderResponse.h
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import <Foundation/Foundation.h>
#import "CJPayTradeInfo.h"
#import "CJPayTypeInfo.h"
#import "CJPayIntergratedBaseResponse.h"
#import "CJPayDeskConfig.h"
#import "CJPayMerchantInfo.h"
#import "CJPayBDRetainInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayUserInfo;
@interface CJPayCreateOrderResponse : CJPayIntergratedBaseResponse

@property (nonatomic, copy) NSString *originJsonString;

@property (nonatomic, strong) CJPayTradeInfo *tradeInfo;
//支付信息
@property (nonatomic, strong) CJPayTypeInfo *payInfo;

@property (nonatomic, strong) CJPayDeskConfig *deskConfig;

@property (nonatomic, strong) CJPayMerchantInfo *merchantInfo;

@property (nonatomic, strong) CJPayUserInfo *userInfo;

@property (nonatomic, copy) NSDictionary *feMetrics;

@property (nonatomic, copy, nullable) NSString *dypayReturnURL;

@property (nonatomic, copy) NSString *paySource;

@property (nonatomic, copy) NSString *toastMsg;

- (NSInteger)totalAmountWithDiscount;
- (NSInteger)closeAfterTime;

@end

NS_ASSUME_NONNULL_END
