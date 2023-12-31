//
//  CJPayNewIAPConfirmModel.h
//  CJPay
//
//  Created by 尚怀军 on 2022/2/28.
//

#import "CJPayNewIAPBaseResponseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNewIAPConfirmModel : CJPayNewIAPBaseResponseModel

@property (nonatomic, assign) BOOL finishTransaction;

@end

NS_ASSUME_NONNULL_END
