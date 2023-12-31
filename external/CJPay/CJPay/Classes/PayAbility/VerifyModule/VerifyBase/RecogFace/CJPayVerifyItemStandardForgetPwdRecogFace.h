//
//  CJPayVerifyItemStandardForgetPwdRecogFace.h
//  CJPaySandBox
//
//  Created by shanghuaijun on 2023/6/7.
//

#import "CJPayVerifyItem.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayGetTicketResponse;
@interface CJPayVerifyItemStandardForgetPwdRecogFace : CJPayVerifyItem

@property (nonatomic, strong) CJPayGetTicketResponse *getTicketResponse;

@end

NS_ASSUME_NONNULL_END
