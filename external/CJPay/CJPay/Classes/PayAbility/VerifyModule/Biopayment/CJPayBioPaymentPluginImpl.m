//
//  CJPayBioPaymentPluginImpl.m
//  Pods
//
//  Created by 王新华 on 2021/9/8.
//

#import "CJPayBioPaymentPluginImpl.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"
#import "CJPayBioManager.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayBioGuideViewController.h"
#import "CJPayRequestParam.h"
#import "CJPayTouchIdManager.h"
#import "NSString+CJPay.h"
#import "CJPayEnvManager.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayBioPaymentTimeCorrectRequest.h"
#import "UIViewController+CJTransition.h"
#import "CJPayBioGuideFigureViewController.h"
#import "CJPayResultPageGuideInfoModel.h"
#import "CJPayBioSystemSettingGuideViewController.h"
#import "CJPayDeskServiceHeader.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "CJPayCashdeskEnableBioPayRequest.h"
#import "CJPayUIMacro.h"
#import "CJPaySafeManager.h"

@interface CJPayBioPaymentPluginImpl()<CJPayBioPaymentPlugin, CJPayRequestParamInjectDataProtocol>

@end

@implementation CJPayBioPaymentPluginImpl

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassToPtocol(self, CJPayBioPaymentPlugin)
    [CJPayRequestParam injectDataProtocol:self];
});

- (void)correctLocalTime {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CJPayBioPaymentTimeCorrectRequest checkServerTimeStamp];
    });
    
}

- (BOOL)pluginHasInstalled {
    return YES;
}

- (NSString *)biometricParams {
    NSData *bioParamData = [CJPayTouchIdManager currentOriTouchIdData];
    return [bioParamData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (BOOL)isValidForCurrentUid:(NSString *)uid {
    return [CJPayBioManager isValidWithUid:uid];
}

- (BOOL)hasValidToken {
    return [CJPayTouchIdManager currentOriTouchIdData].length > 0;
}

// 判断是否可展示生物识别引导（App有无生物识别权限、是否录入了生物识别信息且可用、生物识别信息是否变更过）
- (BOOL)isBioGuideAvailable {
    return ![CJPayTouchIdManager isBiometryNotAvailable] && ![CJPayTouchIdManager isTouchIDNotEnrolled] && ![CJPayTouchIdManager touchIdInfoDidChange];
}

- (BOOL)isBiometryNotAvailable {
    return [CJPayTouchIdManager isBiometryNotAvailable];
}

-  (BOOL)isBiometryLockout {
    return [CJPayTouchIdManager isErrorBiometryLockout];
}

- (NSString *)bioType {
    CJPayBioPaymentType type = [CJPayTouchIdManager currentSupportBiopaymentType];
    switch (type) {
        case CJPayBioPaymentTypeNone:
            return @"0";
        case CJPayBioPaymentTypeFinger:
            return @"1";
        case CJPayBioPaymentTypeFace:
            return @"2";
    }
}

- (void)openBioPay:(NSDictionary *)requestModel withExtraParams:(NSDictionary *)extraParams completion:(void (^)(NSError * _Nonnull, BOOL))completion {
    [CJPayCashdeskEnableBioPayRequest startWithModel:requestModel withExtraParams:extraParams completion:^(NSError * _Nonnull error, CJPayCashdeskEnableBioPayResponse * _Nonnull response, BOOL result) {
        CJ_CALL_BLOCK(completion, error, result);
    }];
}

- (void)asyncOpenBioPayWithResponse:(CJPayBDCreateOrderResponse *)response
                            lastPWD:(NSString *)lastPWD {
    NSMutableDictionary *requestModel = [NSMutableDictionary new];
    [requestModel cj_setObject:response.merchant.appId forKey:@"app_id"];
    [requestModel cj_setObject:response.merchant.merchantId forKey:@"merchant_id"];
    [requestModel cj_setObject:response.userInfo.uid forKey:@"uid"];
    [requestModel cj_setObject:response.tradeInfo.tradeNo forKey:@"trade_no"];
    [requestModel cj_setObject:[response.processInfo dictionaryValue] forKey:@"process_info"];
    [requestModel cj_setObject:[CJPaySafeManager buildEngimaEngine:@""] forKey:@"engimaEngine"];
    NSDictionary *pwdDic = [CJPayBioManager buildPwdDicWithModel:requestModel
                                                         lastPWD:CJString(lastPWD)];
    [CJPayCashdeskEnableBioPayRequest startWithModel:requestModel
                                     withExtraParams:pwdDic
                                          completion:^(NSError * _Nonnull error, CJPayCashdeskEnableBioPayResponse * _Nonnull response, BOOL result) {
        if (result) {
            NSString *msg = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"指纹支付已开通" : @"面容支付已开通";
            [CJToast toastText:msg code:@"" duration:1 inWindow:[UIViewController cj_topViewController].cj_window];
        } else {
            NSString *msg = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"指纹支付开通失败" : @"面容支付开通失败";
            [CJToast toastText:msg code:@"" duration:1 inWindow:[UIViewController cj_topViewController].cj_window];
        }
    }];
}

- (BOOL)isBioPayAvailableWithResponse:(CJPayBDCreateOrderResponse *)response {
    if ([CJPayTouchIdManager isBiometryNotAvailable] || [CJPayTouchIdManager isTouchIDNotEnrolled] || [CJPayTouchIdManager touchIdInfoDidChange]) {
        return NO;
    }
    
    CJPayBioPaymentBaseRequestModel *requestModel = [CJPayBioPaymentBaseRequestModel new];
    requestModel.uid = response.userInfo.uid;
    requestModel.appId = response.merchant.appId;
    requestModel.merchantId = response.merchant.merchantId;
    CJPayBioSafeModel *model = [CJPayBioManager getSafeModelBy:requestModel];
    
    // 当前的token文件无效，或指纹无信息
    if (![model isValid] || ![CJPayTouchIdManager currentOriTouchIdData] || [CJPayTouchIdManager isErrorBiometryLockout]) {
        return NO;
    }
    return YES;
}

- (CJPayBioGuideViewController *)p_bioGuideWithResponse:(CJPayBDOrderResultResponse *)response verifyManager:(CJPayBaseVerifyManager *)verifyManager completion:(void (^)(void))completion {
    if (!response.bioPaymentInfo || !verifyManager) {
        @CJStopLoading(verifyManager)
        CJ_CALL_BLOCK(completion);
        return nil;
    }
    NSDictionary *params = @{
        @"verify_manager": verifyManager, // 已经判空
        @"use_close_btn": @(YES),
        @"payment_info": response.bioPaymentInfo
    };
    
    return [CJPayBioGuideViewController createWithWithParams:[params copy] completionBlock:completion];
}

- (CJPayBioGuideFigureViewController *)p_bioGuideFigureWithResponse:(CJPayBDOrderResultResponse *)response verifyManager:(CJPayBaseVerifyManager *)verifyManager completion:(void (^)(void))completion {
    if (!response.resultPageGuideInfoModel || !verifyManager) {
        @CJStopLoading(verifyManager)
        CJ_CALL_BLOCK(completion);
        return nil;
    }
    NSDictionary *params = @{
        @"verify_manager": verifyManager, // 已经判空
        @"use_close_btn": @(YES),
    };
    
    return [CJPayBioGuideFigureViewController createWithWithParams:[params copy] completionBlock:completion];
}

- (void)showGuidePageVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager completionBlock:(void (^)(void))completion {    
    [self showGuidePageVCWithVerifyManager:verifyManager extParams:nil completionBlock:completion];
}

- (void)showGuidePageVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager
                               extParams:(NSDictionary *)extParams
                         completionBlock:(void (^)(void))completion {
    
    // 判断是否有生物识别权限 && 生物数据是否存在且可用
    if (![self isBioGuideAvailable]) {
        CJ_CALL_BLOCK(completion);
        return;
    }
    
    CJPayBDOrderResultResponse *orderResultResponse = verifyManager.resResponse;
    CJPayHalfPageBaseViewController *bioGuideVC;

    if ([orderResultResponse.resultPageGuideInfoModel.guideType isEqualToString:@"bio_guide"]) { //支付后引导开通生物识别 插图版
        bioGuideVC = [self p_bioGuideFigureWithResponse:orderResultResponse verifyManager:verifyManager completion:completion];
    } else if (orderResultResponse.bioPaymentInfo.showGuide) {
        bioGuideVC = [self p_bioGuideWithResponse:orderResultResponse verifyManager:verifyManager completion:completion];
    }
    
    if (!bioGuideVC) {
        CJ_CALL_BLOCK(completion);
    }
    //供外部调用场景定制引导页面属性
    if (extParams) {
        HalfVCEntranceType animateType = [extParams cj_integerValueForKey:@"animate_type"];
        BOOL useMask = [extParams cj_boolValueForKey:@"use_mask"];
        [bioGuideVC showMask:useMask];
        bioGuideVC.animationType = animateType;
        
        //唤端追光可能取不到verifyManager.homePageVC，因此需外部传入navi
        id navi = [extParams cj_objectForKey:@"cjpay_navi"];
        if ([navi isKindOfClass:CJPayNavigationController.class]) {
            [(CJPayNavigationController *)navi pushViewController:bioGuideVC animated:YES];
            return;
        }
    }
    UIViewController *topVC = [UIViewController cj_topViewController];
    if ([topVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        bioGuideVC.animationType = HalfVCEntranceTypeFromRight;
    } else {
        bioGuideVC.animationType = HalfVCEntranceTypeFromBottom;
        [bioGuideVC showMask:YES];
    }
    [verifyManager.homePageVC push:bioGuideVC animated:YES];
}

- (void)showBioSystemSettingVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager completionBlock:(void (^)(void))completion {
    CJPayBioSystemSettingGuideViewController* vc = [[CJPayBioSystemSettingGuideViewController alloc] initWithGuideInfoModel:verifyManager.resResponse.resultPageGuideInfoModel];
    vc.verifyManager = verifyManager;
    vc.completeBlock = completion;
    [verifyManager.homePageVC push:vc animated:YES];
}

- (BOOL)shouldShowGuideWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    if (![self isBioGuideAvailable]) {
        return NO;
    }

    return [resultResponse.resultPageGuideInfoModel.guideType isEqualToString:@"bio_guide"] || resultResponse.bioPaymentInfo.showGuide;
}

- (BOOL)shouldShowBioSystemSettingGuideWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    return [resultResponse.resultPageGuideInfoModel.guideType isEqualToString:@"bio_fail_retain_guide"];
}

- (NSDictionary *)getPreTradeCreateBioParamDic {
    NSString *bioType = [CJPayTouchIdManager currentBioType];
    NSString *sdkVersion = [[CJSDKParamConfig defaultConfig] settingsVersion];
    NSData *bioParamData = [CJPayTouchIdManager currentOriTouchIdData];
    NSString *biometricParamStr = [bioParamData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    BOOL isSafe = [[CJPayEnvManager shared] isSafeEnv];
    NSDictionary *bioParamDic = @{
        @"biometric_params": CJString(biometricParamStr),
        @"bio_type": CJString(bioType),
        @"is_jailbreak": isSafe ? @"2" : @"1",
        @"cj_sdk": CJString(sdkVersion),
        @"is_hardware_support_biometrics": @(YES),
        @"is_local_enable_biometrics": Check_ValidString(biometricParamStr) ? @(YES) : @(NO)
    };
    return bioParamDic;
}

- (BOOL)showGuidePageVCWithResultResponse:(CJPayBDOrderResultResponse *)response verifyManager:(CJPayBaseVerifyManager *)verifyManager cjbackBlock:(void (^)(void))backBlock {
    CJPayBioGuideViewController *bioGuideVC = [self p_bioGuideWithResponse:response verifyManager:verifyManager completion:nil];
    if (!bioGuideVC) {
        return NO;
    }
    bioGuideVC.cjBackBlock = backBlock;
    [verifyManager.homePageVC push:bioGuideVC animated:NO];
    return YES;
}

#pragma - mark 向基础框架注入数据。
+ (NSDictionary *)injectDevInfoData {
    NSMutableDictionary *params = [NSMutableDictionary new];

    NSString *bioType = [CJPayTouchIdManager currentBioType];
    [params cj_setObject:CJString(bioType) forKey:@"bio_type"];

    return [params copy];
}

+ (NSDictionary *)injectReskInfoData {
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSData *bioParamData = [CJPayTouchIdManager currentOriTouchIdData];
    if (bioParamData && bioParamData.length > 0) {
        [params cj_setObject:CJString([bioParamData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]) forKey:@"biometric_params"];
    }
    BOOL isSafe = (BOOL)[[CJPayEnvManager shared] isSafeEnv];
    [params cj_setObject:(isSafe) ? @"2" : @"1" forKey:@"is_jailbreak"];
    NSString *payReferUrl = [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_wxH5PayReferUrlStr];
    [params cj_setObject:CJString(payReferUrl) forKey:@"pay_refer"];
    
    return [params copy];
}

- (void)callBioVerifyWithParams:(NSDictionary *)params completionBlock:(void (^)(NSDictionary * _Nonnull dic))completionBlock {
    NSString *uid = [params cj_stringValueForKey:@"uid"];
    NSString *aid = [params cj_stringValueForKey:@"aid" defaultValue:[CJPayRequestParam gAppInfoConfig].appId];
    NSString *defaultTitle = [NSString stringWithFormat:@"请验证%@", [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"指纹" : @"面容"];
    NSString *title = [params cj_stringValueForKey:@"title" defaultValue:defaultTitle];
    NSString *cancelText = [params cj_stringValueForKey:@"cancel_text"];
    NSString *fallbackText = [params cj_stringValueForKey:@"fallback_text"];
    
    if (!Check_ValidString(uid) && !Check_ValidString(aid)) {
        CJ_CALL_BLOCK(completionBlock, @{@"code": @(101), @"msg": @"参数不合法, 请检查uid, app_id, merchant_id是否为空"});
        return;
    }
    
    CJPayBioPaymentBaseRequestModel *requestModel = [CJPayBioPaymentBaseRequestModel new];
    requestModel.uid = uid;
    requestModel.appId = aid;
    CJPayBioSafeModel *model = [CJPayBioManager getSafeModelBy:requestModel];
    
    // 当前的token文件无效，或指纹无信息
    if (![CJPayTouchIdManager currentOriTouchIdData]) {
        CJ_CALL_BLOCK(completionBlock, @{@"code": @(105), @"msg": @"指纹/面容未录入"});
        return;
    }
    
    if (![model isValid]) {
        CJ_CALL_BLOCK(completionBlock, @{@"code": @(104), @"msg": @"设备不支持生物校验"});
        return;
    }
    
    if ([CJPayTouchIdManager isErrorBiometryLockout]) {
        CJ_CALL_BLOCK(completionBlock, @{@"code": @(106), @"msg": @"用户设备被锁定，验证失败"});
        return;
    }
    
    [CJPayTouchIdManager showTouchIdWithLocalizedReason:title cancelTitle:cancelText falldBackTitle:fallbackText fallBackBlock:^{
        CJ_CALL_BLOCK(completionBlock, @{@"code": @(200), @"msg": @"用户主动降级"});
    } resultBlock:^(BOOL useable, BOOL success, NSError * _Nonnull error, NSInteger policy) {
        if (success) {
            NSData *tokenData = [model.seedHexString hexToBytes];
            NSString *token = [CJPayBioManager generatorTOTPToken:tokenData dateCorrect:CJPayLocalTimeServerTimeDelta digits:model.tokenLength period:model.timeStep];
            NSString *bioType = [CJPayTouchIdManager currentBioType];
            CJ_CALL_BLOCK(completionBlock, @{@"code": @(0), @"one_time_pwd": CJString(token), @"serial_num": CJString(model.serialNum), @"bio_type": CJString(bioType),@"msg": @"成功"});
        } else {
            if ([CJPayTouchIdManager isErrorBiometryLockout]) {
                CJ_CALL_BLOCK(completionBlock, @{@"code": @(106), @"msg": @"用户设备被锁定，验证失败"});
                return;
            }
            
            if (error.code == LAErrorUserCancel) {
                CJ_CALL_BLOCK(completionBlock, @{@"code": @(102), @"msg": @"用户取消验证"});
                return;
            }
            
            if (error.code == LAErrorSystemCancel) {
                CJ_CALL_BLOCK(completionBlock, @{@"code": @(107), @"msg": @"系统原因导致取消验证，比如前后台切换"});
                return;
            }
            
            if (error.code == LAErrorAuthenticationFailed) {
                CJ_CALL_BLOCK(completionBlock, @{@"code": @(101), @"msg": @"系统回调，验证失败"});
                return;
            }
            
            CJ_CALL_BLOCK(completionBlock, @{@"code": @(101), @"msg": @"未知原因，验证失败"});
        }
    }];
}

- (NSDictionary *)buildPwdDicWithModel:(NSDictionary *)requestModel lastPWD:(NSString *)lastPWD {
    return [CJPayBioManager buildPwdDicWithModel:requestModel lastPWD:lastPWD];
}

@end
