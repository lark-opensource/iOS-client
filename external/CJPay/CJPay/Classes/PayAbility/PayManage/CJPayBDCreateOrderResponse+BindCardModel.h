//
//  CJPayBDCreateOrderResponse+BindCardModel.h
//  CJPay
//
//  Created by wangxiaohong on 2022/12/30.
//

#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBindCardSharedDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBDCreateOrderResponse (BindCardModel)

- (CJPayBindCardSharedDataModel *)buildBindCardCommonModel;

@end

NS_ASSUME_NONNULL_END
