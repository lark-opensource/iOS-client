//
//  BDPayRechargeBalanceViewController.h
//  CJPay
//
//  Created by 王新华 on 3/10/20.
//

#import "CJPayThemeBaseViewController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayFrontCashierResultModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayRechargeBalanceViewController : CJPayThemeBaseViewController <CJPayBaseLoadingProtocol>

- (instancetype)initWithBizParams:(NSDictionary *)bizParams
         bizurl:(NSString *)bizUrl
       response:(CJPayBDCreateOrderResponse *)response
completionBlock:(void(^)(CJPayBDOrderResultResponse *resResponse, CJPayOrderStatus orderStatus)) completionBlock;;

- (void)bindCardFromCardList:(BDChooseCardDismissLoadingBlock)dismissLoadingBlock;

@end

NS_ASSUME_NONNULL_END
