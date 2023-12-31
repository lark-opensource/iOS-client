//
//  CJPayBridgePlugin_bio.m
//  CJPay
//
//  Created by liyu on 2020/2/27.
//

#import "CJPayBridgePlugin_bio.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayTouchIdManager.h"
#import "CJPayMemberEnableBioPayRequest.h"
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayBioManager.h"
#import "CJPaySDKMacro.h"
#import "CJPayBridgeBioModel.h"
#import "CJPayRequestParam.h"
#import "CJPayPrivacyMethodUtil.h"
#import "CJPayABTestManager.h"
#import "CJPayBridgeBlockRegister.h"
#import "CJPaySafeManager.h"
#import "CJPayParamsCacheService.h"

@implementation CJPayBridgePlugin_bio

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_bio, bioPaymentShowState), @"ttcjpay.bioPaymentShowState");
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_bio, switchBioPaymentState), @"ttcjpay.switchBioPaymentState");
    //BPEA跨端改造，使用block方式注册"ttcjpay.goSettings"的jsb
    [CJPayBridgeBlockRegister registerBridgeName:@"ttcjpay.goSettings"
                                      engineType:TTBridgeRegisterAll
                                        authType:TTBridgeAuthProtected
                                         domains:nil
                               needBridgeCommand:YES
                                         handler:^(NSDictionary * _Nullable params, TTBridgeCallback callback, id<TTBridgeEngine> engine, UIViewController * _Nullable controller, TTBridgeCommand * _Nullable command) {
        
        TTBridgePlugin *pluginBio = [CJPayBridgeBlockRegister associatedPluginsOnEngine:engine pluginClassName:NSStringFromClass(self)];
        if ([pluginBio isKindOfClass:CJPayBridgePlugin_bio.class]) {
            [(CJPayBridgePlugin_bio *)pluginBio goSettingsParam:params callback:callback engine:engine controller:controller command:command];
        }
    }];
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)bioPaymentShowStateWithParam:(NSDictionary *)data
                            callback:(TTBridgeCallback)callback
                              engine:(id<TTBridgeEngine>)engine
                          controller:(UIViewController *)controller
{
    CJPayBioCheckSateModel *resModel = [CJPayBioCheckSateModel new];
    if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeNone) {
        resModel.isShow = NO;
        resModel.msg = CJPayLocalizedStr(@"不支持指纹/面容");
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
        return;
    }
    
    switch ([CJPayTouchIdManager currentSupportBiopaymentType]) {
            case CJPayBioPaymentTypeFace:
            resModel.bioType = @"1";
            break;
            case CJPayBioPaymentTypeFinger:
            resModel.bioType = @"2";
            break;
            case CJPayBioPaymentTypeNone:
            resModel.bioType = @"0";
            break;
        default:
            break;
    }
    
    NSString *bioTypeStr = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"指纹" : @"面容";
    NSString *bioIDTypeStr = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"Touch ID" : @"Face ID";
    
    if ([CJPayTouchIdManager isBiometryNotAvailable]) {
        resModel.isShow = YES;
        resModel.isOPen = NO;
        resModel.style = CJPayBioShowStyleGoSettings;
        resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"开启%@支付需要获取你的系统权限，请到手机设置中开启%@支付权限"), bioTypeStr, bioTypeStr];
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
        return;
    }
    
    if (![CJPayTouchIdManager currentOriTouchIdData]) {
        resModel.isShow = YES;
        resModel.isOPen = NO;
        resModel.style = CJPayBioShowStyleAlert;
        if ([CJPayTouchIdManager isErrorBiometryLockout]) {
            resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"%@功能被锁定"), bioIDTypeStr];
        } else {
            resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"设备中没有你的%@信息，可以到「设置-%@与密码」中录入%@信息"), bioTypeStr, bioIDTypeStr, bioTypeStr];
        }
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
        return;
    }
    
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSError *err = nil;
        CJPayBioPaymentBaseRequestModel *model = [[CJPayBioPaymentBaseRequestModel alloc] initWithDictionary:data error:&err];
        if (model.isOnlyReturnDeviceType) {
            resModel.isShow = YES;
            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
            return;
        }
        [CJPayBioManager checkBioPayment:model
                              completion:^(CJPayBioCheckState state) {
            switch (state) {
                case CJPayBioCheckStateOpen:
                    resModel.isShow = YES;
                    resModel.isOPen = YES;
                    resModel.msg = CJPayLocalizedStr(@"已开通指纹/面容支付");
                    break;
                case CJPayBioCheckStateClose:
                    resModel.isShow = YES;
                    resModel.isOPen = NO;
                    resModel.msg = CJPayLocalizedStr(@"未开通指纹/面容支付");
                    break;
                case CJPayBioCheckStateWithoutToken:
                    resModel.isShow = YES;
                    resModel.isOPen = NO;
                    resModel.msg = CJPayLocalizedStr(@"缺少指纹/面容支付的Token文件");
                    break;
                case CJPayBioCheckStateUnknown:
                    resModel.isShow = YES;
                    resModel.isOPen = NO;
                    resModel.msg = CJPayLocalizedStr(@"已开通指纹/面容支付");
                    break;
            }
            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
        }];
    } else {
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
    }
    
}

- (void)switchBioPaymentStateWithParam:(NSDictionary *)data
                              callback:(TTBridgeCallback)callback
                                engine:(id<TTBridgeEngine>)engine
                            controller:(UIViewController *)controller
{
    CJPayBioSwitchStateModel *resModel = [CJPayBioSwitchStateModel new];
    if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeNone) {
        resModel.isOpen = NO;
        resModel.msg = CJPayLocalizedStr(@"不支持指纹支付");
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
        return;
    }
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSError *err = nil;
        CJPayBioPaymentBaseRequestModel *model = [[CJPayBioPaymentBaseRequestModel alloc] initWithDictionary:data error:&err];
        [self p_getSource:model];
        NSDictionary *dic = (NSDictionary *)data;
        
        NSString *bioTypeStr = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"指纹" : @"面容";
        NSString *bioIDTypeStr = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"Touch ID" : @"Face ID";
        
        if ([[dic cj_stringValueForKey:@"open"] isEqualToString:@"1"]) {
            if ([CJPayTouchIdManager isBiometryNotAvailable]) {
                resModel.isOpen = NO;
                resModel.code = @"-1";
                resModel.style = CJPayBioShowStyleGoSettings;
                resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"开启%@支付需要获取你的系统权限，请到手机设置中开启%@ID权限"), bioTypeStr, bioTypeStr];
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
                return;
            }
            
            if (![CJPayTouchIdManager currentOriTouchIdData]) {
                resModel.isOpen = NO;
                resModel.code = @"-1";
                resModel.style = CJPayBioShowStyleAlert;
                if ([CJPayTouchIdManager isErrorBiometryLockout]) {
                    resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"%@功能被锁定"), bioIDTypeStr];
                } else {
                    resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"设备中没有你的%@信息，可以到「设置-%@与密码」中录入%@信息"), bioTypeStr, bioIDTypeStr, bioTypeStr];
                }
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
                return;
            }
            
            if ([dic cj_boolValueForKey:@"is_from_guide"]) {
                // 支付后 lynx 请求开通生物验证
                NSMutableDictionary *requestModel = [[NSMutableDictionary alloc] initWithDictionary:dic];
                [requestModel cj_setObject:model.appId forKey:@"app_id"];
                [requestModel cj_setObject:model.merchantId forKey:@"merchant_id"];
                [requestModel cj_setObject:model.uid forKey:@"uid"];
                [requestModel cj_setObject:[CJPaySafeManager buildEngimaEngine:@""] forKey:@"engimaEngine"];
                if (CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService)) {
                    [requestModel cj_setObject:[CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_getParamsFromCache:@"lastPWD"] forKey:@"lastPwd"];
                } else {
                    CJPayLogAssert(NO, @"没有集成 CJPayParamsCacheService 模块，请确认是否需要集成");
                }
                
                @CJWeakify(self)
                [CJPayBioManager openBioPaymentOnVC:controller
                                  withBioRequestDic:requestModel
                                    completionBlock:^(BOOL result, BOOL needBack) {
                    @CJStrongify(self)
                    if (result) {
                        //生物识别开通成功
                        resModel.isOpen = YES;
                        resModel.code = @"0";
                        resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"%@支付开通成功"), bioTypeStr];
                    } else {
                        //生物识别开通失败
                        resModel.code = @"1";
                        resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"%@支付开通失败"), bioTypeStr];
                    }
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
                }];

            } else {
                NSString *forgetPasswordUrl = [dic cj_stringValueForKey:@"forgetPasswordUrl"];
                model.referVC = controller;
                [CJPayBioManager openBioPayment:model
                                        findUrl:forgetPasswordUrl
                                     completion:^(CJPayBioOpenState state) {
                    if (state == CJPayBioStateBioCheckSuccess) {
                        resModel.isOpen = YES;
                        resModel.code = @"0";
                        resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"%@支付开通成功"), bioTypeStr];
                    } else {
                        resModel.code = @"1";
                        resModel.msg = [NSString stringWithFormat:CJPayLocalizedStr(@"%@支付开通失败"), bioTypeStr];
                    }
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
                }];
            }
        } else if ([[dic cj_stringValueForKey:@"open"] isEqualToString:@"0"]) {
            [CJPayBioManager closeBioPayment:model
                                  completion:^(CJPayBioCloseState state) {
                if (state == CJPayBioCloseStateSuccess) {
                    resModel.isOpen = NO;
                    resModel.code = @"0";
                    resModel.msg = CJPayLocalizedStr(@"已暂停使用");
                } else {
                    resModel.code = @"1";
                    resModel.msg = CJPayLocalizedStr(@"关闭失败");
                }
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
            }];
        }
    } else {
        resModel.msg = CJPayLocalizedStr(@"参数错误");
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toJson], nil);
    }
}

- (void)goSettingsParam:(NSDictionary *)data
               callback:(TTBridgeCallback)callback
                 engine:(id<TTBridgeEngine>)engine
             controller:(UIViewController *)controller
                command:(TTBridgeCommand *)command
{
    // 调用AppJump敏感方法，需走BPEA鉴权
    [CJPayPrivacyMethodUtil applicationOpenUrl:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                    withPolicy:@"bpea-caijing_bio_available_goto_setting"
                                 bridgeCommand:command
                                       options:@{}
                             completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        if (error) {
            CJPayLogError(@"error in bpea-caijing_bio_available_goto_setting");
            TTBRIDGE_CALLBACK_FAILED
        } else {
            TTBRIDGE_CALLBACK_SUCCESS
        }
    }];
    
}

- (void)p_getSource:(CJPayBioPaymentBaseRequestModel*)model {
    if([model.source isEqualToString:@"landing"]) {
        switch ([CJPayTouchIdManager currentSupportBiopaymentType] ) {
            case CJPayBioPaymentTypeFace:
                model.source = @"1";
                break;
            case CJPayBioPaymentTypeFinger:
                model.source = @"2";
                break;
            default:
                break;
        }
    } else if([model.source isEqualToString:@"paymng"]) {
        switch ([CJPayTouchIdManager currentSupportBiopaymentType] ) {
            case CJPayBioPaymentTypeFace:
                model.source = @"4";
                break;
            case CJPayBioPaymentTypeFinger:
                model.source = @"5";
                break;
            default:
                break;
        }
    }
}

@end
