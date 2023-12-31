//
//  CJPayVerifyItemSMS.m
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import "CJPayVerifyItemSMS.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayVerifySMSVCProtocol.h"
#import "CJPayHalfVerifySMSViewController.h"
#import "CJPayVerifySMSViewController.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayRetainUtil.h"
#import "CJPayVerifyCodeTimerLabel.h"
#import "CJPaySettingsManager.h"
#import "CJPayRetainInfoV2Config.h"

@interface CJPayVerifyItemSMS ()

@property (nonatomic, copy) NSString *inputContent;
@property (nonatomic, weak) UIViewController<CJPayVerifySMSVCProtocol> *smsVc;

@end

@implementation CJPayVerifyItemSMS

- (UIViewController<CJPayVerifySMSVCProtocol> *)createVerifySMSVC {
    if (self.verifySMSVC && [self.verifySMSVC.navigationController viewControllers].count > 1) {
        NSMutableArray *vcs = [self.verifySMSVC.navigationController.viewControllers mutableCopy];
        [vcs removeObjectIdenticalTo:self.verifySMSVC];
        self.verifySMSVC.navigationController.viewControllers = [vcs copy];
    }
    
    if ([self shouldUseHalfScreenVC]) {
        self.verifySMSVC = [[CJPayHalfVerifySMSViewController alloc] initWithAnimationType:HalfVCEntranceTypeNone withBizType:CJPayVerifySMSBizTypePay];
        [(CJPayHalfVerifySMSViewController *)self.verifySMSVC showHelpInfo:YES];
    } else {
        self.verifySMSVC = [[CJPayVerifySMSViewController alloc] init];
    }
    self.verifySMSVC.needSendSMSWhenViewDidLoad = YES;
    self.verifySMSVC.trackDelegate = self;
    return self.verifySMSVC;
}

- (CJPayVerifySMSHelpModel *)_buildHelpModel:(CJPayDefaultChannelShowConfig *)defaultConfig {
    CJPayVerifySMSHelpModel *model = [CJPayVerifySMSHelpModel new];
    return model;
}

- (void)_requestVerifyWith:(NSString *)payFlowNo {
    self.payFlowNo = payFlowNo;
    self.smsVc = [self createVerifySMSVC];
    
    CJPayDefaultChannelShowConfig *defaultConfig = self.manager.defaultConfig;
    CJPayVerifySMSHelpModel *model = [self _buildHelpModel:defaultConfig];
    if ([defaultConfig.payChannel isKindOfClass:CJPayQuickPayCardModel.class]
        && [self.smsVc isKindOfClass:CJPayHalfVerifySMSViewController.class]) {
        CJPayQuickPayCardModel *cardModel = (CJPayQuickPayCardModel *)defaultConfig.payChannel;
        CJPayHalfVerifySMSViewController *halfVC = (CJPayHalfVerifySMSViewController *)self.smsVc;
        halfVC.bankCardID = cardModel.bankCardID;
        halfVC.agreements = cardModel.userAgreements;
        model.cardNoMask = cardModel.cardNoMask;
        model.frontBankCodeName = cardModel.frontBankCodeName;
        model.phoneNum = defaultConfig.mobile;
    }
    
    if (Check_ValidString(self.confirmResponse.mobile)) {
        model.phoneNum = self.confirmResponse.mobile;
    } else if(Check_ValidString(self.manager.response.userInfo.mobile)){
        model.phoneNum = self.manager.response.userInfo.mobile;
    } else {
        model.phoneNum = CJString([self.manager.response.tradeConfirmInfo cj_stringValueForKey:@"mobile"]);
    }
    
    if (self.manager.isOneKeyQuickPay) {
        model.cardNoMask = self.manager.response.confirmResponse.cardTailNum;
        model.frontBankCodeName = self.manager.response.confirmResponse.frontBankName;
    }
    
    self.smsVc.defaultConfig = defaultConfig;
    self.smsVc.orderResponse = self.manager.response;
    self.smsVc.helpModel = model;
    @CJWeakify(self)
    [self.smsVc reset];
    self.smsVc.completeBlock = ^(BOOL success, NSString * _Nonnull content) {
        @CJStrongify(self)
        self.inputContent = content;
        [self _verifySMS];
    };
    self.smsVc.cjBackBlock = ^{
        @CJStrongify(self)
        //短验页面增加挽留
        if ([self shouldShowRetainVC]) {
            // 短验取消挽留
        } else {
            [self smsVcCloseAction];
        }
    };
    [self.manager.homePageVC push:self.verifySMSVC animated:YES];
}

- (void)_verifySMS {
    NSMutableDictionary *pwdDic = [NSMutableDictionary new];
    [pwdDic cj_setObject:self.payFlowNo forKey:@"pay_flow_no"];
    [pwdDic cj_setObject:self.inputContent forKey:@"sms"];
    [pwdDic cj_setObject:@"1" forKey:@"req_type"]; // 1表示有验证码
    [pwdDic addEntriesFromDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast]]; // 获取上次的验证数据
    [self.manager submitConfimRequest:pwdDic fromVerifyItem:self];
}

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    self.confirmResponse = response;
    if (self.manager.lastConfirmVerifyItem == self) {
        NSString *eventName = @"wallet_sms_check_halfscreen_result";
        if ([self.verifySMSVC isKindOfClass:CJPayFullPageBaseViewController.class]) {
            eventName = @"wallet_sms_check_fullscreen_result";
        }
        [self event:eventName params:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg)
        }];
    }
        
    if ([response.code isEqual: @"CD002001"]) { // 需要验证短信验证码， 跳转到短信验证码页面
        return YES;
    }

    if ([CJPayBDButtonInfoHandler showErrorTips:response.buttonInfo]) {
        return YES;
    }
    
    [self.verifySMSVC clearInput];
    if ([self.verifySMSVC isKindOfClass:CJPayHalfVerifySMSViewController.class]) {
        [((CJPayHalfVerifySMSViewController *)self.verifySMSVC).timeView reset];
    }
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    if ([response.code isEqual: @"CD002001"]) { // 需要验证短信验证码， 跳转到短信验证码页面
        [self _requestVerifyWith:response.payFlowNo];
        if (self.manager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkipPwd) {
            [CJToast toastText:CJPayLocalizedStr(@"该笔订单无法使用免密支付，请验证后继续付款") inWindow:self.verifySMSVC.cj_window];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [CJToast toastText:CJString(response.msg) inWindow:[UIViewController cj_topViewController].cj_window];
            });
        }
    }
    
    if ([CJPayBDButtonInfoHandler showErrorTips:response.buttonInfo]) {
        [self.verifySMSVC updateTips:response.buttonInfo.page_desc];
    }
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    [self _requestVerifyWith:@""];
}

- (NSDictionary *)getLatestCacheData {
    return @{};
}

- (BOOL)shouldUseHalfScreenVC
{
    UIViewController *topVC = [self.manager.homePageVC topVC];
    NSArray *vcStack = topVC.navigationController.viewControllers;
    BOOL shouldUseHalfScreenVC = YES;
    if (vcStack.count > 0 && [vcStack.lastObject isKindOfClass:CJPayFullPageBaseViewController.class]) {
        shouldUseHalfScreenVC = NO;
    }
    
    return shouldUseHalfScreenVC;
}

- (NSString *)checkTypeName {
    return @"短验";
}

- (BOOL)p_lynxRetain:(CJPayRetainUtilModel *)retainUtilModel {
    retainUtilModel.retainInfoV2Config.fromScene = @"sms_verify";
    @CJWeakify(self)
    retainUtilModel.lynxRetainActionBlock = ^(CJPayLynxRetainEventType eventType, NSDictionary * _Nonnull data) {
        @CJStrongify(self)
        switch (eventType) {
            case CJPayLynxRetainEventTypeOnConfirm:
                break;
            case CJPayLynxRetainEventTypeOnCancelAndLeave: {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self smsVcCloseAction]; // 有可能出现短验页 和 挽留弹窗页同时关闭的时序问题。 所以这里加一个延时关闭
                });
                break;
            }
            default:
                break;
        }
    };
    
    return [CJPayRetainUtil couldShowLynxRetainVCWithSourceVC:[UIViewController cj_topViewController] retainUtilModel:retainUtilModel completion:nil];
}

// 短验取消挽留
- (BOOL)shouldShowRetainVC {
    CJPayRetainUtilModel *retainUtilModel = [self buildRetainUtilModel];
    retainUtilModel.positionType = CJPayRetainVerifyPage;
    // 埋点参数配置
    retainUtilModel.eventNameForPopUpClick = @"wallet_riskcontrol_password_keep_pop_click";
    retainUtilModel.eventNameForPopUpShow = @"wallet_riskcontrol_password_keep_pop_show";
    [retainUtilModel buildTrackEventNormalSetting];
    
    if ([retainUtilModel.retainInfoV2Config isOpenLynxRetain]) {
        return [self p_lynxRetain:retainUtilModel];
    }
    
    CJPayBDRetainInfoModel *retainInfo = self.manager.response.payInfo.retainInfo;
    if (!(retainInfo && retainInfo.needVerifyRetain)) {
        return NO;
    }
    
    //构造挽留弹窗
    @CJWeakify(self);
    retainUtilModel.confirmActionBlock = ^{

    };
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self)
        [self smsVcCloseAction];
    };
    return [CJPayRetainUtil couldShowRetainVCWithSourceVC:[UIViewController cj_topViewController] retainUtilModel:retainUtilModel];
}

- (void)smsVcCloseAction {
    // 由于smsVC有cjBackBlock时内部不会停止计时，因此需要外部主动关闭smsVC的计时器
    @CJWeakify(self)
    if ([self.smsVc isKindOfClass:CJPayHalfVerifySMSViewController.class]) {
        [self.smsVc reset];
        [((CJPayHalfVerifySMSViewController *)self.smsVc) closeWithAnimation:YES comletion:^(BOOL finish) {
            @CJStrongify(self)
            [self smsVCCloseCallBack];
        }];
    } else if ([self.smsVc isKindOfClass:CJPayFullPageBaseViewController.class]) {
        [(CJPayFullPageBaseViewController *)self.smsVc dismissViewControllerAnimated:YES completion:^{
            @CJStrongify(self)
            [self smsVCCloseCallBack];
        }];
    }
}

- (void)smsVCCloseCallBack {
    //子类覆写，电商、标准前置需处理短验页关闭后回调问题
    [self notifyVerifyCancel];
}

@end
