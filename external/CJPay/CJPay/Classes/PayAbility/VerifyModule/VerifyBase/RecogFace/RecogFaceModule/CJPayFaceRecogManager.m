//
//  CJPayFaceRecogManager.m
//  Pods
//
//  Created by 尚怀军 on 2022/10/24.
//

#import "CJPayFaceRecogManager.h"
#import "CJPayFaceRecogConfigModel.h"
#import "CJPayLoadingManager.h"
#import "CJPayFaceRecogUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayFaceRecognitionProtocolViewController.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayFaceRecogResultModel.h"
#import "CJPayBizWebViewController.h"
#import "CJPayFaceRecogAlertViewController.h"
#import "CJPayRetainUtilModel.h"
#import "CJPayBDRetainInfoModel.h"
#import "CJPayRetainUtil.h"
#import "CJPayFaceRecogAlertContentView.h"
#import "CJPayAlertController.h"
#import "CJPayFaceRecogPlugin.h"
#import "CJPaySettingsManager.h"
#import "CJPayRetainInfoV2Config.h"
#import "CJPayFaceVerifyInfo.h"
#import "CJPayMemRecogFaceRequest.h"
#import "CJPayMemberFaceVerifyResponse.h"
#import "CJPaySafeUtil.h"
#import "NSDictionary+CJPay.h"

@interface CJPayFaceRecogManager()<CJPayTrackerProtocol, CJPayFaceRecogPlugin>

@property (nonatomic, strong) CJPayFaceRecogConfigModel *faceRecogConfigModel;
@property (nonatomic, strong) CJPayGetTicketResponse *getTicketResponse;

@end

@implementation CJPayFaceRecogManager

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPayFaceRecogPlugin)
});

+ (instancetype)sharedInstance {
    static CJPayFaceRecogManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayFaceRecogManager alloc] init];
    });
    return manager;
}

- (void)startFaceRecogWithConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel {
    self.faceRecogConfigModel = faceRecogConfigModel;
    if (self.faceRecogConfigModel.getTicketLoadingBlock) {
        self.faceRecogConfigModel.getTicketLoadingBlock(YES);
    } else {
        [self p_showLoading:YES];
    }
    
    [CJPayFaceRecogUtil getTicketWithConfigModel:faceRecogConfigModel
                                      completion:^(CJPayFaceRecogSignResult signResult, CJPayGetTicketResponse * _Nonnull getTicketResponse) {
        self.getTicketResponse = getTicketResponse;
        if (self.faceRecogConfigModel.getTicketLoadingBlock) {
            self.faceRecogConfigModel.getTicketLoadingBlock(NO);
        } else {
            [self p_showLoading:NO];
        }
        if (signResult == CJPayFaceRecogSignResultSuccess) {
            // 用户已经签了人脸验证协议
            [self p_alertNeedFaceRecogWithResponse:getTicketResponse
                              faceRecogConfigModel:faceRecogConfigModel];
        } else if (signResult == CJPayFaceRecogSignResultNeedResign) {
            // 用户没有签人脸验证的协议
            [self p_startSignProtocolWithResponse:getTicketResponse
                             faceRecogConfigModel:faceRecogConfigModel];
        } else {
            CJPayLogInfo(@"get ticket request return unknown sign status");
        }
    }];
}

- (void)startFaceRecogAndVerifyWithParams:(NSDictionary *)params
                                   fromVC:(UIViewController *)fromVC
                             trackerBlock:(void (^)(NSString * _Nonnull event, NSDictionary * _Nonnull params))trackerBlock
                            pagePushBlock:(void (^)(UIViewController * _Nonnull vc, BOOL animated))pagePushBlock
                    getTicketLoadingBlock:(void (^)(BOOL isLoading))getTicketLoadingBlock
                               completion:(void (^)(BOOL success, NSString *token, CJPayFaceRecogResultModel *resultModel))completion {
    if (!completion) {
        return;
    }
    if (BTD_isEmptyDictionary(params)) {
        completion(NO, nil, nil);
        return;
    }
    NSString *outTradeNo = [params cj_objectForKey:@"order_id"];
    NSString *liveRoute = [params cj_objectForKey:@"live_route"];
    NSString *faceScene = [params cj_objectForKey:@"face_scene"];
    NSString *sourceStr = [params cj_objectForKey:@"source"];
    NSString *riskSource = [params cj_objectForKey:@"risk_source"];
    NSString *appId = [params cj_objectForKey:@"app_id"];
    NSString *merchantId = [params cj_objectForKey:@"merchantId"];
    CJPayFaceRecogPopStyle popStyle = [[params cj_objectForKey:@"pop_style"] integerValue];
    if (BTD_isEmptyString(outTradeNo) ||
        BTD_isEmptyString(liveRoute) ||
        BTD_isEmptyString(appId) ||
        BTD_isEmptyString(merchantId) ||
        !fromVC) {
        completion(NO, nil, nil);
        return;
    }
    
    CJPayFaceVerifyInfo *faceVerifyInfo = [CJPayFaceVerifyInfo new];
    faceVerifyInfo.appId = appId;
    faceVerifyInfo.merchantId = merchantId;
    faceVerifyInfo.verifyChannel = liveRoute;
    faceVerifyInfo.faceScene = faceScene;
    
    CJPayFaceRecogConfigModel *faceRecogConfigModel = [CJPayFaceRecogConfigModel new];
    faceRecogConfigModel.popStyle = popStyle;
    faceRecogConfigModel.appId = faceVerifyInfo.appId;
    faceRecogConfigModel.merchantId = faceVerifyInfo.merchantId;
    faceRecogConfigModel.memberBizOrderNo = outTradeNo;
    faceRecogConfigModel.sourceStr = sourceStr;
    faceRecogConfigModel.riskSource = riskSource;
    faceRecogConfigModel.fromVC = fromVC;
    faceRecogConfigModel.faceVerifyInfo = faceVerifyInfo;
    @weakify(self);
    faceRecogConfigModel.trackerBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull params) {
        @strongify(self);
        trackerBlock ? trackerBlock(event, params) : nil;
    };
    if (pagePushBlock) {
        faceRecogConfigModel.pagePushBlock = ^(CJPayBaseViewController * _Nonnull vc, BOOL animated) {
            pagePushBlock ? pagePushBlock(vc, animated) : nil;
        };
    }
    faceRecogConfigModel.getTicketLoadingBlock = ^(BOOL isLoading) {
        getTicketLoadingBlock ? getTicketLoadingBlock(isLoading) : nil;
    };
    faceRecogConfigModel.faceRecogCompletion = ^(CJPayFaceRecogResultModel * _Nonnull resultModel) {
        @strongify(self);
        switch (resultModel.result) {
            case CJPayFaceRecogResultTypeSuccess: {
                // 验证
                NSDictionary *verifyBizParams = @{
                    @"out_trade_no": CJString(outTradeNo),
                    @"ailab_app_id": @"1792",
                    @"scene": CJString(resultModel.getTicketResponse.scene),
                    @"live_detect_data": CJString([CJPaySafeUtil encryptField:resultModel.faceDataStr]),
                    @"ticket": CJString(resultModel.getTicketResponse.ticket),
                    @"face_scene": CJString(resultModel.getTicketResponse.faceScene),
                    @"merchant_id": CJString(faceVerifyInfo.merchantId),
                    @"app_id": CJString(faceVerifyInfo.appId)
                };
                getTicketLoadingBlock(YES);
                [CJPayMemRecogFaceRequest startRequestWithParams:verifyBizParams completion:^(NSError * _Nonnull error, CJPayMemberFaceVerifyResponse * _Nonnull response) {
                    getTicketLoadingBlock(NO);
                    if ([response isSuccess] && response.token) {
                        completion(YES, response.token, resultModel);
                    } else {
                        completion(NO, response.token, resultModel);
                    }
                }];
            }
                break;
            case CJPayFaceRecogResultTypeFail:
                completion(NO, nil, resultModel);
                break;
            case CJPayFaceRecogResultTypeCancel:
                [self p_pop];
                completion(NO, nil, resultModel);
                break;
            default:
                completion(NO, nil, resultModel);
                break;
        }
    };
    [[CJPayFaceRecogManager sharedInstance] startFaceRecogWithConfigModel:faceRecogConfigModel];
}

- (void)p_alertNeedFaceRecogWithResponse:(CJPayGetTicketResponse *)getTicketResponse
                    faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel {
    if (self.faceRecogConfigModel.popStyle == CJPayFaceRecogPopStyleRetry) {
        [self p_retryAlertWithResponse:getTicketResponse
                  faceRecogConfigModel:faceRecogConfigModel];
    } else if (!faceRecogConfigModel.shouldSkipAlertPage) {
        [self p_firstAlertWithResponse:getTicketResponse
                  faceRecogConfigModel:faceRecogConfigModel];
    } else {
        [self p_startFaceRecogWithResponse:getTicketResponse
                      faceRecogConfigModel:faceRecogConfigModel];
    }
}

- (void)p_firstAlertWithResponse:(CJPayGetTicketResponse *)getTicketResponse
            faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel {
    [self event:@"wallet_alivecheck_safetyassurace_imp" params:@{}];
    
    CJPayFaceRecognitionModel *model = [CJPayFaceRecogUtil createFaceRecogAlertModelWithResponse:getTicketResponse
                                                                            faceRecogConfigModel:faceRecogConfigModel];
    
    CJPayFaceRecogAlertViewController *faceRecogAlertVC = [[CJPayFaceRecogAlertViewController alloc] initWithFaceRecognitionModel:model];
    faceRecogAlertVC.contentView.trackDelegate = self;
    NSInteger hasSrcNum = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
    @CJWeakify(self)
    faceRecogAlertVC.closeBtnBlock = ^{
        @CJStrongify(self)
        [self event:@"wallet_alivecheck_safetyassurace_click" params:@{@"button_type": @(0)}];
        if ([self shouldShowRetainVC]) {
            //活体挽留
        } else {
            [self p_callBackWithResultType:CJPayFaceRecogResultTypeCancel faceDataStr:@""];
        }
    };
    faceRecogAlertVC.confirmBtnBlock = ^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(faceRecogConfigModel.firstAlertConfirmBlock);
        [self p_startFaceRecogWithResponse:getTicketResponse
                      faceRecogConfigModel:faceRecogConfigModel];
        [self event:@"wallet_alivecheck_safetyassurace_click" params:@{
            @"button_type": @(1),
            @"alivecheck_scene": CJString(getTicketResponse.faceScene),
            @"alivecheck_type" : @(hasSrcNum)
        }];
    };
    [self p_pushWithVC:faceRecogAlertVC];
}

- (void)p_retryAlertWithResponse:(CJPayGetTicketResponse *)getTicketResponse
            faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel {
    NSInteger hasSrcNum = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
    [self event:@"wallet_alivecheck_fail_pop"
         params:@{@"alivecheck_type": @(hasSrcNum),
                  @"enter_from": @(2),
                  @"fail_before": @(1),
                  @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];

    NSString *headStr = CJPayLocalizedStr(@"人脸识别只能由");
    NSString *tailStr = CJPayLocalizedStr(@"本人操作");
    NSString *messageStr = [NSString stringWithFormat:@"%@ %@ %@",headStr, CJString(getTicketResponse.nameMask), tailStr];
    CJPayAlertController *alertController = [CJPayAlertController alertControllerWithTitle:CJPayLocalizedStr(@"抱歉，没有认出你")
                                                                                   message:messageStr
                                                                            preferredStyle:UIAlertControllerStyleAlert];
    @CJWeakify(self)
    UIAlertAction *leftAction = [UIAlertAction actionWithTitle:CJPayLocalizedStr(@"取消")
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
        @CJStrongify(self)
        [self event:@"wallet_alivecheck_fail_pop_click"
             params:@{@"alivecheck_type": @(hasSrcNum),
                      @"button_type": @(0),
                      @"enter_from": @(2),
                      @"fail_before": @(1),
                      @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
        if ([self shouldShowRetainVC]) {
            //进行活体挽留
        } else {
            [self p_callBackWithResultType:CJPayFaceRecogResultTypeCancel faceDataStr:@""];
        }
    }];
    
    UIAlertAction *rightAction = [UIAlertAction actionWithTitle:CJPayLocalizedStr(@"再试一次")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
        [self event:@"wallet_alivecheck_fail_pop_click"
                  params:@{@"alivecheck_type": @(hasSrcNum),
                           @"button_type": @(1),
                           @"enter_from": @(2),
                           @"fail_before": @(1),
                           @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
        @CJStrongify(self)
        [self p_startFaceRecogWithResponse:getTicketResponse
                      faceRecogConfigModel:faceRecogConfigModel];
    }];
        
    [alertController addAction:leftAction];
    [alertController addAction:rightAction];
    
    [[self p_topVC] cj_presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)p_lynxRetain:(CJPayRetainUtilModel *)retainUtilModel {
    retainUtilModel.retainInfoV2Config.fromScene = @"face_verify";
    @CJWeakify(self)
    retainUtilModel.lynxRetainActionBlock = ^(CJPayLynxRetainEventType eventType, NSDictionary * _Nonnull data) {
        @CJStrongify(self)
        switch (eventType) {
            case CJPayLynxRetainEventTypeOnConfirm:
                [self p_alertNeedFaceRecogWithResponse:self.getTicketResponse
                                  faceRecogConfigModel:self.faceRecogConfigModel];
                break;
            case CJPayLynxRetainEventTypeOnCancelAndLeave:
                [self p_callBackWithResultType:CJPayFaceRecogResultTypeCancel faceDataStr:@""];
                break;
            default:
                break;
        }
    };
    
    return [CJPayRetainUtil couldShowLynxRetainVCWithSourceVC:[self p_topVC] retainUtilModel:retainUtilModel completion:nil];
}

- (BOOL)shouldShowRetainVC {
    CJPayRetainUtilModel *retainUtilModel = self.faceRecogConfigModel.retainUtilModel;
    retainUtilModel.positionType = CJPayRetainVerifyPage;
    // 埋点参数配置
    retainUtilModel.eventNameForPopUpClick = @"wallet_riskcontrol_password_keep_pop_click";
    retainUtilModel.eventNameForPopUpShow = @"wallet_riskcontrol_password_keep_pop_show";
    [retainUtilModel buildTrackEventNormalSetting];
    
    if ([retainUtilModel.retainInfoV2Config isOpenLynxRetain]) {
        return [self p_lynxRetain:retainUtilModel];
    }
    
    CJPayBDRetainInfoModel *retainInfo = self.faceRecogConfigModel.retainUtilModel.retainInfo;
    if (!(retainInfo && retainInfo.needVerifyRetain)) {
        return NO;
    }
    
    //构造挽留弹窗点击逻辑
    @CJWeakify(self);
    retainUtilModel.confirmActionBlock = ^{
        @CJStrongify(self)
        //挽留成功，则再展示活体确认弹窗
        [self p_alertNeedFaceRecogWithResponse:self.getTicketResponse
                          faceRecogConfigModel:self.faceRecogConfigModel];
    };
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self)
        [self p_callBackWithResultType:CJPayFaceRecogResultTypeCancel faceDataStr:@""];
    };
    return [CJPayRetainUtil couldShowRetainVCWithSourceVC:[self p_topVC]
                                          retainUtilModel:retainUtilModel];
}

- (void)p_startSignProtocolWithResponse:(CJPayGetTicketResponse *)getTicketResponse
                   faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel {
    CJPayFaceRecognitionModel *model = [CJPayFaceRecogUtil createFullScreenSignPageModelWithResponse:getTicketResponse
                                                                                faceRecogConfigModel:faceRecogConfigModel];
    CJPayFaceRecognitionProtocolViewController *faceRecogProtocolVC = [[CJPayFaceRecognitionProtocolViewController alloc] initWithFaceRecognitionModel:model];
    faceRecogProtocolVC.trackDelegate = self;
    faceRecogProtocolVC.shouldCloseCallBack = YES;
    @CJWeakify(self)
    @CJWeakify(faceRecogProtocolVC)
    faceRecogProtocolVC.cjBackBlock = ^{
        @CJStrongify(self)
        @CJStrongify(faceRecogProtocolVC)
        if (faceRecogConfigModel.shouldCallBackAfterClose) {
            [faceRecogProtocolVC closeWithCompletionBlock:^{
                @CJStrongify(self)
                [self p_callBackWithResultType:CJPayFaceRecogResultTypeCancel faceDataStr:@""];
            }];
        } else {
            [self p_callBackWithResultType:CJPayFaceRecogResultTypeCancel faceDataStr:@""];
        }
    };
    
    faceRecogProtocolVC.signSuccessBlock = ^(NSString * _Nonnull ticket) {
        @CJStrongify(self)
        [self p_startFaceRecogWithResponse:getTicketResponse
                      faceRecogConfigModel:faceRecogConfigModel];
    };
    
    [self p_pushWithVC:faceRecogProtocolVC];
}

- (void)p_startFaceRecogWithResponse:(CJPayGetTicketResponse *)getTicketResponse
                faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel {
    
    if (![getTicketResponse.liveRoute isEqualToString:BDPayVerifyChannelFacePlusStr]) {
        // ailab 活体验证
        [self p_doAILabFaceRecogWithResponse:getTicketResponse
                        faceRecogConfigModel:faceRecogConfigModel];

    } else {
        // face++ 活体验证
        [self p_doFacePlusLivenessWithResponse:getTicketResponse
                          faceRecogConfigModel:faceRecogConfigModel];
    }
}

// ailab 活体验证
- (void)p_doAILabFaceRecogWithResponse:(CJPayGetTicketResponse *)getTicketResponse
                  faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel {
    if (!CJ_OBJECT_WITH_PROTOCOL(CJPayFaceLivenessProtocol)) {
        [CJMonitor trackService:@"wallet_rd_ailab_face_detect_fail"
                       category:@{}
                          extra:@{}];
        return;
    }
    
    NSString *ailabScene = CJString(getTicketResponse.scene);
    if (Check_ValidString(getTicketResponse.faceScene)) {
        ailabScene = CJString(getTicketResponse.faceScene);
    }
    NSDictionary *baseParam = @{@"cert_app_id": @"1792",
                                @"scene": ailabScene,
                                @"mode": @(0),
                                @"ticket": CJString(getTicketResponse.ticket),
                                @"eventParams": @{@"source": CJString(faceRecogConfigModel.riskSource)}
    };
    
    @CJWeakify(self)
    [CJ_OBJECT_WITH_PROTOCOL(CJPayFaceLivenessProtocol) doFaceLivenessWith:baseParam
                                                               extraParams:[NSDictionary new]
                                                                  callback:^(NSDictionary *data, NSError *error) {
        @CJStrongify(self)
        if (!error) {
            // 成功取到人脸照片
            NSDictionary *dataDic = [data cj_dictionaryValueForKey:@"data"];
            NSData *sdkData = [dataDic cj_dataValueForKey:@"sdk_data"];
            
            // 异步上传活体视频
            [CJPayFaceRecogUtil asyncUploadFaceVideoWithAppId:faceRecogConfigModel.appId
                                                   merchantId:faceRecogConfigModel.merchantId
                                                    videoPath:[dataDic cj_stringValueForKey:@"video_path"]];
            
            NSString *sdkDataStr = @"";
            if (sdkData) {
                sdkDataStr = [[NSString alloc] initWithData:sdkData encoding:NSUTF8StringEncoding];
            }
            [self p_callBackWithResultType:CJPayFaceRecogResultTypeSuccess
                               faceDataStr:sdkDataStr];
        } else {
            NSString *code = [error.userInfo cj_stringValueForKey:@"errorCode"];
            NSString *msg = [error.userInfo cj_stringValueForKey:@"errorMessage"];
            // 非用户主动取消触发错误提示用户
            if (![code isEqualToString:@"-1006"]) {
                if (Check_ValidString(msg)) {
                    [CJToast toastText:msg inWindow:[self p_topVC].cj_window];
                } else {
                    [CJToast toastText:CJPayNoNetworkMessage inWindow:[self p_topVC].cj_window];
                }
            }
            if (![code isEqualToString:@"-3003"]) { //没开系统相册权限不回调停留在原页面
                [self p_callBackWithResultType:CJPayFaceRecogResultTypeFail
                                   faceDataStr:@""];
            }
        }
    }];
}

// face++ 活体验证
- (void)p_doFacePlusLivenessWithResponse:(CJPayGetTicketResponse *)getTicketResponse
                    faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel  {
    CJPayBizWebViewController *webVC = [[CJPayBizWebViewController alloc] initWithUrlString:getTicketResponse.ticket];
    webVC.returnUrl = BDPayFacePlusVerifyReturnURL;
    webVC.allowsPopGesture = NO;
    @CJWeakify(self)
    @CJWeakify(webVC);
    webVC.cjBackBlock = ^{
        @CJStrongify(webVC);
        @CJStrongify(self)
        [webVC closeWebVC];
        [self p_callBackWithResultType:CJPayFaceRecogResultTypeFail
                           faceDataStr:@""];
    };
    
    webVC.closeCallBack = ^(id data) {
        @CJStrongify(self)
        if (!data || ![data isKindOfClass:[NSDictionary class]]) {
            [self p_callBackWithResultType:CJPayFaceRecogResultTypeFail
                               faceDataStr:@""];
            CJPayLogInfo(@"face++ web page close unexpectedly");
            return;
        }
        
        NSDictionary *dic = (NSDictionary *)data;
        if ([[dic cj_stringValueForKey:@"action"] isEqualToString:@"return_by_url"]) {
            [self p_callBackWithResultType:CJPayFaceRecogResultTypeSuccess
                               faceDataStr:@""];
        } else {
            [self p_callBackWithResultType:CJPayFaceRecogResultTypeFail
                               faceDataStr:@""];
            CJPayLogInfo(@"face++ web page close unexpectedly");
        }
    };
    
    [self p_pushWithVC:webVC];
}

- (void)p_callBackWithResultType:(CJPayFaceRecogResultType)resultType
                     faceDataStr:(NSString *)faceDataStr {
    if (resultType == CJPayFaceRecogResultTypeFail) {
        [self event:@"wallet_alivecheck_result"
                  params:@{@"result": @(0),
                           @"alivecheck_type":Check_ValidString(self.getTicketResponse.ticket) ? @(1) : @(0),
                           @"fail_before": self.faceRecogConfigModel.popStyle == CJPayFaceRecogPopStyleRetry ? @(1) : @(0),
                           @"enter_from":@([self.getTicketResponse getEnterFromValue]),
                           @"url": @"open_bytecert_sdk",
                           @"alivecheck_scene": CJString(self.getTicketResponse.faceScene)}];
    }
    
    CJPayFaceRecogResultModel *resultModel = [CJPayFaceRecogResultModel new];
    resultModel.result = resultType;
    resultModel.faceDataStr = faceDataStr;
    resultModel.getTicketResponse = self.getTicketResponse;
    CJ_CALL_BLOCK(self.faceRecogConfigModel.faceRecogCompletion, resultModel);
}

- (UIViewController *)p_topVC {
    return [UIViewController cj_foundTopViewControllerFrom:self.faceRecogConfigModel.fromVC];
}

- (void)p_pushWithVC:(CJPayBaseViewController *)vc {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self.faceRecogConfigModel.fromVC];
    if (self.faceRecogConfigModel.pagePushBlock) {
        self.faceRecogConfigModel.pagePushBlock(vc, YES);
    } else if (topVC.navigationController && [topVC.navigationController isKindOfClass:[CJPayNavigationController class]]) {
        [topVC.navigationController pushViewController:vc animated:YES];
    } else {
        [vc presentWithNavigationControllerFrom:topVC useMask:NO completion:nil];
    }
}

- (void)p_pop {
    if (self.faceRecogConfigModel.pagePushBlock) {
        return;
    }
    UIViewController *topVC = [UIViewController cj_topViewController];
    if (topVC.navigationController && [topVC.navigationController isKindOfClass:[CJPayNavigationController class]]) {
        [topVC.navigationController popViewControllerAnimated:YES];
    } else if (topVC.navigationController.presentingViewController) {
        [topVC.navigationController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)p_showLoading:(BOOL)isLoading {
    if (isLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)event:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *trackParamDic = [NSMutableDictionary new];
    if (params) {
        [trackParamDic addEntriesFromDictionary:params];
    }
    NSString *aliveCheckStyleStr = [self.getTicketResponse getLiveRouteTrackStr];
    [trackParamDic cj_setObject:aliveCheckStyleStr forKey:@"alivecheck_style"];
    [trackParamDic cj_setObject:CJString(self.faceRecogConfigModel.riskSource) forKey:@"risk_source"];
    if (self.faceRecogConfigModel.trackerBlock) {
        self.faceRecogConfigModel.trackerBlock(event, trackParamDic);
    } else {
        [CJTracker event:event params:trackParamDic];
    }
}

- (void)asyncUploadFaceVideoWithAppId:(NSString *)appId
                           merchantId:(NSString *)merchantId
                            videoPath:(NSString *)videoPath {
    [CJPayFaceRecogUtil asyncUploadFaceVideoWithAppId:appId
                                           merchantId:merchantId
                                            videoPath:videoPath];
}

@end
