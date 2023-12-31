//
//  CJPayVerifyItemBindCardRecogFace.h
//  Pods
//
//  Created by 尚怀军 on 2020/12/29.
//

#import "CJPayVerifyItemRecogFace.h"
#import "CJPayCreateOneKeySignOrderResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayFaceVerifyInfo;
@interface CJPayVerifyItemBindCardRecogFace : CJPayVerifyItemRecogFace

@property (nonatomic, copy) void(^loadingBlock)(BOOL);

- (void)startFaceRecogWithOneKeyResponse:(CJPayCreateOneKeySignOrderResponse *)oneKeySignOrderResponse
                              completion:(void(^)(BOOL))completion;

- (void)startFaceRecogWithParams:(NSDictionary *)params
                  faceVerifyInfo:(CJPayFaceVerifyInfo *)verifyInfo
                      completion:(void (^)(BOOL))completion;


@end

NS_ASSUME_NONNULL_END
