//
//  CJPayTypeInfo.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import <Foundation/Foundation.h>
#import "CJPayIntegratedChannelModel.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayChannelModel;
@class CJPayDeskConfig;
@class CJPayCreditPayChannelModel;
@interface CJPayTypeInfo : JSONModel
@property (nonatomic, strong) CJPayDeskConfig *deskConfig;
@property (nonatomic, strong, readonly, nullable) CJPayIntegratedChannelModel *bdPay;
@property (nonatomic, strong, readonly, nullable) CJPayCreditPayChannelModel *creditPay;
@property (nonatomic, copy) NSArray<CJPayChannelModel> *payChannels;
@property (nonatomic, copy) NSString *defaultPayChannel;  //默认选中渠道
@property (nonatomic, copy) NSArray *sortedPayChannels;  //支付方式排序列表
@property (nonatomic, copy) NSString *paySource;//签约并支付或其他


@property (nonatomic, assign) BOOL isDefaultBytePay;
@property (nonatomic, copy) NSString *isCreditPayAvailable; //判断信用支付是否可用
@property (nonatomic, assign) BOOL isBalanceAvailable; //判断零钱是否可用
@property (nonatomic, copy) NSString *creditPayStageListStr; //可用分期数

// 通过渠道字符串获取渠道类型
+ (CJPayChannelType)getChannelTypeBy:(NSString *)channelStr;
// 通过渠道类型获取渠道字符串
+ (NSString *)getChannelStrByChannelType: (CJPayChannelType)channleType;

+ (NSString *)getTrackerMethodByChannelConfig:(CJPayDefaultChannelShowConfig *)channelConfig;

@end

NS_ASSUME_NONNULL_END
