//
//  CJPayBaseVerifyManager+ButtonInfoHandler.h
//  CJPay
//
//  Created by 王新华 on 4/16/20.
//

#import "CJPayBaseVerifyManager.h"
#import "CJPayBDButtonInfoHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBaseVerifyManager(ButtonInfoHandler)

- (CJPayButtonInfoHandlerActionsModel *)commonButtonInfoModelWithResponse:(CJPayOrderConfirmResponse *)response;

@end

NS_ASSUME_NONNULL_END
