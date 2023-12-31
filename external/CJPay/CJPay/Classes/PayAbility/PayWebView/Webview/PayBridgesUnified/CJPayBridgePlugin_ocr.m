//
//  CJPayBridgePlugin_ocr.m
//  CJPay
//
//  Created by 尚怀军 on 2020/5/20.
//

#import "CJPayBridgePlugin_ocr.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayBizWebViewController.h"
#import "CJPayBankCardOCRViewController.h"
#import "CJPayIDCardProfileOCRViewController.h"
#import "CJPayIDCardOCRViewController.h"
#import "CJPayBridgeBlockRegister.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPaySaasSceneUtil.h"

@interface CJPayBridgePlugin_ocr(tracker) <CJPayTrackerProtocol>

@end

@interface  CJPayBridgePlugin_ocr()

@property (nonatomic, copy) NSDictionary *trackBaseParam;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, weak) TTBridgeCommand *command;
@property (nonatomic, copy) NSString *saasSceneRecordKey;

@end

@implementation CJPayBridgePlugin_ocr

+ (void)registerBridge {
    TTRegisterBridgeMethod
    
    //BPEA跨端改造，使用block方式注册"ttcjpay.ocr"的jsb
    [CJPayBridgeBlockRegister registerBridgeName:@"ttcjpay.ocr"
                                      engineType:TTBridgeRegisterAll
                                        authType:TTBridgeAuthProtected
                                         domains:nil
                               needBridgeCommand:YES
                                         handler:^(NSDictionary * _Nullable params, TTBridgeCallback callback, id<TTBridgeEngine> engine, UIViewController * _Nullable controller, TTBridgeCommand * _Nullable command) {
        
        TTBridgePlugin *pluginOcr = [CJPayBridgeBlockRegister associatedPluginsOnEngine:engine pluginClassName:NSStringFromClass(self)];
        if ([pluginOcr isKindOfClass:CJPayBridgePlugin_ocr.class]) {
            [(CJPayBridgePlugin_ocr *)pluginOcr ocrWithParams:params callback:callback engine:engine controller:controller command:command];
        } else {
            TTBRIDGE_CALLBACK_FAILED;
        }
    }];
}

- (void)ocrWithParams:(NSDictionary *)param
             callback:(TTBridgeCallback)callback
               engine:(id<TTBridgeEngine>)engine
           controller:(UIViewController *)controller
              command:(TTBridgeCommand *)command {
    
    if (![param isKindOfClass:NSDictionary.class]) {
        CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code": @"-1", @"msg": @"参数错误"}, nil);
        return;
    }
    self.command = command;
    
    self.appId = [param cj_stringValueForKey:@"app_id"];
    self.merchantId = [param cj_stringValueForKey:@"merchant_id"];
    NSMutableDictionary *trackBaseParam = [[param cj_dictionaryValueForKey:@"track_base_param"] ?: @{} mutableCopy];
    [trackBaseParam addEntriesFromDictionary:@{
        @"app_id" : CJString(self.appId),
        @"merchant_id" : CJString(self.merchantId)
    }];
    self.trackBaseParam = trackBaseParam;
    
    NSString *type = [param cj_stringValueForKey:@"type"];
    if ([type isEqualToString:@"card"]) {
        [self p_openBankCardOCRWithParam:param callback:callback controller:controller];
        return;
    }
    
    if ([@[@"id_card", @"id_card_fxj"] containsObject:type]) {
        [self p_openIDCardOCRWithParam:param callback:callback controller:controller];
        return;
    }
    
    if ([type isEqualToString:@"id_card_front"]) {
        [self p_openIDCardFrontOCRWithParam:param callback:callback controller:controller];
        return;
    }
    
    CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code": @"-1", @"msg": @"OCR类型错误"}, nil);
}

- (void)p_openBankCardOCRWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback controller:(UIViewController *)controller {
    NSDictionary *ruleDic = [param cj_dictionaryValueForKey:@"rule"] ?: @{};
    [self p_recordSaasScene:param];
    
    CJPayBankCardOCRViewController *cardOCRVC = [CJPayBankCardOCRViewController new];
    cardOCRVC.BPEAData.bridgeCommand = self.command;
    cardOCRVC.BPEAData.requestAccessPolicy = @"bpea-caijing_jsb_ocr_bankcard_camera_permission";
    cardOCRVC.BPEAData.jumpSettingPolicy = @"bpea-caijing_jsb_ocr_bankcard_available_goto_setting";
    cardOCRVC.BPEAData.startRunningPolicy = @"bpea-caijing_jsb_ocr_bankcard_avcapturesession_start_running";
    cardOCRVC.BPEAData.stopRunningPolicy = @"bpea-caijing_jsb_ocr_bankcard_avcapturesession_stop_running";
    
    cardOCRVC.appId = CJString(self.appId);
    cardOCRVC.merchantId = CJString(self.merchantId);
    cardOCRVC.minLength = [ruleDic cj_intValueForKey:@"min_length"];
    cardOCRVC.maxLength = [ruleDic cj_intValueForKey:@"max_length"];
    cardOCRVC.trackDelegate = self;
    cardOCRVC.completionBlock = ^(CJPayCardOCRResultModel * _Nonnull resultModel) {
        [self p_resetSaasScene];
        switch (resultModel.result) {
            case CJPayCardOCRResultSuccess:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"0",
                                                              @"msg": @"识别成功",
                                                              @"data" : CJString(resultModel.cardNoStr),
                                                              @"cropped_img" : CJString(resultModel.cropImgStr),
                                                              @"type": resultModel.isFromUploadPhoto ? @"2" : @"1"}, nil);
                break;
            case CJPayCardOCRResultUserCancel:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"用户取消识别"}, nil);
            case CJPayCardOCRResultBackNoCameraAuthority:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"没有相机权限"}, nil);
            case CJPayCardOCRResultBackNoJumpSettingAuthority:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"没有跳转系统设置权限"}, nil);
            default:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"2", @"msg": @"用户手动输入"}, nil);
                break;
        }
    };
    
    [cardOCRVC presentWithNavigationControllerFrom:controller
                                           useMask:YES
                                        completion:nil];

}

- (void)p_openIDCardFrontOCRWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback controller:(UIViewController *)controller {
    NSDictionary *ruleDic = [param cj_dictionaryValueForKey:@"rule"] ?: @{};
    [self p_recordSaasScene:param];

    CJPayIDCardProfileOCRViewController *cardOCRVC = [CJPayIDCardProfileOCRViewController new];
    cardOCRVC.BPEAData.bridgeCommand = self.command;
    
    cardOCRVC.BPEAData.requestAccessPolicy = @"bpea-caijing_jsb_ocr_idcard_camera_permission";
    cardOCRVC.BPEAData.jumpSettingPolicy = @"bpea-caijing_jsb_ocr_idcard_available_goto_setting";
    cardOCRVC.BPEAData.startRunningPolicy = @"bpea-caijing_jsb_ocr_idcard_avcapturesession_start_running";
    cardOCRVC.BPEAData.stopRunningPolicy = @"bpea-caijing_jsb_ocr_idcard_avcapturesession_stop_running";
    
    cardOCRVC.appId = CJString(self.appId);
    cardOCRVC.merchantId = CJString(self.merchantId);
    cardOCRVC.minLength = [ruleDic cj_intValueForKey:@"min_length"];
    cardOCRVC.maxLength = [ruleDic cj_intValueForKey:@"max_length"];
    cardOCRVC.extParams = [ruleDic cj_dictionaryValueForKey:@"ext_params"];
    cardOCRVC.trackDelegate = self;
    cardOCRVC.completionBlock = ^(CJPayCardOCRResultModel * _Nonnull resultModel) {
        [self p_resetSaasScene];
        switch (resultModel.result) {
            case CJPayCardOCRResultSuccess:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"0",
                                                              @"msg": @"识别成功",
                                                              @"id_name":CJString(resultModel.idName),
                                                              @"id_code":CJString(resultModel.idCode),
                                                              @"type": resultModel.isFromUploadPhoto ? @"2" : @"1"}, nil);
                break;
            case CJPayCardOCRResultUserCancel:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"用户取消识别"}, nil);
            case CJPayCardOCRResultBackNoCameraAuthority:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"没有相机权限"}, nil);
            case CJPayCardOCRResultBackNoJumpSettingAuthority:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"没有跳转系统设置权限"}, nil);
            default:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"2", @"msg": @"用户手动输入"}, nil);
                break;
        }
    };
    
    [cardOCRVC presentWithNavigationControllerFrom:controller
                                           useMask:YES
                                        completion:nil];

}

- (void)p_openIDCardOCRWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback controller:(UIViewController *)controller {
    
    [self p_recordSaasScene:param];
    CJPayIDCardOCRViewController *idCardOCRVC = [CJPayIDCardOCRViewController new];
    idCardOCRVC.appId = self.appId;
    idCardOCRVC.merchantId = self.merchantId;
    idCardOCRVC.BPEAData.bridgeCommand = self.command;
    idCardOCRVC.BPEAData.requestAccessPolicy = @"bpea-caijing_jsb_ocr_idcard_camera_permission";
    idCardOCRVC.BPEAData.jumpSettingPolicy = @"bpea-caijing_jsb_ocr_idcard_available_goto_setting";
    idCardOCRVC.BPEAData.startRunningPolicy = @"bpea-caijing_jsb_ocr_idcard_avcapturesession_start_running";
    idCardOCRVC.BPEAData.stopRunningPolicy = @"bpea-caijing_jsb_ocr_idcard_avcapturesession_stop_running";
    idCardOCRVC.extParams = [param cj_dictionaryValueForKey:@"ext_params"];
    idCardOCRVC.compressSize = [param cj_intValueForKey:@"compress_size" defaultValue:150];
    idCardOCRVC.trackDelegate = self;
    if ([[param cj_stringValueForKey:@"type"] isEqualToString:@"id_card_fxj"]) {
        idCardOCRVC.isFxjCustomize = YES;
        idCardOCRVC.frontRequestUrl = [param cj_stringValueForKey:@"frontUploadInteface"];
        idCardOCRVC.backRequestUrl = [param cj_stringValueForKey:@"backUploadInteface"];
        idCardOCRVC.isecKey = [param cj_stringValueForKey:@"publicKey"];
    }
    idCardOCRVC.completionBlock = ^(CJPayCardOCRResultModel * _Nonnull resultModel) {
        [self p_resetSaasScene];
        switch (resultModel.result) {
            case CJPayCardOCRResultSuccess:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"0", @"msg": @"识别成功", @"data": resultModel.fxjResponseDict ?: @{}}, nil);
                break;
            case CJPayCardOCRResultUserCancel:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"用户取消"}, nil);
                break;
            case CJPayCardOCRResultBackNoCameraAuthority:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"没有相机权限"}, nil);
                break;
            case CJPayCardOCRResultBackNoJumpSettingAuthority:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"没有跳转系统设置权限"}, nil);
                break;
            case CJPayCardOCRResultIDCardModifyElementsFail:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"3", @"msg": @"修改九要素失败"}, nil);
            default:
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"用户取消"}, nil);
                break;
        }
    };
    
    [idCardOCRVC presentWithNavigationControllerFrom:controller
                                             useMask:YES
                                          completion:nil];
}

// 通过jsb调用OCR能力时需设置SaaS环境标识
- (void)p_recordSaasScene:(NSDictionary *)param {
    if (!Check_ValidDictionary(param)) {
        return;
    }
    NSString *isCaijingSaas = [param cj_stringValueForKey:CJPaySaasKey];
    
    NSTimeInterval currentTimestamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    NSString *saasRecordKey = [NSString stringWithFormat:@"pluginOCR_%d", (int)currentTimestamp];
    self.saasSceneRecordKey = saasRecordKey;
    
    NSString *saasSceneValue = [isCaijingSaas isEqualToString:@"1"] ? CJPaySaasKey : @"";
    [CJPaySaasSceneUtil addSaasKey:saasRecordKey saasSceneValue:saasSceneValue];
    
}

// 结束调用时重置SaaS环境标识
- (void)p_resetSaasScene {
    [CJPaySaasSceneUtil removeSaasSceneByKey:self.saasSceneRecordKey];
}

@end

@implementation CJPayBridgePlugin_ocr(tracker)

#pragma mark - CJPayTrackerProtocol
- (void)event:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *paramsDic = [params mutableCopy];
    [paramsDic addEntriesFromDictionary:self.trackBaseParam];
    [CJTracker event:event params:paramsDic];
}

@end
