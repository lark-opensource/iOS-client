//
//  CJPayChannelModel.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import <Foundation/Foundation.h>
#import "CJPayDefaultChannelShowConfig.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayChannelInfoModel : JSONModel

@property (nonatomic, copy) NSString *channelData;
@property (nonatomic, copy) NSString *payType;

@end
@protocol CJPayBasicChannel;
@interface CJPayChannelModel : JSONModel

@property (nonatomic,copy)NSString *mark;
@property (nonatomic,copy)NSArray<NSString *> *marks;
@property (nonatomic,copy)NSString *code;
@property (nonatomic,copy)NSString *status;
@property (nonatomic,copy)NSString *msg;//相关描述, 比如不可用原因
@property (nonatomic,copy)NSString *title;
@property (nonatomic,copy)NSString *iconUrl;
@property (nonatomic, copy) NSString *payTypeItemInfo;
@property (nonatomic, strong) CJPayChannelInfoModel *channelInfo; // 端上主动记录的属性
@property (nonatomic, copy) NSString *cjIdentify; //sdk内部使用唯一标示
@property (nonatomic, copy) NSString *identityVerifyWay;
@property (nonatomic, copy) NSString *subTitleColorStr;
@property (nonatomic, copy) NSString *tipsMsg; //一级支付方式功能提示文案
@property (nonatomic, assign) NSInteger signStatus;//签约状态
@property (nonatomic, copy) NSDictionary *retainInfoV2; // lynx挽留弹窗相关配置
@property (nonatomic, assign) NSInteger index;

@end

@interface CJPayChannelModel(Biz)<CJPayDefaultChannelShowConfigBuildProtocol, CJPayRequestParamsProtocol>

@end

NS_ASSUME_NONNULL_END
