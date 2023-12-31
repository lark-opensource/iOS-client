//
//  CJPayBindUnionPayBankCardResponse.h
//  CJPay-5b542da5
//
//  Created by bytedance on 2022/9/7.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayUnionCardInfoModel;
@class CJPayErrorButtonInfo;

@interface CJPayBindUnionPayBankCardResponse : CJPayBaseResponse

@property (nonatomic, copy) NSArray<CJPayUnionCardInfoModel> *bindCardIdList;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;
@property (nonatomic, copy) NSString *isSetPwd;

@end

NS_ASSUME_NONNULL_END
