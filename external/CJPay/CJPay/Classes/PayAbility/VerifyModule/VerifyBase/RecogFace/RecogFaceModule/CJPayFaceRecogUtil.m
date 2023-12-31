//
//  CJPayFaceRecogUtil.m
//  Pods
//
//  Created by 尚怀军 on 2022/10/25.
//

#import "CJPayFaceRecogUtil.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayGetTicketResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayGetTicketRequest.h"
#import "CJPayFaceRecognitionModel.h"
#import "CJPayMemUploadLiveVideoRequest.h"
#import "CJPaySafeUtilsHeader.h"
#import "CJPayToast.h"
#import "UIViewController+CJPay.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayFaceRecognitionProtocolViewController.h"

NSString * const CJPayFaceRecogAlertPopUpViewKey = @"CJPayFaceRecogAlertPopUpViewKey";

@implementation CJPayFaceRecogUtil

+ (void)asyncUploadFaceVideoWithAppId:(NSString *)appId
                           merchantId:(NSString *)merchantId
                            videoPath:(NSString *)videoPath {
    if (!Check_ValidString(appId) || !Check_ValidString(merchantId) || !Check_ValidString(videoPath)) {
        CJPayLogInfo(@"upload face video fail, miss parameter，appid=%@, merchantid=%@, videopath=%@", CJString(appId), CJString(merchantId), CJString(videoPath));
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *videoUrl = [NSURL URLWithString:CJString(videoPath)];
        NSData *videoData = [NSData dataWithContentsOfURL:videoUrl];
        NSString *videoStr = [videoData base64EncodedStringWithOptions:0];
        
        if (!videoStr) {
            CJPayLogInfo(@"get data of face video  fail, videopath=%@", CJString(videoPath));
            return;
        }
        
        NSDictionary *baseParam = @{
            @"app_id": CJString(appId),
            @"merchant_id": CJString(merchantId)
        };
        
        NSDictionary *bizContentParam = @{
            @"face_video": CJString([CJPaySafeUtil encryptField:videoStr])
        };
        [CJPayMemUploadLiveVideoRequest startWithRequestparams:baseParam
                                              bizContentParams:bizContentParam
                                                    completion:^(NSError * _Nonnull error, CJPayBaseResponse * _Nonnull response) {
            CJPayLogInfo(@"upload result, code=%@", CJString(response.code));
            [CJTracker event:@"wallet_rd_face_upload_track" params:@{
                @"is_success" : [response isSuccess] ? @"1" : @"0",
                @"error_code" : CJString(response.code),
                @"error_msg" : CJString(response.msg),
                @"app_id": CJString(appId),
                @"merchant_id": CJString(merchantId)
            }];
        }];
       
    });
}


+ (void)getTicketWithResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse
          createOrderResponse:(CJPayBDCreateOrderResponse *)createOrderResponse
                       source:(NSString *)source
                       fromVC:(UIViewController *)fromVC
                   completion:(void(^)(CJPayFaceRecogSignResult signResult, CJPayGetTicketResponse * _Nonnull getTicketResponse))completionBlock {
    NSDictionary *baseRequestParam = @{@"app_id": CJString(createOrderResponse.merchant.appId),
                                       @"merchant_id": CJString(createOrderResponse.merchant.merchantId)};
    NSString *outTradeNo = createOrderResponse.tradeInfo.outTradeNo;
    if (!Check_ValidString(outTradeNo)) {
        outTradeNo = orderConfirmResponse.outTradeNo;
    }
    
    NSDictionary *bizContentParam = @{@"ailab_app_id": @"1792",
                                      @"source" : CJString(source),
                                      @"member_biz_order_no": CJString(outTradeNo),
                                      @"live_route": CJString(orderConfirmResponse.faceVerifyInfo.verifyChannel),
                                      @"return_url": BDPayFacePlusVerifyReturnURL,
                                      @"face_scene": CJString(orderConfirmResponse.faceVerifyInfo.faceScene)
    };
    
    [CJPayGetTicketRequest startWithRequestparams:baseRequestParam
                                 bizContentParams:bizContentParam
                                       completion:^(NSError * _Nonnull error, CJPayGetTicketResponse * _Nonnull response) {
        if (response && [response.code isEqualToString:@"MP000000"]) {
            if (Check_ValidString(response.ticket)) {
                if (!response.isSigned) {
                    CJ_CALL_BLOCK(completionBlock, CJPayFaceRecogSignResultNeedResign, response);
                } else {
                    CJ_CALL_BLOCK(completionBlock, CJPayFaceRecogSignResultSuccess, response);
                }
            } else {
                CJ_CALL_BLOCK(completionBlock, CJPayFaceRecogResultUnknown, response);
            }
            return;
        }
        
        CJ_CALL_BLOCK(completionBlock, CJPayFaceRecogResultUnknown, response);
        [CJTracker event:@"wallet_alivecheck_result"
                  params:@{@"result": @(0),
                           @"url": @"get_ticket",
                           @"alivecheck_type":@(0),
                           @"fail_before":@(0),
                           @"enter_from":@(0),
                           @"fail_code": CJString(response.code),
                           @"fail_reason": CJString(response.msg),
                           @"alivecheck_scene": CJString(response.faceScene)}];
        if (Check_ValidString(response.msg)) {
            [CJToast toastText:response.msg inWindow:fromVC.cj_window];
        }
    }];
}


+ (void)getTicketWithConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel
                      completion:(void(^)(CJPayFaceRecogSignResult signResult, CJPayGetTicketResponse * _Nonnull getTicketResponse))completionBlock {
    CJPayBDCreateOrderResponse *createOrderResponse = [CJPayBDCreateOrderResponse new];
    CJPayMerchantInfo *merchant = [CJPayMerchantInfo new];
    merchant.appId = faceRecogConfigModel.appId;
    merchant.merchantId = faceRecogConfigModel.merchantId;

    CJPayUserInfo *userInfo = [CJPayUserInfo new];
    
    CJPayBDTradeInfo *tradeInfo = [CJPayBDTradeInfo new];
    tradeInfo.outTradeNo = faceRecogConfigModel.memberBizOrderNo;

    createOrderResponse.merchant = merchant;
    createOrderResponse.userInfo = userInfo;
    createOrderResponse.tradeInfo = tradeInfo;
    
    CJPayOrderConfirmResponse *orderConfirmResponse = [CJPayOrderConfirmResponse new];
    orderConfirmResponse.faceVerifyInfo = faceRecogConfigModel.faceVerifyInfo;
    
    [self getTicketWithResponse:orderConfirmResponse
            createOrderResponse:createOrderResponse
                         source:CJString(faceRecogConfigModel.sourceStr)
                         fromVC:faceRecogConfigModel.fromVC
                     completion:completionBlock];
    
}

+ (CJPayFaceRecognitionModel *)createFullScreenSignPageModelWithResponse:(CJPayGetTicketResponse *)getTicketResponse
                                                    faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel {
    CJPayFaceRecognitionModel *model = [CJPayFaceRecognitionModel new];
    model.userMaskName  = getTicketResponse.nameMask;
    model.agreementName = getTicketResponse.agreementDesc;
    model.agreementURL = getTicketResponse.agreementUrl;
    model.appId = faceRecogConfigModel.appId;
    model.merchantId = faceRecogConfigModel.merchantId;
    model.alivecheckScene = getTicketResponse.faceScene;
    model.alivecheckType = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
    return model;
}

+ (CJPayFaceRecognitionModel *)createFaceRecogAlertModelWithResponse:(CJPayGetTicketResponse *)getTicketResponse
                                                faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel {
    CJPayFaceRecognitionModel *model = [CJPayFaceRecognitionModel new];
    model.agreementName = getTicketResponse.agreementDesc;
    model.agreementURL = getTicketResponse.agreementUrl;
    model.protocolCheckBox = getTicketResponse.protocolCheckBox;
    model.buttonText = faceRecogConfigModel.faceVerifyInfo.buttonDesc;
    model.title = faceRecogConfigModel.faceVerifyInfo.title;
    model.iconUrl = faceRecogConfigModel.faceVerifyInfo.iconUrl;
    model.showStyle = [faceRecogConfigModel getAlertShowStyle];
    model.shouldShowProtocolView = faceRecogConfigModel.shouldShowProtocolView;
    return model;
}

+ (void)tryPoptoTopHalfVC:(UIViewController *)referVC {
    CJPayNavigationController *navVC = (CJPayNavigationController *)[UIViewController cj_foundTopViewControllerFrom:referVC].navigationController;
    
    if (!navVC) {
        // 没有取到导航vc，可能是由于顶层vc是活体识别的vc
        UIViewController *topPresentingVC = [UIViewController cj_foundTopViewControllerFrom:referVC].presentingViewController;
        if (topPresentingVC && [topPresentingVC isKindOfClass:[CJPayNavigationController class]]) {
            navVC = (CJPayNavigationController *)topPresentingVC;
        }
    }
    // pop到导航栈最顶部的半屏vc
    if (navVC && [navVC isKindOfClass:[CJPayNavigationController class]]) {
        NSUInteger count = navVC.viewControllers.count;
        UIViewController *navTopVC = [navVC.viewControllers cj_objectAtIndex:count - 1];
        BOOL topVCIsFullScreenVC = NO;
        if (navTopVC && ![navTopVC isKindOfClass:[CJPayHalfPageBaseViewController class]]) {
            topVCIsFullScreenVC = YES;
        }
        
        __block BOOL foundHalfVC = NO;
        [navVC.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj && [obj isKindOfClass:[CJPayHalfPageBaseViewController class]] && topVCIsFullScreenVC) {
                [navVC popToViewController:obj animated:YES];
                *stop = YES;
                foundHalfVC = YES;
            }
        }];
        // 解决导航栈内无半屏页面时，全屏协议页面验完活体后无法自动关闭问题
        if (!foundHalfVC && [navTopVC isKindOfClass:CJPayFaceRecognitionProtocolViewController.class]) {
            [navVC popViewControllerAnimated:YES];
        }
    }
}

@end
