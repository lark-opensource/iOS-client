//
//  CJPayBDTradeInfo+Biz.m
//  CJPay
//
//  Created by 王新华 on 2019/3/27.
//

#import "CJPayBDTradeInfo+Biz.h"

@implementation CJPayBDTradeInfo (Biz)

- (CJPayOrderStatus)tradeStatus {
    return CJPayOrderStatusFromString(self.tradeStatusString);
}

@end
