//
//  CJPayBDButtonInfoHandler.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/26.
//

#import <Foundation/Foundation.h>
#import "CJPayErrorButtonInfo.h"
#import "CJPayTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^CJPayButtonInfoAction)(void);

typedef void (^CJPayFindPwdAction)(NSString *pwd);

typedef void (^BDPayErrorInPageAction)(NSString *errorText);

typedef NS_ENUM(NSUInteger, CJPayButtonInfoHandlerType) {
    CJPayButtonInfoHandlerTypeClosePayDesk = 1, //关闭收银台
    CJPayButtonInfoHandlerTypeBackToPayHomePage, //回到收银台首页
    CJPayButtonInfoHandlerTypeChangeCard, // 使用其他卡(目前用于银行卡余额不足场景，点击关闭收银台，给业务方银行卡余额不足状态码回调)
    CJPayButtonInfoHandlerTypeCloseAlert, // 关闭当前弹框，停留在当前页面
    CJPayButtonInfoHandlerTypeBack, // 返回前一个页面
    CJPayButtonInfoHandlerTypeFindPwd, // 跳转找回密码
    CJPayButtonInfoHandlerTypeMobileUpdate, // 补签约更新卡信息
    CJPayButtonInfoHandlerTypeBindCard, // 跳转重新绑卡流程
    CJPayButtonInfoHandlerTypeCardList, // 跳转卡列表
    CJPayButtonInfoHandlerTypeUploadIDCard,
    CJPayButtonInfoHandlerContinuePaying,
    CJPayButtonInfoHandlerTypeLogoutBizRealName, // 注销业务方实名信息
    CJPayButtonInfoHandlerTypeIMService, // 跳转IM客服，跳转逻辑在handler内部处理
};

@interface CJPayButtonInfoHandlerActionsModel : NSObject

@property (nonatomic, copy) CJPayButtonInfoAction closePayDeskAction;
@property (nonatomic, copy) CJPayButtonInfoAction backToPayHomePageAction;
@property (nonatomic, copy) CJPayButtonInfoAction changeCardAction;
@property (nonatomic, copy) CJPayButtonInfoAction closeAlertAction;
@property (nonatomic, copy) CJPayButtonInfoAction backAction;
@property (nonatomic, copy) CJPayFindPwdAction findPwdAction;
@property (nonatomic, copy) CJPayButtonInfoAction mobileUpdateAction;
@property (nonatomic, copy) CJPayButtonInfoAction bindCardAction;
@property (nonatomic, copy) CJPayButtonInfoAction cardListAction;
@property (nonatomic, copy) CJPayButtonInfoAction uploadIDCardAction;
@property (nonatomic, copy) BDPayErrorInPageAction errorInPageAction;
@property (nonatomic, copy) CJPayButtonInfoAction continuePayingAction;
@property (nonatomic, copy) CJPayButtonInfoAction logoutBizRealNameAction;
@property (nonatomic, copy) CJPayButtonInfoAction alertPresentAction;

@end


@interface CJPayBDButtonInfoHandler : NSObject

+ (instancetype)shareInstance;

+ (BOOL)showErrorTips:(CJPayErrorButtonInfo *)buttonInfo;

+ (NSString *)findPwdUrlWithAppID:(NSString *)appID merchantID:(NSString *)merchantID smchID:(NSString *)smchID;

- (void)handleButtonInfo:(CJPayErrorButtonInfo *)buttonInfo
                  fromVC:(UIViewController *)fromVC
                errorMsg:(NSString *)msg
             withActions:(CJPayButtonInfoHandlerActionsModel *)actionsModel
               withAppID:(NSString *)appID
              merchantID:(NSString *)merchantID
         alertCompletion:(void (^)(UIViewController * _Nullable alertVC, BOOL handled))alertCompletion;

- (BOOL)handleButtonInfo:(CJPayErrorButtonInfo *)buttonInfo
                  fromVC:(UIViewController *)fromVC
                errorMsg:(NSString *)msg
             withActions:(CJPayButtonInfoHandlerActionsModel *)actionsModel
               withAppID:(NSString *)appID
              merchantID:(NSString *)merchantID;

- (BOOL)handleButtonInfo:(CJPayErrorButtonInfo *)buttonInfo
                  fromVC:(UIViewController *)fromVC
                errorMsg:(NSString *)msg
             withActions:(CJPayButtonInfoHandlerActionsModel *)actionsModel
           trackDelegate:(nullable id<CJPayTrackerProtocol>)trackDelegate
               withAppID:(NSString *)appID
              merchantID:(NSString *)merchantID;

@end

NS_ASSUME_NONNULL_END
