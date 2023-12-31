//
//  CJPayInfo.h
//  Pods
//
//  Created by 易培淮 on 2020/11/17.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CJPayBDRetainInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPayCombinePayShowInfo : JSONModel

@property (nonatomic, copy) NSString *combineType;
@property (nonatomic, copy) NSString *combineMsg;

@end

@protocol BDPayCombinePayShowInfo;
@protocol CJPaySubPayTypeDisplayInfo;
@class CJPayBytePayCreditPayMethodModel;

@interface CJPayInfo : JSONModel

@property (nonatomic, copy) NSString *businessScene;  // Pre_Pay_NewCard  新卡支付、Pre_Pay_Balance  余额支付、Pre_Pay_BankCard 银行卡支付, Pre_Pay_Credit 信用支付, Pre_Pay_PayAfterUse 先用后付, Pre_Pay_Income 业务收入前置支付 Pre_Pay_Combine 组合支付
@property (nonatomic, copy) NSString *bankCardId; //卡id'
@property (nonatomic, copy) NSString *creditPayInstallment;//期数, 信用支付分期, "1","3","6","12","1"表示不分期
@property (nonatomic, copy) NSString *payAmountPerInstallment;//每期需要支付的金额
@property (nonatomic, copy) NSString *originFeePerInstallment; //原手续费
@property (nonatomic, copy) NSString *realFeePerInstallment; //实际手续费金额
@property (nonatomic, copy) NSArray<NSString *> *voucherNoList; //营销券列表
@property (nonatomic, copy) NSString *decisionId;   //小贷风控decision_id, 仅信用支付时有效
@property (nonatomic, copy) NSString *realTradeAmount; //实付金额。对于满减，实付金额 = 原金额 - 满减金额。随机立减, 实付金额 = 原金额。
@property (nonatomic, assign) NSInteger realTradeAmountRaw; // 实付金额，以分为单位
@property (nonatomic, copy) NSString *originTradeAmount;  //原金额
@property (nonatomic, copy) NSString *voucherMsg;   //营销文案
@property (nonatomic, assign) BOOL isCreditActivate;  // 是否激活了信用支付, 该字段仅business_scene为信用支付时有效
@property (nonatomic, copy) NSString *creditActivateUrl;  //激活信用支付的url
@property (nonatomic, assign) BOOL isNeedJumpTargetUrl; // 是否需要跳转目标链接，优先级高于激活
@property (nonatomic, copy) NSString *targetUrl;  // 信用付的目标跳转链接
@property (nonatomic, copy) NSString *voucherType; //营销类型, "0"无营销, "1"满减营销, "2"随机立减营销, "3"免手续费, "4"手续费打折, "5"手续费不打折 "8"手续费不打折+渠道固定立减 "9"手续费不打折+渠道随机立减 "10"先用后付验密页文案展示
@property (nonatomic, copy) NSString *payName;  //支付方式描述, 指纹/面容确认支付页用, 如"放心花(不分期)"
@property (nonatomic, copy) NSArray<NSString *> *cashierTags; // 后端下发标签，如：["bio_recover"]
@property (nonatomic, copy) NSString *verifyDesc; //密码验证额外描述
@property (nonatomic, copy) NSString *localVerifyDownGradeDesc; //密码验证额外描述，该字段主要是客户端主动降级用，比如指纹不可用降级到密码时，服务端下发兜底文案
@property (nonatomic, copy) NSString *verifyDowngradeReason; // 验证方式降级原因
/**
 电商使用：
0 -- 默认不启用verifyDesc；
1 -- 免密前置，免密验证被server降级为密码，带verifyDesc；
2 -- 生物前置了，serve没降级正常下发生物，(但可能客户端判断出生物本机拉不起则降级为密码)带verifyDesc；
3 -- 生物前置了，server降级下发了密码，带verifyDesc。
4 -- 生物或免密前置，server进行降级，端上在密码页进行toast提示
 */
@property (nonatomic, assign) NSInteger verifyDescType;
@property (nonatomic, copy) NSString *tradeDesc; //用于描述分期详情
@property (nonatomic, copy) NSString *currency;  //货币类型, 如CNY
@property (nonatomic, assign) BOOL hasRandomDiscount;  //是否有随机立减营销
@property (nonatomic, copy) NSString *iconUrl;  //图标
@property (nonatomic, strong) CJPayBDRetainInfoModel *retainInfo;
@property (nonatomic, copy) NSDictionary *retainInfoV2;
@property (nonatomic, copy) NSString *combineType; //资产组合方式 3:余额+卡, 129:业务收入+卡
@property (nonatomic, copy) NSString *primaryPayType;//主资产支付方式枚举 bank_card:老卡 new_bank_card是新卡

@property (nonatomic, copy) NSArray<BDPayCombinePayShowInfo> *combineShowInfo;
@property (nonatomic, assign, readonly) BOOL isCombinePay;
@property (nonatomic, copy) NSString *guideVoucherLabel;
@property (nonatomic, assign) BOOL isGuideCheck;

@property (nonatomic, copy) NSString *priceZoneShowStyle; //msgMarketing价格区展示样式："LINE"表示根据后端下发字段standardRecDesc、standardShowAmount来展示营销
@property (nonatomic, copy) NSString *standardRecDesc; // 营销信息（使用~~XX~~包围的是删除线文案）
@property (nonatomic, copy) NSString *standardShowAmount; // 已经减过营销后的支付金额
@property (nonatomic, assign, readonly) BOOL needShowStandardVoucher; //是否在验密页使用上述standardRecDesc等字段展示营销信息

@property (nonatomic, copy) NSArray<CJPaySubPayTypeDisplayInfo> *subPayTypeDisplayInfoList; //展示当前支付方式信息（验密页使用）
@property (nonatomic, copy) NSString *showChangePaytype; //命中新样式验密页（subPayTypeDisplayInfoList有值）时，是否在验密页展示“切换支付方式”UI。“0”表示不展示，其余情况则展示

- (CJPayBytePayCreditPayMethodModel *)buildCreditPayMethodModel;
- (BOOL)isDynamicLayout; // 判断是否动态化布局
@end

NS_ASSUME_NONNULL_END
