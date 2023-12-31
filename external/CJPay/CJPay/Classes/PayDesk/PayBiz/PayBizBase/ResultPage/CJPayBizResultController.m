//
//  CJPayBizResultController.m
//  aweme_transferpay_opt
//
//  Created by shanghuaijun on 2023/6/10.
//

#import "CJPayBizResultController.h"
#import "CJPayResultPageViewController.h"
#import "CJPayResultPageModel.h"
#import "CJPayOrderResultRequest.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayNavigationController.h"
#import "CJPayHomePageViewController.h"
#import "CJPayDeskUtil.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayWebViewUtil.h"
#import "CJPayFullResultPageViewController.h"

@interface CJPayBizResultController()

@property (nonatomic, copy) void(^completionBlock)(void);

@end

@implementation CJPayBizResultController

- (void)showResultPageWithOrderResultResponse:(CJPayOrderResultResponse *)bizOrderResultResponse
                              completionBlock:(void(^)(void))completionBlock {
    self.completionBlock = completionBlock;
    
    if (![bizOrderResultResponse isSuccess] || bizOrderResultResponse.tradeInfo.tradeStatus != CJPayOrderStatusSuccess){
        [self p_resultPageNative:bizOrderResultResponse];
    } else {
        if (bizOrderResultResponse.resultPageInfo) {
            NSString *CJPayCJOrderResultCacheStringKey = @"CJPayCJPayOrderResultResponse";
            NSString *dataJsonStr = [[[bizOrderResultResponse toDictionary] cj_dictionaryValueForKey:@"data"] btd_jsonStringEncoded];
            if (CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService)) {
                [CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_setParams:dataJsonStr key:CJPayCJOrderResultCacheStringKey];
            }

            NSString *renderType = bizOrderResultResponse.resultPageInfo.renderInfo.type;
            if ([renderType isEqualToString:@"native"]) {
                [self p_resultPageLynxCard:bizOrderResultResponse];
            } else if ([renderType isEqualToString:@"lynx"]){
                [self p_resultPageLynx:bizOrderResultResponse];
            } else {
                [self p_resultPageNative:bizOrderResultResponse];
            }
        } else {
            [self p_resultPageNative:bizOrderResultResponse];
        }
    }
}

- (void)p_resultPageLynx:(CJPayOrderResultResponse *)resultResponse {
    NSString *url = resultResponse.resultPageInfo.renderInfo.lynxUrl;
    CJPayNavigationController *navi = (CJPayNavigationController *)([self topVC].navigationController);
    @CJWeakify(self)
    [self.homeVC.presentingViewController dismissViewControllerAnimated:NO
                                                             completion:^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.resultPageWillAppearBlock);
        [CJPayDeskUtil openLynxPageBySchema:url
                            completionBlock:^(CJPayAPIBaseResponse * _Nullable response) {
            @CJStrongify(self)
            [self p_resultProcessCallBack];
        }];
    }];
}

- (void)p_resultPageNative:(CJPayOrderResultResponse *)bizOrderResultResponse {
    if ([self.bizCreateOrderResponse closeAfterTime] == 0) {
        [self closeActionAndCallbackAfterTime:0];
    } else {
        CJPayResultPageViewController *resultPage = [CJPayResultPageViewController new];// 新增聚合结果页处理
        resultPage.resultResponse = bizOrderResultResponse;
        resultPage.orderResponse = self.bizCreateOrderResponse;
        resultPage.commonTrackerParams = [self buildCommonTrackDic:@{
            @"method": CJString([CJPayTypeInfo getTrackerMethodByChannelConfig:self.showConfig]),
            @"second_method_list": CJString([[self.homeVC trackerParams] cj_stringValueForKey:@"second_method_list"])
        }];
        @CJWeakify(self)
        resultPage.closeActionCompletionBlock = ^(BOOL isClose) {
            @CJStrongify(self)
            [self p_resultProcessCallBack];
        };
        CJ_CALL_BLOCK(self.resultPageWillAppearBlock);
        [(CJPayNavigationController *)self.homeVC.navigationController pushViewControllerSingleTop:resultPage
                                                                                          animated:NO
                                                                                        completion:nil];
    }
}

- (NSDictionary *)buildCommonTrackDic:(NSDictionary *)dic {//传入的字典若包含通参则使用传入的新值
    NSMutableDictionary *mutableDic = [[CJPayCommonTrackUtil getBytePayDeskCommonTrackerWithResponse:self.bizCreateOrderResponse] mutableCopy];
//    [mutableDic cj_setObject:CJString([self.createOrderParams cj_stringValueForKey:@"cashier_source" defaultValue:@"0"]) forKey:@"cashier_source"];
    [mutableDic addEntriesFromDictionary:dic];
    if ([self.homeVC respondsToSelector:@selector(trackerParams)]) {
        [mutableDic addEntriesFromDictionary:[self.homeVC performSelector:@selector(trackerParams)]];
    }
    return [mutableDic copy];
}

- (nonnull UIViewController *)topVC {
    return [UIViewController cj_foundTopViewControllerFrom:self.homeVC];
}

- (CJPayResultPageModel *)p_resultmodelwithResponse:(CJPayOrderResultResponse *)response {
    CJPayResultPageModel *model = [[CJPayResultPageModel alloc] init];
//    model.tradeInfo = response.tradeInfo;
    //    model.paymentInfo = response.paymentInfo;
    model.orderType = response.tradeInfo.ptCode;
    model.amount = response.tradeInfo.amount;
    
    model.remainTime = response.remainTime;
    model.resultPageInfo = response.resultPageInfo;
    model.openSchema = response.openSchema;
    model.openUrl = response.openUrl;
    model.orderResponse = [response toDictionary]?:@{};
    return model;
}

- (void)p_resultPageLynxCard:(CJPayOrderResultResponse *)resultResponse {
    NSMutableDictionary *trackParams = @{
                @"query_type" : @"0",
                @"result_page_type" : @"full"
            }.mutableCopy;
    [trackParams addEntriesFromDictionary:self.trackParams];
    CJPayResultPageModel *resultPageModel = [self p_resultmodelwithResponse:resultResponse];
    CJPayFullResultPageViewController *resultPage = [[CJPayFullResultPageViewController alloc] initWithCJResultModel:resultPageModel
                                                                                                       trackerParams:[trackParams copy]];
    resultPage.closeCompletion = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self p_handleClose:resultResponse];
            if (self.homeVC.response.deskConfig.callBackType == CJPayDeskConfigCallBackTypeAfterClose) {
                [self p_resultProcessCallBack];
            }
        });
    };
    
    CJPayNavigationController *navi = (CJPayNavigationController *)([self topVC].navigationController);
    if (navi && [navi isKindOfClass:[CJPayNavigationController class]]) { // 有可能找不到
        CJ_CALL_BLOCK(self.resultPageWillAppearBlock);
        [navi pushViewControllerSingleTop:resultPage
                                 animated:NO
                               completion:^{
            if (self.homeVC.response.deskConfig.callBackType == CJPayDeskConfigCallBackTypeAfterQuery) {
                [self p_resultProcessCallBack];
            }
        }];
    } else {
        [self closeActionAndCallbackAfterTime:[self.bizCreateOrderResponse closeAfterTime]];
    }
}

- (void)p_handleClose:(CJPayOrderResultResponse *)response {
    NSString *buttonAction = response.resultPageInfo.buttonInfo.action;
    NSString *url = response.openUrl;
    if ([buttonAction isEqualToString:@"open"] && Check_ValidString(url)) {
        if ([url hasPrefix:@"http"]) {
            [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_topViewController]
                                                               toUrl:url
                                                              params:@{}];
        } else {
            [CJPayDeskUtil openLynxPageBySchema:url
                                completionBlock:^(CJPayAPIBaseResponse * _Nullable response) {}];
        }
    }
}

- (void)closeActionAndCallbackAfterTime:(CGFloat)time {
    if (time < 0) {
        return;
    }
    @CJWeakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        [self p_dismissAllVCWithAnimated:YES
                              completion:^{
            @CJStrongify(self)
            [self p_resultProcessCallBack];
        }];
    });
}

- (void)p_dismissAllVCWithAnimated:(BOOL)isAnimated completion:(void (^)(void))completion {
    if (self.homeVC.presentingViewController) {
        [self.homeVC.presentingViewController dismissViewControllerAnimated:isAnimated completion:completion];
    } else if (self.homeVC) {
        [self.homeVC dismissViewControllerAnimated:isAnimated completion:completion];
    } else {
        CJ_CALL_BLOCK(completion);
    }
}

- (void)p_resultProcessCallBack {
    CJ_CALL_BLOCK(self.completionBlock);
}

@end
