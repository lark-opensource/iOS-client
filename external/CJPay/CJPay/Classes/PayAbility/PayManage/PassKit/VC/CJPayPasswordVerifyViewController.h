//
//  CJPayPasswordVerifyViewController.h
//  Pods
//
//  Created by wangxiaohong on 2021/1/5.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayUserInfo.h"
NS_ASSUME_NONNULL_BEGIN

@class CJPayProcessInfo;

@interface CJPayPassCodeVerifyModel : NSObject

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *smchId;
@property (nonatomic, copy) NSString *mobile; //埋点使用
@property (nonatomic, copy) void (^backBlock)(void);
@property (nonatomic, copy) NSString *source; //埋点使用, 验密来源
@property (nonatomic, copy) NSString *orderNo;//关联单号，用于确认订单已验密
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, assign) BOOL isIndependentBindCard;
@property (nonatomic, assign) BOOL isQuickBindCard; // 埋点使用，是否来源于一件绑卡
@property (nonatomic, strong) CJPayProcessInfo *processInfo;
@property (nonatomic, copy) NSArray *activityInfo;//埋点用
@property (nonatomic, copy) NSDictionary *trackParams;
@property (nonatomic, assign) BOOL isUnionBindCard; //是否是云闪付绑卡,埋点用

@end

typedef void(^CJPayPassCodeVerifyCompletion)(BOOL isSuccess, BOOL isCancel);

@interface CJPayPasswordVerifyViewController : CJPayFullPageBaseViewController

- (instancetype)initWithVerifyModel:(CJPayPassCodeVerifyModel *)verifyModel completion:(CJPayPassCodeVerifyCompletion)completion;

@end

NS_ASSUME_NONNULL_END
