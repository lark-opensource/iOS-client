
//
//  CJPayVerifyItemPassword.m
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import "CJPayVerifyItemPassword.h"
#import "CJPaySafeUtil.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseVerifyManager.h"
#import <TTReachability/TTReachability.h>
#import "CJPayVerifyItemUploadIDCard.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayVerifyPassVCConfigModel.h"
#import "CJPayRetainUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayKVContext.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayGetVerifyInfoRequest.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayForgetPwdInfo.h"
#import "CJPayLoadingManager.h"
#import "CJPayMetaSecManager.h"
#import "CJPayPasswordLockPopUpViewController.h"
#import "CJPayHalfVerifyPasswordNormalViewController.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayErrorInfoActionView.h"
#import "CJPaySafeInputView.h"
#import "CJPayHalfVerifyPasswordBaseViewController.h"
#import "CJPayHalfVerifyPasswordWithSkipPwdGuideViewController.h"
#import "CJPayHalfVerifyPasswordWithOpenBioGuideViewController.h"
#import "CJPayForgetPwdOptController.h"
#import "CJPayHalfVerifyPasswordV2ViewController.h"
#import "CJPayHalfVerifyPasswordV3ViewController.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayPasswordContentViewV2.h"
#import "CJPayPasswordContentViewV3.h"
#import "CJPayRetainRecommendInfoModel.h"
#import "CJPayDeskUtil.h"
#import "CJPayParamsCacheService.h"
#import "CJPaySettingsManager.h"
#import "CJPayRetainInfoV2Config.h"

@interface CJPayVerifyItemPassword()

@property (nonatomic, assign) BOOL hasInputSuccess;
@property (nonatomic, assign) BOOL isInputPassword;
@property (nonatomic, assign) BOOL retainUserContinuePaySuccess;
@property (nonatomic, copy) NSString *recogFaceSource;
@property (nonatomic, copy) NSString *lastPWD;
@property (nonatomic, assign) NSInteger verifyTimes;
@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;
@property (nonatomic, strong) CJPayEvent *event;

@end

@implementation CJPayVerifyItemPassword

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_setShowKeyBoard:) name:CJPayShowPasswordKeyBoardNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createVerifyPasscodeVC {

    if ([self useV3PasswordVCWithChooseMethod]) {
        [self createVerifyPasscodeVCv3WithChooseMethod];
        return;
    }
    
    if ([self usePasswordVCWithChooseMethod]) {
        [self createVerifyPasscodeVCWithChooseMethod];
        return;
    }
    if (self.verifyPasscodeVC && self.verifyPasscodeVC.navigationController) {
        if (self.verifyPasscodeVC.navigationController.viewControllers.count > 1) {
            NSMutableArray *vcs = [self.verifyPasscodeVC.navigationController.viewControllers mutableCopy];
            [vcs removeObjectIdenticalTo:self.verifyPasscodeVC];
            self.verifyPasscodeVC.navigationController.viewControllers = [vcs copy];
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
    }
    
    CJPayVerifyPasswordViewModel *viewModel = [self createPassCodeViewModel];
    self.viewModel = viewModel;
    
    if (self.manager.response.skipPwdGuideInfoModel.needGuide) {
        self.verifyPasscodeVC = [[CJPayHalfVerifyPasswordWithSkipPwdGuideViewController alloc] initWithViewModel:self.viewModel];
    } else if ([self isNeedShowOpenBioGuide]) {
        self.verifyPasscodeVC = [[CJPayHalfVerifyPasswordWithOpenBioGuideViewController alloc] initWithViewModel:self.viewModel];
    } else {
        self.verifyPasscodeVC = [[CJPayHalfVerifyPasswordNormalViewController alloc] initWithViewModel:viewModel];
    }
    
    @CJWeakify(self)
    self.verifyPasscodeVC.cjBackBlock = ^{
        @CJStrongify(self);
        if ([self shouldShowRetainVC]) {
            // 展示了挽留弹窗，就以挽留弹窗的事件进行页面的关闭。
        } else {
            [self closeAction];
        }
    };
}

// 展示唤端追光新样式验密页
- (void)createVerifyPasscodeVCv3WithChooseMethod {
    if (self.verifyPasscodeVCv3 && self.verifyPasscodeVCv3.navigationController) {
        if (self.verifyPasscodeVCv3.navigationController.viewControllers.count > 1) {
            NSMutableArray *vcs = [self.verifyPasscodeVCv3.navigationController.viewControllers mutableCopy];
            [vcs removeObjectIdenticalTo:self.verifyPasscodeVCv3];
            self.verifyPasscodeVCv3.navigationController.viewControllers = [vcs copy];
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
            [self.verifyPasscodeVCv3 showLoadingStatus:NO];
            return;
        }
    }
    
    self.viewModel = [self createVerifyPasswordViewModelWithChooseMethod];
    self.verifyPasscodeVCv3 = [[CJPayHalfVerifyPasswordV3ViewController alloc] initWithViewModel:self.viewModel];
    self.verifyPasscodeVCv3.response = self.manager.response;
    self.verifyPasscodeVCv3.verifyManager = self.manager;
    BOOL isSimpleVerifyStyle = [self.manager.bizParams cj_boolValueForKey:@"is_simple_verify_style"];
    self.verifyPasscodeVCv3.isSimpleVerifyStyle = isSimpleVerifyStyle;

    self.viewModel.hideChoosedPayMethodView = isSimpleVerifyStyle;
    self.viewModel.hideMerchantNameLabel = isSimpleVerifyStyle;
    self.viewModel.hidePasswordFixedTips = isSimpleVerifyStyle;
    
    self.viewModel.canChangeCombineStatus = YES;
    self.viewModel.cancelRetainWindow = [self.manager.bizParams cj_boolValueForKey:@"is_cancel_retain_window"];
    self.verifyPasscodeVCv3.changeMethodDelegate = self.manager.changePayMethodDelegate; // 设置验密页的 更改支付方式代理
    @CJWeakify(self)
    self.verifyPasscodeVCv3.cjBackBlock = ^{
        @CJStrongify(self);
        if ([self shouldShowRetainVC]) {
            // 展示了挽留弹窗，就以挽留弹窗的事件进行页面的关闭。
        } else {
            [self closeAction]; // 电商场景会重写改方法
        }
    };
    
    self.verifyPasscodeVCv3.inputCompleteBlock = ^(NSString * pwd) {
        @CJStrongify(self)
        
        if (pwd.length == 0 && ![self.verifyPasscodeVCv3.passwordContentView isPasswordVerifyStyle]) {
            // 新卡支付
            if ([self.manager.response.topRightBtnInfo.action isEqualToString:@"bio_verify"]) {
                self.manager.isSkipPWDForbiddenOpt = YES;
            }
            
            CJPayVerifyType verifyType = [self.manager getVerifyTypeWithPwdCheckWay:self.manager.response.userInfo.pwdCheckWay];
            if ([self.viewModel isNeedResignCard]) {
                [self.manager wakeSpecificType:CJPayVerifyTypeSignCard orderRes:self.manager.response event:self.event];
            } else if (self.viewModel.defaultConfig.type == BDPayChannelTypeAddBankCard) {
                // 获取新卡绑卡的字段
                CJPayDefaultChannelShowConfig *defaultConfig = self.viewModel.defaultConfig;
                NSDictionary *bindCardInfo = @{
                    @"bank_code": CJString(defaultConfig.frontBankCode),
                    @"card_type": CJString(defaultConfig.cardType),
                    @"card_add_ext": CJString(defaultConfig.cardAddExt),
                    @"business_scene": CJString([defaultConfig bindCardBusinessScene])
                };
                // 发起新卡支付
                [self.manager sendEventTOVC:CJPayHomeVCEventBindCardPay obj:@{@"bind_card_info":bindCardInfo}];
            } else if (verifyType == CJPayVerifyTypeSkipPwd) {
                // 免密支付
                [self.manager wakeSpecificType:CJPayVerifyTypeSkipPwd
                                      orderRes:self.manager.response
                                         event:[self p_buildEventSwitchToBio]];
            } else {
                // 老卡支付
                // 使用生物验证
                [self.verifyPasscodeVCv3 switchToPasswordVerifyStyle:YES showPasswordVerifyKeyboard:NO];
                if (!self.manager.isStandardDouPayProcess) {
                    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading isNeedValidateTimer:YES];
                }
                [self.manager wakeSpecificType:CJPayVerifyTypeBioPayment orderRes:self.manager.response event:[self p_buildEventSwitchToBio]];
            }
            [self.viewModel trackWithEventName:@"wallet_cashier_pay_loading" params:@{}];
            [self.verifyPasscodeVCv3 showLoadingStatus:YES];
        
            return;
        }
        
        if (pwd.length < 6) {
            [[CJPayLoadingManager defaultService] stopLoading];
            return;
        }
        self.hasInputSuccess = YES;
        self.isInputPassword = YES;
        if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:[self.manager.homePageVC topVC].cj_window];
            return;
        }
        
        self.verifyTimes = self.verifyTimes + 1;
        
        self.lastPWD = pwd;
        self.manager.lastPWD = pwd;
        [self.viewModel trackWithEventName:@"wallet_cashier_pay_loading" params:@{}];
        [self.verifyPasscodeVCv3 showLoadingStatus:YES];
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading isNeedValidateTimer:YES];
        [self.manager submitConfimRequest:[self _buildPwdParam] fromVerifyItem:self];
    };
    
    self.verifyPasscodeVCv3.otherVerifyPayBlock = ^(CJPayPasswordSwitchOtherVerifyType verifyType) {
        @CJStrongify(self)
        if (verifyType == CJPayPasswordSwitchOtherVerifyTypeBio) {
            // 切换使用 面容/指纹验证
            if ([CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBiometryLockout]) {
                NSString *bioType = [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) bioType];
                NSString *msg = CJPayLocalizedStr(@"不支持指纹/面容");
                
                if ([bioType isEqualToString: @"1"]) {
                    msg = CJPayLocalizedStr(@"指纹已锁定，可在「设置-触控ID与密码」验证密码解锁");
                } else if ([bioType isEqualToString: @"2"]) {
                    msg = CJPayLocalizedStr(@"面容已锁定，可在「设置-面容ID与密码」验证密码解锁");
                }
                
                [CJToast toastText:msg inWindow:[self.manager.homePageVC topVC].cj_window];
                return;
            }
            self.verifyPasscodeVCv3.otherVerifyButton.hidden = YES;
            [self.verifyPasscodeVCv3 retractKeyBoardView];
            if ([self.manager.response.topRightBtnInfo.action isEqualToString:@"bio_verify"]) {
                self.manager.isSkipPWDForbiddenOpt = YES;
            }
            
            if (!self.manager.isStandardDouPayProcess) {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading isNeedValidateTimer:YES];
            }
            [self.manager wakeSpecificType:CJPayVerifyTypeBioPayment orderRes:self.manager.response event:[self p_buildEventSwitchToBio]];
            
        } else if (verifyType == CJPayPasswordSwitchOtherVerifyTypeRecogFace) {
            // 切换使用 活体验证
            self.recogFaceSource = @"未输错密码-刷脸支付";
            [self.verifyPasscodeVCv3 retractKeyBoardView];
            [self p_requestVerifyItem];
        } else {
            [CJToast toastText:CJPayLocalizedStr(@"不支持切换验证方式") inWindow:[self.manager.homePageVC topVC].cj_window];
            return;
        }
    };
    self.verifyPasscodeVCv3.forgetPasswordBtnBlock = ^{
        @CJStrongify(self);
        [self forgetPasswordBtnTapped];
    };
}

// 展示新样式验密页
- (void)createVerifyPasscodeVCWithChooseMethod {
    if (self.verifyPasscodeVCv2 && self.verifyPasscodeVCv2.navigationController) {
        if (self.verifyPasscodeVCv2.navigationController.viewControllers.count > 1) {
            NSMutableArray *vcs = [self.verifyPasscodeVCv2.navigationController.viewControllers mutableCopy];
            [vcs removeObjectIdenticalTo:self.verifyPasscodeVCv2];
            self.verifyPasscodeVCv2.navigationController.viewControllers = [vcs copy];
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
    }
    
    self.viewModel = [self createVerifyPasswordViewModelWithChooseMethod];
    self.viewModel.canChangeCombineStatus = NO;
    BOOL isSimpleVerifyStyle = [self.manager.bizParams cj_boolValueForKey:@"is_simple_verify_style"];
    if (isSimpleVerifyStyle) {
        self.viewModel.isStillShowForgetBtn = YES;
        self.viewModel.hideMerchantNameLabel = YES;
    }
    
    self.verifyPasscodeVCv2 = [[CJPayHalfVerifyPasswordV2ViewController alloc] initWithViewModel:self.viewModel];
    self.verifyPasscodeVCv2.response = self.manager.response;
    self.verifyPasscodeVCv2.verifyManager = self.manager;
    self.verifyPasscodeVCv2.changeMethodDelegate = self.manager.changePayMethodDelegate; // 设置验密页的 更改支付方式代理
    @CJWeakify(self)
    self.verifyPasscodeVCv2.cjBackBlock = ^{
        @CJStrongify(self);
        if ([self shouldShowRetainVC]) {
            // 展示了挽留弹窗，就以挽留弹窗的事件进行页面的关闭。
        } else {
            [self closeAction]; // 电商场景会重写改方法
        }
    };
    
    self.verifyPasscodeVCv2.forgetPasswordBtnBlock = ^{
        @CJStrongify(self);
        [self forgetPasswordBtnTapped];
    };
    
    self.verifyPasscodeVCv2.inputCompleteBlock = ^(NSString * pwd) {
        @CJStrongify(self)
        if (pwd.length < 6) {
            [[CJPayLoadingManager defaultService] stopLoading];
            return;
        }
        self.hasInputSuccess = YES;
        self.isInputPassword = YES;
        if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:[self.manager.homePageVC topVC].cj_window];
            return;
        }
        
        self.verifyTimes = self.verifyTimes + 1;
        
        self.lastPWD = pwd;
        self.manager.lastPWD = pwd;
        [self.manager submitConfimRequest:[self _buildPwdParam] fromVerifyItem:self];
    };
    
    self.verifyPasscodeVCv2.otherVerifyPayBlock = ^(CJPayPasswordSwitchOtherVerifyType verifyType) {
        @CJStrongify(self)
        if (verifyType == CJPayPasswordSwitchOtherVerifyTypeBio) {
            // 切换使用 面容/指纹验证
            if ([CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBiometryLockout]) {
                NSString *bioType = [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) bioType];
                NSString *msg = CJPayLocalizedStr(@"不支持指纹/面容");
                
                if ([bioType isEqualToString: @"1"]) {
                    msg = CJPayLocalizedStr(@"指纹已锁定，可在「设置-触控ID与密码」验证密码解锁");
                } else if ([bioType isEqualToString: @"2"]) {
                    msg = CJPayLocalizedStr(@"面容已锁定，可在「设置-面容ID与密码」验证密码解锁");
                }
                
                [CJToast toastText:msg inWindow:[self.manager.homePageVC topVC].cj_window];
                return;
            }
            
            [self.verifyPasscodeVCv2 retractKeyBoardView];
            if ([self.manager.response.topRightBtnInfo.action isEqualToString:@"bio_verify"]) {
                self.manager.isSkipPWDForbiddenOpt = YES;
            }
            
            if (self.viewModel.isGuideSelected && self.manager.response.skipPwdGuideInfoModel.needGuide) {
                self.manager.isSkipPwdSelected = YES;
            } else {
                self.manager.isSkipPwdSelected = NO;
            }
            
            [self.manager wakeSpecificType:CJPayVerifyTypeBioPayment orderRes:self.manager.response event:[self p_buildEventSwitchToBio]];
            
        } else if (verifyType == CJPayPasswordSwitchOtherVerifyTypeRecogFace) {
            // 切换使用 活体验证
            self.recogFaceSource = @"未输错密码-刷脸支付";
            [self.verifyPasscodeVCv2 retractKeyBoardView];
            [self p_requestVerifyItem];
        } else {
            [CJToast toastText:CJPayLocalizedStr(@"不支持切换验证方式") inWindow:[self.manager.homePageVC topVC].cj_window];
            return;
        }
    };
}

// 展示新样式验密页，设置viewModel
- (CJPayVerifyPasswordViewModel *)createVerifyPasswordViewModelWithChooseMethod {
    CJPayVerifyPasswordViewModel *viewModel = [CJPayVerifyPasswordViewModel new];
    viewModel.response = self.manager.response;
    viewModel.defaultConfig = self.manager.defaultConfig;
    viewModel.hideChoosedPayMethodView = [self.manager.bizParams cj_boolValueForKey:@"is_simple_verify_style"] || [self.manager.response.payInfo.showChangePaytype isEqualToString:@"0"];
    viewModel.downgradePasswordTips = CJString(self.manager.response.payInfo.verifyDesc);
    viewModel.cancelRetainWindow = [self.manager.bizParams cj_boolValueForKey:@"is_cancel_retain_window"];
    viewModel.isDynamicLayout = [self.manager.response.payInfo isDynamicLayout];
    viewModel.outDisplayInfoModel = self.manager.response.payTypeInfo.outDisplayInfo;
    if (self.manager.isOneKeyQuickPay) {
        CJPayVerifyPassVCConfigModel *configModel = [CJPayVerifyPassVCConfigModel new];
        configModel.tipsText = self.manager.response.confirmResponse.oneKeyPayPwdCheckMsg;
        viewModel.configModel = configModel;
    }
    viewModel.trackDelegate = self;
    @CJWeakify(self)
    viewModel.faceRecogPayBlock = ^(NSString * _Nonnull verifySource) {
        @CJStrongify(self)
        self.recogFaceSource = verifySource;
        [self p_requestVerifyItem];
    };

    return viewModel;
}

- (BOOL)isNeedShowOpenBioGuide {
    return [self p_isNeedShowOpenBioGuide];
}

- (CJPayVerifyPasswordViewModel *)createPassCodeViewModel {
    CJPayVerifyPasswordViewModel *viewModel = [CJPayVerifyPasswordViewModel new];
    viewModel.response = self.manager.response;
    viewModel.defaultConfig = self.manager.defaultConfig;
    viewModel.isPaymentForOuterApp = self.manager.isPaymentForOuterApp;
    if (self.manager.isOneKeyQuickPay) {
        CJPayVerifyPassVCConfigModel *configModel = [CJPayVerifyPassVCConfigModel new];
        configModel.tipsText = self.manager.response.confirmResponse.oneKeyPayPwdCheckMsg;
        viewModel.configModel = configModel;
    }
    viewModel.trackDelegate = self;
    @CJWeakify(self)
    viewModel.forgetPasswordBtnBlock = ^{
        @CJStrongify(self);
        [self forgetPasswordBtnTapped];
    };
    //切换为指纹/面容支付/刷脸支付
    @CJWeakify(viewModel)
    viewModel.otherVerifyPayBlock = ^(NSString *verifyType) {
        @CJStrongify(viewModel)
        @CJStrongify(self)
        if (Check_ValidString(verifyType)) {
            if ([verifyType isEqualToString:@"forget_pwd_verify"]) {
                self.recogFaceSource = @"输错密码-刷脸支付";
                [self p_requestVerifyItem];
            }
            return;
        }
        
        if (viewModel.isStillShowingTopRightBioVerifyButton) {
            if ([CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBiometryLockout]) {
                NSString *bioType = [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) bioType];
                NSString *msg = CJPayLocalizedStr(@"不支持指纹/面容");
                
                if ([bioType isEqualToString: @"1"]) {
                    msg = CJPayLocalizedStr(@"指纹已锁定，可在「设置-触控ID与密码」验证密码解锁");
                } else if ([bioType isEqualToString: @"2"]) {
                    msg = CJPayLocalizedStr(@"面容已锁定，可在「设置-面容ID与密码」验证密码解锁");
                }
                
                [CJToast toastText:msg inWindow:[self.manager.homePageVC topVC].cj_window];
                return;
            }
            [CJKeyboard resignFirstResponder:viewModel.inputPasswordView];
            [self.manager wakeSpecificType:CJPayVerifyTypeBioPayment orderRes:self.manager.response event:[self p_buildEventSwitchToBio]];
            return;
        }
        
        if ([self.confirmResponse.forgetPwdInfo.action isEqualToString:@"forget_pwd_verify"] || [self.manager.response.topRightBtnInfo.action isEqualToString:@"forget_pwd_verify"]) {
            self.recogFaceSource = @"未输错密码-刷脸支付";
            [self p_requestVerifyItem];
        } else if ([self.manager.response.topRightBtnInfo.action isEqualToString:@"bio_verify"]) {
            self.manager.isSkipPWDForbiddenOpt = YES;
            [self.manager wakeSpecificType:CJPayVerifyTypeBioPayment orderRes:self.manager.response event:nil];
        }
    };

    viewModel.inputCompleteBlock = ^(NSString * pwd) {
        @CJStrongify(self)
        @CJStrongify(viewModel)
        if (pwd.length < 6) {
            [[CJPayLoadingManager defaultService] stopLoading];
            return;
        }
        self.hasInputSuccess = YES;
        self.isInputPassword = YES;
        if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:[self.manager.homePageVC topVC].cj_window];
            return;
        }
        
        self.verifyTimes = self.verifyTimes + 1;
        
        self.lastPWD = pwd;
        self.manager.lastPWD = pwd;
        [self.manager submitConfimRequest:[self _buildPwdParam] fromVerifyItem:self];
    };
    
    viewModel.faceRecogPayBlock = ^(NSString * verifySource) {
        @CJStrongify(self)
        self.recogFaceSource = verifySource;
        [self p_requestVerifyItem];
    };
    
    return viewModel;
}

- (void)forgetPasswordBtnTapped {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeForgetPayPWDRequest];
    self.hasInputSuccess = YES;
    @CJWeakify(self);
    void(^forgetPasswordCompletion)(BOOL) = ^(BOOL resetPassword) {
        @CJStrongify(self)
        // 密码重置成功需清空错误文案
        if (resetPassword && [self usePasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv2 updateErrorText:@""];
        }
    };
    if (!self.confirmResponse.forgetPwdInfo) {
        [self.viewModel gotoForgetPwdVCFromVC:[self getPasswordVC] completion:forgetPasswordCompletion];
        return;
    }
    
    NSString *style = self.confirmResponse.forgetPwdInfo.style;
    // 命中实验，输错密码后忘记密码，直接跳转
    if ([style isEqualToString:@"next_to_tips"] || [style isEqualToString:@"top_right"]) {
        [self.viewModel gotoForgetPwdVCFromVC:[self getPasswordVC] completion:forgetPasswordCompletion];
        return;
    }
    
    NSString *action = self.confirmResponse.forgetPwdInfo.action;
    
    if ([action isEqualToString:@"forget_pwd_verify"]) {
        self.recogFaceSource = @"输错密码-刷脸支付";
        [self p_requestVerifyItem];
    } else if ([action isEqualToString:@"reset_pwd"]) {
        [self.viewModel gotoForgetPwdVCFromVC:[self getPasswordVC] completion:forgetPasswordCompletion];
    } else {
        [self.viewModel gotoForgetPwdVCFromVC:[self getPasswordVC] completion:forgetPasswordCompletion];
    }
}

// 创建密码设置的参数
- (NSDictionary *)_buildPwdParam {
    if (!Check_ValidString(self.lastPWD)) {
        return @{};
    }
    NSString *pwdType = @"2"; //密码类型1设置密码、2验证密码
    NSMutableDictionary *pwdDic = [NSMutableDictionary new];
    [pwdDic cj_setObject:[CJPaySafeUtil encryptPWD:self.lastPWD serialNumber:self.manager.response.processInfo.processId] forKey:@"pwd"];
    [pwdDic cj_setObject:pwdType forKey:@"pwd_type"];
    if (self.manager.confirmResponse && [self.manager.confirmResponse.code isEqualToString:@"CD002005"]) {
        [pwdDic cj_setObject:@"6" forKey:@"req_type"];
    }
    if (Check_ValidString([self p_guideTypeKey])) {
        [pwdDic cj_setObject:@(self.viewModel.isGuideSelected) forKey:[self p_guideTypeKey]];
    }
    return pwdDic;
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    [self p_showPasswordViewController];
}

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    if (self.manager.lastConfirmVerifyItem == self) {
        [self event:@"wallet_password_verify_page_verify_result" params:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg),
            @"activity_label" : [self.manager.response.payInfo.voucherType integerValue] !=0 ? CJString(self.manager.response.payInfo.voucherMsg) : @"",
            @"time" : @(self.viewModel.passwordInputCompleteTimes),
            @"confirm_time" : @(self.viewModel.confirmBtnClickTimes),
            @"guide_choose" : CJString([self p_getGuideChoose]),
            @"guide_type" : CJString([self p_getGuideType]),
            @"is_fingerprint_default" : CJString([self p_getIsFingerprintDefault]),
            @"is_awards_show" : @"1",
            @"awards_info" : CJString(self.manager.response.payInfo.guideVoucherLabel)
        }];
    }
    
    if (self.verifyPasscodeVCv3 && ![response isSuccess]) {
        [self.verifyPasscodeVCv3 showLoadingStatus:NO];
    }
    
    // 免密的场景下密码支持加验
    if ([response.code isEqualToString:@"CD002005"]) {
        return YES;
    }
    
    if ([response.code isEqualToString:@"CD006003"]) {
        return YES;
    }
    
    // 显示密码错误5的后的非系统弹窗
    if ([response.code isEqualToString:@"CD006007"] || [response.code isEqualToString:@"CD006004"]) {
        return YES;
    }
    
    if ([CJPayBDButtonInfoHandler showErrorTips:response.buttonInfo]) {
        return YES;
    }

    [self.viewModel reset];
    
    if (!response) {
        if ([self useV3PasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv3 showLoadingStatus:NO];
        } else if ([self usePasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv2 showKeyBoardView];
        } else {
            [CJKeyboard becomeFirstResponder:self.viewModel.inputPasswordView];
        }
    }
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 免密的场景下密码支持加验
    if ([response.code isEqualToString:@"CD002005"]) {
        [self p_showPasswordViewController];
        if (self.manager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkipPwd) {
            [CJToast toastText:CJPayLocalizedStr(@"该笔订单无法使用免密支付，请验证后继续付款") inWindow:[self.manager.homePageVC topVC].cj_window];
        }
    }
    
    BOOL hasUpdatedErrorText = NO;
    
    if ([response.code isEqualToString:@"CD006003"]) {
        self.confirmResponse = response;
        NSString *style = response.forgetPwdInfo.style;
        
        if ([style isEqualToString:@"next_to_tips"]) {
            self.viewModel.errorInfoActionView.action = response.forgetPwdInfo.action;
            [self.viewModel.errorInfoActionView.verifyItemBtn cj_setBtnTitle:response.forgetPwdInfo.desc ?: CJPayLocalizedStr(@"刷脸支付")];
            [self event:@"wallet_password_verify_page_alivecheck_imp" params:@{@"button_position":@"2"}];
        } else if ([style isEqualToString:@"top_right"]) {
            [self.viewModel.otherVerifyButton  cj_setBtnTitle:response.forgetPwdInfo.desc ?: CJPayLocalizedStr(@"刷脸支付")];
            [self event:@"wallet_password_verify_page_alivecheck_imp" params:@{@"button_position":@"0"}];
        } else {
            BOOL isForgetCheck = [self.viewModel.forgetPasswordBtn.titleLabel.text isEqualToString:@"忘记密码"];
            [self.viewModel.forgetPasswordBtn cj_setBtnTitle:CJPayLocalizedStr(response.forgetPwdInfo.desc) ?: CJPayLocalizedStr(@"忘记密码")];
            //如果输错密码后，右下角忘记密码按钮展现为面容支付，上报埋点
            if(isForgetCheck && ![self.viewModel.forgetPasswordBtn.titleLabel.text isEqualToString:@"忘记密码"]) {
                [self event:@"wallet_password_verify_page_alivecheck_imp" params:@{@"button_position":@"1"}];
            }
        }

        if ([CJPayBDButtonInfoHandler showErrorTips:response.buttonInfo]) {
            hasUpdatedErrorText = YES;
            if ([self usePasswordVCWithChooseMethod]) {
                [self.verifyPasscodeVCv2 updateErrorText:response.buttonInfo.page_desc];
            } else if ([self useV3PasswordVCWithChooseMethod]) {
                [self.verifyPasscodeVCv3 updateErrorText:response.buttonInfo.page_desc];
            } else {
                [self.viewModel updateErrorText:response.buttonInfo.page_desc
                                 withTypeString:style
                                      currentVC:self.verifyPasscodeVC];
            }
        }
        // 生物验证系统取消后，验密一直显示刷脸支付按钮
        if (self.viewModel.isStillShowingTopRightBioVerifyButton) {
            [self p_handleSwitchPasswordEvent:self.event];
        }
    }
    
    //输错5次密码
    if ([response.code isEqualToString:@"CD006007"] || [response.code isEqualToString:@"CD006004"]) {
        self.confirmResponse = response;
        [self.viewModel.forgetPasswordBtn cj_setBtnTitle:self.confirmResponse.forgetPwdInfo.desc ?: CJPayLocalizedStr(@"忘记密码")];
        if ([self usePasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv2 updateErrorText:@""];
        } else if ([self useV3PasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv3 updateErrorText:@""];
        } else {
            [self.viewModel updateErrorText:@"" withTypeString:@"" currentVC:self.verifyPasscodeVC];
        }
        
        // 密码锁定实验
        if ([self.viewModel.forgetPwdController isNeedFacePay]) {
            NSString *title = CJConcatStr(CJString(self.confirmResponse.buttonInfo.page_desc), CJPayLocalizedStr(@"，可刷脸支付"));
            [self.viewModel.forgetPwdController pwdLockRecommendFacePay:self.verifyPasscodeVC
                                                                  title:title];
            return;
        }
        
        if ([self.viewModel.forgetPwdController isNeedFaceVerify]) {
            if ([self useV3PasswordVCWithChooseMethod]) {
                [self.verifyPasscodeVCv3 retractKeyBoardView];
            } else if ([self usePasswordVCWithChooseMethod]) {
                [self.verifyPasscodeVCv2 retractKeyBoardView];
            } else {
                [CJKeyboard resignFirstResponder:self.viewModel.inputPasswordView];
            }
            NSString *title = CJConcatStr(CJString(self.confirmResponse.buttonInfo.page_desc), CJPayLocalizedStr(@"，可刷脸验证"));
            [self.viewModel.forgetPwdController pwdLockRecommendFaceVerify:self.verifyPasscodeVC
                                                                     title:title];
            return;
        }
        
        CJPayPasswordLockPopUpViewController *pwdLockVC = [[CJPayPasswordLockPopUpViewController alloc] initWithButtonInfo:self.confirmResponse.buttonInfo];
        @CJWeakify(self)
        @CJWeakify(pwdLockVC)
        pwdLockVC.cancelBlock = ^ {
            @CJStrongify(self)
            @CJStrongify(pwdLockVC)
            [self event:@"wallet_alert_pop_click" params:@{
                @"button_type" : self.confirmResponse.buttonInfo.button_type,
                @"title" : self.confirmResponse.buttonInfo.page_desc,
                @"button_name": CJString(self.confirmResponse.buttonInfo.left_button_desc)
            }];
            
            @CJWeakify(self)
            [pwdLockVC dismissSelfWithCompletionBlock:^{
                @CJStrongify(self)
                [self cancelFromPasswordLock];
            }];
        };
        
        pwdLockVC.forgetPwdBlock = ^{
            @CJStrongify(self)
            @CJStrongify(pwdLockVC)
            [self event:@"wallet_alert_pop_click" params:@{
                @"button_type" : self.confirmResponse.buttonInfo.button_type,
                @"title" : self.confirmResponse.buttonInfo.page_desc,
                @"button_name": CJString(self.confirmResponse.buttonInfo.right_button_desc)
            }];
            [pwdLockVC dismissSelfWithCompletionBlock:^{
                @CJStrongify(self)
                [self.viewModel gotoForgetPwdVCFromVC:[self getPasswordVC]];
            }];
        };
        
        [self event:@"wallet_alert_pop_imp" params:@{
            @"button_type" : self.confirmResponse.buttonInfo.button_type,
            @"title" : self.confirmResponse.buttonInfo.page_desc}];
        [self.manager.homePageVC push:pwdLockVC animated:YES];
        return;
    }
    
    if (!hasUpdatedErrorText && [CJPayBDButtonInfoHandler showErrorTips:response.buttonInfo]) {
        if ([self usePasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv2 updateErrorText:response.buttonInfo.page_desc];
        } else {
            [self.viewModel updateErrorText:response.buttonInfo.page_desc
                             withTypeString:response.forgetPwdInfo.style
                                  currentVC:self.verifyPasscodeVC];
        }
    }
}

- (void)receiveEvent:(CJPayEvent *)event {
    if ([event.name isEqualToString:CJPayVerifyEventSwitchToPassword]) {
        [self p_handleSwitchPasswordEvent:event];
    }
}

// 处理切换为密码后的事件
- (void)p_handleSwitchPasswordEvent:(CJPayEvent *)event {
    id data = event.data;
    if (![data isKindOfClass:NSDictionary.class]) {
        return;
    }
    
    self.event = event;
    NSDictionary *eventDict = (NSDictionary *)data;
    BOOL isSwitchActive = [eventDict cj_boolValueForKey:@"is_active"];

    if (self.event && !isSwitchActive) { // 从指纹/面容进来，并且非主动降级弹toast
        if (self.manager.response.payInfo.verifyDescType == 4) { // 电商场景免密前置特殊处理
            self.viewModel.downgradePasswordTips = self.manager.response.payInfo.localVerifyDownGradeDesc;
        } else {
            NSString *switchReason = [eventDict cj_stringValueForKey:@"switch_reason"];
            if (Check_ValidString(switchReason)) {
                self.viewModel.downgradePasswordTips = switchReason; // 展示降级原因
            }
        }
    } else {
        self.viewModel.downgradePasswordTips = @""; //主动降级不给提示
    }
    // 生物验证降级为密码验证
    if (self.event.verifySourceType == CJPayVerifyTypeBioPayment) {
        if (isSwitchActive) { // 生物验证主动降级，则在验密页仍可切换为生物验证
            NSString *otherVerifyBtnText = CJString([eventDict cj_stringValueForKey:@"other_verify_btn"]);
            self.viewModel.isStillShowingTopRightBioVerifyButton = YES;
            
            if ([self usePasswordVCWithChooseMethod]) {
                self.verifyPasscodeVCv2.bioDowngradeToPassscodeReason = @"";
                if ([eventDict cj_boolValueForKey:@"is_active"]) {
                    self.verifyPasscodeVCv2.bioDowngradeToPassscodeReason = @"用户主动生物降级";
                }
                self.verifyPasscodeVCv2.otherVerifyButton.hidden = NO;
                [self.verifyPasscodeVCv2 updateOtherVerifyType:CJPayPasswordSwitchOtherVerifyTypeBio btnText:otherVerifyBtnText];
            } else {
                [self.viewModel.otherVerifyButton setTitle:otherVerifyBtnText forState:UIControlStateNormal];
                self.viewModel.otherVerifyButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
                self.viewModel.otherVerifyButton.hidden = NO;
            }
        }
    }
}

// 构造密码切换生物验证的verifyEvent
- (CJPayEvent *)p_buildEventSwitchToBio {
    NSDictionary *data = @{
        @"is_active": @(YES),
        @"is_need_loading" : @(YES)
    };
    CJPayEvent *event = [[CJPayEvent alloc] initWithName:CJPayVerifyEventSwitchToBio data:data];
    return event;
}

- (void)showLoading:(BOOL)isLoading {
    if (isLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)p_showPasswordViewController {
    [self createVerifyPasscodeVC];
    [self getPasswordVC].from = self.manager.from;
    [self.manager.homePageVC push:[self getPasswordVC] animated:YES];
}

- (void)p_requestVerifyItem{
    @CJWeakify(self);
    [self showLoading:YES];
    CJPayHalfPageBaseViewController *currentVC = [self getPasswordVC];
    CJ_SafeDelayEnableView(currentVC.view);
    NSDictionary *bizContentParams = @{
        @"process_info": [self.manager.response.processInfo dictionaryValue] ?: @{},
        @"trade_no": CJString(self.manager.response.tradeInfo.tradeNo),
        @"exts":@{@"face_pay_scene" :[self p_getFaceRecogScene]}
    };
    [CJKeyboard prohibitKeyboardShow];
    [CJPayGetVerifyInfoRequest startVerifyInfoRequestWithAppid:self.manager.response.merchant.appId merchantId:self.manager.response.merchant.merchantId bizContentParams:bizContentParams completionBlock:^(NSError * _Nonnull error, CJPayVerifyInfoResponse * _Nonnull response) {
        [CJKeyboard permitKeyboardShow];
        @CJStrongify(self);
        [self showLoading:NO];
        if ([response isSuccess]) {
            [self p_switchOtherVerifyWithResponse:response];
        } else {
            [CJToast toastText:response.msg ?: CJPayNoNetworkMessage inWindow:[self.manager.homePageVC.topVC cj_window]];
        }
    }];
}

- (NSString *)p_getFaceRecogScene {
    NSDictionary *sceneMapDic = @{
        @"挽留弹窗-刷脸支付": @"retain_face_pay",
        @"忘记密码-刷脸支付": @"forget_pwd_face_pay",
        @"密码锁定-刷脸支付": @"pwd_lock_face_pay"
    };
    NSString *scene = [sceneMapDic cj_stringValueForKey:CJString(self.recogFaceSource)];
    return  Check_ValidString(scene) ? scene: @"top_right_face_pay";
}

- (void)p_switchOtherVerifyWithResponse:(CJPayVerifyInfoResponse *)verifyInfoResponse {
    if (![verifyInfoResponse isSuccess]) {
        return;
    }
    
    if ([verifyInfoResponse.verifyType isEqualToString:@"face"]) {
        [self p_verifyByRecogFaceWithVerifyInfo:verifyInfoResponse];
    } else if ([verifyInfoResponse.verifyType isEqualToString:@"member_auth"] ||
               [verifyInfoResponse.verifyType isEqualToString:@"bind_card"]) {
        [self p_verifyAuthWithVerifyInfo:verifyInfoResponse];
    } else {
        CJPayLogAssert(NO, @"建议的验证方式不正确！");
    }
}

- (void)p_verifyAuthWithVerifyInfo:(CJPayVerifyInfoResponse *)verifyInfoResponse {
    @CJWeakify(self);
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[self.manager.homePageVC topVC] toUrl:verifyInfoResponse.jumpUrl
                                                      params:@{
                                                          @"source" : @"sdk",
                                                          @"service" : @"02001110"
                                                      }
                                               closeCallBack:^(id  _Nonnull data) {
        @CJStrongify(self);
        if (data && [data isKindOfClass:NSDictionary.class]) {
            NSDictionary *dataDic = (NSDictionary *)data;
            if ([[dataDic cj_stringValueForKey:@"service"] isEqualToString:@"02001110"]) {
                NSDictionary *tokenData = [dataDic cj_dictionaryValueForKey:@"data"];
                if (tokenData && [tokenData isKindOfClass:NSDictionary.class]) {
                    [self p_confirmPayWithAuthTokenDict:tokenData];
                } else {
                    [CJToast toastText:CJPayNoNetworkMessage inWindow:[self.manager.homePageVC topVC].cj_window];
                }
            }
        }
    }];
}

- (void)p_verifyByRecogFaceWithVerifyInfo:(CJPayVerifyInfoResponse *)verifyInfoResponse {
    if (!self.confirmResponse) {
        self.confirmResponse = [CJPayOrderConfirmResponse new];
    }
    self.confirmResponse.faceVerifyInfo = verifyInfoResponse.faceVerifyInfo;
    CJPayEvent *event = [[CJPayEvent alloc] initWithName:CJPayVerifyEventRecommandVerifyKey data:self.confirmResponse];
    event.verifySource = self.recogFaceSource;
    if (Check_ValidString([self p_guideTypeKey])) {
        event.boolData = self.viewModel.isGuideSelected;
        event.stringData = [self p_guideTypeKey];
    }
    [self.manager wakeSpecificType:CJPayVerifyTypeForgetPwdFaceRecog orderRes:self.manager.response event:event];
}

- (void)p_confirmPayWithAuthTokenDict:(NSDictionary *)authDic {
    NSMutableDictionary *requestParams = [authDic mutableCopy];
    [requestParams cj_setObject:@"9" forKey:@"req_type"];
    if (Check_ValidString([self p_guideTypeKey])) {
        [requestParams cj_setObject:@(self.viewModel.isGuideSelected) forKey:[self p_guideTypeKey]];
    }
    [[self getPasswordVC].view endEditing:YES];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
    [self.manager submitConfimRequest:[requestParams copy] fromVerifyItem:self];
}

- (void)p_showKeybord {
    if ([self useV3PasswordVCWithChooseMethod]) {
        [self.verifyPasscodeVCv3 showLoadingStatus:NO];
    } else if ([self usePasswordVCWithChooseMethod]) {
       [self.verifyPasscodeVCv2 showKeyBoardView];
   } else {
       [self.viewModel.inputPasswordView becomeFirstResponder];
   }
}

- (BOOL)p_lynxRetain:(CJPayRetainUtilModel *)retainUtilModel {
    CJPayRetainInfoV2Config *retainInfoV2Config = retainUtilModel.retainInfoV2Config;
    retainInfoV2Config.hasTridInputPassword = self.isInputPassword;
    retainInfoV2Config.hasInputHistory = retainUtilModel.hasInputHistory;
    retainInfoV2Config.fromScene = @"verify_password";
    retainInfoV2Config.defaultDialogHasVoucher = retainUtilModel.isHasVoucher;
    retainInfoV2Config.selectedPayType = self.viewModel.defaultConfig.subPayType;
    
    @CJWeakify(self)
    @CJWeakify(retainUtilModel)
    retainUtilModel.lynxRetainActionBlock = ^(CJPayLynxRetainEventType eventType, NSDictionary * _Nonnull data) {
        @CJStrongify(self)
        @CJStrongify(retainUtilModel)
        switch (eventType) {
            case CJPayLynxRetainEventTypeOnCancel: //这里是切换支付方式 「暂不取消」按钮
            case CJPayLynxRetainEventTypeOnConfirm: {
                 if ([self usePasswordVCWithChooseMethod]) {
                    [self.verifyPasscodeVCv2 showKeyBoardView];
                } else {
                    [CJKeyboard becomeFirstResponder:self.viewModel.inputPasswordView];
                }
                self.retainUserContinuePaySuccess = YES;
                break;
            }
            case CJPayLynxRetainEventTypeOnCancelAndLeave: { // 这里是「X」
                [self closeAction];
                if ([self usePasswordVCWithChooseMethod]) {
                    [CJKeyboard delayPermitKeyboardShow:0.5];
                }
                break;
            }
            case CJPayLynxRetainEventTypeOnOtherVerify: {
                self.recogFaceSource = @"挽留弹窗-刷脸支付";
                [self p_requestVerifyItem];
                self.retainUserContinuePaySuccess = YES;
                 break;
            }
            case CJPayLynxRetainEventTypeOnChangePayType: {
                NSDictionary *extraData = [data cj_dictionaryValueForKey:@"extra_data"];
                NSString *payType = [extraData cj_stringValueForKey:@"pay_type"];
                NSString *bankCardId = [extraData cj_stringValueForKey:@"bank_card_id"];
                if ([self usePasswordVCWithChooseMethod]) {
                    [self.verifyPasscodeVCv2 changePayMethodWithPayType:[retainUtilModel recommendChannelType:payType]
                                                             bankCardId:bankCardId];
                    [self.verifyPasscodeVCv2 showKeyBoardView];
                } else {
                    CJPayLogInfo(@"验密页V1没有选卡功能展示。")
                }
                break;
            }
            case CJPayLynxRetainEventTypeOnReinputPwd: {
                // 进入其他页面再回来会自动清除密码
                break;
            }
            default:
                break;
        }
    };
    
    return [CJPayRetainUtil couldShowLynxRetainVCWithSourceVC:[self getPasswordVC] retainUtilModel:retainUtilModel completion:nil];
}

- (BOOL)shouldShowRetainVC {
    // 余额充提场景不需要挽留弹窗
    if (!Check_ValidString(self.manager.response.intergratedTradeIdentify)) {
        return NO;
    }
    
    if (self.viewModel.cancelRetainWindow) {
        return NO;
    }
    
    CJPayRetainUtilModel *retainUtilModel = [self buildRetainUtilModel];
    if ([self usePasswordVCWithChooseMethod]) {
        retainUtilModel.hasInputHistory = [[self.verifyPasscodeVCv2 getPasswordContentView] hasInputHistory];
    } else if ([self useV3PasswordVCWithChooseMethod]) {
        retainUtilModel.hasInputHistory = self.verifyPasscodeVCv3.passwordContentView.inputPasswordView.hasInputHistory;
    } else {
        retainUtilModel.hasInputHistory = self.viewModel.inputPasswordView.hasInputHistory;
    }
    retainUtilModel.positionType = CJPayRetainVerifyPage;
    retainUtilModel.isBonusPath = self.hasInputSuccess;
    retainUtilModel.isTransform = self.isInputPassword;
    
    if ([retainUtilModel.retainInfoV2Config isOpenLynxRetain]) {
        return [self p_lynxRetain:retainUtilModel];
    }

    CJPayBDRetainInfoModel *retainInfo = self.manager.response.payInfo.retainInfo;
    // 埋点参数配置
    NSString *topButtonTitle = self.isInputPassword ? CJString(retainInfo.choicePwdCheckWayTitle) : CJString(retainInfo.retainButtonText);
    NSString *bottomButtonTitle = self.isInputPassword ? CJString(retainInfo.retainButtonText) : CJString(retainInfo.choicePwdCheckWayTitle);
    BOOL shouldFeatureRetain = [retainInfo isfeatureRetain] && retainUtilModel.hasInputHistory;
    if (shouldFeatureRetain) {
        topButtonTitle = retainInfo.recommendInfoModel.topRetainButtonText;
        bottomButtonTitle = retainInfo.recommendInfoModel.bottomRetainButtonText;
    }
    
    NSDictionary *dict = @{
        @"main_verify": CJString(topButtonTitle),
        @"other_verify" : CJString(bottomButtonTitle)};
    
    NSMutableDictionary *confirmParam = [@{
        @"button_verify": shouldFeatureRetain ? CJString(bottomButtonTitle) :CJString(retainInfo.retainButtonText)
    } mutableCopy];
    [confirmParam addEntriesFromDictionary:dict];
        
    NSMutableDictionary *otherVerifyParam = [@{
        @"button_verify": shouldFeatureRetain ? CJString(topButtonTitle) : CJString(retainInfo.choicePwdCheckWayTitle)
    } mutableCopy];
    [otherVerifyParam addEntriesFromDictionary:dict];
    retainUtilModel.extraParamForPopUpShow = dict;
    retainUtilModel.extraParamForConfirm = confirmParam;
    retainUtilModel.extraParamForOtherVerify = otherVerifyParam;
    
    @CJWeakify(self)
    retainUtilModel.confirmActionBlock = ^{
        @CJStrongify(self)
        if ([self useV3PasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv3 showLoadingStatus:NO];
        } else if ([self usePasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv2 showKeyBoardView];
        } else {
            [CJKeyboard becomeFirstResponder:self.viewModel.inputPasswordView];
        }
        self.retainUserContinuePaySuccess = YES;
    };
    retainUtilModel.otherVerifyActionBlock = ^{
        @CJStrongify(self)
        self.recogFaceSource = @"挽留弹窗-刷脸支付";
        [self p_requestVerifyItem];
        self.retainUserContinuePaySuccess = YES;
    };
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self)
        [self closeAction];
        if ([self usePasswordVCWithChooseMethod]) {
            [CJKeyboard delayPermitKeyboardShow:0.5];
        }
    };
    
    return [CJPayRetainUtil couldShowRetainVCWithSourceVC:[self getPasswordVC] retainUtilModel:retainUtilModel];
}

- (void)closeAction {
    if (self.manager.isStandardDouPayProcess) {
        @CJWeakify(self)
        [[self getPasswordVC] closeWithAnimation:YES
                                       comletion:^(BOOL isSuccess) {
            @CJStrongify(self)
            [self notifyVerifyCancel];
        }];
    } else {
        NSUInteger closeAnimate = [self usePasswordVCWithChooseMethod] ? 1 : 0;
        [self.manager sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(closeAnimate)];
    }
}

- (NSDictionary *)getLatestCacheData {
    return [self _buildPwdParam];
}

- (NSString *)checkTypeName {
    return @"密码";
}

- (NSString *)checkType {
    return @"0";
}

- (void)cancelFromPasswordLock {
    CJPayStayAlertForOrderModel *model = [CJPayStayAlertForOrderModel new];
    model.tradeNo = self.manager.response.intergratedTradeIdentify;
    model.shouldShow = NO;
    [CJPayKVContext kv_setValue:model forKey:CJPayStayAlertShownKey];
    [self p_showKeybord];
}

// 判断是否是新样式验密页, 唤端追光走这里的逻辑
- (BOOL)useV3PasswordVCWithChooseMethod {
    if (self.manager.pwdPageStyle == CJPayDouPayPwdPageStyleNone) {
        return Check_ValidArray(self.manager.response.payTypeInfo.subPayTypeGroupInfoList);
    }
    
    return self.manager.pwdPageStyle == CJPayDouPayPwdPageStyleV3 && Check_ValidArray(self.manager.response.payTypeInfo.subPayTypeGroupInfoList);
}

- (BOOL)usePasswordVCWithChooseMethod {
    if (self.manager.pwdPageStyle == CJPayDouPayPwdPageStyleNone) {
        return Check_ValidArray(self.manager.response.payInfo.subPayTypeDisplayInfoList);
    }
    
    return self.manager.pwdPageStyle == CJPayDouPayPwdPageStyleV2;
}

- (CJPayHalfPageBaseViewController *)getPasswordVC {
    if ([self useV3PasswordVCWithChooseMethod]) {
        return self.verifyPasscodeVCv3;
    } else if ([self usePasswordVCWithChooseMethod]) {
        return self.verifyPasscodeVCv2;
    } else {
        return self.verifyPasscodeVC;
    }
}
#pragma mark - private method

- (BOOL)p_isNeedShowOpenBioGuide {
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin)) {
        BOOL isBioGuideAvailable = [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBioGuideAvailable];
        return self.manager.response.preBioGuideInfo != nil && isBioGuideAvailable;
    }
    return NO;
}

- (BOOL)p_isNeedShowSkipPwdGuide {
    return self.viewModel.response.skipPwdGuideInfoModel.needGuide;
}

- (NSString *)p_getGuideType {
    NSString *guideType = @"";
    if ([self p_isNeedShowOpenBioGuide]) {
        guideType = [self.manager.response.preBioGuideInfo.guideStyle isEqualToString:@"CHECKBOX"] ? @"checkbox" : @"switch";
    }
    return guideType;
}

- (NSString *)p_getIsFingerprintDefault {
    NSString *isFingerprintDefault = @"";
    if ([self p_isNeedShowOpenBioGuide]) {
        isFingerprintDefault = self.manager.response.preBioGuideInfo.choose ? @"1" : @"0";
    }
    return isFingerprintDefault;
}

- (NSString *)p_getGuideChoose {
    NSString *guideChoose = @"";
    if ([self p_isNeedShowOpenBioGuide] || self.manager.response.skipPwdGuideInfoModel.needGuide) {
        guideChoose = self.viewModel.isGuideSelected ? @"1" : @"0";
    }
    return guideChoose;
}

- (NSString *)p_guideTypeKey {
    if ([self p_isNeedShowSkipPwdGuide]) {
        return @"selected_open_nopwd";
    }
    if ([self p_isNeedShowOpenBioGuide]) {
        return @"selected_bio_pay";
    }
    return @"";
}

- (void)p_setShowKeyBoard:(NSNotification *)aNotification {
    if (![aNotification.object isKindOfClass:NSNumber.class]) {
        return;
    }
    
    BOOL showKeyBoard = ((NSNumber *)aNotification.object).boolValue;
    
    if (showKeyBoard) {
        // 通知验密页唤起键盘
        if ([self useV3PasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv3 switchToPasswordVerifyStyle:YES];
            [[CJPayLoadingManager defaultService] stopLoading];
            [self.verifyPasscodeVCv3 showLoadingStatus:NO];
        } else if ([self usePasswordVCWithChooseMethod]) {
            [self.verifyPasscodeVCv2 showKeyBoardView];
        } else {
            [CJKeyboard becomeFirstResponder:self.viewModel.inputPasswordView];
        }
    }
}

- (void)p_availableShowKeyBoard:(NSNotification *)aNotification {
    if (![aNotification.object isKindOfClass:NSNumber.class]) {
        return;
    }
    BOOL canShowKeyBoard = ((NSNumber *)aNotification.object).boolValue;
}

- (void)event:(NSString *)event params:(NSDictionary *)params {
//    nopwd_disable：是否免密降级
//    nopwd_disable_reason：免密降级原因
//    biology_degrade：是否生物降级
//    biology_degrade_reason：生物降级原因
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    NSDictionary *eventDict = (NSDictionary *)self.event.data;

    BOOL isBioDowngrade = NO;
    NSString *bioDownGradeReason = @"";
    if (self.event.verifySourceType == CJPayVerifyTypeBioPayment) { // 从指纹/面容进来，并且非主动降级弹toast
        isBioDowngrade = ![eventDict btd_boolValueForKey:@"is_active"];
        bioDownGradeReason = [eventDict btd_stringValueForKey:@"switch_reason"];
    }
    [mutableParams addEntriesFromDictionary:@{@"nopwd_disable_reason": CJString(self.manager.response.payInfo.verifyDowngradeReason), @"biology_degrade": isBioDowngrade ? @"1" : @"0", @"biology_degrade_reason": CJString(bioDownGradeReason)}];

    [super event:event params:[mutableParams copy]];
}

@end
