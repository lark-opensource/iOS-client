//
//  CJPayFaceRecogCommonResponse.h
//  Pods
//
//  Created by 尚怀军 on 2022/10/31.
//

#import "CJPayBaseResponse.h"
#import "CJPayIntergratedBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayFaceVerifyInfo;
@interface CJPayFaceRecogCommonResponse : CJPayIntergratedBaseResponse

@property (nonatomic, copy) NSString *lynxUrl;
@property (nonatomic, strong) CJPayFaceVerifyInfo *faceVerifyInfo;

@end

NS_ASSUME_NONNULL_END
