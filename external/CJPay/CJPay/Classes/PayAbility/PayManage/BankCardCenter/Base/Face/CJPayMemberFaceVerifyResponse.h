//
//  CJPayMemberFaceVerifyResponse.h
//  Pods
//
//  Created by 尚怀军 on 2020/12/31.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMemberFaceVerifyResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *faceRecognitionType;
@property (nonatomic, copy) NSString *faceContent;
@property (nonatomic, copy) NSString *nameMask;
@property (nonatomic, copy) NSString *token;

@end

NS_ASSUME_NONNULL_END
