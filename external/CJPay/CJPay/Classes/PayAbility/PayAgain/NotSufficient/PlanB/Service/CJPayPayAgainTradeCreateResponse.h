//
//  CJPayPayAgainTradeCreateResponse.h
//  Pods
//
//  Created by wangxiaohong on 2021/7/19.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDCreateOrderResponse;
@interface CJPayPayAgainTradeCreateResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayBDCreateOrderResponse *pageInfo;
@property (nonatomic, copy) NSDictionary *verifyPageInfoDict;

@end

NS_ASSUME_NONNULL_END
