//
//  CJPayVerifyItemRecogFaceRetry.m
//  CJPay
//
//  Created by 尚怀军 on 2020/8/23.
//

#import "CJPayVerifyItemRecogFaceRetry.h"
#import "CJPayAlertUtil.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayVerifyItemRecogFace.h"
#import "CJPayVerifyItemRecogFace.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayBizWebViewController.h"
#import "UIViewController+CJTransition.h"
#import "CJPaySafeUtilsHeader.h"
#import "CJPayRetainUtil.h"
#import "CJPayFaceRecogUtil.h"
#import "CJPaySettingsManager.h"
#import "CJPayRetainInfoV2Config.h"

@implementation CJPayVerifyItemRecogFaceRetry

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 人脸验证失败，再试一次
    if (self.manager.lastConfirmVerifyItem == self) {
        CJPayVerifyItem *faceVerifyItem = [self.manager getSpecificVerifyType:CJPayVerifyTypeFaceRecog];
        NSNumber *enterFrom = @(2);
        if (faceVerifyItem && [faceVerifyItem isKindOfClass:CJPayVerifyItemRecogFace.class]) {
            enterFrom = @(((CJPayVerifyItemRecogFace *)faceVerifyItem).enterFrom.intValue);
        }
        [self event:@"wallet_alivecheck_result"
             params:@{@"result": [response isSuccess] ? @(1) : @(0),
                      @"alivecheck_type":[response.faceVerifyInfo.verifyType isEqualToString:@"1"] ? @(1) : @(0),
                      @"fail_before": @(1),
                      @"fail_code": CJString(response.code),
                      @"fail_reason": CJString(response.msg),
                      @"enter_from":@(enterFrom.intValue),
                      @"url": @"open_bytecert_sdk",
                      @"alivecheck_scene": CJString(self.getTicketResponse.faceScene)}];
    }
    if ([response.code isEqualToString:@"CD002011"]) {
        self.verifySource = [self wakeVerifySource];
        [self alertNeedRetryFaceRecogWith:response];
        return YES;
    }
    return NO;
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

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    if (self.manager.isOneKeyQuickPay) {
        self.verifySource = @"极速支付-加验";
    }
    // 下单转确认支付
    [self alertNeedRetryFaceRecogWith:response.confirmResponse];
}

- (void)alertNeedRetryFaceRecogWith:(CJPayOrderConfirmResponse *)orderConfirmResponse {
    [self showLoading:YES];
    @CJWeakify(self);
    [CJKeyboard prohibitKeyboardShow];
    [CJPayVerifyItemRecogFace getTicketWithResponse:orderConfirmResponse
                                createOrderResponse:[self getCreateOrderResponse]
                                             source:[self getSourceStr]
                                             fromVC:[self p_topVC]
                                         completion:^(CJPayFaceRecogSignResult signResult,  CJPayGetTicketResponse * _Nonnull getTicketResponse) {
        @CJStrongify(self);
        self.getTicketResponse = getTicketResponse;
        [self showLoading:NO];
        [self p_showRetryFaceRecogAlertWithConfirmResponse:orderConfirmResponse
                                         getTicketResponse:getTicketResponse];
    }];
}

- (void)p_showRetryFaceRecogAlertWithConfirmResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse
                                   getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse  {
    CJPayVerifyItem *faceVerifyItem = [self.manager getSpecificVerifyType:CJPayVerifyTypeFaceRecog];
    NSNumber *enterFrom = @(2);
    if (faceVerifyItem && [faceVerifyItem isKindOfClass:CJPayVerifyItemRecogFace.class]) {
        enterFrom = @(((CJPayVerifyItemRecogFace *)faceVerifyItem).enterFrom.intValue);
    }
    NSInteger hasSrcNum = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
    [self event:@"wallet_alivecheck_fail_pop"
         params:@{@"alivecheck_type": @(hasSrcNum),
                  @"enter_from": enterFrom,
                  @"fail_before": @(1),
                  @"pop_type" : (Check_ValidString(orderConfirmResponse.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                  @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];

    NSString *headStr = CJPayLocalizedStr(@"人脸识别只能由");
    NSString *tailStr = CJPayLocalizedStr(@"本人操作");
    NSString *messageStr = [NSString stringWithFormat:@"%@ %@ %@",headStr, CJString(getTicketResponse.nameMask), tailStr];
    @CJWeakify(self)
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"抱歉，没有认出你") content:messageStr leftButtonDesc:CJPayLocalizedStr(@"取消") rightButtonDesc:CJPayLocalizedStr(@"再试一次") leftActionBlock:^{
        @CJStrongify(self)
        [self event:@"wallet_alivecheck_fail_pop_click"
             params:@{@"alivecheck_type": @(hasSrcNum),
                      @"button_type": @(0),
                      @"enter_from": enterFrom,
                      @"fail_before": @(1),
                      @"pop_type" : (Check_ValidString(orderConfirmResponse.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                      @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
        if ([self shouldShowRetainVC]) {
            //进行活体挽留
        } else {
            [self failRetryRecogFace];
        }
    } rightActioBlock:^{
        [self event:@"wallet_alivecheck_fail_pop_click"
                  params:@{@"alivecheck_type": @(hasSrcNum),
                           @"button_type": @(1),
                           @"enter_from": @(2),
                           @"fail_before": @(1),
                           @"pop_type" : (Check_ValidString(orderConfirmResponse.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                           @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
        @CJStrongify(self)
        if (self) {
            [self p_startFaceRecogWithConfirmResponse:orderConfirmResponse
                                    getTicketResponse:getTicketResponse];
        }
    } useVC:[self p_topVC]];
}

- (void)p_startFaceRecogWithConfirmResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse
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
        
        [self p_doFaceLivenessWith:orderConfirmResponse
                 getTicketResponse:getTicketResponse
                         baseParam:baseParam];
    } else {
        // faceplusplus 活体验证
        [self p_doFacePlusLivenessWith:orderConfirmResponse
                     getTicketResponse:getTicketResponse];
    }
}

- (NSString *)getSourceStr {
    return @"cashdesk_pay";
}

- (void)p_doFaceLivenessWith:(CJPayOrderConfirmResponse *)response
           getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                   baseParam:(NSDictionary *)baseParam {
    NSString *enterFrom = @"1";
    if (self.manager.lastVerifyType == self.verifyType) {
        enterFrom = @"2";
    }
    
    if (!CJ_OBJECT_WITH_PROTOCOL(CJPayFaceLivenessProtocol)) {
        [CJMonitor trackService:@"wallet_rd_ailab_face_detect_fail"
                       category:@{}
                          extra:@{}];
        return;
    }
    [CJKeyboard prohibitKeyboardShow];

    [CJ_OBJECT_WITH_PROTOCOL(CJPayFaceLivenessProtocol) doFaceLivenessWith:baseParam
                                                               extraParams:[NSDictionary new]
                                                                  callback:^(NSDictionary *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CJKeyboard permitKeyboardShow];

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
                // 收银台验证流程中需要pop到最上边的半屏vc做loading
                if (self.manager) {
                    [CJPayFaceRecogUtil tryPoptoTopHalfVC:[self.manager.homePageVC topVC]];
                }
                [self submitFaceDataWithResponse:response
                               getTicketResponse:getTicketResponse
                                         sdkData:sdkDataStr];
                
            } else {
                [self failRetryRecogFace];
                [self showLoading:NO];
                NSString *code = [error.userInfo cj_stringValueForKey:@"errorCode"];
                NSString *msg = [error.userInfo cj_stringValueForKey:@"errorMessage"];
                if (Check_ValidString(msg)) {
                    [CJToast toastText:msg inWindow:[self p_topVC].cj_window];
                }
                [self event:@"wallet_alivecheck_result"
                          params:@{@"result": @(0),
                                   @"alivecheck_type":Check_ValidString(getTicketResponse.ticket) ? @(1) : @(0),
                                   @"fail_before":@(1),
                                   @"enter_from":@(enterFrom.intValue),
                                   @"url": @"open_bytecert_sdk",
                                   @"fail_code": CJString(code),
                                   @"fail_reason": CJString(msg),
                                   @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
            }
        });
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
        @CJStrongify(self)
        [webVC closeWebVC];
        [self showLoading:NO];
        [self failRetryRecogFace];
    };
    webVC.closeCallBack = ^(id data) {
        @CJStrongify(self)
        NSDictionary *dic = (NSDictionary *)data;
        if ([[dic cj_stringValueForKey:@"action"] isEqualToString:@"return_by_url"]) {
            [self submitFaceDataWithResponse:orderConfirmResponse
                           getTicketResponse:getTicketResponse
                                     sdkData:@""];
        } else {
            [self failRetryRecogFace];
        }
    };
    [self pushWithVC:webVC];
}

- (void)failRetryRecogFace {
    [self.manager sendEventTOVC:CJPayHomeVCEventUserCancelRiskVerify obj:@(CJPayVerifyTypeFaceRecogRetry)];
    [self.manager sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
    [CJKeyboard delayPermitKeyboardShow:0.5];
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

- (CJPayBDCreateOrderResponse *)getCreateOrderResponse {
    return self.manager.response;
}

- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData {
    NSMutableDictionary *requestParams = [NSMutableDictionary new];
    if (Check_ValidString(self.manager.response.processInfo.processId)) {
        sdkData = [NSString stringWithFormat:@"%@%@", sdkData, self.manager.response.processInfo.processId];
    }
    NSDictionary *verifyParams = @{@"face_app_id": @"1792",
                                   @"face_scene" : CJString(getTicketResponse.scene),
                                   @"face_sdk_data" : CJString([CJPaySafeUtil encryptField:sdkData]),
                                   @"face_veri_ticket" : CJString(getTicketResponse.ticket)};
    
    [requestParams cj_setObject:verifyParams forKey:@"face_verify_params"];
    [requestParams cj_setObject:CJString(response.payFlowNo) forKey:@"pay_flow_no"];
    [requestParams cj_setObject:@"5" forKey:@"req_type"];
    [requestParams addEntriesFromDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast]]; // 获取上次的验证数据
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLoading:YES];
    });
    [self.manager submitConfimRequest:requestParams fromVerifyItem:self];
    [CJKeyboard permitKeyboardShow];
}

- (NSString *)wakeVerifySource {
    NSString *verifySource = [self.manager.lastWakeVerifyItem checkTypeName];
    NSString *wakeVerifySource = [NSString stringWithFormat:@"%@-加验", verifySource];
    return wakeVerifySource;
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
                [self p_startFaceRecogWithConfirmResponse:self.manager.confirmResponse getTicketResponse:self.getTicketResponse];
                break;
            case CJPayLynxRetainEventTypeOnCancelAndLeave:
                [self failRetryRecogFace];
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
    
    //构造挽留弹窗
    @CJWeakify(self);
    retainUtilModel.confirmActionBlock = ^{
        @CJStrongify(self)
        [self p_startFaceRecogWithConfirmResponse:self.manager.confirmResponse getTicketResponse:self.getTicketResponse];
    };
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self)
        [self failRetryRecogFace];
    };
    return [CJPayRetainUtil couldShowRetainVCWithSourceVC:[UIViewController cj_topViewController] retainUtilModel:retainUtilModel];
}

@end
