//
//  CJPayQuickPayChannelModel.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/23.
//

#import <Foundation/Foundation.h>
#import "CJPayQuickPayUserAgreement.h"
#import <JSONModel/JSONModel.h>
#import "CJPayChannelModel.h"
/**
 银行卡信息
 */
@protocol CJPayQuickPayUserAgreement;
@interface CJPayQuickPayCardModel : CJPayChannelModel

@property(nonatomic, copy) NSString *bankCardID; //卡号加密
@property(nonatomic, copy) NSString *cardNoMask; //展示卡号
@property(nonatomic, copy) NSString *cardType; //卡类型 信用卡储蓄卡
@property(nonatomic, copy) NSString *cardTypeName;//卡类型名称 储蓄卡 信用卡
@property(nonatomic, copy) NSString *frontBankCode; //前端银行编码（工行储蓄卡)
@property(nonatomic, copy) NSString *trueNameMask;//姓名
@property(nonatomic, copy) NSString *frontBankCodeName;//前端银行名称
@property(nonatomic, copy) NSString *mobileMask;//手机号掩码
@property(nonatomic, copy) NSString *certificateCodeMask;//证件号
@property(nonatomic, copy) NSString *certificateType;//证件类型
@property(nonatomic, copy) NSString *needRepaire;//支付是否需要补全 目前不需要关注
//@property(nonatomic, copy) NSArray *displayItems;//需要补全展示的卡要素 目前不需要关注
@property(nonatomic, copy) NSArray<CJPayQuickPayUserAgreement> *userAgreements;//用户协议
@property(nonatomic, assign) NSInteger cardLevel; //1: 签约卡，2：未签约卡
@property (nonatomic, copy) NSString *perDayLimit;
@property (nonatomic, copy) NSString *perPayLimit;
@property (nonatomic, copy) NSString *withdrawMsg;
@property (nonatomic, copy) NSString *cardBinVoucher;
@property (nonatomic, strong) CJPayVoucherInfoModel *voucherInfo;

@property (nonatomic, assign) CJPayComeFromSceneType comeFromSceneType;

@end

/**
 银行卡支付方式
 */
@protocol CJPayQuickPayCardModel;
@interface CJPayQuickPayChannelModel : CJPayChannelModel

@property(nonatomic, copy) NSArray<CJPayQuickPayCardModel> *cards; // 银行卡列表
@property(nonatomic, copy) NSArray<CJPayQuickPayCardModel> *discountBanks; // 有营销&优惠券的未绑卡列表
@property(nonatomic, copy) NSString *enableBindCard; // 是否展示绑卡按钮，1为展示，0为不不可用
@property(nonatomic, copy) NSString *enableBindCardMsg; // 绑卡按钮不可用时的文案提示
@property(nonatomic, copy) NSString *discountBindCardMsg; // 绑卡促销文案
@property(nonatomic, copy) NSString *ttSubTitle;


- (BOOL)hasValidBankCard;

@end
