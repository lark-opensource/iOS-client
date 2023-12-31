//
//  CJPayIntegratedChannelModel.h
//  CJPay
//
//  Created by wangxinhua on 2020/9/6.
//

#import "CJPayChannelModel.h"
#import "CJPayBalanceModel.h"
#import "CJPayQuickPayChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayDefaultChannelShowConfig;
@class CJPayUserInfo;
@class CJPaySubPayTypeSumInfoModel;
@class CJPayMerchantInfo;
@class CJPayBDRetainInfoModel;
@protocol CJPaySubPayTypeGroupInfo;
@interface CJPayIntegratedChannelModel : CJPayChannelModel

@property (nonatomic, copy) NSArray<NSString *> *payChannels;
@property (nonatomic, copy) NSString *defaultPayChannel;
@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, copy) NSDictionary *promotionProcessInfo;
@property (nonatomic, strong) CJPaySubPayTypeSumInfoModel *subPayTypeSumInfo;
@property (nonatomic, strong) CJPayMerchantInfo *merchantInfo;
@property (nonatomic, strong) CJPayBDRetainInfoModel *retainInfo;
@property (nonatomic, copy) NSString *homePagePictureUrl;
@property (nonatomic, copy) NSArray<CJPaySubPayTypeGroupInfo> *subPayTypeGroupInfoList; //支付中切卡页的二级支付方式分组信息
@property (nonatomic, copy) NSString *extParamStr; // 透传字段

@end

NS_ASSUME_NONNULL_END
