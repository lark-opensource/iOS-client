//
//  CJPayChannelBizModel.h
//  CJPay
//
//  Created by 王新华 on 2019/4/18.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"
#import "CJPayDefaultChannelShowConfig.h"

NS_ASSUME_NONNULL_BEGIN

// 主要用于支付方式列表的数据模型
@interface CJPayChannelBizModel: NSObject

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *discountStr;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *subTitleColorStr;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *channelStr;
@property (nonatomic, copy) NSString *reasonStr;
@property (nonatomic, copy) NSString *rightDiscountStr;
@property (nonatomic, assign) CJPayChannelType type;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *channelConfig;
@property (nonatomic, assign) BOOL isConfirmed;
@property (nonatomic, assign) BOOL hasConfirmBtnWhenUnConfirm;
@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) BOOL hasSub;
@property (nonatomic, assign) BOOL isNoActive;
@property (nonatomic, copy) NSString *limitMsgStr; // 限额信息
@property (nonatomic, copy) NSString *WithDrawMsgStr; // 限额信息
@property (nonatomic, assign) CJPayComeFromSceneType comeFromSceneType;
@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *tipsMsg; //一级支付方式功能提示文案
@property (nonatomic, assign) BOOL isChooseMethodSubPage;
@property (nonatomic, assign) BOOL isLineBreak;
@property (nonatomic, assign) BOOL isDefaultBytePay;
@property (nonatomic, assign) BOOL showCombinePay;
@property (nonatomic, assign) BOOL isCombinePayBackToHomePage; //组合支付是否跳转回首页，默认为NO
@property (nonatomic, assign) BOOL isCombinePay;
@property (nonatomic, assign) CJPayChannelType combineType; //组合支付的类型（零钱或者业务收入）
@property (nonatomic, assign) BOOL isEcommercePay; //是否是电商支付
@property (nonatomic, assign) BOOL isPaymentForOuterApp; //是否外部App拉起收银台支付，默认为 NO
@property (nonatomic, assign) BOOL isIntegerationChooseMethodSubPage;//聚合二级支付页
@property (nonatomic, assign, readonly) BOOL isUnionBindCard; // 是否是云闪付绑卡
@property (nonatomic, assign) BOOL isDYRecommendPayAgain; // 是否是追光二次支付推荐列表
@property (nonatomic, assign) BOOL isFromCombinePay;
@property (nonatomic, copy) NSString *homePageShowStyle;
@property (nonatomic, assign) BOOL useSubPayListVoucherMsg;//二级支付营销是否使用 SubPayListVoucherMsg 中的字段
@property (nonatomic, copy, nullable) NSArray<CJPaySubPayTypeInfoModel *> *subPayTypeData; // 无卡无零钱新人支付卡片
@property (nonatomic, copy) NSString *primaryCombinePayAmount;
@property (nonatomic, assign) BOOL isNeedTopLine;
@property (nonatomic, copy) NSString *selectPageGuideText;

@property (nonatomic, assign) CJPayVoucherMsgType voucherMsgV2Type; //取voucherMsgV2Model属性的具体营销信息
@property (nonatomic, strong) CJPayTypeVoucherMsgV2Model *voucherMsgV2Model; //营销新结构，其余营销结构逐步下线

- (BOOL)isDisplayCreditPayMetheds;

- (NSDictionary *)toMethodInfoTracker;

@end

@interface CJPayDefaultChannelShowConfig(CJPayToBizModel)

- (CJPayChannelBizModel *)toBizModel;

@end

NS_ASSUME_NONNULL_END
