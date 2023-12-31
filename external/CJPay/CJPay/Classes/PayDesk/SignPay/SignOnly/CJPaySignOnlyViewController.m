//
//  CJPaySignOnlyViewController.m
//  Pods
//
//  Created by wangxiaohong on 2022/9/9.
//

#import "CJPaySignOnlyViewController.h"

#import "CJPaySignView.h"
#import "CJPayUIMacro.h"
#import "CJPayOuterPayUtil.h"
#import "CJPayAlertController.h"
#import "CJPayAlertUtil.h"
#import "CJPayStyleButton.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayRequestParam.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPaySignPayQuerySignInfoResponse.h"
#import "CJPayUserInfo.h"
#import "CJPaySignQueryMemberPayListRequest.h"
#import "CJPaySignQueryMemberPayListResponse.h"
#import "CJPaySignCardListViewController.h"
#import "CJPaySignSetMemberFirstPayTypeRequest.h"
#import "CJPaySignSetMemberFirstPayTypeResponse.h"
#import "CJPayExceptionViewController.h"
#import "CJPaySignOnlyQuerySignTemplateRequest.h"
#import "CJPaySignOnlyQuerySignTemplateResponse.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayMemVerifyManager.h"
#import "CJPaySignOnlyBindBytePayAccountRequest.h"
#import "CJPaySignOnlyBindBytePayAccountResponse.h"
#import "CJPayHalfVerifyPasswordNormalViewController.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPaySignOnlyResultPageViewController.h"
#import "CJPaySignDYPayModule.h"
#import "CJPayPasswordLockPopUpViewController.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPaySafeUtil.h"
#import "CJPayDeskUtil.h"
#import "CJPaySettingsManager.h"
#import "CJPayKVContext.h"

@interface CJPaySignOnlyViewController ()

@property (nonatomic, strong) CJPaySignView *contentView;
@property (nonatomic, strong) CJPayMemVerifyManager *memVerifyManager;
@property (nonatomic, assign) BOOL isHadShowRetain; //是否展示过挽留弹框
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *selectedShowConfig;

@end

@implementation CJPaySignOnlyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_trackForPage:@"wallet_withhold_open_page_imp" params:@{}];
}

- (void)back {
    [self p_trackForPage:@"wallet_withhold_open_back_click" params:@{}];
    [self p_closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeCancel];
}

- (void)p_setupUI {
    [self.view addSubview:self.contentView];
    
    [self.navigationBar setTitle:CJString(self.querySignInfo.signTemplateInfo.pageTitle)];
    
    CJPayMasMaker(self.contentView, {
        make.top.equalTo(self.view).offset([self navigationHeight]);
        make.left.right.bottom.equalTo(self.view);
    });
    [self.contentView updateWithSignModel:[self.querySignInfo toSignModel]];
}

- (void)p_onConfirmPayAction {
    if ([self p_isNeedGoLynxBind]) {
        [self p_openLynxBindCardAndSign];
    } else if (self.querySignInfo.hasBankCard) {
        [self p_sign];
    } else {
        [self p_bindCard];
    }
}

- (CJPayVerifyType)p_verifyType {
    if ([self.querySignInfo.verifyType isEqualToString:@"password"]) {
        return CJPayVerifyTypePassword;
    }
    return CJPayVerifyTypePassword;
}

- (void)p_showRetainWithVC:(CJPayHalfVerifyPasswordNormalViewController *)passwordVC {
    if (!self.isHadShowRetain) {
        self.isHadShowRetain = YES;
        [CJPayAlertUtil doubleAlertWithTitle:CJPayLocalizedStr(@"是否放弃开通自动扣款")
                                     content:nil
                              leftButtonDesc:CJPayLocalizedStr(@"放弃")
                             rightButtonDesc:CJPayLocalizedStr(@"继续开通")
                             leftActionBlock:^{
            [passwordVC closeWithAnimation:YES comletion:^(BOOL isSuccess) {
                [self p_closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeCancel];
            }];
        } rightActioBlock:^{
        } useVC:passwordVC];
    } else {
        [passwordVC closeWithAnimated:YES];
    }
}

- (void)p_bindBytePayAccountWithVC:(CJPayHalfVerifyPasswordNormalViewController *)passwordVC resultModel:(CJPayMemVerifyResultModel *)resultModel {
    NSMutableDictionary *params = [[self p_baseRequestParams] mutableCopy];
    [params cj_setObject:CJString(self.querySignInfo.verifyType) forKey:@"verify_type"];
    [params addEntriesFromDictionary:resultModel.paramsDict];
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:CJPayLocalizedStr(@"输入抖音支付密码")];
    [CJPaySignOnlyBindBytePayAccountRequest startWithBizParams:[params copy] completion:^(NSError * _Nonnull error, CJPaySignOnlyBindBytePayAccountResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if ([response isSuccess]) {
            [self p_gotoResultPageWithResponse:response fromVC:passwordVC];
            return;
        }
        if ([response.code isEqualToString:@"MP020403"]) { //密码错误
            [passwordVC.viewModel.inputPasswordView clearInput];
            NSString *tipsText = response.msg;
            if (response.remainRetryCount != 0) {
                tipsText = [NSString stringWithFormat:@"支付密码错误，还有%d次机会", response.remainRetryCount];
            }
            [passwordVC.viewModel updateErrorText:tipsText withTypeString:@"" currentVC:passwordVC];
            return;
        } else if ([response.code isEqualToString:@"MP020407"] || [response.code isEqualToString:@"MP020404"]) { //密码错误5次被锁定 | 密码锁定保护中
            [self p_gotoPwdLockVCWithResponse:response passwordVC:passwordVC];
            return;
        } else {
            [passwordVC.viewModel reset];
            NSString *errorMsg = Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage;
            [CJToast toastText:errorMsg inWindow:self.cj_window];
        }
    }];
}

- (NSDictionary *)p_baseRequestParams {
    return @{
        @"app_id": CJString(self.zg_app_id),
        @"merchant_id": CJString(self.zg_merchant_id),
        @"member_biz_order_no": CJString(self.tradeNo)
    };
}

- (void)p_sign {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params addEntriesFromDictionary:[self p_baseRequestParams]];
    [params addEntriesFromDictionary:@{
        @"track_info": @{@"cashier_style": @"2"}
    }];
    
    @CJWeakify(self)
    [self.memVerifyManager beginMemVerifyWithType:[self p_verifyType] params:[params copy] fromVC:self completion:^(CJPayMemVerifyResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        if (![resultModel.verifyVC isKindOfClass:CJPayHalfVerifyPasswordNormalViewController.class]) {
            CJPayLogError(@"页面类型异常：%@", resultModel.verifyVC);
            return;
        }
        
        CJPayHalfVerifyPasswordNormalViewController *passwordVC = (CJPayHalfVerifyPasswordNormalViewController *)resultModel.verifyVC;
        if (resultModel.resultType == CJPayMemVerifyResultTypeCancel) {
            [self p_showRetainWithVC:passwordVC];
            return;
        }
        [self p_bindBytePayAccountWithVC:passwordVC resultModel:resultModel];
    }];
}

- (void)p_signWithNoPwd {
    [self p_requestQuerySignInfo]; // 刷新首页UI
    NSMutableDictionary *requestParams = [[self p_baseRequestParams] mutableCopy];
    [requestParams cj_setObject:CJString(self.querySignInfo.verifyType) forKey:@"verify_type"];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    [CJPaySignOnlyBindBytePayAccountRequest startWithBizParams:[requestParams copy] completion:^(NSError * _Nonnull error, CJPaySignOnlyBindBytePayAccountResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if ([response isSuccess]) {
            [self p_gotoResultPageWithResponse:response fromVC:nil];
            return;
        }
        NSString *errorMsg = Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage;
        [CJToast toastText:errorMsg inWindow:self.cj_window];
    }];
}

- (void)p_gotoPwdLockVCWithResponse:(CJPaySignOnlyBindBytePayAccountResponse *)response passwordVC:(CJPayHalfVerifyPasswordNormalViewController *)passwordVC {
    CJPayErrorButtonInfo *buttonInfo = [CJPayErrorButtonInfo new];
    buttonInfo.page_desc = response.remainLockDesc;
    CJPayPasswordLockPopUpViewController *pwdLockVC = [[CJPayPasswordLockPopUpViewController alloc] initWithButtonInfo:buttonInfo];
    @CJWeakify(pwdLockVC)
    pwdLockVC.cancelBlock = ^ {
        @CJStrongify(pwdLockVC)
        [pwdLockVC dismissSelfWithCompletionBlock:nil];
    };
    
    pwdLockVC.forgetPwdBlock = ^{
        @CJStrongify(pwdLockVC)
        [pwdLockVC dismissSelfWithCompletionBlock:^{
            [passwordVC.viewModel gotoForgetPwdVCFromVC:passwordVC];
        }];
    };
    
    [passwordVC.navigationController pushViewController:pwdLockVC animated:YES];
}

- (CJPayOrderStatus)p_stateTypeWithSignStatus:(NSString *)signStatus {
    if ([signStatus isEqualToString:@"SUCCESS"]) {
        return CJPayOrderStatusSuccess;
    }
    if ([signStatus isEqualToString:@"FAIL"]) {
        return CJPayOrderStatusFail;
    }
    if ([signStatus isEqualToString:@"PROCESSING"]) {
        return CJPayOrderStatusProcess;
    }
    CJPayLogError(@"签约结果异常%@", CJString(signStatus));
    return CJPayOrderStatusProcess;
}

- (void)p_gotoResultPageWithResponse:(CJPaySignOnlyBindBytePayAccountResponse *)response fromVC:(UIViewController *)fromVC {
    CJPaySignOnlyResultPageViewController *resultVC = [CJPaySignOnlyResultPageViewController new];
    CJPayOrderStatus resultType = [self p_stateTypeWithSignStatus:response.resultDesc.signStatus];
    resultVC.result = response.resultDesc;
    resultVC.isFromOuterApp = (self.signType != CJPayOuterTypeInnerPay);
    [resultVC useCloseBackBtn];
    @CJWeakify(self);
    resultVC.closeActionCompletionBlock = ^(BOOL isSuccess) {
        @CJStrongify(self);
        [self p_closeSignWithSignResult:resultType];
    };
    if ([fromVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        CJPayNavigationController *navi = (CJPayNavigationController *)fromVC.navigationController;
        [navi pushViewControllerSingleTop:resultVC animated:NO completion:nil];
    } else {
        [resultVC showMask:YES];
        resultVC.animationType = HalfVCEntranceTypeFromBottom;
        [self.navigationController pushViewController:resultVC animated:YES];
    }
}

- (void)p_closeSignWithSignResult:(CJPayOrderStatus)orderStatue {
    if (orderStatue != CJPayOrderStatusCancel) {
        CJPayDypayResultType resultType = [CJPayOuterPayUtil dypayResultTypeWithOrderStatus:orderStatue];
        [self p_closeCashierDeskAndJumpBackWithResult:resultType];
    }
}

- (void)p_alertRequestErrorWithMsg:(NSString *)alertText
                       clickAction:(void(^)(void))clickAction {
    [CJPayAlertUtil singleAlertWithTitle:alertText content:@"" buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:^{
        CJ_CALL_BLOCK(clickAction);
    } useVC:self];
}

- (void)p_bindCard {
    CJPayBindCardSharedDataModel *commonModel = [self p_buildCommonModel];
    BOOL enableNativeBindCard = [CJPaySettingsManager shared].currentSettings.nativeBindCardConfig.enableNativeBindCard;
    if (!enableNativeBindCard || [[CJPayBindCardManager sharedInstance] isLynxReady]) {
        [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:commonModel];
        return;
    }
    
    NSDictionary *params = @{
        @"source" : @"payment_manage",
        @"app_id" : CJString(self.zg_app_id),
        @"merchant_id" : CJString(self.zg_merchant_id)
    };
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:CJPayDYPayTitleMessage];
    [[CJPayBindCardManager sharedInstance] onlyBindCardWithCommonModel:commonModel params:params completion:nil stopLoadingBlock:^{
        [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
    }];
}

- (void)p_requestQuerySignInfo {
    NSDictionary *params = @{
        @"app_id": CJString(self.zg_app_id),
        @"merchant_id": CJString(self.zg_merchant_id),
        @"member_biz_order_no": CJString(self.tradeNo)
    };
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:CJPayDYPayTitleMessage];
    [CJPaySignOnlyQuerySignTemplateRequest startWithBizParams:params completion:^(NSError * _Nonnull error, CJPaySignOnlyQuerySignTemplateResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
        if ([response isSuccess]) {
            self.querySignInfo = response;
            [self.contentView updateWithSignModel:[self.querySignInfo toSignModel]];
        } else {
            NSString *alertText = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
            [CJToast toastText:alertText inWindow:self.cj_window];
        }
    }];
}

- (CJPayBindCardSharedDataModel *)p_buildCommonModel {
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceSignPay;
    model.cardBindSource = CJPayCardBindSourceTypeFrontIndependent;
    model.appId = self.zg_app_id;
    model.merchantId = self.zg_merchant_id;
    model.referVC = self;
    model.cjpay_referViewController = self;
    @CJWeakify(self);
    model.completion = ^(CJPayBindCardResultModel * _Nonnull cardResult) {
        @CJStrongify(self)
        switch (cardResult.result) {
            case CJPayBindCardResultSuccess:
                [self p_requestQuerySignInfo];
                break;
            case CJPayBindCardResultFail:
            case CJPayBindCardResultCancel:
                CJPayLogInfo(@"绑卡失败 code: %ld", cardResult.result);
                break;
        }
    };
    return model;
}

- (void)p_trackForPage:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
    double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
    [trackData addEntriesFromDictionary:@{
        @"template_id" : CJString(self.querySignInfo.signTemplateInfo.templateId),
        @"withhold_project" : CJString(self.querySignInfo.signTemplateInfo.serviceName),
        @"original_amount" : @(self.querySignInfo.tradeAmount),
        @"reduce_amount" : @(self.querySignInfo.tradeAmount - self.querySignInfo.realTradeAmount),
        @"cashier_style" : @"2",
        @"app_id": CJString(self.zg_app_id),
        @"merchant_id": CJString(self.zg_merchant_id),
        @"button_name": CJString(self.querySignInfo.signTemplateInfo.buttonDesc),
        @"haspass" : self.querySignInfo.hasBankCard ? @"1" : @"0",
        @"client_duration":@(durationTime)
    }];
    [trackData addEntriesFromDictionary:params];
    [CJTracker event:CJString(eventName) params:trackData];
}

- (void)p_closeCashierDeskAndJumpBackWithResult:(CJPayDypayResultType)resultType {
    if (self.signType == CJPayOuterTypeInnerPay) {
        if (resultType == CJPayDypayResultTypeSuccess || resultType == CJPayDypayResultTypeFailed) {
            if (self.immediatelyClose) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    CJ_CALL_BLOCK(self.completion,resultType, @"");
                }];
            } else {
                // 支付成功|失败场景，先回调，300ms后关闭签约页面
                CJ_CALL_BLOCK(self.completion,resultType, @"");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                        
                    }];
                });
            }
        } else {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                CJ_CALL_BLOCK(self.completion,resultType, @"");
            }];
        }
        return;
    } else {
        [CJPayOuterPayUtil closeCashierDeskVC:self signType:self.signType jumpBackURL:self.returnURLStr jumpBackResult:resultType complettion:^(BOOL isSuccess) {
            CJ_CALL_BLOCK(self.completion,resultType, @"");
        }];
    }
}

- (BOOL)p_isNeedGoLynxBind {
    return [self.querySignInfo.jumpType isEqualToString:@"bind_card"] && Check_ValidString(self.querySignInfo.bindCardUrl);
}

- (void)p_changePayMethodBtnClick {
    if ([self p_isNeedGoLynxBind]) {
        [self p_openLynxBindCardAndSign];
    } else {
        [self p_gotoCardListVC];
    }
}

- (void)p_openLynxBindCardAndSign {
    NSString *schema = self.querySignInfo.bindCardUrl;
    [CJPayDeskUtil openLynxPageBySchema:schema completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
        NSDictionary *data = response.data;
        if (Check_ValidDictionary(data) && [data cj_dictionaryValueForKey:@"data"]) {
            NSDictionary *dataDic = [[data cj_dictionaryValueForKey:@"data"] cj_dictionaryValueForKey:@"msg"];
            NSString *processStr = [dataDic cj_stringValueForKey:@"process"];
            if ([processStr isEqualToString:@"bind_card_open_account"] && [dataDic cj_intValueForKey:@"code"] == 0) {
                [self p_signWithNoPwd];
            } else {
                CJPayLogInfo(@"回调数据非绑卡成功");
            }
        }
    }];
}

- (void)p_gotoCardListVC {
    NSDictionary *requestParmas = @{
        @"app_id" : CJString(self.zg_app_id),
        @"merchant_id" : CJString(self.zg_merchant_id),
        @"support_pay_type" : self.querySignInfo.signTemplateInfo.supportPayType ?: @[]
    };
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    [CJPaySignQueryMemberPayListRequest startWithBizParams:requestParmas completion:^(NSError * _Nonnull error, CJPaySignQueryMemberPayListResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if (error || ![response isSuccess]) {
            [CJToast toastText:Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        if (!self.selectedShowConfig) { //缓存首次扣款方式，一次签约流程中，除非用户手动设置，否则扣款方式不变
            self.selectedShowConfig = [response.firstPayTypeItem buildShowConfig].firstObject;
        }
        
        CJPaySignCardListViewController *listVC = [CJPaySignCardListViewController new];
        listVC.animationType = HalfVCEntranceTypeFromBottom;
        [listVC showMask:YES];
        listVC.listResponse = response;
        listVC.payTypeListUrl = self.querySignInfo.deductOrderUrl;
        listVC.requestParams = requestParmas;
        listVC.zgAppId = self.zg_app_id;
        listVC.zgMerchantId = self.zg_merchant_id;
        listVC.defaultShowConfig = self.selectedShowConfig;
        listVC.isSignOnly = YES;
        listVC.trackParams = @{
            @"app_id" : CJString(self.zg_app_id),
            @"merchant_id" : CJString(self.zg_merchant_id),
            @"button_name": CJString(self.querySignInfo.signTemplateInfo.buttonDesc),
            @"haspass" : self.querySignInfo.hasBankCard ? @"1" : @"0",
        };
        @CJWeakify(self);
        listVC.didClickMethodBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull showConfig) {
            @CJStrongify(self);
            [self p_updateDeductMethodWithShowConfig:showConfig];
        };
        [self.navigationController pushViewController:listVC animated:YES];
    }];
}

- (void)p_updateDeductMethodWithShowConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    NSDictionary *params = @{
        @"app_id": CJString(self.zg_app_id),
        @"merchant_id": CJString(self.zg_merchant_id),
        @"pay_type_item": [showConfig.payChannel toDictionary]
    };
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    [CJPaySignSetMemberFirstPayTypeRequest startWithBizParams:params completion:^(NSError * _Nonnull error, CJPaySignSetMemberFirstPayTypeResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if (![response isSuccess]) {
            [CJToast toastText:Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        self.contentView.deductMethodLabel.text = response.displayName;
        self.selectedShowConfig = nil;
    }];
}


#pragma mark - lazy view
     
- (CJPaySignView *)contentView {
    if (!_contentView) {
        _contentView = [[CJPaySignView alloc] initWithViewType:CJPaySignViewTypeSignOnly];;
        @CJWeakify(self)
        _contentView.confirmActionBlock = ^(void) {
            @CJStrongify(self)
            [self p_trackForPage:@"wallet_withhold_open_open_click" params:@{@"button_name" : CJString(self.contentView.confirmButton.titleLabel.text)}];
            [self p_onConfirmPayAction];
        };
        
        _contentView.changePayMethodBlock = ^(void) {
            @CJStrongify(self)
            [self p_trackForPage:@"wallet_withhold_open_method_click" params:@{}];
            [self p_changePayMethodBtnClick];
        };
    }
    return _contentView;
}

- (CJPayMemVerifyManager *)memVerifyManager {
    if (!_memVerifyManager) {
        _memVerifyManager = [CJPayMemVerifyManager new];
    }
    return _memVerifyManager;
}

@end
