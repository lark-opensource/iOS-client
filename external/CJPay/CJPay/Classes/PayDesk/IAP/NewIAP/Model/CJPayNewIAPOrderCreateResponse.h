//
//  CJPayNewIAPOrderCreateResponse.h
//  Pods
//
//  Created by 尚怀军 on 2022/3/8.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayNewIAPOrderCreateModel;
@interface CJPayNewIAPOrderCreateResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, copy) NSString *outTradeNo;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *uidEncrypt;
@property (nonatomic, copy) NSString *tradeAmount;

- (CJPayNewIAPOrderCreateModel *)toNewIAPOrderCreateModel;

@end

NS_ASSUME_NONNULL_END
