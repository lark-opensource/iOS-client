//
//  CJPayVerifyItemRecogFace.m
//  CJPay
//
//  Created by 尚怀军 on 2020/8/23.
//

#import "CJPayVerifyItemRecogFace.h"
#import "CJPayGetTicketRequest.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayFaceRecognitionProtocolViewController.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayFaceRecogAlertViewController.h"
#import "CJPayLoadingManager.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayBizWebViewController.h"
#import "UIViewController+CJTransition.h"
#import "CJPayMetaSecManager.h"
#import "CJPayFaceRecogAlertContentView.h"
#import "CJPaySafeUtilsHeader.h"
#import "CJPayRetainUtil.h"
#import "CJPayFaceRecogUtil.h"
#import "CJPaySettingsManager.h"
#import "CJPayRetainInfoV2Config.h"
#import "CJPaySkipPwdConfirmHalfPageViewController.h"

@implementation CJPayVerifyItemRecogFace

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 需要人脸验证
    if (self.manager.lastConfirmVerifyItem == self) {
        [self event:@"wallet_alivecheck_result"
             params:@{@"result": [response isSuccess] ? @(1) : @(0),
                      @"alivecheck_type":[response.faceVerifyInfo.verifyType isEqualToString:@"1"] ? @(1) : @(0),
                      @"fail_before":@(0),
                      @"fail_code": CJString(response.code),
                      @"fail_reason": CJString(response.msg),
                      @"enter_from":@(self.enterFrom.intValue),
                      @"url": @"open_bytecert_sdk",
                      @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                      @"alivecheck_scene": CJString(self.getTicketResponse.faceScene)}];
    }
    if ([response.code isEqualToString:@"CD002104"]) {
        UIViewController *topVC = [UIViewController cj_topViewController];
        if ([topVC isKindOfClass:CJPaySkipPwdConfirmHalfPageViewController.class]) {
            CJPaySkipPwdConfirmHalfPageViewController *skipPwdConfirm = (CJPaySkipPwdConfirmHalfPageViewController *)topVC;
            [skipPwdConfirm closeWithAnimated:YES];
        }
        
        self.verifySource = [self handleSourceType];
        [self tryFaceRecogWithResponse:response];
        return YES;
    }
    return NO;
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    // 下单转确认支付
    if (self.manager.isOneKeyQuickPay) {
        self.verifySource = @"极速支付-加验";
    }
    [self tryFaceRecogWithResponse:response.confirmResponse];
}

- (void)receiveEvent:(CJPayEvent *)event {
    if ([event.name isEqualToString:CJPayVerifyEventRecommandVerifyKey] && [event.data isKindOfClass:CJPayOrderConfirmResponse.class]) {
        [self tryFaceRecogWithResponse:event.data];
    }
}

- (void)event:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *trackParamDic = [NSMutableDictionary new];
    if (params) {
        [trackParamDic addEntriesFromDictionary:params];
    }
    NSString *aliveCheckStyleStr = [self.getTicketResponse getLiveRouteTrackStr];
    [trackParamDic cj_setObject:aliveCheckStyleStr forKey:@"alivecheck_style"];
    [super event:event params:trackParamDic];
}

- (void)tryFaceRecogWithResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.getTicketLoadingBlock) {
            self.getTicketLoadingBlock(YES);
        } else {
            [self showLoading:YES];
        }
    });
    [CJKeyboard prohibitKeyboardShow];
    [self.class getTicketWithResponse:orderConfirmResponse
                  createOrderResponse:[self getCreateOrderResponse]
                               source:[self getSourceStr]
                               fromVC:[self p_topVC]
                           completion:^(CJPayFaceRecogSignResult signResult, CJPayGetTicketResponse * _Nonnull getTicketResponse) {
        self.getTicketResponse = getTicketResponse;
        if (self.getTicketLoadingBlock) {
            self.getTicketLoadingBlock(NO);
        } else {
            [self showLoading:NO];
        }

        if (signResult == CJPayFaceRecogSignResultSuccess) {
            // 用户已经签了人脸验证协议
            [self alertNeedFaceRecogWith:orderConfirmResponse getTicketResponse:getTicketResponse];
        } else if (signResult == CJPayFaceRecogSignResultNeedResign) {
            // 用户没有签人脸验证的协议
            [self startSignFaceRecogProtocolWith:orderConfirmResponse
                                 getTicketResponse:getTicketResponse];
        }
    }];
}
- (CJPayFaceRecognitionModel *)createFaceRecognitionModelOfFullPage:(CJPayOrderConfirmResponse *)response
                                    withGetTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    CJPayFaceRecognitionModel *model = [CJPayFaceRecognitionModel new];
    model.userMaskName  = getTicketResponse.nameMask;
    model.agreementName = getTicketResponse.agreementDesc;
    model.agreementURL = getTicketResponse.agreementUrl;
    model.appId = [self getCreateOrderResponse].merchant.appId;
    model.merchantId = [self getCreateOrderResponse].merchant.merchantId;
    model.alivecheckScene = getTicketResponse.faceScene;
    model.alivecheckType = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
    if (self.manager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkip) {
        model.buttonText = CJPayLocalizedStr(@"刷脸验证并支付");
    }
    return model;
}

- (void)startSignFaceRecogProtocolWith:(CJPayOrderConfirmResponse *)response
                       getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    CJPayFaceRecognitionModel *model = [self createFaceRecognitionModelOfFullPage:response withGetTicketResponse:getTicketResponse];
    CJPayFaceRecognitionProtocolViewController *faceRecogProtocolVC = [[CJPayFaceRecognitionProtocolViewController alloc] initWithFaceRecognitionModel:model];
    faceRecogProtocolVC.trackDelegate = self;
    @CJWeakify(self)
    faceRecogProtocolVC.cjBackBlock = ^{
        @CJStrongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            [self failRecogFace];
        });
    };
    
    faceRecogProtocolVC.signSuccessBlock = ^(NSString * _Nonnull ticket) {
        @CJStrongify(self)
        [self startFaceRecogWith:response getTicketResponse:getTicketResponse];
        self.enterFrom = @"1";
    };
    
    [self pushWithVC:faceRecogProtocolVC];
}

- (CJPayFaceRecognitionModel *)createFaceRecognitionModelOfAlert:(CJPayOrderConfirmResponse *)response withGetTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    CJPayFaceRecognitionModel *model = [CJPayFaceRecognitionModel new];
    model.agreementName = getTicketResponse.agreementDesc;
    model.agreementURL = getTicketResponse.agreementUrl;
    model.protocolCheckBox = getTicketResponse.protocolCheckBox;
    model.buttonText = response.faceVerifyInfo.buttonDesc;
    model.title = response.faceVerifyInfo.title;
    model.iconUrl = response.faceVerifyInfo.iconUrl;
    model.showStyle = CJPayFaceRecognitionStyleExtraTestInPayment;
    model.shouldShowProtocolView = NO;
    return model;
}

- (void)alertNeedFaceRecogWith:(CJPayOrderConfirmResponse *)response
             getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    
    [CJKeyboard prohibitKeyboardShow];

    CJPayFaceRecognitionModel * model = [self createFaceRecognitionModelOfAlert:response withGetTicketResponse:getTicketResponse];
    [self event:@"wallet_alivecheck_safetyassurace_imp" params:@{
        @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0"),
        @"is_skip_ver" : self.manager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkip ? @(1) : @(0),
        @"title_name" : CJString(model.title)
    }];
    CJPayFaceRecogAlertViewController *faceRecogAlertVC = [[CJPayFaceRecogAlertViewController alloc] initWithFaceRecognitionModel:model];
    faceRecogAlertVC.contentView.trackDelegate = self;
    NSInteger hasSrcNum = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
    @CJWeakify(self)
    faceRecogAlertVC.closeBtnBlock = ^{
        @CJStrongify(self)
        [self event:@"wallet_alivecheck_safetyassurace_click" params:@{
            @"button_type": @(0),
            @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0"),
            @"is_skip_ver" : self.manager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkip ? @(1) : @(0),
            @"title_name" : CJString(model.title)
        }];
        if ([self shouldShowRetainVC]) {
            //活体挽留
        } else {
            [self failRecogFace];
        }
    };
    faceRecogAlertVC.confirmBtnBlock = ^{
        @CJStrongify(self)
        if (self) {
            self.enterFrom = @"2";
            [self startFaceRecogWith:response getTicketResponse:getTicketResponse];
        }
        [self event:@"wallet_alivecheck_safetyassurace_click" params:@{
            @"button_type": @(1),
            @"alivecheck_scene": CJString(getTicketResponse.faceScene),
            @"alivecheck_type" : @(hasSrcNum),
            @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0"),
            @"is_skip_ver" : self.manager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkip ? @(1) : @(0),
            @"title_name" : CJString(model.title)
        }];
    };
    [self pushWithVC:faceRecogAlertVC];
}

- (void)startFaceRecogWith:(CJPayOrderConfirmResponse *)response
         getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    
    if (![getTicketResponse.liveRoute isEqualToString:BDPayVerifyChannelFacePlusStr]) {
        // ailab 活体验证
        NSString *ailabScene = CJString(getTicketResponse.scene);
        if (Check_ValidString(getTicketResponse.faceScene)) {
            ailabScene = CJString(getTicketResponse.faceScene);
        }
        NSDictionary *baseParam = @{@"cert_app_id" : @"1792",
                                    @"scene" : ailabScene,
                                    @"mode" : @(0),
                                    @"ticket" : CJString(getTicketResponse.ticket),
                                    @"eventParams": @{@"source": CJString(self.verifySource)}
        };
        [self p_doFaceLivenessWith:response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                         baseParam:baseParam];

    } else {
        // faceplusplus 活体验证
        [self p_doFacePlusLivenessWith:response
                     getTicketResponse:getTicketResponse];
    }
}

// ailab 活体验证
- (void)p_doFaceLivenessWith:(CJPayOrderConfirmResponse *)response
           getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                   baseParam:(NSDictionary *)baseParam {
    if (!CJ_OBJECT_WITH_PROTOCOL(CJPayFaceLivenessProtocol)) {
        [CJMonitor trackService:@"wallet_rd_ailab_face_detect_fail"
                       category:@{}
                          extra:@{}];
        return;
    }
    
    [CJ_OBJECT_WITH_PROTOCOL(CJPayFaceLivenessProtocol) doFaceLivenessWith:baseParam
                                                               extraParams:[NSDictionary new]
                                                                  callback:^(NSDictionary *data, NSError *error) {
        //活体回调后才允许拉起键盘
        if (!error) {
            // 成功取到人脸照片
            NSDictionary *dataDic = [data cj_objectForKey:@"data"];
            NSData *sdkData = [dataDic cj_objectForKey:@"sdk_data"];
            
            // 异步上传活体视频
            [CJPayFaceRecogUtil asyncUploadFaceVideoWithAppId:[self getCreateOrderResponse].merchant.appId
                                                   merchantId:[self getCreateOrderResponse].merchant.merchantId
                                                    videoPath:[dataDic cj_stringValueForKey:@"video_path"]];
            
            NSString *sdkDataStr = @"";
            if (sdkData) {
                sdkDataStr = [[NSString alloc] initWithData:sdkData encoding:NSUTF8StringEncoding];
            }
            if (self.manager) {
                [CJPayFaceRecogUtil tryPoptoTopHalfVC:[self.manager.homePageVC topVC]];
            }
            [self submitFaceDataWithResponse:response
                           getTicketResponse:getTicketResponse
                                     sdkData:sdkDataStr];
        } else {
            if (![[error.userInfo cj_stringValueForKey:@"errorCode"] isEqualToString:@"-3003"]) { //没开系统相册权限的时候，不回收银台首页
                [self failRecogFace];
            } else {
                [CJKeyboard permitKeyboardShow];
            }
            [self showLoading:NO];
            NSString *code = [error.userInfo cj_stringValueForKey:@"errorCode"];
            NSString *msg = [error.userInfo cj_stringValueForKey:@"errorMessage"];
            if (Check_ValidString(msg) && ![code isEqualToString:@"-1006"]) { // 用户取消生物识别不弹toast
                [CJToast toastText:msg inWindow:[self p_topVC].cj_window];
            }
            [self event:@"wallet_alivecheck_result"
                      params:@{@"result": @(0),
                               @"alivecheck_type":Check_ValidString(getTicketResponse.ticket) ? @(1) : @(0),
                               @"fail_before":@(0),
                               @"enter_from":@(self.enterFrom.intValue),
                               @"url": @"open_bytecert_sdk",
                               @"fail_code": CJString(code),
                               @"fail_reason": CJString(msg),
                               @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                               @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
        }
    }];
}

// face++ 活体验证
- (void)p_doFacePlusLivenessWith:(CJPayOrderConfirmResponse *)orderConfirmResponse
               getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    CJPayBizWebViewController *webVC = [[CJPayBizWebViewController alloc] initWithUrlString:getTicketResponse.ticket];
    webVC.returnUrl = BDPayFacePlusVerifyReturnURL;
    webVC.allowsPopGesture = NO;
    @CJWeakify(self)
    @CJWeakify(webVC);
    webVC.cjBackBlock = ^{  // disbale访问历史，点击back直接关闭
        @CJStrongify(webVC);
        [webVC closeWebVC];
        [CJKeyboard permitKeyboardShow];
    };
    webVC.closeCallBack = ^(id data) {
        @CJStrongify(self)
        NSDictionary *dic = (NSDictionary *)data;
        if ([[dic cj_stringValueForKey:@"action"] isEqualToString:@"return_by_url"]) {
            [self submitFaceDataWithResponse:orderConfirmResponse
                           getTicketResponse:getTicketResponse
                                     sdkData:@""];
        }
    };
    [self pushWithVC:webVC];
}

- (UIViewController *)p_topVC {
    if (self.manager.homePageVC) {
        return [UIViewController cj_foundTopViewControllerFrom:[self.manager.homePageVC topVC]];
    } else {
        return [UIViewController cj_foundTopViewControllerFrom:self.referVC];
    }
}

- (void)pushWithVC:(UIViewController *)vc {
    UIViewController *topVC = [self p_topVC];
    if (topVC.navigationController && [topVC.navigationController isKindOfClass:[CJPayNavigationController class]]) {
        if (self.manager.homePageVC) {
            [self.manager.homePageVC push:vc animated:YES];
            return;
        }
        [topVC.navigationController pushViewController:vc animated:YES];
    } else {
        if ([vc isKindOfClass:[CJPayBaseViewController class]]) {
            if (self.manager.homePageVC) {
                [self.manager.homePageVC push:vc animated:YES];
            } else {
                CJPayBaseViewController *baseVC = (CJPayBaseViewController *)vc;
                [baseVC presentWithNavigationControllerFrom:topVC useMask:NO completion:nil];
            }
        }
    }
}

- (void)showLoading:(BOOL)isLoading {
    if (self.manager.loadingDelegate) {
        if (isLoading) {
            @CJStartLoading(self.manager.loadingDelegate)
        } else {
            @CJStopLoading(self.manager.loadingDelegate)
        }
        return;
    }
    
    if (isLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)failRecogFace {
    [self.manager sendEventTOVC:CJPayHomeVCEventUserCancelRiskVerify obj:@(CJPayVerifyTypeFaceRecog)];
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskUserVerifyResult];
    // 增加0.5s的延时，避免人脸SDK回调太早，导致topVC错乱问题
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.manager sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
        [CJKeyboard delayPermitKeyboardShow:0.5];
    });
}

- (CJPayBDCreateOrderResponse *)getCreateOrderResponse {
    return self.manager.response;
}

- (NSDictionary *)confirmRequestParasmWithResponse:(CJPayOrderConfirmResponse *)response
                                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                                           sdkData:(NSString *)sdkData {
    NSMutableDictionary *requestParams = [NSMutableDictionary new];
    NSString *scene = @"cj_live_check_no_src";
    if ([response.faceVerifyInfo.verifyType isEqualToString:@"1"]) {
        scene = @"cj_live_check";
    }
    if (Check_ValidString(self.manager.response.processInfo.processId)) {
        sdkData = [NSString stringWithFormat:@"%@%@", sdkData, self.manager.response.processInfo.processId];
    }
    NSDictionary *verifyParams = @{@"face_app_id": @"1792",
                                   @"face_scene" : scene,
                                   @"face_sdk_data" : CJString([CJPaySafeUtil encryptField:sdkData]),
                                   @"face_veri_ticket" : CJString(getTicketResponse.ticket)
    };
    [requestParams cj_setObject:verifyParams forKey:@"face_verify_params"];
    [requestParams cj_setObject:CJString(response.payFlowNo) forKey:@"pay_flow_no"];
    [requestParams cj_setObject:@"5" forKey:@"req_type"];
    [requestParams addEntriesFromDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast]]; // 获取上次的验证数据
    return [requestParams copy];
}

- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData {
    NSDictionary *requestParams = [self confirmRequestParasmWithResponse:response getTicketResponse:getTicketResponse sdkData:sdkData];
    // 延迟到下一个runloop，避免提交请求时的loading把现有的loading打断
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLoading:YES];
    });
    [CJKeyboard prohibitKeyboardShow];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.manager submitConfimRequest:requestParams fromVerifyItem:self];
//        [CJKeyboard permitKeyboardShow];
        [CJKeyboard delayPermitKeyboardShow:1];
    });
}

+ (void)getTicketWithResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse
          createOrderResponse:(CJPayBDCreateOrderResponse *)createOrderResponse
                       source:(NSString *)source
                       fromVC:(UIViewController *)fromVC
                   completion:(void(^)(CJPayFaceRecogSignResult signResult, CJPayGetTicketResponse * _Nonnull getTicketResponse))completionBlock {
    [CJPayFaceRecogUtil getTicketWithResponse:orderConfirmResponse
                          createOrderResponse:createOrderResponse
                                       source:source
                                       fromVC:fromVC
                                   completion:completionBlock];
}

- (NSString *)getSourceStr {
    return @"cashdesk_pay";
}

- (NSString *)checkTypeName {
    return @"人脸";
}

- (BOOL)p_lynxRetain:(CJPayRetainUtilModel *)retainUtilModel {
    retainUtilModel.retainInfoV2Config.fromScene = @"face_verify";
    @CJWeakify(self)
    retainUtilModel.lynxRetainActionBlock = ^(CJPayLynxRetainEventType eventType, NSDictionary * _Nonnull data) {
        @CJStrongify(self)
        switch (eventType) {
            case CJPayLynxRetainEventTypeOnConfirm:
                [self alertNeedFaceRecogWith:self.manager.confirmResponse getTicketResponse:self.getTicketResponse];
                break;
            case CJPayLynxRetainEventTypeOnCancelAndLeave:
                [self failRecogFace];
                break;
            default:
                break;
        }
    };
    
    return [CJPayRetainUtil couldShowLynxRetainVCWithSourceVC:[UIViewController cj_topViewController] retainUtilModel:retainUtilModel completion:nil];
}

// 活体取消挽留
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
    //构造挽留弹窗点击逻辑
    @CJWeakify(self);
    retainUtilModel.confirmActionBlock = ^{
        @CJStrongify(self)
        //挽留成功，则再展示活体确认弹窗
        [self alertNeedFaceRecogWith:self.manager.confirmResponse getTicketResponse:self.getTicketResponse];
    };
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self)
        [self failRecogFace];
    };
    return [CJPayRetainUtil couldShowRetainVCWithSourceVC:[UIViewController cj_topViewController] retainUtilModel:retainUtilModel];
}

@end
