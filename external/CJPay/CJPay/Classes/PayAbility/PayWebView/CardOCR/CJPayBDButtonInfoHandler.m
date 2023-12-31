//
//  CJPayBDButtonInfoHandler.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/26.
//

#import "CJPayBDButtonInfoHandler.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayDyTextPopUpViewController.h"
#import "CJPayWebViewService.h"
#import "CJPayAlertUtil.h"
#import "CJPayToast.h"

@implementation CJPayButtonInfoHandlerActionsModel

@end

@interface CJPayBDButtonInfoHandler()

@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate;

@end

@implementation CJPayBDButtonInfoHandler

+ (instancetype)shareInstance {
    static CJPayBDButtonInfoHandler *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayBDButtonInfoHandler alloc] init];
    });
    return manager;
}

+ (BOOL)showErrorTips:(CJPayErrorButtonInfo *)buttonInfo {
    if ([buttonInfo.button_type isEqualToString:@"4"] && Check_ValidString(buttonInfo.page_desc)) {
        return YES;
    }
    return NO;
}

- (BOOL)handleButtonInfo:(CJPayErrorButtonInfo *)buttonInfo
                  fromVC:(UIViewController *)fromVC
                errorMsg:(NSString *)msg
             withActions:(CJPayButtonInfoHandlerActionsModel *)actionsModel
           trackDelegate:(nullable id<CJPayTrackerProtocol>)trackDelegate
               withAppID:(NSString *)appID
              merchantID:(NSString *)merchantID {
    self.trackDelegate = trackDelegate;
    return [self handleButtonInfo:buttonInfo
                           fromVC:fromVC
                         errorMsg:msg
                      withActions:actionsModel
                        withAppID:appID
                       merchantID:merchantID];
}

- (BOOL)handleButtonInfo:(CJPayErrorButtonInfo *)buttonInfo
                  fromVC:(UIViewController *)fromVC
                errorMsg:(NSString *)msg
             withActions:(CJPayButtonInfoHandlerActionsModel *)actionsModel
               withAppID:(NSString *)appID
              merchantID:(NSString *)merchantID {
    __block BOOL isHandled = NO;
    
    [self handleButtonInfo:buttonInfo fromVC:fromVC 
                  errorMsg:msg
               withActions:actionsModel
                 withAppID:appID
                merchantID:merchantID
           alertCompletion:^(UIViewController * _Nullable alertVC, BOOL handled) {
        isHandled = handled;
        if (!alertVC) {
            return;
        }
        
        // 弹窗展现前 上报埋点
        CJ_CALL_BLOCK(actionsModel.alertPresentAction);
    }];
    
    return isHandled;
}

- (void)handleButtonInfo:(CJPayErrorButtonInfo *)buttonInfo
                  fromVC:(UIViewController *)fromVC
                errorMsg:(NSString *)msg
             withActions:(CJPayButtonInfoHandlerActionsModel *)actionsModel
               withAppID:(NSString *)appID
              merchantID:(NSString *)merchantID
         alertCompletion:(void (^)(UIViewController * _Nullable alertVC, BOOL handled))alertCompletion {
    @CJWeakify(self)
    
    buttonInfo.appID = appID;
    buttonInfo.merchantID = merchantID;

    if ([buttonInfo.button_type isEqualToString:@"4"]) {
        if (!Check_ValidString(buttonInfo.page_desc)) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:fromVC.cj_window];
            CJ_CALL_BLOCK(alertCompletion, nil ,YES);
            return;
        }
        
        if (actionsModel.errorInPageAction) {
            actionsModel.errorInPageAction(buttonInfo.page_desc);
        } else {
            [CJToast toastText:buttonInfo.page_desc inWindow:fromVC.cj_window];
        }
        CJ_CALL_BLOCK(alertCompletion, nil ,YES);
        return;
    }

    UIViewController *alertController;

    //带主标题的新弹窗双按钮样式
    if (Check_ValidString(buttonInfo.mainTitle)) {
        buttonInfo.left_button_desc = CJPayLocalizedStr(@"知道了");
        buttonInfo.right_button_desc = CJPayLocalizedStr(@"去绑其他卡");
        buttonInfo.left_button_action = @4;
        buttonInfo.right_button_action = @8;
        CJPayDyTextPopUpModel *model = [CJPayDyTextPopUpModel new];
        model.title = buttonInfo.mainTitle;
        model.content = buttonInfo.page_desc;
        model.mainOperation = buttonInfo.right_button_desc;
        model.secondOperation = buttonInfo.left_button_desc;
        model.secondOperationColor = [UIColor cj_161823WithAlpha:0.75];
        model.type = CJPayTextPopUpTypeHorizontal;
        alertController = [[CJPayDyTextPopUpViewController alloc] initWithPopUpModel:model];
        @CJWeakify(self)
        @CJWeakify(alertController);
        model.didClickMainOperationBlock = ^{
            @CJStrongify(self)
            @CJStrongify(alertController)
            [self execActionWithActionNum:buttonInfo.right_button_action
                               buttonInfo:buttonInfo
                              withActions:actionsModel
                                   fromVC:fromVC
                                  alertVC:alertController];
        };
        model.didClickSecondOperationBlock = ^{
            @CJStrongify(self)
            @CJStrongify(alertController)
            [self execActionWithActionNum:buttonInfo.left_button_action
                               buttonInfo:buttonInfo
                              withActions:actionsModel
                                   fromVC:fromVC
                                  alertVC:alertController];
        };
        [self p_presentAlertVC:alertController fromVC:fromVC];
        
    } else if ([buttonInfo.button_type isEqualToString:@"2"]) {
        // 双按钮
        alertController = [CJPayAlertUtil customDoubleAlertWithTitle:CJString(buttonInfo.page_desc)
                                                             content:@""
                                                      leftButtonDesc:CJString(buttonInfo.left_button_desc)
                                                     rightButtonDesc:CJString(buttonInfo.right_button_desc)
                                                     leftActionBlock:^{
            @CJStrongify(self)
            [self p_trackerEvent:@"wallet_alert_pop_click" buttonInfo:buttonInfo params:@{
                @"button_name": CJString(buttonInfo.left_button_desc)
            }];
            [self execActionWithActionNum:buttonInfo.left_button_action
                               buttonInfo:buttonInfo
                              withActions:actionsModel
                                   fromVC:fromVC
                                  alertVC:alertController];
        }
                                                     rightActioBlock:^{
            @CJStrongify(self)
            [self p_trackerEvent:@"wallet_alert_pop_click" buttonInfo:buttonInfo params:@{
                @"button_name": CJString(buttonInfo.right_button_desc)
            }];
            [self execActionWithActionNum:buttonInfo.right_button_action
                               buttonInfo:buttonInfo
                              withActions:actionsModel
                                   fromVC:fromVC
                                  alertVC:alertController];
        } useVC:fromVC];
    } else if ([buttonInfo.button_type isEqualToString:@"3"]) {
        // 单按钮
        alertController = [CJPayAlertUtil customSingleAlertWithTitle:CJString(buttonInfo.page_desc)
                                           content:@""
                                        buttonDesc:CJString(buttonInfo.button_desc)
                                       actionBlock:^{
            @CJStrongify(self)
            [self p_trackerEvent:@"wallet_alert_pop_click" buttonInfo:buttonInfo params:@{
                @"button_name": CJString(buttonInfo.button_desc)
            }];
            [self execActionWithActionNum:buttonInfo.action
                               buttonInfo:buttonInfo
                              withActions:actionsModel
                                   fromVC:fromVC
                                  alertVC:alertController];
        }
                                             useVC:fromVC];
    }

    if (alertController) {
        CJ_CALL_BLOCK(alertCompletion, alertController, YES);
        
        [self p_trackIMServiceWithEvent:@"wallet_im_service_pop_imp" buttonInfo:buttonInfo params:nil];
        
        return;
    } else if (Check_ValidString(msg)) {
        [CJToast toastText:msg inWindow:fromVC.cj_window];
    } else {
        [CJToast toastText:CJPayNoNetworkMessage inWindow:fromVC.cj_window];
    }

    CJ_CALL_BLOCK(alertCompletion, nil, NO);
}

- (void)execActionWithActionNum:(NSNumber *)actionNum
                     buttonInfo:(CJPayErrorButtonInfo *)buttonInfo
                    withActions:(CJPayButtonInfoHandlerActionsModel *)actionsModel
                         fromVC:(nullable UIViewController *)fromVC
                        alertVC:(nullable UIViewController *)alertVC {
    
    UIViewController *sourceVC = nil;
    
    switch ([actionNum integerValue]) {
        case CJPayButtonInfoHandlerTypeClosePayDesk:
            [self p_closeAlertVC:alertVC action:actionsModel.closePayDeskAction];
            break;
        case CJPayButtonInfoHandlerTypeBackToPayHomePage:
            [self p_closeAlertVC:alertVC action:actionsModel.backToPayHomePageAction];
            break;
        case CJPayButtonInfoHandlerTypeChangeCard:
            [self p_closeAlertVC:alertVC action:actionsModel.changeCardAction];
            break;
        case CJPayButtonInfoHandlerTypeCloseAlert:
            [self p_closeAlertVC:alertVC action:actionsModel.closeAlertAction];
            break;
        case CJPayButtonInfoHandlerTypeBack:
            [self p_closeAlertVC:alertVC action:actionsModel.backAction];
            break;
        case CJPayButtonInfoHandlerTypeFindPwd:
            if (alertVC && [alertVC isKindOfClass:CJPayDyTextPopUpViewController.class]) {
                CJPayDyTextPopUpViewController *popUpVC = (CJPayDyTextPopUpViewController *)alertVC;
                [popUpVC dismissSelfWithCompletionBlock:^{
                    CJ_CALL_BLOCK(actionsModel.findPwdAction, buttonInfo.findPwdUrl);
                }];
            } else {
                CJ_CALL_BLOCK(actionsModel.findPwdAction, buttonInfo.findPwdUrl);
            }
            break;
        case CJPayButtonInfoHandlerTypeMobileUpdate:
            [self p_closeAlertVC:alertVC action:actionsModel.mobileUpdateAction];
            break;
        case CJPayButtonInfoHandlerTypeBindCard:
            [self p_closeAlertVC:alertVC action:actionsModel.bindCardAction];
            break;
        case CJPayButtonInfoHandlerTypeCardList:
            [self p_closeAlertVC:alertVC action:actionsModel.cardListAction];
            break;
        case CJPayButtonInfoHandlerTypeUploadIDCard:
            [self p_closeAlertVC:alertVC action:actionsModel.uploadIDCardAction];
            break;
        case CJPayButtonInfoHandlerContinuePaying:
            [self p_closeAlertVC:alertVC action:actionsModel.continuePayingAction];
            break;
        case CJPayButtonInfoHandlerTypeLogoutBizRealName:
            [self p_closeAlertVC:alertVC action:actionsModel.logoutBizRealNameAction];
            break;
        case CJPayButtonInfoHandlerTypeIMService:
            [self p_trackIMServiceWithEvent:@"wallet_im_service_pop_click" buttonInfo:buttonInfo params:@{
                @"button_name": CJString(buttonInfo.right_button_desc)
            }];
            if (alertVC && [alertVC isKindOfClass:CJPayDyTextPopUpViewController.class]) {
                sourceVC = alertVC;
            } else {
                sourceVC = fromVC;
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService) i_gotoIMServiceWithAppID:buttonInfo.appID fromVC:sourceVC];
            break;
        default:
            break;
    }
}

- (void)p_presentAlertVC:(UIViewController *)alertVC fromVC:(UIViewController *)fromVC {
    
    if (!alertVC || !fromVC || ![alertVC isKindOfClass:UIViewController.class] || ![fromVC isKindOfClass:UIViewController.class]) {
        return;
    }
    
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:fromVC];
    if (![alertVC isKindOfClass:UIAlertController.class] &&
        !CJ_Pad &&
        topVC.navigationController && [topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        [topVC.navigationController pushViewController:alertVC animated:YES];
    } else {
        alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [topVC presentViewController:alertVC animated:YES completion:^{}];
    }
}

- (void)p_closeAlertVC:(UIViewController *)vc action:(CJPayButtonInfoAction)actionBlock {
    if (vc && [vc respondsToSelector:@selector(dismissSelfWithCompletionBlock:)]) {
        [vc performSelector:@selector(dismissSelfWithCompletionBlock:) withObject:actionBlock];
    } else {
        // 系统弹窗会自动关闭
        CJ_CALL_BLOCK(actionBlock);
    }
}

+ (NSString *)findPwdUrlWithAppID:(NSString *)appID merchantID:(NSString *)merchantID smchID:(NSString *)smchID {
    return [NSString stringWithFormat:
        @"%@/usercenter/setpass/guide?merchant_id=%@&app_id=%@&service=21&smch_id=%@",
            CJString([CJPayBaseRequest bdpayH5DeskServerHostString]),
            CJString(merchantID),
            CJString(appID),
            CJString(smchID)
    ];
}

- (void)p_trackerEvent:(NSString *)event buttonInfo:(CJPayErrorButtonInfo *)buttonInfo params:(NSDictionary *)params {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict addEntriesFromDictionary:params];
    [dict cj_setObject:buttonInfo.button_type forKey:@"button_type"];
    [dict cj_setObject:buttonInfo.page_desc forKey:@"title"];
    if ([self.trackDelegate conformsToProtocol:@protocol(CJPayTrackerProtocol)]) {
        [self.trackDelegate event:CJString(event) params:[dict copy]];
    } else {
        [CJTracker event:CJString(event) params:[dict copy]];
    }
}

- (void)p_trackIMServiceWithEvent:(NSString *)event buttonInfo:(CJPayErrorButtonInfo *)buttonInfo params:(NSDictionary *)params {
    
    if ([buttonInfo.left_button_action integerValue] != CJPayButtonInfoHandlerTypeIMService && [buttonInfo.right_button_action integerValue] != CJPayButtonInfoHandlerTypeIMService) {
        return;
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic cj_setObject:CJString(buttonInfo.appID) forKey:@"app_id"];
    [dic cj_setObject:CJString(buttonInfo.merchantID) forKey:@"merchant_id"];
    [dic cj_setObject:CJString(buttonInfo.trackCase) forKey:@"case"];
    [dic cj_setObject:CJString(buttonInfo.code) forKey:@"error_code"];
    [dic cj_setObject:CJString(buttonInfo.page_desc) forKey:@"error_message"];
    [dic cj_setObject:@"1" forKey:@"is_chaselight"];
    
    if (params) {
        [dic addEntriesFromDictionary:params];
    }
    
    [CJTracker event:CJString(event) params:[dic copy]];
}

@end
