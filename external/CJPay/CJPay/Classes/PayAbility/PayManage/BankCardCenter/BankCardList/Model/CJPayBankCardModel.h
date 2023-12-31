//
//  CJPayBankCardModel.h
//  BDPay
//
//  Created by 易培淮 on 2020/5/28.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>


NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardModel : JSONModel

@property(nonatomic, copy) NSString *bankCardId;//卡id
@property(nonatomic, copy) NSString *signNo;//签约协议号
@property(nonatomic, copy) NSString *bankCode;//银行编码
@property(nonatomic, copy) NSString *bankName;//银行名称
@property(nonatomic, copy) NSString *iconUrl;//银行图标
@property(nonatomic, copy) NSString *cardType;//卡类型
@property(nonatomic, copy) NSString *cardNoMask;//银行卡号掩码
@property(nonatomic, copy) NSString *mobileMask;//银行预留手机号掩码
@property(nonatomic, copy) NSString *nameMask;//持卡人姓名掩码
@property(nonatomic, copy) NSString *identityType;//证件类型
@property(nonatomic, copy) NSString *identityCodeMask;//证件号掩码
@property(nonatomic, copy) NSString *perdayLimit; //每日限额
@property(nonatomic, copy) NSString *perpayLimit; //每笔限额
@property(nonatomic, copy) NSString *status;//状态
@property(nonatomic, copy) NSString *quickPayMark;//快捷支付标签
@property(nonatomic, copy) NSString *cardBackgroundColor;
@property(nonatomic, copy) NSString *channelIconUrl;//渠道图标地址
@property(nonatomic, assign) BOOL needResign;//是否需要签约

@property(nonatomic, assign) BOOL isSmallStyle;//是否是小卡片样式，propertyIsIgnored放到最后!!!

@property(nonatomic, copy) void(^createNormalOrderAndSendSMSBlock)(void);

@end

NS_ASSUME_NONNULL_END
