//
//  CJPayDefaultChannelShowConfig.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/23.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"
#import <JSONModel/JSONModel.h>

typedef NS_ENUM(NSUInteger, CJPayVoucherMsgType) {
    CJPayVoucherMsgTypeDefault = 0,  //老逻辑，使用旧数据结构展示营销
    CJPayVoucherMsgTypeHomePage, //首页营销信息，使用pay_type_voucher_msg_v2.tag34展示营销
    CJPayVoucherMsgTypeCardList //卡列表营销信息，使用pay_type_voucher_msg_v2.tag56展示营销
};

// 这个类是把各种支付方式配置的数据做一层转换和包装，在对外时提供一致的字段名称
@class CJPayChannelModel;
@class CJPayVoucherInfoModel;
@class CJPaySubPayTypeData;
@class CJPaySubPayTypeInfoModel;
@class CJPayTypeVoucherMsgV2Model;
@interface CJPayDefaultChannelShowConfig : JSONModel<NSCopying>

@property (nonatomic, assign) NSInteger index; // 支付方式索引
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *subTitleColor;
@property (nonatomic, copy) NSString *descTitle; //支付方式描述信息，用于展示背书信息，可以和sub_title同时存在
@property (nonatomic, strong) CJPayChannelModel *payChannel;
@property (nonatomic, copy) NSString *subPayType;
@property (nonatomic, copy) NSString *status; // 状态 "1"可以用, "0"不可用
@property (nonatomic, assign) CJPayChannelType type;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, copy) NSString *mobile;// 电话号
@property (nonatomic, copy) NSString *mark; // 渠道标记 、比如 推荐
@property (nonatomic, copy) NSArray<NSString *> *marks;
@property (nonatomic, copy) NSString *cjIdentify; // 端上自己用来区分各种支付渠道的参数
@property (nonatomic, copy) NSString *reason;
@property (nonatomic, assign) NSInteger cardLevel;
@property (nonatomic, copy) NSString *cardTailNumStr;
@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *accountUrl;
@property (nonatomic, assign) BOOL inValidConfig;
@property (nonatomic, copy) NSString *limitMsg;
@property (nonatomic, copy) NSString *withdrawMsg;
@property (nonatomic, copy) NSString *discountStr;
@property (nonatomic, copy) NSString *cardBinVoucher;
@property (nonatomic, copy) NSString *voucherMsg;
@property (nonatomic, assign) BOOL showCombinePay;
@property (nonatomic, copy) NSString *frontBankCode;
@property (nonatomic, assign) BOOL isLineBreak;
@property (nonatomic, copy) NSString *cardAddExt;
@property (nonatomic, copy) NSString *cardType;
@property (nonatomic, assign) BOOL isShowRedDot;
@property (nonatomic, copy) NSDictionary *retainInfoV2;
@property (nonatomic, copy) NSString *subExt;

@property (nonatomic, copy, nullable) NSString *primaryCombinePayAmount;
@property (nonatomic, copy, nullable) NSString *payAmount; //即后端下发的standardAmount
@property (nonatomic, copy, nullable) NSString *payVoucherMsg; //即后端下发的standardRecDesc

@property (nonatomic, strong, nullable) CJPayVoucherInfoModel *voucherInfo; //营销信息

@property (nonatomic, assign) CJPayVoucherMsgType voucherMsgV2Type;

@property (nonatomic, assign) CJPayComeFromSceneType comeFromSceneType;
@property (nonatomic, assign) BOOL isCombinePay; //是否是组合支付
@property (nonatomic, assign) BOOL isSecondPayCombinePay; //是否是二次支付组合支付
@property (nonatomic, assign)  CJPayChannelType combineType; //组合支付的类型，目前只有BDPayChannelTypeIncomePay和BDPayChannelTypeBalance

@property (nonatomic, copy) NSString *businessScene;
@property (nonatomic, copy) NSString *bankCardId;
@property (nonatomic, copy, nullable) CJPaySubPayTypeData *payTypeData;
@property (nonatomic, copy, nullable) NSString *homePageShowStyle;// 抖音支付二级支付方式的样式
@property (nonatomic, assign) BOOL useSubPayListVoucherMsg; // 二级支付营销是否使用 SubPayListVoucherMsg 中的字段
@property (nonatomic, copy, nullable) NSArray<CJPaySubPayTypeInfoModel *> *subPayTypeData; // 无卡无零钱用户根据card_style_index_list字段加入的
@property (nonatomic, assign) BOOL canUse; // 当前支付方式是否可用
@property (nonatomic, copy, nullable) NSString *paymentInfo; //该支付方式在验密页展示的描述信息（仅组合支付使用）
@property (nonatomic, copy, nullable) NSDictionary *lynxExtParams; //扩展字段，聚合confirm接口会透传此字段;

@property (nonatomic, copy, nullable) NSString *tradeConfirmButtonText; //支付方式对应的确认支付按钮文案
@property (nonatomic, copy, nullable) NSString *decisionId;   //小贷风控decision_id, 仅信用支付时有效
@property (nonatomic, assign) BOOL isCreditActivate;   //是否已激活抖音月付
@property (nonatomic, copy, nullable) NSString *creditActivateUrl;  //抖音月付激活url
@property (nonatomic, copy, nullable) NSString *creditSignUrl;  //抖音月付签约极速付url
@property (nonatomic, copy, nullable) NSString *feeVoucher;  //抖音月付手续费营销

// 替代bizModel同名字段
@property (nonatomic, assign, readonly) BOOL isUnionBindCard; // 是否是云闪付绑卡
@property (nonatomic, assign) BOOL hasConfirmBtnWhenUnConfirm;
@property (nonatomic, copy, nullable) NSString *reasonStr;
@property (nonatomic, assign) BOOL isChooseMethodSubPage;
@property (nonatomic, assign, readonly) BOOL hasSub;
@property (nonatomic, assign) BOOL isPaymentForOuterApp; //是否外部App拉起收银台支付
@property (nonatomic, assign, readonly) BOOL isNoActive;
@property (nonatomic, assign) BOOL isEcommercePay; //是否是电商支付
@property (nonatomic, assign) BOOL isFromCombinePay;
@property (nonatomic, assign) BOOL isIntegerationChooseMethodSubPage;//聚合二级支付页

- (BOOL)enable;
- (BOOL)isNeedReSigning; //是否需要补签约
- (BOOL)isDisplayCreditPayMetheds;

- (NSDictionary *)toActivityInfoTracker;
- (NSDictionary *)toCombinePayActivityInfoTracker;
- (NSArray *)toActivityInfoTrackerForCreditPay;
- (NSArray *)toActivityInfoTrackerForCreditPay:(NSString *)installment;
- (NSDictionary *)toMethodInfoTracker;
- (NSDictionary *)toSubPayMethodInfoTrackerDic;
- (BOOL)isFromCombinePay;
- (nullable NSDictionary *)getStandardAmountAndVoucher; //return {"pay_amount": amountStr, "pay_voucher": voucherStr}
- (NSString *)bindCardBusinessScene;

@end

// 内部各model数据统一协议
@protocol CJPayDefaultChannelShowConfigBuildProtocol <NSObject>

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig;

@end

// 支付参数生成协议
@protocol CJPayRequestParamsProtocol <NSObject>

- (NSDictionary *)requestNeedParams;

@end

