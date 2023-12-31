//
//  CJPayVerifyItemSkipPwd.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/8.
//

#import "CJPayVerifyItemSkipPwd.h"
#import "CJPaySkipPwdConfirmViewController.h"
#import "CJPaySkipPwdConfirmModel.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPaySafeUtil.h"
#import "CJPayKVContext.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayRetainUtil.h"
#import "CJPaySettingsManager.h"
#import "CJPayRetainInfoV2Config.h"
#import "CJPaySkipPwdConfirmHalfPageViewController.h"

@interface CJPayVerifyItemSkipPwd()

@property (nonatomic, assign) BOOL hideSelected; //记录免密确认页是否勾选了“以后不再提示”或“XX天不再提示”

@end

@implementation CJPayVerifyItemSkipPwd

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    self.hideSelected = [response.secondaryConfirmInfo.checkboxSelectDefault isEqualToString:@"1"];
    self.manager.isSkipConfirmRequest = response.confirmResponse != nil && [response isSkippwdMerged];
    
    if (response.skipNoPwdConfirm) {
        [self p_startConfirmRequestWithExtraParams:nil];
        return;
    }
    switch (response.showNoPwdConfirmPage) {
        case 0:
            [self p_showPopUp:response];
            break;
        case 1:
            [self event:@"wallet_cashier_onesteppswd_pay_page_loading_imp"
                 params:@{@"from" : CJString([self getFromSourceStr])}];
            [self p_startConfirmRequestWithExtraParams:nil];
            break;
        case 2:
            [self p_showlHalfPage:response];
            break;
        default:
            break;
    }
}

- (NSString *)getFromSourceStr {
    return @"收银台";
}

- (void)p_showPopUp:(CJPayBDCreateOrderResponse *)response {
    [[CJPayLoadingManager defaultService] stopLoading];
    CJPaySkipPwdConfirmModel *model = [self p_confirmModel:response];
    CJPaySkipPwdConfirmViewController *skipPwdConfirmVC = [[CJPaySkipPwdConfirmViewController alloc] initWithModel:model];
    self.skipPwdVC = skipPwdConfirmVC;
    [skipPwdConfirmVC presentWithNavigationControllerFrom:[UIViewController cj_topViewController] useMask:YES completion:nil];
}

- (void)p_showlHalfPage:(CJPayBDCreateOrderResponse *)response {
    [[CJPayLoadingManager defaultService] stopLoading];
    CJPaySkipPwdConfirmModel *model = [self p_confirmModel:response];
    CJPaySkipPwdConfirmHalfPageViewController *skipPwdConfirmVC = [[CJPaySkipPwdConfirmHalfPageViewController alloc] initWithModel:model];
    self.skipPwdHalfPageVC = skipPwdConfirmVC;
    skipPwdConfirmVC.animationType = HalfVCEntranceTypeFromBottom;
    [skipPwdConfirmVC presentWithNavigationControllerFrom:[UIViewController cj_topViewController] useMask:YES completion:nil];
}

- (CJPaySkipPwdConfirmModel *)p_confirmModel:(CJPayBDCreateOrderResponse *)response {
    CJPaySkipPwdConfirmModel *model = [CJPaySkipPwdConfirmModel new];
    model.createOrderResponse = self.manager.response;
    model.verifyManager = self.manager;
    model.confirmInfo = self.manager.response.secondaryConfirmInfo;
    
    @CJWeakify(self)
    model.confirmBlock = ^{
        @CJStrongify(self)
        [self confirmButtonClick];
    };
    model.checkboxClickBlock = ^(BOOL isCheckboxSelected) {
        @CJStrongify(self)
        self.hideSelected = isCheckboxSelected;
    };
    
    //免密确认弹窗（旧样式）取消挽留接入营销
    model.backCompletionBlock = ^{
        @CJStrongify(self)
        [self closeButtonClick];
    };
    
    return model;
}

- (BOOL)p_lynxRetain:(CJPayRetainUtilModel *)retainUtilModel {
    retainUtilModel.retainInfoV2Config.fromScene = @"skip_pwd";
    @CJWeakify(self)
    retainUtilModel.lynxRetainActionBlock = ^(CJPayLynxRetainEventType eventType, NSDictionary * _Nonnull data) {
        @CJStrongify(self)
        switch (eventType) {
            case CJPayLynxRetainEventTypeOnConfirm:
                [self onConfirmActionFromPage];
                break;
            case CJPayLynxRetainEventTypeOnCancelAndLeave:
                [self retainCloseButtonClick];
                break;
            case CJPayLynxRetainEventTypeOnOtherVerify: {
                NSDictionary *extraData = [data cj_dictionaryValueForKey:@"extra_data"];
                [self retainOtherVerifyWithWay:CJString([extraData cj_stringValueForKey:@"choice_pwd_check_way"])];
                break;
            }
            default:
                break;
        }
    };
    return [CJPayRetainUtil couldShowLynxRetainVCWithSourceVC:[UIViewController cj_topViewController]
                                              retainUtilModel:retainUtilModel
                                                   completion:nil];
}

- (BOOL)shouldShowRetainVC {
    CJPayRetainUtilModel *retainUtilModel = [self buildRetainUtilModel];
    retainUtilModel.positionType = CJPayRetainSkipPwdPage;
    retainUtilModel.isBonusPath = YES;
    
    if ([retainUtilModel.retainInfoV2Config isOpenLynxRetain]) {
        return [self p_lynxRetain:retainUtilModel];
    }
    
    CJPayBDRetainInfoModel *retainInfo = self.manager.response.payInfo.retainInfo;
    if (!retainInfo) {
        return NO;
    }
    
    // 埋点
    //判断挽留类型（文案挽留、兜底挽留）
    NSString *trackPopType;
    CJPayRetainType retainType = retainUtilModel.retainType;
    if (retainType == CJPayRetainTypeText) {
        trackPopType = retainInfo.showChoicePwdCheckWay ? @"0" : @"1";
    } else {
        trackPopType = retainInfo.showChoicePwdCheckWay ? @"2" : @"3";
    }
    NSString *otherVerifyWay = CJString(retainInfo.choicePwdCheckWay);
    NSString *trackVerifyType = [self getOtherVerifyTypeTrack:otherVerifyWay];
    NSDictionary *trackParam = @{
        @"pop_type": trackPopType,
        @"rec_check_type": CJString(trackVerifyType)
    };
    
    retainUtilModel.eventNameForPopUpClick = @"wallet_cashier_onesteppswd_keep_pop_click";
    retainUtilModel.eventNameForPopUpShow = @"wallet_cashier_onesteppswd_keep_pop_show";
    
    retainUtilModel.extraParamForConfirm = trackParam;
    retainUtilModel.extraParamForOtherVerify = trackParam;
    retainUtilModel.extraParamForClose = trackParam;
    retainUtilModel.extraParamForPopUpShow = trackParam;
    
    self.manager.loadingDelegate = self.manager.homePageVC;
    //构造挽留弹窗
    @CJWeakify(self);
    retainUtilModel.confirmActionBlock = ^{
        @CJStrongify(self)
        [self onConfirmActionFromPage];
    };

    retainUtilModel.otherVerifyActionBlock = ^{
        @CJStrongify(self)
        if (retainInfo.showChoicePwdCheckWay) {
            [self retainOtherVerifyWithWay:otherVerifyWay];
            
        }
    };
    
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self)
        [self retainCloseButtonClick];
    };
    
    retainUtilModel.isUseClearBGColor = YES;
    return [CJPayRetainUtil couldShowRetainVCWithSourceVC:[UIViewController cj_topViewController] retainUtilModel:retainUtilModel completion:^(BOOL success) {
        @CJStrongify(self);
        if (self.skipPwdVC) {
            [self.skipPwdVC removeFromParentViewController];
        }
    }];
}


//点击“确认支付”关闭免密确认弹窗
- (void)closeSkipPwdVC {
    @CJWeakify(self)
    if (self.skipPwdHalfPageVC) {
        [self.skipPwdHalfPageVC closeWithAnimation:YES comletion:^(BOOL isFinish) {
            @CJStrongify(self)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self onConfirmActionFromPage];
            });
        }];
        return;
    }
    
    [self.skipPwdVC dismissSelfWithCompletionBlock:^{
        @CJStrongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onConfirmActionFromPage];
        });
    }];
}

//点击“×”关闭免密确认弹窗
- (void)closeButtonClick {
    if (self.skipPwdHalfPageVC) {
        @CJWeakify(self)
        [self.skipPwdHalfPageVC closeWithAnimation:YES comletion:^(BOOL isFinish) {
            @CJStrongify(self)
            if ([self shouldShowRetainVC]) {
                
            } else {
                [self notifyVerifyCancel];
            }
        }];
        return;
    }
    
    @CJWeakify(self)
    [self.skipPwdVC dismissSelfWithCompletionBlock:^{
        @CJStrongify(self)
        if ([self shouldShowRetainVC]) {
            
        } else {
            [self notifyVerifyCancel];
        }
    }];
}

- (void)confirmButtonClick {
    if (self.skipPwdHalfPageVC) {
        @CJWeakify(self)
        [self.skipPwdHalfPageVC closeWithAnimation:YES comletion:^(BOOL) {
            @CJStrongify(self)
            [self onConfirmActionFromPage];
        }];
        return;
    }
    
    @CJWeakify(self)
    [self.skipPwdVC dismissSelfWithCompletionBlock:^{
        @CJStrongify(self)
        [self onConfirmActionFromPage];
    }];
}

- (void)retainCloseButtonClick {
    [self notifyVerifyCancel];
}

- (void)retainOtherVerifyWithWay:(NSString *)otherVerifyWay {
    self.manager.response.userInfo.pwdCheckWay = otherVerifyWay;
    [CJPayLoadingManager defaultService].isLoadingTitleDowngrade = YES;
    [self.manager wakeSpecificType:[self getOtherVerifyType:otherVerifyWay]
                          orderRes:self.manager.response
                             event:nil];
}

// 免密二次确认页、免密挽留弹窗走确认支付流程，需先判断是否勾选了频控
- (void)onConfirmActionFromPage {

    NSString *skipPwdHideType = self.manager.response.secondaryConfirmInfo.nopwdConfirmHidePeriod;
    // 默认频控类型为”以后不再提示“
    if (!Check_ValidString(skipPwdHideType)) {
        skipPwdHideType = @"INF";
    }
    
    // 上报勾选情况，若是”以后不再提示“类型的频控则本地也记录一份
    NSString *skipPwdHideUpload = self.hideSelected ? skipPwdHideType : @"";
    NSDictionary *params = @{@"no_pwd_confirm_hide_period" : CJString(skipPwdHideUpload)};
    
    [self p_startConfirmRequestWithExtraParams:params];
}

// 确认支付
- (void)p_startConfirmRequestWithExtraParams:(NSDictionary *)extraParams{

    NSMutableDictionary *params = [NSMutableDictionary new];
    if (extraParams != nil) {
        [params addEntriesFromDictionary:extraParams];
    }
    [self.manager submitConfimRequest:[params copy]
                       fromVerifyItem:self];
}

//获取降级验证方式类型
- (CJPayVerifyType)getOtherVerifyType:(NSString *)otherVerifyWay {
    return ([otherVerifyWay isEqualToString:@"1"] || [otherVerifyWay isEqualToString:@"2"]) ? CJPayVerifyTypeBioPayment : CJPayVerifyTypePassword;
}

//获取降级验证方式埋点类型
- (NSString *)getOtherVerifyTypeTrack:(NSString *)otherVerifyWay {
    NSString *verifyTypeTrack = @"";
    if ([otherVerifyWay isEqualToString:@"1"]) {
        verifyTypeTrack = @"指纹";
    } else if ([otherVerifyWay isEqualToString:@"2"]) {
        verifyTypeTrack = @"面容";
    } else {
        verifyTypeTrack = @"密码";
    }
    return verifyTypeTrack;
}

- (NSString *)checkTypeName {
    return @"免密";
}

- (NSString *)checkType {
    return @"3";
}

@end
