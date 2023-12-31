//
//  CJPayIDCardOCRResponse.h
//  CJPay
//
//  Created by youerwei on 2022/6/21.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIDCardOCRResponse : CJPayBaseResponse

// 证件上传订单号
@property (nonatomic, copy) NSString *flowNo;
@property (nonatomic, copy) NSString *idName;
@property (nonatomic, copy) NSString *idCode;

@end

NS_ASSUME_NONNULL_END
