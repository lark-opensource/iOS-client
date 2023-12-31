//
//  CJPayUnionBindCardCommonModel.h
//  Pods
//
//  Created by wangxiaohong on 2021/10/11.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionPaySignInfo;
@interface CJPayUnionBindCardCommonModel : JSONModel

@property (nonatomic, copy) NSString *promotionTips; // 云闪付绑卡营销信息, 从支付流程选卡列表页传过来
@property (nonatomic, assign) BOOL isShowMask; //云闪付授权页是否展示蒙层
@property (nonatomic, assign) BOOL isAliveCheck; // 用于埋点上报
@property (nonatomic, strong) CJPayUnionPaySignInfo *unionPaySignInfo;
@property (nonatomic, copy) NSString *unionIconUrl;

@end

NS_ASSUME_NONNULL_END
