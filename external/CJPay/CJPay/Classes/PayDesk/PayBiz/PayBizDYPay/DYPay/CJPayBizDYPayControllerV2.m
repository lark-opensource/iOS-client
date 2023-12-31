//
//  CJPayBizDYPayControllerV2.m
//  CJPaySandBox
//
//  Created by shanghuaijun on 2023/6/8.
//

#import "CJPayBizDYPayControllerV2.h"

#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBDResultPageViewController.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayBizDYPayPluginV2.h"
#import "CJPayHomePageViewController.h"
#import "CJPayOrderResultRequest.h"
#import "CJPayDouPayProcessController.h"
#import "CJPayBizResultController.h"
#import "CJPayBizDYPayModel.h"

@interface CJPayBizDYPayControllerV2 ()<CJPayBizDYPayPluginV2>

@property (nonatomic, strong) CJPayBizDYPayModel *dypayModel;
@property (nonatomic, copy) void(^completionBlock)(CJPayOrderStatus orderStatus, CJPayBDOrderResultResponse * _Nonnull response);
@property (nonatomic, strong) NSMutableArray *mutableControllers;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *bdPayCreateOrderResponse;
@property (nonatomic, strong) CJPayBDOrderResultResponse *bdPayResultResponse;
@property (nonatomic, strong) CJPayBizResultController *bizResultController;
@property (nonatomic, copy) NSString *bdProcessInfoStr;

@end

@implementation CJPayBizDYPayControllerV2

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassToPtocol(self, CJPayBizDYPayPluginV2);
});

- (void)dyPayWithModel:(nonnull CJPayBizDYPayModel *)model
            completion:(nonnull void (^)(CJPayOrderStatus, CJPayBDOrderResultResponse * _Nonnull))completion {
    self.dypayModel = model;
    self.completionBlock = completion;

    CJPayBDCreateOrderResponse *bdPayCreateOrderResponse = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:@{@"response": [model.createResponseStr cj_toDic] ?: @{}} error:nil];
    bdPayCreateOrderResponse.intergratedTradeIdentify = CJString(model.intergratedTradeIdentify);
    bdPayCreateOrderResponse.cj_merchantID = CJString(model.cj_merchantID);
    
    CJPayDouPayProcessModel *douPayProcessModel = [CJPayDouPayProcessModel new];
    douPayProcessModel.createResponse = bdPayCreateOrderResponse;
    douPayProcessModel.showConfig = model.showConfig;
    douPayProcessModel.homeVC = model.homeVC;
    douPayProcessModel.cashierType = CJPayCashierTypeHalfPage;
    douPayProcessModel.resultPageStyle = [model isNeedQueryBizOrder] ? CJPayDouPayResultPageStyleOnlyHiddenSuccess : CJPayDouPayResultPageStyleShowAll;
    douPayProcessModel.isHasLaterProcess = [model isNeedQueryBizOrder];
    douPayProcessModel.isShowMask = NO;
    douPayProcessModel.extParams = @{@"track_info": model.trackParams ?: @{}};
    @CJWeakify(self);
    douPayProcessModel.refreshCreateOrderBlock = ^(CJPayRefreshCreateOrderCompletionBlock _Nonnull completionBlock) {
        @CJStrongify(self);
        [self.dypayModel.processManager updateCreateOrderResponseWithCompletionBlock:^(NSError * _Nonnull error, CJPayCreateOrderResponse * _Nonnull response) {
            @CJStrongify(self);
            if ([response isSuccess]) {
                [self.dypayModel.homeVC updateOrderResponse:response];
                [self.dypayModel.homeVC updateSelectConfig:nil];
                [self.dypayModel.homeVC changePayMethodTo:self.dypayModel.homeVC.curSelectConfig];
            }
        }];
    };
    douPayProcessModel.queryFinishBlock = ^{
        @CJStrongify(self)
        [self.dypayModel.homeVC.countDownView invalidate];
    };
    douPayProcessModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceIntegratedCashier;
    
    CJPayDouPayProcessController *douPayController = [CJPayDouPayProcessController new];
    [self.mutableControllers addObject:douPayController];
    @CJWeakify(douPayController)
    [douPayController douPayProcessWithModel:douPayProcessModel
                                  completion:^(CJPayDouPayProcessResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        @CJStrongify(douPayController)
        // 处理抖音支付标准化的支付结果
        [self p_handleWithResultModel:resultModel];
        [self.mutableControllers removeObject:douPayController];
    }];
}

- (NSMutableArray *)mutableControllers {
    if (!_mutableControllers) {
        _mutableControllers = [NSMutableArray new];
    }
    return _mutableControllers;
}

- (CJPayBizResultController *)bizResultController {
    if (!_bizResultController) {
        _bizResultController = [CJPayBizResultController new];
    }
    return _bizResultController;
}

- (void)p_handleWithResultModel:(CJPayDouPayProcessResultModel *)resultModel {
    if ([resultModel isReachOrderFinalState]) {
        CJPayBDOrderResultResponse *bdOrderResultResponse = [CJPayBDOrderResultResponse new];
        CJPayBDTradeInfo *bdTradeInfo = [CJPayBDTradeInfo new];
        bdTradeInfo.tradeStatusString = resultModel.resultCode == CJPayDouPayResultCodeClose ? @"FAIL" : [resultModel.extParams cj_stringValueForKey:kDouPayResultTradeStatusStrKey];
        bdOrderResultResponse.tradeInfo = bdTradeInfo;
        self.bdPayResultResponse = bdOrderResultResponse;
        
        // 抖音支付推到查单成功终态
        if (resultModel.resultCode == CJPayDouPayResultCodeOrderSuccess) {
            if ([self.dypayModel isNeedQueryBizOrder]) {
                // 需要聚合查单-聚合查单-全屏lynx结果页面/lynxcard结果页/半屏聚合结果页
                self.bdProcessInfoStr = [resultModel.extParams cj_stringValueForKey:kDouPayResultBDProcessInfoStrKey];
                [self p_queryBizOrderResult];
            } else {
                // 不需要聚合查单-回调业务
                [self p_callBackBiz];
            }
        } else {
            // 不需要聚合查单-回调业务
            [self p_callBackBiz];
        }
    } else {
        // 抖音支付没有到查单终态处理收入转零钱成功，零钱扣减失败 & 抖音月付激活失败的case
        if (resultModel.resultCode == CJPayDouPayResultCodeCreditActivateFail) {
            [self p_gotoCardListWithTipsMsg:Check_ValidString(resultModel.errorDesc) ? resultModel.errorDesc : CJPayLocalizedStr(@"月付激活失败，请选择其它支付方式")
                                 disableMsg:[resultModel.extParams cj_stringValueForKey:kDouPayResultCreditPayDisableStrKey]];
        }
    }
}

- (void)p_callBackBiz {
    CJ_CALL_BLOCK(self.completionBlock, self.bdPayResultResponse.tradeInfo.tradeStatus, self.bdPayResultResponse);
}

// 抖音月付激活失败推聚合卡列表让用户可以选择其他支付方式
- (void)p_gotoCardListWithTipsMsg:(NSString *)tipsMsg
                       disableMsg:(NSString *)disableMsg {
    if ([self.dypayModel.homeVC respondsToSelector:@selector(creditPayFailWithTipsMsg:disableMsg:)]) {
        [self.dypayModel.homeVC creditPayFailWithTipsMsg:CJString(tipsMsg) disableMsg:CJString(disableMsg)];
    }
}

#pragma mark private

- (void)p_queryBizOrderResult {
    @CJWeakify(self)
    void(^completion)(NSError *error, CJPayOrderResultResponse *response) = ^(NSError *error, CJPayOrderResultResponse *response){
        @CJStrongify(self)
        NSString *renderType = response.resultPageInfo.renderInfo.type;
        if (![renderType isEqualToString:@"lynx"]) {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
        self.bizResultController.homeVC = self.dypayModel.homeVC;
        self.bizResultController.bizCreateOrderResponse = self.dypayModel.bizCreateOrderResponse;
        self.bizResultController.showConfig = self.dypayModel.showConfig;
        self.bizResultController.trackParams = self.dypayModel.trackParams;
        self.bizResultController.resultPageWillAppearBlock = ^{
            if ([renderType isEqualToString:@"lynx"]) {
                [[CJPayLoadingManager defaultService] stopLoading];
            }
        };
        [self.bizResultController showResultPageWithOrderResultResponse:response
                                                        completionBlock:^{
            @CJStrongify(self)
            [self p_callBackBiz];
        }];
        
    };

    if (![[CJPayLoadingManager defaultService] isLoading]) { //当前如果有loading，则不再新起loading
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading];
    }
    [self p_queryBizOrder:[self.bdPayCreateOrderResponse.resultConfig queryResultTimes]
               completion:^(NSError *error, CJPayOrderResultResponse *response) {
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

- (void)p_queryBizOrder:(NSInteger)retryCount
             completion:(void (^)(NSError * _Nonnull, CJPayOrderResultResponse * _Nonnull))completionBlock {
    @CJWeakify(self)
    [CJPayOrderResultRequest startWithTradeNo:self.dypayModel.intergratedTradeIdentify
                                  processInfo:self.dypayModel.processStr
                                bdProcessInfo:self.bdProcessInfoStr
                                   completion:^(NSError *error, CJPayOrderResultResponse *response) {
        if ([response.code isEqualToString:@"GW400008"]) {//宿主未登录
            CJ_CALL_BLOCK(completionBlock, error, response);
            return;
        }

        if ((response.tradeInfo.tradeStatus == CJPayOrderStatusProcess || ![response isSuccess]) && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weak_self p_queryBizOrder:retryCount - 1 completion:completionBlock];
            });
            return;
        }
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

@end
