//
//  CJPayPassCodeSetBaseViewController.h
//  Pods
//
//  Created by wangxiaohong on 2021/1/7.
//

#import "CJPayFullPageBaseViewController.h"

#import "CJPayMemBankInfoModel.h"
#import "CJPayPasswordView.h"
#import "CJPayBindCardRetainInfo.h"
#import "CJPayBindCardPageBaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayProcessInfo;

@interface CJPayPassCodeSetBaseViewModel: CJPayBindCardPageBaseModel

@property (nonatomic, strong) CJPayBindCardRetainInfo *retainInfo;
@property (nonatomic, assign) BOOL isHadShowRetain;

@end

@interface CJPayPasswordSetModel : NSObject

@property (nonatomic, copy, nullable) NSString *password;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *merchantID;
@property (nonatomic, copy) void (^backCompletion)(void);
@property (nonatomic, copy) void (^backFirstStepCompletion)(NSString *);
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *smchID;
@property (nonatomic, assign) BOOL isNeedCardInfo;
@property (nonatomic, copy) NSString *mobile; //埋点使用
@property (nonatomic, strong) CJPayMemBankInfoModel *bankCardInfo;
@property (nonatomic, strong) CJPayProcessInfo *processInfo;
@property (nonatomic, assign) BOOL isSetAndPay; //是否为设置密码并支付
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *source; //设密来源，埋点使用

@property (nonatomic, copy) NSArray *activityInfos;//埋点用
@property (nonatomic, assign) BOOL isUnionBindCard; //是否是云闪付绑卡，埋点用

@end

typedef void(^BDPayPassCodeSetCompletion)(NSString * _Nullable token, BOOL isSuccess, BOOL isExit);

@class CJPayButtonInfoHandlerActionsModel;
@class CJPaySettingPasswordResponse;

@interface CJPayPassCodeSetBaseViewController : CJPayFullPageBaseViewController <CJPayBindCardPageProtocol>

@property (nonatomic, strong) CJPayPasswordSetModel *setModel;
@property (nonatomic, copy) BDPayPassCodeSetCompletion completion;
@property (nonatomic, strong) CJPayPassCodeSetBaseViewModel *viewModel;

@property (nonatomic, strong, readonly) CJPayPasswordView *passwordView;
- (void)updateWithPassCodeType:(CJPayPassCodeType)type;
- (void)clearInputContent;
- (void)clearErrorText;
- (void)showErrorText:(NSString *)text;
- (UIView <CJPayBaseLoadingProtocol> *)getLoadingView;
- (CJPayButtonInfoHandlerActionsModel *)buttonInfoActions:(CJPaySettingPasswordResponse *)response;

- (void)trackerEventName:(NSString *)name params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
