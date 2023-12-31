//
//  CJPayDYMainViewController.h
//  CJPay
//
//  Created by wangxiaohong on 2020/2/13.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDOrderResultResponse;
typedef void(^CJPayCompletionBlock) (CJPayBDOrderResultResponse *resResponse, CJPayOrderStatus orderStatus);

@class CJPayBDCreateOrderResponse;
@interface CJPayDYMainViewController : CJPayHalfPageBaseViewController<CJPayBaseLoadingProtocol>

- (instancetype)initWithParams:(NSDictionary *)params
           createOrderResponse:(CJPayBDCreateOrderResponse *)response
               completionBlock:(CJPayCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
