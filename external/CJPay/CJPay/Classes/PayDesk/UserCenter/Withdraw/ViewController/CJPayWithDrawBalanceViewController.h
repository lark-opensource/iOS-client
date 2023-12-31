//
//  BDPayWithDrawBalanceViewController.h
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import <UIKit/UIKit.h>
#import "CJPayThemeBaseViewController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayLoadingManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawBalanceViewController : CJPayThemeBaseViewController <CJPayBaseLoadingProtocol>
- (instancetype)initWithBizParams:(NSDictionary *)bizParams
                           bizurl:(NSString *)bizUrl
                         response:(CJPayBDCreateOrderResponse *)response
                  completionBlock:(void(^)(CJPayBDOrderResultResponse *resResponse, CJPayOrderStatus orderStatus)) completionBlock;;
@end

NS_ASSUME_NONNULL_END
