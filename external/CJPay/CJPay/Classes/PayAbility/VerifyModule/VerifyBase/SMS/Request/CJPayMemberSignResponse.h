//
//  CJPayMemberSignResponse.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/17.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CJPayBaseResponse.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPayMemberFaceVerifyInfoModel.h"

NS_ASSUME_NONNULL_BEGIN
@protocol CJPayErrorButtonInfo;
@protocol CJPayMemAgreementModel;

//绑卡发短信响应
@interface CJPaySendSMSResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *smsToken;
@property (nonatomic, copy) NSString *mobileMask;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *agreements;
@property (nonatomic, copy) NSDictionary *protocolGroupNames;

//验证短信窗口展示文案
@property (nonatomic, copy) NSString *verifyTextMsg;

// 验脸
@property (nonatomic, strong) CJPayMemberFaceVerifyInfoModel *faceVerifyInfo;

@end
//绑卡签约验短信响应
@interface CJPaySignSMSResponse : CJPayBaseResponse

@property (nonatomic,copy) NSString *signNo;
@property (nonatomic, copy) NSString *bankCardId;
@property (nonatomic, copy) NSString *pwdToken;
@property (nonatomic, copy) CJPayMemBankInfoModel *cardInfoModel;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

NS_ASSUME_NONNULL_END
