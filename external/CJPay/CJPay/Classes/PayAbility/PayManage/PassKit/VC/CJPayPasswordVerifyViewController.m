//
//  CJPayPasswordVerifyViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/1/5.
//

#import "CJPayPasswordVerifyViewController.h"
#import "CJPayFixKeyboardView.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPaySafeKeyboard.h"
#import "CJPaySafeInputView.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKDefine.h"
#import "CJPayVerifyPasswordRequest.h"
#import "CJPayStyleButton.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPaySafeUtil.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayMetaSecManager.h"
#import "CJPayVerifyManagerHeader.h"
#import "CJPayPasswordView.h"
#import "CJPaySettingsManager.h"
#import "CJPayDeskUtil.h"

@implementation CJPayPassCodeVerifyModel

@end

@interface CJPayPasswordVerifyViewController () <CJPaySafeInputViewDelegate>
@property (nonatomic, strong) CJPayPasswordView *passwordView; // 密码输入新样式
@property (nonatomic, strong) CJPayFixKeyboardView *keyboardView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) CJPayPassCodeVerifyModel *verifyModel;
@property (nonatomic, copy) CJPayPassCodeVerifyCompletion completion;

@end

@implementation CJPayPasswordVerifyViewController

- (instancetype)initWithVerifyModel:(CJPayPassCodeVerifyModel *)verifyModel completion:(nonnull CJPayPassCodeVerifyCompletion)completion {
    self = [super init];
    if (self) {
        _verifyModel = verifyModel;
        _completion = completion;
    }
    return self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    @CJStopLoading(self.passwordView)
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self p_setupUI];
    if (self.verifyModel.isIndependentBindCard) {
        [self.passwordView updateWithPassCodeType:CJPayPassCodeTypeIndependentBindCardVerify];
    } else {
        [self.passwordView updateWithPassCodeType:CJPayPassCodeTypePayVerify title:self.verifyModel.title subTitle:self.verifyModel.subTitle];
    }
    
    [self p_trackerEventName:@"wallet_modify_password_imp" params:nil];
}

- (BOOL)cjAllowTransition {
    return NO;
}

- (void)back {
    if (self.verifyModel.backBlock) {
        self.verifyModel.backBlock();
    } else {
        [super back];
    }
}

- (void)p_setupUI {
    [self p_setupBackgroundImageView];
    
    [self.view addSubview:self.passwordView];
    CJPayMasMaker(self.passwordView, {
        if (CJ_SMALL_SCREEN) {
            make.top.equalTo(self.view).offset([self navigationHeight]);
        }
        else {
            make.top.equalTo(self.view).offset(134);
        }
        make.left.right.equalTo(self.view);
    });
    [self.view addSubview:self.keyboardView];
    
    CJPayMasMaker(self.keyboardView, {
        make.left.right.equalTo(self.view);
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            make.height.mas_equalTo(242 + CJ_TabBarSafeBottomMargin);
        } else {
            make.height.mas_equalTo(224 + CJ_TabBarSafeBottomMargin);
        }
        if (CJ_Pad) {
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            } else {
                make.bottom.equalTo(self.view);
            }
        } else {
            make.bottom.equalTo(self.view);
        }
    });
}

- (void)p_setupBackgroundImageView {
    [self.view addSubview:self.backgroundImageView];
    if (![CJPaySettingsManager shared].currentSettings.abSettingsModel.isHiddenDouyinLogo) {
        [self.backgroundImageView cj_setImage:@"cj_bindcard_logo_icon"];
    }
    CJPayMasMaker(self.backgroundImageView, {
        make.top.right.equalTo(self.view);
        make.width.height.mas_equalTo(self.view.cj_width * 200 /
                                          375.0);
    });
}

- (void)p_clearInputContent {
    [self.passwordView.safeInputView clearInput];
}

- (void)p_clearErrorText {
    self.passwordView.errorLabel.text = @"";
}

- (void)p_clickForgetBtn {
    [self p_trackerEventName:@"wallet_modify_password_forget_click" params:nil];
    
    [self p_clearErrorText];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    [params cj_setObject:self.verifyModel.merchantId forKey:@"merchant_id"];
    [params cj_setObject:self.verifyModel.appId forKey:@"app_id"];

    CJPayMigrateH5PageToLynx *model = [CJPaySettingsManager shared].currentSettings.migrateH5PageToLynx;
    if (Check_ValidString(model.forgetpassSchema)) {
        [CJPayDeskUtil openLynxPageBySchema:[CJPayCommonUtil appendParamsToUrl:model.forgetpassSchema
                                                                    params:params]
                           completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
            [self p_handleWebViewCloseCallBack:response.data];
        }];
        return;
    }
    
    [params cj_setObject:@"21" forKey:@"service"];
    [params cj_setObject:@"SmchId" forKey:@"smch_id"];
    
    NSString *url = [NSString stringWithFormat:@"%@/usercenter/setpass/guide",[CJPayBaseRequest bdpayH5DeskServerHostString]];
    @CJWeakify(self);
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self useNewNavi:CJ_Pad toUrl:url params:params nativeStyleParams:@{} closeCallBack:^(id  _Nonnull data) {
        @CJStrongify(self);
        //处理web返回
        [self p_handleWebViewCloseCallBack:data];
        [self p_clearErrorText];
    }];
}

- (void)p_handleWebViewCloseCallBack:(id)data {
    if (data != nil && [data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)data;
        NSString *service = [dic cj_stringValueForKey:@"service"];
        if (Check_ValidString(service) && [service isEqualToString:@"resetPassword"]) {
             if ([data isKindOfClass:[NSDictionary class]] && data != nil) {
                 NSDictionary *dict = [CJPayCommonUtil jsonStringToDictionary:data[@"data"]];
                 int cardFlag = [dict cj_intValueForKey:@"card"];
                 if (cardFlag == 1) {
                    //通过H5绑卡找回支付密码 发送刷新卡列表通知
                    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayH5BindCardSuccessNotification object:nil];
                 }
             }
         }
    }
}

- (void)p_trackerEventName:(NSString *)name params:(NSDictionary *)params {
    
    NSMutableDictionary *dict = params ? [params mutableCopy] : [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
            @"app_id": CJString(self.verifyModel.appId),
            @"merchant_id": CJString(self.verifyModel.merchantId),
            @"is_bind_mobile" : Check_ValidString(self.verifyModel.mobile) ? @"1" : @"0",
            @"is_chaselight" : @"1",
            @"process_id": CJString(self.verifyModel.processInfo.processId),
            @"source": CJString(self.verifyModel.source),
            @"is_onestep" : self.verifyModel.isQuickBindCard ? @"1" : @"0",
            @"activity_info" : self.verifyModel.activityInfo ?: @[],
            @"addbcard_type" : self.verifyModel.isUnionBindCard ? @"云闪付" : @""
    }];
    if (self.verifyModel.trackParams.count > 0) {
        [dict addEntriesFromDictionary:self.verifyModel.trackParams];
    }
    [CJTracker event:name params:[dict copy]];
}

#pragma mark - CJPaySafeInputViewDelegate

- (CJPayButtonInfoHandlerActionsModel *)p_buttonInfoActions {
    @CJWeakify(self)
    CJPayButtonInfoHandlerActionsModel *actionsModel = [CJPayButtonInfoHandlerActionsModel new];
    actionsModel.backAction = ^{
        @CJStrongify(self)
        self.completion(NO, YES);
    };
    actionsModel.findPwdAction = ^(NSString *_) {
        @CJStrongify(self)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @CJStrongify(self)
            if (self) {
                [self p_clearInputContent];
            }
        });
        CJPayMigrateH5PageToLynx *model = [CJPaySettingsManager shared].currentSettings.migrateH5PageToLynx;
        if (Check_ValidString(model.forgetpassSchema)) {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            [params cj_setObject:self.verifyModel.merchantId forKey:@"merchant_id"];
            [params cj_setObject:self.verifyModel.appId forKey:@"app_id"];
            [CJPayDeskUtil openLynxPageBySchema:[CJPayCommonUtil appendParamsToUrl:model.forgetpassSchema params:params]
                               completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {}];
            return;
        }
        NSString *pwd = [CJPayBDButtonInfoHandler findPwdUrlWithAppID:self.verifyModel.appId
                                                         merchantID:self.verifyModel.merchantId
                                                             smchID:self.verifyModel.smchId];
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self.navigationController toUrl:pwd];
    };
    actionsModel.errorInPageAction = ^(NSString *errorText) {
        @CJStrongify(self)
        [self p_clearInputContent];
        self.passwordView.errorLabel.text = errorText;
    };
    return actionsModel;
}

- (void)inputView:(CJPaySafeInputView *)inputView completeInputWithCurrentInput:(NSString *)currentStr {
    [self p_trackerEventName:@"wallet_modify_password_input" params:nil];

    [self p_clearErrorText];
    self.passwordView.completeButton.enabled = YES;
    @CJStartLoading(self.passwordView)
    
    NSDictionary *params = @{
        @"app_id": CJString(self.verifyModel.appId),
        @"merchant_id": CJString(self.verifyModel.merchantId),
        @"password": [CJPaySafeUtil encryptPWD:currentStr],
        @"sign_order_no": CJString(self.verifyModel.orderNo)
    };
    
    [CJPayVerifyPasswordRequest startWithParams:params completion:^(NSError * _Nonnull error, CJPayVerifyPassCodeResponse * _Nonnull response) {
        @CJStopLoading(self.passwordView)
        
        [self p_trackerEventName:@"wallet_modify_password_result" params:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"error_code" : CJString(response.code),
            @"error_mesage" : CJString(response.msg)
        }];
        
        [CJMonitor trackService:@"wallet_rd_passkit_verify_password" extra:@{
            @"result" : [response isSuccess] ? @"1" : @"0"
        }];
        
        if (![response isSuccess]) {
            
            [CJMonitor trackService:@"wallet_rd_passkit_verify_exception" extra:@{
                @"code": CJString(response.code),
                @"reason": CJString(response.msg)
            }];
            
            [self p_clearInputContent];
            
            response.buttonInfo.code = response.code;
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                              fromVC:self errorMsg:response.msg
                                                         withActions:[self p_buttonInfoActions]
                                                           withAppID:self.verifyModel.appId
                                                          merchantID:self.verifyModel.merchantId
                                                     alertCompletion:^(UIViewController * _Nullable alertVC, BOOL handled) {
                [CJMonitor trackService:@"wallet_rd_passkit_verify_password_break" extra:@{
                    @"code": CJString(response.code),
                    @"reason": CJString(response.msg)
                }];
            }];
        }
        
        if (self.completion) {
            self.completion(response.isSuccess, NO);
        }
    }];
}

- (BOOL)inputViewShouldResignFirstResponder:(CJPaySafeInputView *)inputView {
    return YES;
}

- (void)inputView:(CJPaySafeInputView *)inputView textDidChangeWithCurrentInput:(NSString *)currentStr {
    
}

#pragma mark - Getter
- (CJPayPasswordView *)passwordView {
    if (!_passwordView) {
        _passwordView = [[CJPayPasswordView alloc] initWithFrame:CGRectZero];
        _passwordView.safeInputView.safeInputDelegate = self;
        @CJWeakify(self)
        _passwordView.forgetButtonTappedBlock = ^{
            @CJStrongify(self)
            [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeForgetPayPWDRequest];
            [self p_clickForgetBtn];
        };
    }
    return _passwordView;
}

- (CJPayFixKeyboardView *)keyboardView {
    if (!_keyboardView) {
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            _keyboardView = [[CJPayFixKeyboardView alloc] initWithSafeGuardIconUrl:[CJPayAccountInsuranceTipView keyboardLogo]];
            _keyboardView.notShowSafeguard = NO;
        } else {
            _keyboardView = [CJPayFixKeyboardView new];
        }
        @CJWeakify(self)
        _keyboardView.safeKeyboard.numberClickedBlock = ^(NSInteger number) {
            @CJStrongify(self)
            if (self) {
                [self.passwordView.safeInputView inputNumber:number];
            }
        };
        _keyboardView.safeKeyboard.deleteClickedBlock = ^{
            @CJStrongify(self)
            if (self) {
                [self.passwordView.safeInputView deleteBackWord];
            }
        };
    }
    return _keyboardView;
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [UIImageView new];
    }
    return _backgroundImageView;
}

@end
