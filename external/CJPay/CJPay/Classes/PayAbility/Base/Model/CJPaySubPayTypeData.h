//
//  CJPaySubPayTypeData.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/12.
//

#import <JSONModel/JSONModel.h>
#import "CJPayBytePayCreditPayMethodModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayVoucherInfoModel;
@class CJPaySubPayTypeIconTipModel;
@class CJPayCombinePayInfoModel;
@class CJPayTypeVoucherMsgV2Model;
@protocol CJPayBytePayCreditPayMethodModel;
@protocol BDPayCombinePayShowInfo;

typedef NS_ENUM(NSInteger, CJPayOutDisplayTradeAreaMsgType) {
    CJPayOutDisplayTradeAreaMsgTypePayBackVoucher, // 后反营销
    CJPayOutDisplayTradeAreaMsgTypeSubPayTypeVoucher, // 二级支付方式上的营销。，模式二展示的营销
    CJPayOutDisplayTradeAreaMsgTypeSubPayTypeCombineVoucher,// 支持组合支付时，签约并支付的，营销展示。
    CJPayOutDisplayTradeAreaMsgTypeOrderAmountText, // 订单金额
};

@interface CJPaySubPayTypeData : JSONModel

@property (nonatomic, assign) BOOL showCombinePay;
@property (nonatomic, copy) NSString *mobileMask;
@property (nonatomic, assign) NSInteger balanceAmount;
@property (nonatomic, assign) NSInteger incomeAmount;
@property (nonatomic, assign) NSInteger freezedAmount;

@property (nonatomic, copy) NSArray<NSString *> *voucherMsgList;
@property (nonatomic, copy) NSArray<NSDictionary *> *bytepayVoucherMsgList;// 抖音支付后的营销
@property (nonatomic, copy) NSArray<NSString *> *subPayVoucherMsgList; // 二级支付为card类型时 取的营销字段
@property (nonatomic, copy) CJPayVoucherInfoModel *voucherInfo;
@property (nonatomic, strong) CJPayTypeVoucherMsgV2Model *voucherMsgV2Model; //营销新结构，上面结构会逐步废弃

@property (nonatomic, copy) NSString *bankCardId;
@property (nonatomic, copy) NSString *cardNo;
@property (nonatomic, copy) NSString *cardNoMask;
@property (nonatomic, copy) NSString *cardType;
@property (nonatomic, copy) NSString *cardTypeName;
@property (nonatomic, copy) NSString *cardStyleShortName;
@property (nonatomic, copy) NSString *supportOneKeySign;
@property (nonatomic, copy) NSString *frontBankCode;
@property (nonatomic, copy) NSString *frontBankCodeName;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *cardShowName;
@property (nonatomic, copy) NSString *cardLevel;
@property (nonatomic, copy) NSString *perdayLimit;
@property (nonatomic, copy) NSString *perpayLimit;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *signNo;
@property (nonatomic, copy) NSString *creditPayInstallment;
@property (nonatomic, copy) NSArray<CJPayBytePayCreditPayMethodModel> *creditPayMethods;
@property (nonatomic, copy) NSString *cardAddExt;
@property (nonatomic, strong) CJPaySubPayTypeIconTipModel *iconTips;
@property (nonatomic, assign) NSInteger recommendType;
@property (nonatomic, copy) NSString *subExt;

// 抖音月付使用参数
@property (nonatomic, assign) BOOL isCreditActivate; // 是否已激活抖音月付
@property (nonatomic, copy) NSString *decisionId;   //小贷风控decision_id, 仅信用支付时有效
@property (nonatomic, copy) NSString *creditActivateUrl;  //抖音月付激活url
@property (nonatomic, copy) NSString *creditSignUrl;
// 端外支付
@property (nonatomic, copy) NSString *standardRecDesc; // 营销信息（使用~~XX~~包围的是删除线文案）
@property (nonatomic, copy) NSString *standardShowAmount; // 已经减过营销后的支付金额

@property (nonatomic, copy) NSArray<BDPayCombinePayShowInfo> *combineShowInfo;
@property (nonatomic, strong) CJPayCombinePayInfoModel *combinePayInfo;
@property (nonatomic, copy) NSString *selectPageGuideText; //二级支付方式右侧引导文案（目前仅支付中选卡页使用）

// O项目「签约信息前置」 信息展示的内容
@property (nonatomic, copy) NSString *voucherDescText; // 支付优惠/支付立减/付款立减/付款优惠
@property (nonatomic, copy) NSDictionary *tradeAreaVoucher;
// key: pay_back_voucher       value: xxxx 后反营销
// key：sub_pay_type_voucher   value：xxxx 二级支付方式上的营销
// key：order_amount_text      value：订单金额文案描述

- (CJPayBytePayCreditPayMethodModel *)curSelectCredit; //当前选中的分期数
- (void)updateDefaultCreditModel:(CJPayBytePayCreditPayMethodModel *)creditModel; //强制设置月付首次分期model，电商场景首次拉起使用

- (NSString *)obtainOutDisplayMsg:(CJPayOutDisplayTradeAreaMsgType)msgType;

@end

NS_ASSUME_NONNULL_END
