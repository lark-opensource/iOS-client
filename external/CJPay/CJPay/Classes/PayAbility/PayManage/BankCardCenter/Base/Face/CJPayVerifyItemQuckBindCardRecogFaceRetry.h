//
//  CJPayVerifyItemQuckBindCardRecogFaceRetry.h
//  Pods
//
//  Created by 尚怀军 on 2020/12/29.
//

#import "CJPayVerifyItemRecogFaceRetry.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVerifyItemQuckBindCardRecogFaceRetry : CJPayVerifyItemRecogFaceRetry

@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;
@property (nonatomic, copy) NSString *memberBizOrderNo;
@property (nonatomic, copy) void(^loadingBlock)(BOOL);


- (void)startFaceRecogRetryWithResponse:(CJPayOrderConfirmResponse *)response
                             completion:(void(^)(BOOL))completion;

@end

NS_ASSUME_NONNULL_END
