//
//  CJPayFaceVerifyInfo.h
//  CJPay
//
//  Created by 尚怀军 on 2020/8/23.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFaceVerifyInfo : JSONModel

@property (nonatomic, copy) NSString *verifyType;
@property (nonatomic, copy) NSString *faceContent;
@property (nonatomic, copy) NSString *agreementURL;
@property (nonatomic, copy) NSString *agreementDesc;
@property (nonatomic, copy) NSString *nameMask;
@property (nonatomic, copy) NSString *verifyChannel;
@property (nonatomic, copy) NSString *style;
@property (nonatomic, copy) NSString *buttonDesc;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *faceScene; //活体动作场景
@property (nonatomic, assign) BOOL skipCheckAgreement; //主动刷脸是否需要跳过确认弹窗
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;

@end

NS_ASSUME_NONNULL_END
