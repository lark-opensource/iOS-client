//
//  CJPayBDTradeInfo.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/20.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

typedef NS_ENUM(NSInteger, CJBDPayWithdrawTradeStatus) {
    CJBDPayWithdrawTradeStatusUnknown = -1,
    CJBDPayWithdrawTradeStatusInit,
    CJBDPayWithdrawTradeStatusSuccess,
    CJBDPayWithdrawTradeStatusFail,
    CJBDPayWithdrawTradeStatusReviewing,
    CJBDPayWithdrawTradeStatusProcessing,
    CJBDPayWithdrawTradeStatusClosed,
    CJBDPayWithdrawTradeStatusTimeout,
    CJBDPayWithdrawTradeStatusReexchange,
};

@protocol CJPayCombinePayFund;//交易相关数据
@interface CJPayBDTradeInfo : JSONModel

@property(nonatomic, copy) NSString *createTime;
@property(nonatomic, copy) NSString *expirationTime;
@property(nonatomic, copy) NSString *outTradeNo;
@property(nonatomic, copy) NSString *returnUrl;
@property(nonatomic, assign) NSInteger tradeAmount;
@property(nonatomic, copy) NSString *tradeDesc;
@property(nonatomic, copy) NSString *tradeName;
@property(nonatomic, copy) NSString *tradeNo;
@property(nonatomic, copy) NSString *tradeStatusString;
@property(nonatomic, copy) NSString *tradeTime;
@property(nonatomic, copy) NSString *amountCanChange;
@property(nonatomic, copy) NSString *tradeType;
@property(nonatomic, copy) NSString *productID;
@property(nonatomic, copy) NSString *tradeDescMessage;
@property (nonatomic, copy) NSString *bankCodeMask;         //银行卡掩码
@property (nonatomic, copy) NSString *bankName;             //银行名称
@property (nonatomic, copy) NSString *failMsg;              //对于交易失败的, 交易失败详情
@property (nonatomic, copy) NSString *expectedTime;         //预计到账时间
@property (nonatomic, copy) NSString *iconUrl;              //icon url
@property (nonatomic, copy) NSString *rechargeType;         //充值方式
@property (nonatomic, copy) NSString *serviceFee;           //服务费
@property (nonatomic, copy) NSString *remark;
@property (nonatomic, copy) NSString *tradeInfoType;//订单类型, withdraw, recharge, pay. 取值为withdraw时表示withdraw_trade_info有效。取值为recharge,表示recharge_trade_info有效
@property (nonatomic, copy) NSString *finishTime;
@property (nonatomic, copy) NSString *withdrawType;
@property(nonatomic, assign) NSInteger payAmount;
@property (nonatomic, assign, readonly) BOOL isFailed;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *merchantID;
@property (nonatomic, copy) NSString *cardType;
//组合支付支付组成
@property (nonatomic, copy) NSString *payType;
@property (nonatomic, copy) NSArray <CJPayCombinePayFund> *combinePayFundList;
//结果页抖音月付分期描述信息
@property (nonatomic, copy) NSString *creditPayInstallmentDesc;
//结果页支付营销信息（目前仅唤端追光结果页使用）
@property (nonatomic, copy, nullable) NSString *discountDesc;
+ (CJBDPayWithdrawTradeStatus)statusFromString:(NSString *)string;

@property (nonatomic, assign) NSInteger reduceAmount;  //券金额, 单位, 分
@property (nonatomic, assign) BOOL isTradeCreateAgain; //非首次支付,如余额不足后二次支付

- (NSString *)formattedCreateTime;

@end

