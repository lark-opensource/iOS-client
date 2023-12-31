//
//  CJPayVerifyInfoResponse.h
//  Pods
//
//  Created by wangxinhua on 2021/7/30.
//

#import "CJPayBaseResponse.h"
#import "CJPayFaceVerifyInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVerifyInfoResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *verifyType;
@property (nonatomic, copy) NSString *jumpUrl;
@property (nonatomic, strong) CJPayFaceVerifyInfo *faceVerifyInfo;

@end

NS_ASSUME_NONNULL_END
