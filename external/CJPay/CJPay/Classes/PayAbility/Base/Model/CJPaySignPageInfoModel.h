//
//  CJPaySignPageInfoModel.h
//  CJPaySandBox
//
//  Created by ByteDance on 2023/6/30.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayMemAgreementModel;
@interface CJPaySignPageInfoModel : JSONModel

@property (nonatomic, copy) NSString *merchantName;                 // 页面标题
@property (nonatomic, copy) NSString *serviceName;                  // 服务名称
@property (nonatomic, copy) NSString *icon;                         // 商户logo
@property (nonatomic, copy) NSString *serviceDesc;                  // 服务描述
@property (nonatomic, copy) NSString *templateId;                   // 模板ID
@property (nonatomic, copy) NSString *tradeAmount;                  // 订单金额
@property (nonatomic, copy) NSString *realTradeAmount;              // 实付金额
@property (nonatomic, copy) NSString *promotionDesc;                // 营销文案
@property (nonatomic, copy) NSString *nextDeductDate;               // 下次扣款周期
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *protocolInfo;                 // 协议信息
@property (nonatomic, copy) NSDictionary *protocolGroupNames;           // 协议组信息
@property (nonatomic, copy) NSString *paySignSwitch;                 // 是否允许切换到普通支付 none:无开关， open: 有开关，默认打开，close:有开关，默认关闭
@property (nonatomic, copy) NSString *paySignSwitchInfo;            // 切换到普通支付的描述
@property (nonatomic, copy) NSString *deductMethodSubDesc;          // 扣款方式附加描述
@property (nonatomic, copy) NSString *buttonAction;                 // 按钮行为 pay-支付、bind-绑卡
@property (nonatomic, copy) NSString *buttonDesc;                   // 按钮文案 "确认支付"、"支付并开通"

@property (nonatomic, copy) NSString *signPageURL;                  //打开lynx页面的url， 若切到native可以删除

@end

NS_ASSUME_NONNULL_END
