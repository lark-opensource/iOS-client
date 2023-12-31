//
//  CJPayTransferPayController.m
//  CJPay-5b542da5
//
//  Created by 尚怀军 on 2022/10/28.
//

#import "CJPayTransferPayController.h"
#import "CJPayNavigationController.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPayLoadingManager.h"
#import "CJPayFaceRecogManager.h"
#import "CJPayFaceRecogConfigModel.h"
#import "CJPayFaceRecogResultModel.h"
#import "CJPayFaceRecogCommonRequest.h"
#import "CJPayFaceRecogCommonResponse.h"
#import "CJPayTransferInfoModel.h"
#import "CJPayFaceVerifyInfo.h"
#import "CJPayGetTicketResponse.h"
#import "CJPaySDKDefine.h"
#import "CJPaySafeManager.h"
#import "CJPaySafeUtil.h"
#import "CJPayBindCardController.h"
#import "CJPayDeskUtil.h"
#import "UIViewController+CJPay.h"
#import "CJPayToast.h"
#import "CJPayBaseViewController.h"

@interface CJPayTransferPayController()

@property (nonatomic, copy, nullable) void (^completion)(CJPayManagerResultType, NSString *);
@property (nonatomic, strong) CJPayNavigationController *navigationController;
@property (nonatomic, strong) CJPayFaceRecogConfigModel *faceRecogConfigModel;
@property (nonatomic, copy) void(^customLoadingBlock)(BOOL);

@end

@implementation CJPayTransferPayController

- (void)startPaymentWithParams:(NSDictionary *)params
                    completion:(void (^)(CJPayManagerResultType type, NSString *errorMsg))completion {
    self.completion = [completion copy];
    self.customLoadingBlock = [[params cj_objectForKey:@"custom_loading_block"] copy];
    NSString *transferInfoStr = [params cj_stringValueForKey:@"transfer_info"];
    CJPayTransferInfoModel *transferModel = [[CJPayTransferInfoModel alloc] initWithDictionary:[transferInfoStr cj_toDic] error:nil];
    transferModel.trackInfoDic = [params cj_dictionaryValueForKey:@"track_info"];
    
    if ([transferModel.needBindCard isEqualToString:@"1"]) {
        [self p_bindCardWithTransferModel:transferModel
                                   params:params];
    } else if ([transferModel.needOpenAccount isEqualToString:@"1"]) {
        [self p_openAccountWithTransferModel:transferModel
                                      params:params];
    } else {
        [self p_transferPayWithTransferModel:transferModel];
    }
}

- (void)p_bindCardWithTransferModel:(CJPayTransferInfoModel *)transferModel
                             params:(NSDictionary *)params {
    NSMutableDictionary *bindCardParams = [NSMutableDictionary new];
    [bindCardParams cj_setObject:CJString(transferModel.zgAppId) forKey:@"app_id"];
    [bindCardParams cj_setObject:CJString(transferModel.zgMerchantId) forKey:@"merchant_id"];
    [bindCardParams cj_setObject:[params cj_dictionaryValueForKey:@"bind_card_info"] forKey:@"bind_card_info"];
    [bindCardParams cj_setObject:[params cj_dictionaryValueForKey:@"track_info"] forKey:@"track_info"];
    [bindCardParams cj_setObject:@"transfer_pay" forKey:@"trade_scene"];
    
    __block CJPayBindCardController *bindCardController = [CJPayBindCardController new];
    @CJWeakify(self)
    [bindCardController startBindCardWithParams:bindCardParams
                                     completion:^(CJPayBindCardResult type, NSString * _Nonnull errorMsg) {
        @CJStrongify(self)
        if (type == CJPayBindCardResultSuccess) {
            if ([transferModel.needQueryFaceData isEqualToString:@"1"]) {
                [self p_queryFaceDataAndTransferPayWithTransferModel:transferModel];
            } else {
                [self p_transferPayWithTransferModel:transferModel];
            }
        } else {
            [self p_callbackWithResult:CJPayManagerResultFailed];
        }
        bindCardController = nil;
    }];
}

- (void)p_openAccountWithTransferModel:(CJPayTransferInfoModel *)transferModel
                                params:(NSDictionary *)params {
    if (!Check_ValidString(transferModel.openAccountUrl)) {
        CJPayLogInfo(@"open_account_url nil!")
        [self p_callbackWithResult:CJPayManagerResultFailed];
        return;
    }
    
    // 1:成功，0:取消
    @CJWeakify(self)
    [CJPayDeskUtil openLynxPageBySchema:transferModel.openAccountUrl
                       completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
        NSDictionary *dataDic = [[response.data cj_dictionaryValueForKey:@"data"] cj_dictionaryValueForKey:@"msg"];
        if (!Check_ValidDictionary(dataDic)){
            CJPayLogInfo(@"transfer pay lynx callback data wrong!")
            [self p_callbackWithResult:CJPayManagerResultFailed];
            return;
        }
        
        int code = [dataDic cj_intValueForKey:@"code" defaultValue:0];
        @CJStrongify(self)
        if (code == 1) {
            if ([transferModel.needQueryFaceData isEqualToString:@"1"]) {
                [self p_queryFaceDataAndTransferPayWithTransferModel:transferModel];
            } else {
                [self p_transferPayWithTransferModel:transferModel];
            }
        } else {
            [self p_callbackWithResult:CJPayManagerResultFailed];
        }
    }];
}

- (void)p_queryFaceDataAndTransferPayWithTransferModel:(CJPayTransferInfoModel *)transferModel {
    NSMutableDictionary *bizParams = [NSMutableDictionary new];
    NSMutableDictionary *extDic = [NSMutableDictionary new];
    NSMutableDictionary *secureDic = [NSMutableDictionary dictionary];
    [extDic cj_setObject:CJString(transferModel.processId) forKey:@"process_id"];
    
    [bizParams cj_setObject:CJString(transferModel.appId) forKey:@"app_id"];
    [bizParams cj_setObject:CJString(transferModel.merchantId) forKey:@"merchant_id"];
    [bizParams cj_setObject:CJString(transferModel.tradeNo) forKey:@"trade_no"];
    [bizParams cj_setObject:@"query_member_face" forKey:@"method"];
    [bizParams cj_setObject:extDic forKey:@"exts"];
    
    [self startLoading];
    @CJWeakify(self)
    [CJPayFaceRecogCommonRequest startFaceRecogRequestWithBizParams:bizParams
                                                    completionBlock:^(NSError * _Nonnull error, CJPayFaceRecogCommonResponse * _Nonnull response) {
        @CJStrongify(self)
        if (response && [response isSuccess] && response.faceVerifyInfo) {
            if (Check_ValidString(response.lynxUrl)) {
                transferModel.lynxUrl = response.lynxUrl;
            }
            transferModel.faceVerifyInfo = response.faceVerifyInfo;
            [self p_transferPayWithTransferModel:transferModel];
        } else {
            [self stopLoading];
            NSString *toastMsg = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
            [CJToast toastText:CJString(toastMsg) inWindow:[UIViewController cj_topViewController].cj_window];
            [self p_callbackWithResult:CJPayManagerResultFailed];
        }
    }];
}

- (void)p_transferPayWithTransferModel:(CJPayTransferInfoModel *)transferModel {
    if (![transferModel.needFace isEqualToString:@"1"]) {
        [self stopLoading];
        if (Check_ValidString(transferModel.lynxUrl)) {
            [self p_openBigPayLynxPageWithSchema:transferModel.lynxUrl
                                   transferModel:transferModel];
        } else {
            [self p_callbackWithResult:CJPayManagerResultFailed];
            CJPayLogInfo(@"transfer pay no lynxUrl, isNeedFaceRecog = NO!")
        }
        return;
    }
    
    CJPayFaceRecogConfigModel *faceRecogConfigModel = [CJPayFaceRecogConfigModel new];
    faceRecogConfigModel.popStyle = CJPayFaceRecogPopStyleRiskVerifyInPay;
    faceRecogConfigModel.appId = transferModel.faceVerifyInfo.appId;
    faceRecogConfigModel.merchantId = transferModel.faceVerifyInfo.merchantId;
    faceRecogConfigModel.memberBizOrderNo = transferModel.outTradeNo;
    faceRecogConfigModel.sourceStr = @"transfer_pay";
    faceRecogConfigModel.riskSource = @"大额支付";
    faceRecogConfigModel.fromVC = [UIViewController cj_topViewController];
    faceRecogConfigModel.faceVerifyInfo = transferModel.faceVerifyInfo;
    @CJWeakify(self)
    faceRecogConfigModel.trackerBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull params) {
        @CJStrongify(self)
        [self event:event params:params];
    };
    faceRecogConfigModel.pagePushBlock = ^(CJPayBaseViewController * _Nonnull vc, BOOL animated) {
        @CJStrongify(self)
        [self p_push:vc animated:animated];
    };
    faceRecogConfigModel.getTicketLoadingBlock = ^(BOOL isLoading) {
        @CJStrongify(self)
        if (isLoading) {
            [self startLoading];
        } else {
            [self stopLoading];
        }
    };
    faceRecogConfigModel.faceRecogCompletion = ^(CJPayFaceRecogResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        switch (resultModel.result) {
            case CJPayFaceRecogResultTypeSuccess:
                [self p_verifyFaceDataWithResultModel:resultModel
                                        transferModel:transferModel];
                break;
            case CJPayFaceRecogResultTypeFail:
                [self p_callbackWithResult:CJPayManagerResultFailed];
                break;
            case CJPayFaceRecogResultTypeCancel:
                [self p_callbackWithResult:CJPayManagerResultCancel];
                break;
            default:
                [self p_callbackWithResult:CJPayManagerResultFailed];
                break;
        }
    };
    self.faceRecogConfigModel = faceRecogConfigModel;
    [[CJPayFaceRecogManager sharedInstance] startFaceRecogWithConfigModel:faceRecogConfigModel];
}

- (void)p_verifyFaceDataWithResultModel:(CJPayFaceRecogResultModel *)resultModel
                          transferModel:(CJPayTransferInfoModel *)transferModel {
    NSMutableDictionary *bizParams = [NSMutableDictionary new];
    NSMutableDictionary *extDic = [NSMutableDictionary new];
    NSMutableDictionary *secureDic = [NSMutableDictionary dictionary];
    [extDic cj_setObject:CJString(transferModel.outTradeNo) forKey:@"out_trade_no"];
    NSString *scene = Check_ValidString(resultModel.getTicketResponse.faceScene) ? resultModel.getTicketResponse.faceScene : resultModel.getTicketResponse.scene;
    [extDic cj_setObject:CJString(scene) forKey:@"face_scene"];
    [extDic cj_setObject:CJString([CJPaySafeUtil encryptField:resultModel.faceDataStr]) forKey:@"live_detect_data"];
    [extDic cj_setObject:CJString(resultModel.getTicketResponse.ticket) forKey:@"ticket"];
    [extDic cj_setObject:CJString(transferModel.processId) forKey:@"process_id"];
    
    // 加解密逻辑待联调
    [secureDic addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    NSMutableArray *fields = [NSMutableArray array];
    [fields addObject:@"live_detect_data"];
    [secureDic cj_setObject:fields forKey:@"fields"];
    [extDic cj_setObject:secureDic forKey:@"secure_request_params"];
    
    [bizParams cj_setObject:CJString(transferModel.appId) forKey:@"app_id"];
    [bizParams cj_setObject:CJString(transferModel.merchantId) forKey:@"merchant_id"];
    [bizParams cj_setObject:CJString(transferModel.tradeNo) forKey:@"trade_no"];
    [bizParams cj_setObject:@"verify_face_data" forKey:@"method"];
    [bizParams cj_setObject:extDic forKey:@"exts"];
    
    [self startLoading];
    @CJWeakify(self)
    [CJPayFaceRecogCommonRequest startFaceRecogRequestWithBizParams:bizParams
                                                    completionBlock:^(NSError * _Nonnull error, CJPayFaceRecogCommonResponse * _Nonnull response) {
        @CJStrongify(self)
        [self stopLoading];
        NSNumber *result = [response isSuccess] ? @(1) : @(0);
        [self event:@"wallet_alivecheck_result"
                  params:@{@"result": result,
                           @"alivecheck_type":Check_ValidString(resultModel.getTicketResponse.ticket) ? @(1) : @(0),
                           @"fail_before": self.faceRecogConfigModel.popStyle == CJPayFaceRecogPopStyleRetry ? @(1) : @(0),
                           @"enter_from":@([resultModel.getTicketResponse getEnterFromValue]),
                           @"url": @"open_bytecert_sdk",
                           @"alivecheck_scene": CJString(resultModel.getTicketResponse.faceScene),
                           @"risk_source": @"大额支付"}];
        if (response && [response isSuccess]) {
            // 拉起lynx转账收银台
            [self p_openBigPayLynxPageWithSchema:CJString(response.lynxUrl)
                                   transferModel:transferModel];
        } else if ([response.code isEqualToString:@"CA9008"]) {
            // 活体重试
            self.faceRecogConfigModel.popStyle = CJPayFaceRecogPopStyleRetry;
            [[CJPayFaceRecogManager sharedInstance] startFaceRecogWithConfigModel:self.faceRecogConfigModel];
        } else {
            NSString *toastMsg = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
            [CJToast toastText:CJString(toastMsg) inWindow:[UIViewController cj_topViewController].cj_window];
            [self p_callbackWithResult:CJPayManagerResultFailed];
        }
    }];
}

- (void)p_openBigPayLynxPageWithSchema:(NSString *)schema
                         transferModel:(CJPayTransferInfoModel *)transaferModel {
    [self event:@"ec_cashier_large_payment_page_call_out"
         params:@{@"result": @"1"}];
    NSString *finalSchema = schema;
    NSString *trackInfoStr = [[CJPayCommonUtil dictionaryToJson:transaferModel.trackInfoDic] cj_URLEncode];
    if (Check_ValidString(trackInfoStr) && transaferModel.trackInfoDic.count > 0) {
        finalSchema = [CJPayCommonUtil appendParamsToUrl:schema
                                                  params:@{@"track_info": trackInfoStr}];
    }
    
    // 0:成功，101:处理中，102:失败 103:超时 104:取消
    [CJPayDeskUtil openLynxPageBySchema:finalSchema
                       completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
        NSDictionary *data = response.data;
        NSDictionary *dataDic = [data cj_dictionaryValueForKey:@"data"];
        if (!Check_ValidDictionary(dataDic)){
            CJPayLogInfo(@"transfer pay lynx callback data wrong!")
            [self p_callbackWithResult:CJPayManagerResultFailed];
            return;
        }
        int code = [dataDic cj_intValueForKey:@"code" defaultValue:102];
        switch (code) {
            case 0:
                [self p_callbackWithResult:CJPayManagerResultSuccess];
                break;
            case 101:
                [self p_callbackWithResult:CJPayManagerResultProcessing];
                break;
            case 102:
                [self p_callbackWithResult:CJPayManagerResultFailed];
                break;
            case 103:
                [self p_callbackWithResult:CJPayManagerResultTimeout];
                break;
            case 104:
                [self p_callbackWithResult:CJPayManagerResultCancel];
                break;
            default:
                [self p_callbackWithResult:CJPayManagerResultFailed];
                break;
        }
    }];
}

- (void)p_callbackWithResult:(CJPayManagerResultType)result {
    if (!self.completion) {
        CJPayLogAssert(NO, @"completion can't be nil.");
        return;
    }
    UIViewController *topVC = [UIViewController cj_topViewController];
    if (self.navigationController && topVC.navigationController == self.navigationController) {
        @CJWeakify(self)
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.completion, result, @"");
        }];
       
    } else if (self.navigationController.presentingViewController) {
        @CJWeakify(self)
        [self.navigationController.presentingViewController dismissViewControllerAnimated:NO completion:^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.completion, result, @"");
        }];
    } else {
        CJ_CALL_BLOCK(self.completion, result, @"");
    }
}

- (void)p_push:(UIViewController *)vc animated:(BOOL)animated {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if (topVC.navigationController != self.navigationController || !self.navigationController) {
        // 新起导航栈
        if ([CJPaySettingsManager shared].currentSettings == nil || [CJPaySettingsManager shared].currentSettings.loadingConfig.isEcommerceDouyinLoadingAutoClose ) {
            [[CJPayLoadingManager defaultService] stopLoading]; // 关闭电商拉起的Loading
        }
       if ([vc isKindOfClass:CJPayBaseViewController.class]){
            CJPayBaseViewController *cjpayVC = (CJPayBaseViewController *)vc;
            self.navigationController = [cjpayVC presentWithNavigationControllerFrom:topVC useMask:YES completion:nil];
        } else {
            [self event:@"wallet_rd_present_notcjpay"
                 params:@{@"pushed_vc": CJString([vc cj_trackerName]),
                            @"top_navi": CJString([topVC.navigationController cj_trackerName]),
                            @"top_vc": CJString([topVC cj_trackerName]),
                            @"cashdesk": @"ecommerce_large_pay"}];
            
            CJPayNavigationController *nav = [CJPayNavigationController instanceForRootVC:vc];
            nav.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet :UIModalPresentationOverFullScreen;
            nav.view.backgroundColor = UIColor.clearColor;
            self.navigationController = nav;
            [topVC presentViewController:nav animated:animated completion:nil];
        }
    } else {
        // 使用现有导航栈来push新页面
        [self p_trackPushParams:@{
            @"pushed_vc": CJString([vc cj_trackerName]),
            @"ec_rd_type": CJString([self.navigationController cj_trackerName]),
        }];
        [self.navigationController pushViewController:vc animated:animated];
    }
}

- (void)p_trackPushParams:(NSDictionary *)params {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [mutableParams addEntriesFromDictionary:@{
        @"cjpay_topVC": CJString([[UIViewController cj_topViewController] cj_trackerName]),
        @"cjpay_navi": CJString([self.navigationController cj_trackerName]),
        @"cjpay_navi_presentingVC" : CJString([self.navigationController.presentingViewController cj_trackerName]),
        @"cjpay_navi_presentedVC" : CJString([self.navigationController.presentedViewController cj_trackerName])
    }];

    [self event:@"wallet_rd_ecommerce_push" params:mutableParams];
}


#pragma mark - CJPayBaseLoadingDelegate
- (void)startLoading {
    if (self.customLoadingBlock) {
        CJ_CALL_BLOCK(self.customLoadingBlock, YES);
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
    }
}

- (void)stopLoading {
    if (self.customLoadingBlock) {
        CJ_CALL_BLOCK(self.customLoadingBlock, NO);
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)event:(NSString *)event params:(NSDictionary *)params {
    [CJTracker event:event params:params];
}

@end
