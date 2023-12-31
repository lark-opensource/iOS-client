//
//  CJPayBDTradeInfo+Biz.h
//  CJPay
//
//  Created by 王新华 on 2019/3/27.
//

#import <Foundation/Foundation.h>
#import "CJPayBDTradeInfo.h"
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBDTradeInfo(Biz)

- (CJPayOrderStatus)tradeStatus;

@end

NS_ASSUME_NONNULL_END
