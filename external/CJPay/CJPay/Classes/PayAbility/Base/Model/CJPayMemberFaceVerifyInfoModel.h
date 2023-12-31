//
//  CJPayMemberFaceVerifyInfoModel.h
//  Pods
//
//  Created by 尚怀军 on 2020/12/31.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayFaceVerifyInfo;
@interface CJPayMemberFaceVerifyInfoModel : JSONModel

@property (nonatomic, copy) NSString *verifyType;
@property (nonatomic, copy) NSString *faceContent;
@property (nonatomic, copy) NSString *agreementUrl;
@property (nonatomic, copy) NSString *agreementDesc;
@property (nonatomic, copy) NSString *nameMask;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *smchId;
@property (nonatomic, assign) BOOL needLiveDetection;

- (CJPayFaceVerifyInfo *)getFaceVerifyInfoModel;

@end

NS_ASSUME_NONNULL_END
