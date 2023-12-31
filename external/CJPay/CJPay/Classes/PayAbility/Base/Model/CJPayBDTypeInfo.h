//
//  CJPayBDTypeInfo.h
//  CJPay
//
//  Created by wangxiaohong on 2020/3/11.
//

#import <Foundation/Foundation.h>
#import "CJPayQuickPayChannelModel.h"
#import "CJPayBalanceModel.h"
#import <JSONModel/JSONModel.h>
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

//支付信息
@protocol CJPayQuickPayChannelModel;
@protocol CJPayBalanceModel;
@protocol CJPayCreditPayModel;
@protocol CJPaySubPayTypeGroupInfo;

@class CJPaySubPayTypeSumInfoModel;
@class CJPayOutDisplayInfoModel;

@interface CJPayBDTypeInfo : JSONModel

@property (nonatomic, strong) CJPayQuickPayChannelModel *quickPay;
@property (nonatomic, strong) CJPayBalanceModel *balance;
//@property (nonatomic, strong) CJPayCreditPayModel *creditPayModel;
@property (nonatomic, copy) NSArray *payChannels;
@property (nonatomic, copy) NSString *defaultPayChannel;  //默认选中渠道

@property (nonatomic, copy) NSArray *allPayChannels; //按照PayChannels的顺序返回所有的paychannels [内部计算存储]
@property (nonatomic, copy) NSString *payBrand; //支付品牌名称
@property (nonatomic, copy) NSString *homePagePictureUrl; //c2c红包背景图

@property (nonatomic, copy) NSArray<CJPaySubPayTypeGroupInfo> *subPayTypeGroupInfoList; //支付中切卡页的二级支付方式分组信息

@property (nonatomic, strong) CJPaySubPayTypeSumInfoModel *subPayTypeSumInfo; //唤端新追光的所有支付方式从该字段取得
@property (nonatomic, strong) NSArray *allSumInfoPayChannels; //从subPayTypeSumInfo取得所有支付方式（唤端追光使用此字段替代allPayChannels）
@property (nonatomic, strong) CJPayOutDisplayInfoModel *outDisplayInfo; // O项目「签约信息前置」，普通收银台验密页展示代扣信息
- (nullable CJPayDefaultChannelShowConfig *)getDefaultDyPayConfig; // 获取默认支付方式
- (nullable CJPayDefaultChannelShowConfig *)getDefaultBankCardPayConfig;// 获取第一张可用的银行卡，如果没有使用新卡
// 通过渠道字符串获取渠道类型
+ (CJPayChannelType)getChannelTypeBy:(NSString *)channelStr;
// 通过渠道类型获取渠道字符串
+ (NSString *)getChannelStrByChannelType:(CJPayChannelType)channleType
                            isCombinePay:(BOOL)isCombinePay;

- (nullable CJPayDefaultChannelShowConfig *)obtainDefaultConfig;

+ (NSString *)getTrackerMethodByChannelConfig:(CJPayDefaultChannelShowConfig *)channelConfig;

@end

NS_ASSUME_NONNULL_END
