//
//  CJPayBaseVerifyManager+ButtonInfoHandler.m
//  CJPay
//
//  Created by 王新华 on 4/16/20.
//

#import "CJPayBaseVerifyManager+ButtonInfoHandler.h"
#import "CJPayUIMacro.h"
#import "CJPayWebViewUtil.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayVerifyItemUploadIDCard.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPaySettingsManager.h"
#import "CJPayDeskUtil.h"

@implementation CJPayBaseVerifyManager(ButtonInfoHandler)

- (CJPayButtonInfoHandlerActionsModel *)commonButtonInfoModelWithResponse:(CJPayOrderConfirmResponse *)response {
    CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
    @CJWeakify(self)
    actionModel.backToPayHomePageAction = ^{
        @CJStrongify(self)
        [self sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
        
        switch ([response.buttonInfo.right_button_action integerValue]) {
            case CJPayButtonInfoHandlerTypeUploadIDCard:
                if ([self.verifyManagerQueen respondsToSelector:@selector(trackVerifyWithEventName:params:)]) {
                    [self.verifyManagerQueen trackVerifyWithEventName:@"wallet_identified_verification_inform_pate_click" params:@{
                        @"button_name" : @"取消"
                    }];
                }
                break;
            default:
                break;
        }
    };
    actionModel.cardListAction = ^{
        @CJStrongify(self)
        [self sendEventTOVC:CJPayHomeVCEventGotoCardList obj:@(0)];
    };
    actionModel.closePayDeskAction = ^{
        @CJStrongify(self)
        [self.homePageVC closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromCloseAction];
    };
    actionModel.changeCardAction = ^{
        @CJStrongify(self)
        [self sendEventTOVC:CJPayHomeVCEventGotoCardList obj:@(0)];
    };
    actionModel.backAction = ^{
        @CJStrongify(self);
        UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:[self.homePageVC topVC]];
        if ([topVC respondsToSelector:@selector(back)]) {
            [topVC performSelector:@selector(back)];
        }
    };
    actionModel.findPwdAction = ^(NSString * _Nonnull pwd) {
        @CJStrongify(self)
        CJPayMigrateH5PageToLynx *model = [CJPaySettingsManager shared].currentSettings.migrateH5PageToLynx;
        if (Check_ValidString(model.forgetpassSchema)) {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            [params cj_setObject:self.response.merchant.merchantId forKey:@"merchant_id"];
            [params cj_setObject:self.response.merchant.appId forKey:@"app_id"];
            [CJPayDeskUtil openLynxPageBySchema:[CJPayCommonUtil appendParamsToUrl:model.forgetpassSchema params:params]
                               completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {}];
            return;
        }
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[self.homePageVC topVC] toScheme:[CJPayBDButtonInfoHandler findPwdUrlWithAppID:self.response.merchant.appId merchantID:self.response.merchant.merchantId smchID:@"SmchId"]];
    };
    actionModel.continuePayingAction = ^{
        @CJStrongify(self)
        [self p_showTopHalfVCLoading];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self loadSpecificTypeCacheData:CJPayVerifyTypeLast]];
        [params cj_setObject:@"true" forKey:@"nonblock_anti_laundering_canceled"];
        [self submitConfimRequest:params fromVerifyItem:nil];
    };
    actionModel.uploadIDCardAction = ^{
        @CJStrongify(self)
        CJPayVerifyItem *verifyItem = [self getSpecificVerifyType:CJPayVerifyTypeUploadIDCard];
        if ([verifyItem isKindOfClass:[CJPayVerifyItemUploadIDCard class]]) {
            [((CJPayVerifyItemUploadIDCard *)verifyItem) startUploadIDCardWithConfirmResponse:response];
        }
        if ([self.verifyManagerQueen respondsToSelector:@selector(trackVerifyWithEventName:params:)]) {
            [self.verifyManagerQueen trackVerifyWithEventName:@"wallet_identified_verification_inform_pate_click" params:@{
                @"button_name" : @"去上传"
            }];
        }
    };
    actionModel.alertPresentAction = ^{
        @CJStrongify(self)
        switch ([response.buttonInfo.right_button_action integerValue]) {
            case CJPayButtonInfoHandlerTypeUploadIDCard:
                if ([self.verifyManagerQueen respondsToSelector:@selector(trackVerifyWithEventName:params:)]) {
                    [self.verifyManagerQueen trackVerifyWithEventName:@"wallet_identified_verification_inform_page" params:@{}];
                }
                break;
            default:
                break;
        }
    };
    return actionModel;
}

- (void)p_showTopHalfVCLoading {
    CJPayNavigationController *navVC = (CJPayNavigationController *)[self.homePageVC topVC].navigationController;
    // 取导航栈最顶部的半屏vc
    if (navVC && [navVC isKindOfClass:[CJPayNavigationController class]]) {
        [navVC.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj && [obj isKindOfClass:[CJPayHalfPageBaseViewController class]]) {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
            }
        }];
    }
}

@end
