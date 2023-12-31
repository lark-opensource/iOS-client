//
//  CJPayVerifyItemBioPaymentRecogFace.h
//  Pods
//
//  Created by 孔伊宁 on 2022/4/1.
//

#import "CJPayVerifyItemRecogFace.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBioPaymentBaseRequestModel;

@interface CJPayVerifyItemRecogFaceOnBioPayment : CJPayVerifyItemRecogFace

@property (nonatomic, copy) void(^faceRecogCompletion)(BOOL);
@property (nonatomic, assign) NSInteger failBefore;

- (void)tryFaceRecogWithResponse:(CJPayBDCreateOrderResponse *)response requestModel:(CJPayBioPaymentBaseRequestModel *)requestModel;

@end

NS_ASSUME_NONNULL_END
