//
//  CJPaySkippwdGuideUtil.m
//  Pods
//
//  Created by 利国卿 on 2022/4/2.
//

#import "CJPaySkippwdGuideUtil.h"
#import "CJPaySkipPwdGuideFigureViewController.h"
#import "CJPayECSkipPwdUpgradeViewController.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPaySkipPwdUpgradeGuideViewController.h"
#import "CJPayUIMacro.h"

@implementation CJPaySkippwdGuideUtil
+ (BOOL)shouldShowGuidePageWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    NSString *guideType = resultResponse.resultPageGuideInfoModel.guideType;
    if ([guideType isEqualToString:@"nopwd_guide"] ||
        [guideType isEqualToString:@"upgrade"] ||
        resultResponse.skipPwdGuideInfoModel.needGuide) {
        return YES;
    } else {
        return NO;
    }
}

// 支付后展示免密相关引导入口
+ (void)showGuidePageVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager
                            pushAnimated:(BOOL)animated
                         completionBlock:(void (^)(void))completionBlock {
    
    CJPayBDOrderResultResponse *resultResponse = verifyManager.resResponse;
    CJPayBaseViewController *guideVC;
    // 插画版免密开通 | 提额引导
    NSString *guideType = resultResponse.resultPageGuideInfoModel.guideType;
    if ([guideType isEqualToString:@"nopwd_guide"]) {
        guideVC = [self p_skipPwdFigureGuideVCWithVerifyManager:verifyManager completionBlock:completionBlock];
    } else if ([guideType isEqualToString:@"upgrade"]) {
        guideVC = [self p_skipPwdUpgradeFigureGuideVCWithVerifyManager:verifyManager completionBlock:completionBlock];
    } else if (resultResponse.skipPwdGuideInfoModel.needGuide) {
        // 免密提额引导
        guideVC = [self p_skipPwdUpgradeGuideVCWithVerifyManager:verifyManager completionBlock:completionBlock];
    }
    
    if (!guideVC) {
        CJ_CALL_BLOCK(completionBlock);
    }
    
    [verifyManager.homePageVC push:guideVC animated:animated];
    
}

// 插画版免密开通引导
+ (CJPaySkipPwdGuideFigureViewController *)p_skipPwdFigureGuideVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager completionBlock:(void (^)(void))completionBlock {
    
    CJPaySkipPwdGuideFigureViewController *guideVC = [[CJPaySkipPwdGuideFigureViewController alloc] initWithGuideInfoModel:verifyManager.resResponse.resultPageGuideInfoModel];
    guideVC.verifyManager = verifyManager;
    guideVC.completeBlock = completionBlock;
    guideVC.isTradeCreateAgain = verifyManager.resResponse.tradeInfo.isTradeCreateAgain;
    
    return guideVC;
}

// 插画版免密提额引导
+ (CJPaySkipPwdUpgradeGuideViewController *)p_skipPwdUpgradeFigureGuideVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager completionBlock:(void (^)(void))completionBlock {
    
    CJPaySkipPwdUpgradeGuideViewController *guideVC = [[CJPaySkipPwdUpgradeGuideViewController alloc] initWithGuideInfoModel:verifyManager.resResponse.resultPageGuideInfoModel];
    guideVC.verifyManager = verifyManager;
    guideVC.completion = completionBlock;
    guideVC.isTradeCreateAgain = verifyManager.resResponse.tradeInfo.isTradeCreateAgain;
    return guideVC;
}

// 免密提额引导
+ (CJPayECSkipPwdUpgradeViewController *)p_skipPwdUpgradeGuideVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager
                                                                    completionBlock:(void (^)(void))completionBlock {
    
    CJPayECSkipPwdUpgradeViewController *guideVC = [[CJPayECSkipPwdUpgradeViewController alloc] initWithVerifyManager:verifyManager];
    guideVC.isTradeCreateAgain = verifyManager.resResponse.tradeInfo.isTradeCreateAgain;
    guideVC.completion = completionBlock;
    
    return guideVC;
}

@end
