//
//  CJPayVerifyItemStandardRecogFaceRetry.h
//  transferpay_standard
//
//  Created by shanghuaijun on 2023/6/6.
//

#import "CJPayVerifyItem.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayGetTicketResponse;
@interface CJPayVerifyItemStandardRecogFaceRetry : CJPayVerifyItem

@property (nonatomic, strong) CJPayGetTicketResponse *getTicketResponse;
@property (nonatomic, weak) UIViewController *referVC;

@end

NS_ASSUME_NONNULL_END
