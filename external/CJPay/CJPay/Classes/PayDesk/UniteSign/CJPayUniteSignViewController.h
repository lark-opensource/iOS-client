//
//  CJPayUniteSignViewController.h
//  CJPay-7351af12
//
//  Created by 王新华 on 2022/9/14.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayOuterPayUtil.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignCreateResponse;
@class CJPaySignQueryResponse;
@interface CJPayUniteSignViewController : CJPayHalfPageBaseViewController

- (instancetype)initWithBizParams:(NSDictionary *)bizParams
                         response:(CJPaySignCreateResponse *)response completionBlock:(nonnull void (^)(CJPaySignQueryResponse * _Nullable queryResponse, CJPayDypayResultType status))completionBlock;

@end

NS_ASSUME_NONNULL_END
