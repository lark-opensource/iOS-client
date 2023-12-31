//
//  CJPayFrontCashierManager.m
//  CJPay
//
//  Created by 王新华 on 3/9/20.
//

#import "CJPayFrontCashierManager.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayFrontCardListViewController.h"
#import "CJPayBindCardManager.h"
#import "CJPayFrontCardListRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayToast.h"

@interface CJPayFrontCashierManager()

@property (nonatomic, strong) NSMutableArray *mutableControllers;
@end

@implementation CJPayFrontCashierManager

+ (instancetype)shared {
    static CJPayFrontCashierManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJPayFrontCashierManager new];
    });
    return manager;
}

- (NSMutableArray *)mutableControllers {
    if (!_mutableControllers) {
        _mutableControllers = [NSMutableArray new];
    }
    return _mutableControllers;
}

- (void)p_gotoFrontCardListViewControllerWithModel:(BDChooseCardCommonModel *)commonModel
{
    [CJPayFrontCardListViewController showVCWithCommonModel:commonModel];
}

- (void)chooseCardWithCommonModel:(BDChooseCardCommonModel *)commonModel {
    
    if (!commonModel.orderResponse) {
        [CJPayFrontCardListRequest startWithParams:commonModel.bizParams completion:^(NSError * _Nonnull error, CJPayBDCreateOrderResponse * _Nonnull response) {
            CJ_CALL_BLOCK(commonModel.dismissLoadingBlock);
            if (![response isSuccess]) {
                [CJToast toastText:response.msg ?: CJPayNoNetworkMessage inWindow:commonModel.fromVC.cj_window];
                return;
            }
            commonModel.orderResponse = response;
            [self p_gotoFrontCardListViewControllerWithModel:commonModel];
        }];
    } else {
        CJ_CALL_BLOCK(commonModel.dismissLoadingBlock);
        [self p_gotoFrontCardListViewControllerWithModel:commonModel];
    }
}

- (void)bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel {
    if (bindCardCommonModel.cardBindSource == CJPayCardBindSourceTypeBalanceRecharge) {
        bindCardCommonModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceBalanceRecharge;
    } else if (bindCardCommonModel.cardBindSource == CJPayCardBindSourceTypeBalanceWithdraw) {
        bindCardCommonModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceBalanceWithdraw;
    }
    [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:bindCardCommonModel];
}

@end
