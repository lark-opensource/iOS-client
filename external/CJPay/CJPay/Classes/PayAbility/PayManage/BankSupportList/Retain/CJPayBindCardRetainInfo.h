//
//  CJPayBindCardRetainInfo.h
//  Pods
//
//  Created by youerwei on 2021/9/9.
//

#import <JSONModel/JSONModel.h>
#import "CJPayTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardRetainInfo : JSONModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *iconUrls;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSString *creditMsg;
@property (nonatomic, copy) NSString *color;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate;
@property (nonatomic, copy) void(^cancelBlock)(void);
@property (nonatomic, copy) void(^continueBlock)(void);

@property (nonatomic, copy) NSString *controlFrequencyStr; // 1 ：表示控频率 0: 表示不控频率
@property (nonatomic, copy) NSString *buttonMsg; // 单btn文案
@property (nonatomic, copy) NSString *isNeedSaveUserInfo; //是否需要缓存四要素|二要素用户信息
@property (nonatomic, assign) BOOL isHadShowRetain; //标记是否已经展示过挽留弹框，整个绑卡流程中只挽留一次
@property (nonatomic, copy) NSString *cardType; // 卡类型，一键绑卡卡类型页面挽留需要区分卡类型展示不同营销文案

- (UIView *)generateRetainView;

@end

NS_ASSUME_NONNULL_END
