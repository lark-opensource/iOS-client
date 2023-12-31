//
//  CJPaySubPayTypeInfoModel.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/12.
//

#import "CJPayChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySubPayTypeData;
@class CJPayDefaultChannelShowConfig;
@interface CJPaySubPayTypeInfoModel : CJPayChannelModel

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy) NSString *subPayType;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *descTitle; //支付方式描述信息，用于展示背书信息，可以和sub_title同时存在
@property (nonatomic, assign) NSInteger way;
@property (nonatomic, assign) BOOL isChoosed;
@property (nonatomic, copy) NSString *homePageShow;
@property (nonatomic, strong) CJPaySubPayTypeData *payTypeData;

@property (nonatomic, weak) CJPayDefaultChannelShowConfig *currentShowConfig;
// 组合支付具体类型
@property (nonatomic, assign, readonly, getter=channelType) CJPayChannelType channelType;

@property (nonatomic, assign, readonly) BOOL isCombinePay;
@property (nonatomic, copy) NSString *tradeConfirmButtonText; //支付方式对应的确认支付按钮文案
@property (nonatomic, copy) NSString *extParamStr; // 透传字段

- (NSString *)businessSceneString;

@end

NS_ASSUME_NONNULL_END
