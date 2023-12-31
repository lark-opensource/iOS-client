//
//  CJPayMemVerifyItemPassword.m
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/19.
//

#import "CJPayMemVerifyItemPassword.h"

#import "CJPayHalfVerifyPasswordNormalViewController.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayTouchIdManager.h"
#import "CJPayBioManager.h"
#import "CJPayRetainInfoModel.h"
#import "CJPayPayCancelRetainViewController.h"
#import "CJPaySDKMacro.h"
#import "CJPayAlertUtil.h"
#import "CJPaySafeUtil.h"

@interface CJPayMemVerifyItemPassword()

@end

@implementation CJPayMemVerifyItemPassword

- (void)verifyWithParams:(NSDictionary *)params fromVC:(UIViewController *)fromVC completion:(void (^)(CJPayMemVerifyResultModel * _Nonnull))completedBlock {
    
    CJPayVerifyPasswordViewModel *viewModel = [CJPayVerifyPasswordViewModel new];
    CJPayBDCreateOrderResponse *response = [CJPayBDCreateOrderResponse new];
    response.merchant = [CJPayMerchantInfo new];
    response.merchant.appId = [params cj_stringValueForKey:@"app_id"];
    response.merchant.merchantId = [params cj_stringValueForKey:@"merchant_id"];
    viewModel.response = response;
    CJPayHalfVerifyPasswordNormalViewController *passwordVC = [[CJPayHalfVerifyPasswordNormalViewController alloc] initWithAnimationType:HalfVCEntranceTypeFromBottom viewModel:viewModel];
    [passwordVC useCloseBackBtn];
    @CJWeakify(passwordVC)
    @CJWeakify(viewModel)
    //用户主动点击左上角x退出
    passwordVC.cjBackBlock = ^{
        @CJStrongify(passwordVC)
        CJPayMemVerifyResultModel *model = [CJPayMemVerifyResultModel new];
        model.verifyVC = passwordVC;
        model.resultType = CJPayMemVerifyResultTypeCancel;
        CJ_CALL_BLOCK(completedBlock, model);
    };
    
    viewModel.forgetPasswordBtnBlock = ^{
        @CJStrongify(passwordVC)
        @CJStrongify(viewModel)
        [viewModel gotoForgetPwdVCFromVC:passwordVC];
    };
    
    viewModel.inputCompleteBlock = ^(NSString * _Nonnull password) {
        @CJStrongify(passwordVC)
        if (!password || password.length < 1) {
            return;
        }
        CJPayMemVerifyResultModel *model = [CJPayMemVerifyResultModel new];
        model.verifyVC = passwordVC;
        model.resultType = CJPayMemVerifyResultTypeFinish;
        model.paramsDict = @{@"password" : [CJPaySafeUtil encryptPWD:password]};

        CJ_CALL_BLOCK(completedBlock, model);
        return;
    };
    
    viewModel.trackDelegate = self.verifyManager;
    
    passwordVC.animationType = HalfVCEntranceTypeFromBottom;
    [passwordVC presentWithNavigationControllerFrom:fromVC useMask:YES completion:nil];
}

@end
