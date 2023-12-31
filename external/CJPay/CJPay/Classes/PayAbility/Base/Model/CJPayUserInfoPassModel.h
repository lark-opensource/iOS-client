//
//  CJPayUserInfoPassModel.h
//  CJPay
//
//  Created by 王新华 on 10/29/19.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPassExtModel : JSONModel

@property (nonatomic, copy) NSString *agreements;
@property (nonatomic, copy) NSString *authUidMaskMobile;
@property (nonatomic, copy) NSString *entrance;
@property (nonatomic, copy) NSString *isNeedAgreementUpgrade;
@property (nonatomic, copy) NSString *merchantAppId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *merchantName;
@property (nonatomic, copy) NSString *mobileAuthPageInfo;
@property (nonatomic, copy) NSString *pidMobile;
@property (nonatomic, copy) NSString *redirectUrl;
@property (nonatomic, copy) NSString *scene;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *upgradeAgreements;
@property (nonatomic, copy) NSString *aid;
@property (nonatomic, copy) NSString *createEntranceTitle;
@property (nonatomic, copy) NSString *dataUserStatus;
@property (nonatomic, copy) NSString *isNeedCheck;
@property (nonatomic, copy) NSString *randomStr;
@property (nonatomic, copy) NSString *tagAid;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *upgradeIsNeedCheck;

@end

@protocol CJPayPassExtModel;
@interface CJPayUserInfoPassModel : JSONModel

@property (nonatomic, strong) CJPayPassExtModel *extModel;
@property (nonatomic, copy) NSDictionary *extDic;
@property (nonatomic, assign) BOOL isNeedLogin;
@property (nonatomic, assign) NSInteger passportStauts;
@property (nonatomic, copy, readonly) NSString *redirectUrl;
@property (nonatomic, copy) NSString *url;

@end

NS_ASSUME_NONNULL_END
