//
//  CJPayBioManager.m
//  BDPay
//
//  Created by 王新华 on 2019/1/21.
//  Modified by 易培淮 on 2020/7/20

#import "CJPayBioManager.h"
#import "TOTPGenerator.h"
#import "CJPaySafeManager.h"
#import "CJPayUIMacro.h"
#import "CJPayTouchIdManager.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPaySafeUtilsHeader.h"
#import "CJPayRequestParam.h"
#import <SAMKeychain/SAMKeychain.h>
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayWebViewUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPayVerifyPasswordRequest.h"
#import "CJPayVerifyItemRecogFaceOnBioPayment.h"
#import "CJPayRetainInfoModel.h"
#import "CJPayPayCancelRetainViewController.h"
#import "CJPayHalfVerifyPasswordNormalViewController.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayPasswordLockPopUpViewController.h"
#import "CJPaySettingsManager.h"
#import "CJPayDeskUtil.h"
#import "CJPayLoadingManager.h"

@implementation CJPayBioManager

+ (BOOL)isValidWithUid:(NSString *)uid
{
    CJPayBioPaymentBaseRequestModel *requestModel = [CJPayBioPaymentBaseRequestModel new];
    requestModel.uid = uid;
    CJPayBioSafeModel *model = [self getSafeModelBy:requestModel];
    return [model isValid];
}

+ (nullable CJPayBioSafeModel *)getSafeModelBy:(CJPayBioPaymentBaseRequestModel *)model{
    NSString *aid = [CJPayRequestParam gAppInfoConfig].appId;
    NSString *tokenStr = [self p_getTokenStrWithUid:model.uid aid:aid];
    if (Check_ValidString(tokenStr)) {
        return [[CJPayBioSafeModel alloc] initWithTokenFile:tokenStr];
    }
    // 火山新老版本兼容
    NSDictionary *backupAidMap = @{
        @"8663": @"1112",
        @"1112": @"8663"
    };
    NSString *backupAid = [backupAidMap cj_stringValueForKey:aid];
    if (!Check_ValidString(aid)) {
        return nil;
    }
    tokenStr = [self p_getTokenStrWithUid:model.uid aid:backupAid];
    return [[CJPayBioSafeModel alloc] initWithTokenFile:tokenStr];
}

+ (nullable NSString *)p_getTokenStrWithUid:(NSString *)uid aid:(NSString *)aid {
    NSString *key = [NSString stringWithFormat:@"CJPay%@_%@TokenStr", CJString(uid), CJString(aid)];
    return [SAMKeychain passwordForService:key account:@"CJPay"];
}

+ (void)saveTokenStrInKey:(NSString *)tokenStr uid:(NSString *)uid{
    if (!tokenStr) {
        return;
    }
    NSString *key = [NSString stringWithFormat:@"CJPay%@_%@TokenStr", CJString(uid), CJString([CJPayRequestParam gAppInfoConfig].appId)];
    [SAMKeychain setPassword:tokenStr forService:key account:@"CJPay"];
}

+ (NSString *)generatorTOTPToken:(NSData *)tokenData dateCorrect:(NSTimeInterval) dateCorrect digits:(NSUInteger) digits period: (NSInteger) period {
    TOTPGenerator *otpGenerator = [[TOTPGenerator alloc] initWithSecret:tokenData algorithm:kOTPGeneratorSHA1Algorithm digits:digits period:period];
    NSDate *date = [NSDate new];
    NSTimeInterval serverTime = [date timeIntervalSince1970] - dateCorrect;
    
    [CJTracker event:@"wallet_rd_generate_otp" params:@{@"server_time": @(serverTime),
                                                        @"current_time": @([date timeIntervalSince1970]),
                                                        @"date_correct": @(dateCorrect)}];
    
    return [otpGenerator generateOTPForDate:[NSDate dateWithTimeIntervalSince1970:serverTime]];
}

+ (void)checkBioPayment:(CJPayBioPaymentBaseRequestModel *)requestModel
             completion:(void(^)(CJPayBioCheckState state))completion {
    if ([[CJPayBioManager getSafeModelBy:requestModel] isValid]) {
        @CJWeakify(self)
        // extraparams 需要有pwd_type 字段 1：指纹支付 2：人脸支付（暂不支持）
        [CJPayBioPaymentCheckRequest startWithModel:requestModel
                                      withExtraParams:@{@"pwd_type": CJString([self getSupportPwdType])}
                                           completion:^(NSError * _Nonnull error, CJPayBioPaymentCheckResponse * _Nonnull response) {
            @CJStrongify(self)
            if ([response.code isEqualToString:@"MP000000"]) {
                if ( response.fingerPrintPay || response.faceIdPay ) {
                    CJ_CALL_BLOCK(completion, CJPayBioCheckStateOpen);
                } else {
                    CJ_CALL_BLOCK(completion, CJPayBioCheckStateClose);
                }
            } else if ([response.code isEqualToString:@"MT2002"]) {
                [self saveTokenStrInKey:@"" uid:requestModel.uid];
                CJ_CALL_BLOCK(completion, CJPayBioCheckStateClose);
            } else {
                CJ_CALL_BLOCK(completion, CJPayBioCheckStateUnknown);
            }
        }];
    } else {
        CJ_CALL_BLOCK(completion, CJPayBioCheckStateWithoutToken);
    }
}

+ (void)openBioPaymentOnVC:(UIViewController *)vc
         withBioRequestDic:(NSDictionary *)requestDic
           completionBlock:(void (^)(BOOL, BOOL))completionBlock {
    
    __block BOOL isOpenGuide = NO;
    __block BOOL needDismissPage = NO;
    if (![CJPayTouchIdManager currentOriTouchIdData]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([CJPayTouchIdManager isErrorBiometryLockout]) {
                if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger) {
                    [CJToast toastText:CJPayLocalizedStr(@"Touch ID已锁定") inWindow:vc.cj_window];
                } else {
                    [CJToast toastText:CJPayLocalizedStr(@"Face ID已锁定") inWindow:vc.cj_window];
                }
            } else {
                NSString *msg = @"";
                if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger) {
                    msg = CJPayLocalizedStr(@"设备中没有你的指纹信息，可以到「设置-Touch ID与密码」中录入指纹信息");
                } else {
                    msg = CJPayLocalizedStr(@"设备中没有你的面容信息，可以到「设置-面容ID与密码」中录入面容信息");
                }
                [CJToast toastText:msg inWindow:vc.cj_window];
            }
        });
        CJ_CALL_BLOCK(completionBlock, isOpenGuide, needDismissPage);
    } else { // 验证
        NSString *localizedReason = CJPayLocalizedStr(@"请验证已有的指纹，用于支付");
       
        if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace) {
            localizedReason = CJPayLocalizedStr(@"面容验证失败");
        }
        
        @CJWeakify(vc)
        [CJPayTouchIdManager showTouchIdWithLocalizedReason:localizedReason
                                             falldBackTitle:@""
                                              fallBackBlock:^{}
                                                resultBlock:^(BOOL useable, BOOL success, NSError * _Nonnull error, NSInteger policy) {
            if (!success) {
                // 验证失败
                [CJToast toastText:CJPayLocalizedStr(@"开启失败，请重试") inWindow:vc.cj_window];
                needDismissPage = YES;
                CJ_CALL_BLOCK(completionBlock, isOpenGuide, needDismissPage);
            } else {
                // 指纹或面容验证成功
                @CJStrongify(vc)
                CJPayBaseViewController <CJPayBaseLoadingProtocol>*loadingVC;
                if ([vc conformsToProtocol:@protocol(CJPayBaseLoadingProtocol)]) {
                    loadingVC = (CJPayBaseViewController <CJPayBaseLoadingProtocol >*)vc;
                }
                if (loadingVC) {
                    @CJStartLoading(loadingVC)
                }
                
                NSString *lastPwd = [requestDic cj_stringValueForKey:@"lastPwd"];
                NSMutableDictionary *bioRequestDic = [requestDic mutableCopy];
                [bioRequestDic removeObjectForKey:@"lastPwd"];
                NSDictionary *bioRequestModel = [bioRequestDic copy];
                NSDictionary *pwdDic = [self buildPwdDicWithModel:bioRequestModel lastPWD:lastPwd];
                
                // 请求开通生物识别
                [CJPayCashdeskEnableBioPayRequest startWithModel:bioRequestModel
                                       withExtraParams:pwdDic
                                            completion:^(NSError * _Nonnull error, CJPayCashdeskEnableBioPayResponse * _Nonnull response, BOOL result) {
                    @CJStrongify(vc)
                    if (loadingVC) {
                        @CJStopLoading(loadingVC)
                    }
                    
                    if (result) {
                        NSString *msg = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? CJPayLocalizedStr(@"指纹支付已开通") : CJPayLocalizedStr(@"面容支付已开通");
                        [CJToast toastText:msg code:@"" duration:1 inWindow:vc.cj_window];
                        isOpenGuide = YES;
                        needDismissPage = YES;
                    } else {
                        if (Check_ValidString(response.msg)) {
                            [CJToast toastText:response.msg inWindow:vc.cj_window];
                        }
                    }
                    CJ_CALL_BLOCK(completionBlock, isOpenGuide, needDismissPage);
                }];
            }
        }];
    }
}

+ (void)openBioPayment:(CJPayBioPaymentBaseRequestModel *)requestModel
               findUrl:(NSString *)findUrl
            completion:(void(^)(CJPayBioOpenState state))completion {
    CJPayVerifyPasswordViewModel *viewModel = [CJPayVerifyPasswordViewModel new];
    CJPayBDCreateOrderResponse *response = [CJPayBDCreateOrderResponse new];
    response.userInfo = [CJPayUserInfo new];
    response.userInfo.findPwdURL = findUrl;
    response.merchant = [CJPayMerchantInfo new];
    response.merchant.appId = requestModel.appId;
    response.merchant.merchantId = requestModel.merchantId;
    viewModel.response = response;
    [viewModel setShowKeyBoardSafeGuard:YES];
    CJPayHalfVerifyPasswordNormalViewController *passwordVC = [[CJPayHalfVerifyPasswordNormalViewController alloc] initWithAnimationType:HalfVCEntranceTypeFromBottom viewModel:viewModel];
    [passwordVC useCloseBackBtn];
    
    NSString *verifyType = @"指纹验证";
    if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace) {
        verifyType = @"面容验证";
    }
    passwordVC.from = verifyType;
    @CJWeakify(self)
    @CJWeakify(passwordVC)
    @CJWeakify(viewModel)
    
    void (^closePageBlock)(CJPayBioOpenState state) = ^(CJPayBioOpenState state) {
        @CJStrongify(viewModel)
        @CJStrongify(passwordVC)
        [[CJPayLoadingManager defaultService] stopLoading];
        [viewModel.inputPasswordView resignFirstResponder];
        [passwordVC close];
        CJ_CALL_BLOCK(completion, state);
    };
    
    //用户主动点击左上角x退出
    passwordVC.cjBackBlock = ^{
        @CJStrongify(passwordVC)
        @CJStrongify(viewModel)
        
        [self trackEvent:@"wallet_modify_password_click" params:@{@"button_name":@"关闭"} requestModel:requestModel];
        
        //挽留弹窗
        BOOL isFacePay = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace;
        CJPayRetainInfoModel *retainInfoModel = [CJPayRetainInfoModel new];
        retainInfoModel.title = isFacePay ? CJPayLocalizedStr(@"确认放弃开通面容支付？") : CJPayLocalizedStr(@"确认放弃开通指纹支付？");
        retainInfoModel.voucherContent = isFacePay ? CJPayLocalizedStr(@"开通面容支付，安全又便捷") : CJPayLocalizedStr(@"开通指纹支付，安全又便捷");
        retainInfoModel.topButtonText = @"继续开通";
        retainInfoModel.titleColor = [UIColor cj_161823WithAlpha:0.75];
        retainInfoModel.closeCompletionBlock = ^{
            [self trackEvent:@"wallet_modify_password_keep_pop_click" params:@{
                @"button_name":@"0",
                @"is_discount":@"0",
                @"main_verify":@"继续开通",
                @"other_verify":@""
            } requestModel:requestModel];
            CJ_CALL_BLOCK(closePageBlock, CJPayBioStateBioCheckFailure);
        };
        retainInfoModel.topButtonBlock = ^{
            [self trackEvent:@"wallet_modify_password_keep_pop_click" params:@{
                @"button_name":@"1",
                @"is_discount":@"0",
                @"main_verify":@"继续开通",
                @"other_verify":@""
            } requestModel:requestModel];
        };
        
        CJPayPayCancelRetainViewController *popupVC = [[CJPayPayCancelRetainViewController alloc] initWithRetainInfoModel:retainInfoModel];
        
        [passwordVC.navigationController pushViewController:popupVC animated:YES];
        
        [self trackEvent:@"wallet_modify_password_keep_pop_show" params:@{
            @"is_discount":@"0",
            @"main_verify":@"继续开通",
            @"other_verify":@""
        } requestModel:requestModel];
    };
    
    //新流程免验直接开通
    if ([self p_isSkipPWDWithVerifyType:requestModel.verifyType]) {
        [self p_verifyTouchIDAndEnableBioPaymentWithPassword:@"" passwordVC:passwordVC requestModel:requestModel viewModel:viewModel closePageBlock:closePageBlock];
        return;
    }
    
    //新流程活体验证
    if ([self p_isSupportRecogFaceWithVerifyType:requestModel.verifyType]) {
        response.confirmResponse = [CJPayOrderConfirmResponse new];
        response.confirmResponse.faceVerifyInfo = requestModel.verifyInfo;
        viewModel.bioVerifyItem = [CJPayVerifyItemRecogFaceOnBioPayment new];
        viewModel.isFromOpenBioPayVerify = YES;
        viewModel.otherVerifyPayBlock = ^(NSString *verifyType) {
            @CJStrongify(viewModel)
            @CJStrongify(self)
            @CJStrongify(passwordVC)
            viewModel.bioVerifyItem.verifySource = @"生物识别开通-刷脸验证";
            viewModel.bioVerifyItem.faceRecogCompletion = ^(BOOL isSuccess) {
                @CJStrongify(viewModel)
                @CJStrongify(self)
                @CJStrongify(passwordVC)
                if (isSuccess) {
                    [viewModel.inputPasswordView resignFirstResponder];
                    [self p_enableBioPaymentWithPassword:@"" passwordVC:passwordVC requestModel:requestModel viewModel:viewModel closePageBlock:closePageBlock];
                }
            };
            [viewModel.inputPasswordView resignFirstResponder];
            [viewModel.bioVerifyItem tryFaceRecogWithResponse:response requestModel:requestModel];
            
            [self trackEvent:@"wallet_modify_password_click" params:@{@"button_name":@"刷脸支付"} requestModel:requestModel];
        };
    }
    
    viewModel.forgetPasswordBtnBlock = ^{
        @CJStrongify(passwordVC)
        @CJStrongify(viewModel)
        [self trackEvent:@"wallet_modify_password_click" params:@{@"button_name":@"忘记密码"} requestModel:requestModel];
        [viewModel gotoForgetPwdVCFromVC:passwordVC];
    };
    
    viewModel.inputCompleteBlock = ^(NSString * _Nonnull password) {
        @CJStrongify(passwordVC)
        @CJStrongify(viewModel)
        @CJStrongify(self)
        
        if (!password || password.length < 1) {
            return;
        }
        
        [self trackEvent:@"wallet_modify_password_input" params:nil requestModel:requestModel];
        
        //新流程要先通过verifyPasscode接口验密，验密通过后再验面容和调用enableBioPayment接口
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:CJPayLocalizedStr(@"抖音支付")];
        NSDictionary *params = @{
            @"app_id" : CJString(requestModel.appId),
            @"merchant_id" : CJString(requestModel.merchantId),
            @"password" : [CJPaySafeUtil encryptPWD:password],
            @"member_biz_order_no" : CJString(requestModel.memberBizOrderNo)
        };
        [CJPayVerifyPasswordRequest startWithParams:params completion:^(NSError * _Nonnull error, CJPayVerifyPassCodeResponse * _Nonnull response) {
            @CJStrongify(viewModel)
            @CJStrongify(passwordVC)
            @CJStrongify(self)
            [self trackEvent:@"wallet_modify_password_result" params:@{
                @"result": [response isSuccess] ? @"1" : @"0",
                @"error_code": CJString(response.code),
                @"error_message": CJString(response.msg),
            } requestModel:requestModel];
            
            if ([response isSuccess]) {
                [self p_verifyTouchIDAndEnableBioPaymentWithPassword:password passwordVC:passwordVC requestModel:requestModel viewModel:viewModel closePageBlock:closePageBlock];
                return;
            } else if ([response.code isEqualToString:@"MP020403"]) {
                [[CJPayLoadingManager defaultService] stopLoading];

                //密码错误
                [viewModel.inputPasswordView clearInput];

                [viewModel updateErrorText:response.buttonInfo.page_desc withTypeString:@"" currentVC:passwordVC];
            } else if (response.buttonInfo) {
                [[CJPayLoadingManager defaultService] stopLoading];

                CJPayPasswordLockPopUpViewController *pwdLockVC;
                pwdLockVC = [[CJPayPasswordLockPopUpViewController alloc] initWithButtonInfo:response.buttonInfo];
                @CJWeakify(pwdLockVC)
                pwdLockVC.cancelBlock = ^ {
                    @CJStrongify(pwdLockVC)
                    [pwdLockVC dismissSelfWithCompletionBlock:^{
                        CJ_CALL_BLOCK(closePageBlock, CJPayBioStateBioCheckFailure);
                    }];
                };

                pwdLockVC.forgetPwdBlock = ^{
                    @CJStrongify(pwdLockVC)
                    @CJStrongify(passwordVC)
                    [pwdLockVC dismissSelfWithCompletionBlock:^{
                        @CJStrongify(passwordVC)
                        CJPayMigrateH5PageToLynx *model = [CJPaySettingsManager shared].currentSettings.migrateH5PageToLynx;
                        if (Check_ValidString(model.forgetpassSchema)) {
                            NSMutableDictionary *params = [NSMutableDictionary dictionary];
                            [params cj_setObject:requestModel.merchantId forKey:@"merchant_id"];
                            [params cj_setObject:requestModel.appId forKey:@"app_id"];
                            [CJPayDeskUtil openLynxPageBySchema:[CJPayCommonUtil appendParamsToUrl:model.forgetpassSchema
                                                                                        params:params]
                                               completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {}];
                            return;
                        }
                        NSString *url = [CJPayBDButtonInfoHandler findPwdUrlWithAppID:requestModel.appId
                                                                         merchantID:requestModel.merchantId
                                                                             smchID:requestModel.smchId];
                        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:passwordVC toUrl:url];
                    }];
                };
                [passwordVC.navigationController pushViewController:pwdLockVC animated:YES];
            } else {
                [[CJPayLoadingManager defaultService] stopLoading];

                [viewModel reset];
                [CJToast toastText:response.msg inWindow:passwordVC.cj_window];
            }
        }];
        return;
    };
    
    passwordVC.animationType = HalfVCEntranceTypeFromBottom;
    CJPayNavigationController *navigationVC = [CJPayNavigationController instanceForRootVC:passwordVC];
    navigationVC.view.backgroundColor = [UIColor cj_maskColor];
    navigationVC.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet : UIModalPresentationOverFullScreen;
    [self trackEvent:@"wallet_modify_password_imp" params:nil requestModel:requestModel];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIViewController cj_foundTopViewControllerFrom:requestModel.referVC] presentViewController:navigationVC animated:CJ_Pad completion:nil];
    });
}

+ (void)closeBioPayment:(CJPayBioPaymentBaseRequestModel *)requestModel
             completion:(void(^)(CJPayBioCloseState state))completion {
    CJPayBioSafeModel *safeModel = [self getSafeModelBy:requestModel];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSString *encryptSerialNumStr = [CJPaySafeUtil encryptField:safeModel.serialNum];
    [dic cj_setObject:encryptSerialNumStr forKey:@"serial_num"];
    [dic cj_setObject:@(safeModel.pwdType).stringValue forKey:@"pwd_type"];
    
    if (!Check_ValidString(encryptSerialNumStr)) {
        [CJTracker event:@"wallet_rd_generate_snum_fail"
                  params:@{@"uid": CJString(requestModel.uid),
                           @"serial_num": CJString(safeModel.serialNum),
                           @"app_id":CJString([CJPayRequestParam gAppInfoConfig].appId)}];
    }

    @CJWeakify(self)
    [CJPayBioPaymentCloseRequest startWithModel:requestModel
                                  withExtraParams:dic
                                       completion:^(NSError * _Nonnull error, CJPayBioPaymentCloseResponse * _Nonnull response) {
        @CJStrongify(self)
        if ([response.code isEqualToString:@"MP000000"] || [response.code isEqualToString:@"MT2002"]) {
            [self saveTokenStrInKey:@"" uid:requestModel.uid];
            CJ_CALL_BLOCK(completion, CJPayBioCloseStateSuccess);
        } else {
            CJ_CALL_BLOCK(completion, CJPayBioCloseStateFailure);
        }
    }];
}

+ (NSString *)getSupportPwdType {
    switch ([CJPayTouchIdManager currentSupportBiopaymentType]) {
        case CJPayBioPaymentTypeFinger:
            return @"1";
        case CJPayBioPaymentTypeFace:
            return @"2";
        case CJPayBioPaymentTypeNone:
            return @"";
    }
}

+ (void)p_verifyTouchIDAndEnableBioPaymentWithPassword:(NSString * _Nonnull)password
                                          passwordVC:(CJPayHalfVerifyPasswordNormalViewController *)passwordVC
                                        requestModel:(CJPayBioPaymentBaseRequestModel *)requestModel
                                           viewModel:(CJPayVerifyPasswordViewModel *)viewModel
                                      closePageBlock:(void(^)(CJPayBioOpenState state))closePageBlock {
    @CJWeakify(self)
    @CJWeakify(viewModel)
    @CJWeakify(passwordVC)
    [[self class] verifyTouchID:^(BOOL isSuccess) {
        @CJStrongify(self)
        @CJStrongify(viewModel)
        @CJStrongify(passwordVC)
        [self trackEvent:@"wallet_cashier_fingerprint_enable_result" params:@{@"result": isSuccess ? @"成功" : @"失败"} requestModel:requestModel];
        if (isSuccess) {
            [self p_enableBioPaymentWithPassword:password passwordVC:passwordVC requestModel:requestModel viewModel:viewModel closePageBlock:closePageBlock];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //验证失败回调前端开启失败
                CJ_CALL_BLOCK(closePageBlock, CJPayBioStateBioCheckFailure);
            });
        }
    }];
}

+ (void)p_enableBioPaymentWithPassword:(NSString * _Nonnull)password
                          passwordVC:(CJPayHalfVerifyPasswordNormalViewController *)passwordVC
                        requestModel:(CJPayBioPaymentBaseRequestModel *)requestModel
                           viewModel:(CJPayVerifyPasswordViewModel *)viewModel
                      closePageBlock:(void(^)(CJPayBioOpenState state))closePageBlock {
    @CJWeakify(self)
    @CJWeakify(passwordVC)
    @CJWeakify(viewModel)
    BOOL isNeedLoading = ![self p_isSkipPWDWithVerifyType:requestModel.verifyType];//免密情况下不展示此loading
    if(isNeedLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:CJPayLocalizedStr(@"输入密码并开通")];
    }
    NSMutableDictionary *pwdDic = [NSMutableDictionary dictionary];
    NSString *safePassword;
    
    id<CJPayEngimaProtocol> engimaEngine = [CJPaySafeManager buildEngimaEngine:@""];
    if ([self p_isVerifyPWDOnNewProcessWithVerifyType:requestModel.verifyType password:password]) {
        //在新流程的活体or免验证流程中
        safePassword = [CJPaySafeUtil objEncryptPWD:[NSString stringWithFormat:@"%.0lf",[[NSDate date]timeIntervalSince1970]] engimaEngine:engimaEngine];
        [pwdDic cj_setObject:safePassword forKey:@"key"];
        [pwdDic cj_setObject:@"" forKey:@"mobile_pwd"];
    } else {
        //在验密流程里
        safePassword = [CJPaySafeUtil objEncryptPWD:password engimaEngine:engimaEngine];
        [pwdDic cj_setObject:safePassword forKey:@"mobile_pwd"];
    }
    [pwdDic cj_setObject:[CJPayBioManager getSupportPwdType] forKey:@"pwd_type"];
    
    [CJPayMemberEnableBioPayRequest startWithModel:requestModel
                             withExtraParams:pwdDic
                                  completion:^(NSError * _Nonnull error, CJPayMemberEnableBioPayResponse * _Nonnull response) {
        @CJStrongify(self)
        @CJStrongify(passwordVC)
        @CJStrongify(viewModel)
        
        //密码验证的情况 埋点
        if (![password isEqualToString:@""]) {
            [self trackEvent:@"wallet_modify_password_result" params:@{
                @"result": [response isSuccess] ? @"1" : @"0",
                @"error_code": CJString(response.code),
                @"error_message": CJString(response.msg),
            } requestModel:requestModel];
        }
        if(isNeedLoading) {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
        NSString *tokenStr = [CJPaySafeUtil objDecryptContentFromH5:CJString(response.tokenFileStr) engimaEngine:engimaEngine];
        CJPayBioSafeModel *model = [[CJPayBioSafeModel alloc] initWithTokenFile:tokenStr];
        
        if ([model isValid]) {
            [self saveTokenStrInKey:tokenStr uid:requestModel.uid];
            CJ_CALL_BLOCK(closePageBlock, CJPayBioStateBioCheckSuccess);
            return ;
        } else if ([response.code isEqualToString:@"MT1001"] || [response.code isEqualToString:@"MT1002"]) {
            [viewModel.inputPasswordView clearInput];
            [viewModel updateErrorText:response.msg withTypeString:@"" currentVC:passwordVC];
        } else if ([response.code isEqualToString:@"OM2001"]) {
            // 触发风控逻辑，关闭输入密码 的页面
            CJ_CALL_BLOCK(closePageBlock, CJPayBioStateBioCheckFailure);
        } else if (response.buttonInfo) {
            CJPayPasswordLockPopUpViewController *pwdLockVC;
            pwdLockVC = [[CJPayPasswordLockPopUpViewController alloc] initWithButtonInfo:response.buttonInfo];
            @CJWeakify(pwdLockVC)
            pwdLockVC.cancelBlock = ^ {
                @CJStrongify(pwdLockVC)
                [pwdLockVC dismissSelfWithCompletionBlock:^{
                    CJ_CALL_BLOCK(closePageBlock, CJPayBioStateBioCheckFailure);
                }];
            };
            
            pwdLockVC.forgetPwdBlock = ^{
                @CJStrongify(pwdLockVC)
                @CJStrongify(passwordVC)
                [pwdLockVC dismissSelfWithCompletionBlock:^{
                    @CJStrongify(passwordVC)
                    CJPayMigrateH5PageToLynx *model = [CJPaySettingsManager shared].currentSettings.migrateH5PageToLynx;
                    if (Check_ValidString(model.forgetpassSchema)) {
                        NSMutableDictionary *params = [NSMutableDictionary dictionary];
                        [params cj_setObject:requestModel.merchantId forKey:@"merchant_id"];
                        [params cj_setObject:requestModel.appId forKey:@"app_id"];
                        [CJPayDeskUtil openLynxPageBySchema:[CJPayCommonUtil appendParamsToUrl:model.forgetpassSchema
                                                                                    params:params]
                                           completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {}];
                        return;
                    }
                    
                    NSString *url = [CJPayBDButtonInfoHandler findPwdUrlWithAppID:requestModel.appId
                                                                     merchantID:requestModel.merchantId
                                                                         smchID:requestModel.smchId];
                    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:passwordVC toUrl:url];
                }];
            };
            [passwordVC.navigationController pushViewController:pwdLockVC animated:YES];
        } else {
            [viewModel reset];
            [CJToast toastText:response.msg inWindow:passwordVC.cj_window];
        }
        if ([response.code isEqualToString:@"OM2001"]) {
            // 触发风控逻辑，关闭输入密码 的页面
            CJ_CALL_BLOCK(closePageBlock, CJPayBioStateBioCheckFailure);
        }
    }];
}

+ (void)verifyTouchID:(void(^)(BOOL))completion {
    NSString *localizedReason = CJPayLocalizedStr(@"请验证已有的指纹，用于支付");
    
    if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace) {
        localizedReason = CJPayLocalizedStr(@"面容验证失败");
    }
    
    [CJPayTouchIdManager showTouchIdWithLocalizedReason:localizedReason
                                         falldBackTitle:@""
                                          fallBackBlock:^{}
                                            resultBlock:^(BOOL useable, BOOL success, NSError * _Nonnull error, NSInteger policy) {
        if (success) {
            // 指纹或面容验证成功,则继续
            CJ_CALL_BLOCK(completion,YES);
        } else {
            // 验证失败
            CJ_CALL_BLOCK(completion,NO);
        }
    }];
}

+ (NSDictionary *)buildPwdDicWithModel:(NSDictionary *)requestModel lastPWD:(NSString *)lastPWD {
    NSMutableDictionary *pwdDic = [NSMutableDictionary dictionary];
    NSMutableDictionary *extDic = [NSMutableDictionary dictionary];
    NSString *safePwd = [CJPaySafeUtil encryptPWD:lastPWD];
    [pwdDic cj_setObject:CJString(safePwd) forKey:@"mobile_pwd"];
    [pwdDic cj_setObject:[CJPayBioManager getSupportPwdType] forKey:@"pwd_type"];
    [extDic cj_setObject:[requestModel cj_objectForKey:@"trade_no"] forKey:@"trade_no"];
    [pwdDic cj_setObject:extDic forKey:@"exts"];
    [pwdDic cj_setObject:[requestModel cj_objectForKey:@"process_info"] forKey:@"process_info"];
    
    return pwdDic;
}

+ (void)trackEvent:(NSString *)event params:(NSDictionary *)params requestModel:(CJPayBioPaymentBaseRequestModel *)requestModel {
    NSMutableDictionary *trackParamDic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"app_id":CJString(requestModel.appId),
        @"merchant_id":CJString(requestModel.merchantId),
        @"is_chaselight":@"1",
        @"modify_source":CJString(requestModel.source),
    }];
    
    if (params) {
        [trackParamDic addEntriesFromDictionary:params];
    }
    
    [CJTracker event:event params:trackParamDic];
}

+ (BOOL)p_isSkipPWDWithVerifyType:(NSString *)verifyType {
    return [verifyType isEqualToString:@"skip"];
}

+ (BOOL)p_isSupportRecogFaceWithVerifyType:(NSString *)verifyType {
    return [verifyType isEqualToString:@"livepwd"];
}

+ (BOOL)p_isVerifyPWDOnNewProcessWithVerifyType:(NSString *)verifyType password:(NSString *)password{
    return ([verifyType isEqualToString:@"skip"] || [verifyType isEqualToString:@"livepwd"]) && [password isEqualToString:@""];
}


@end
