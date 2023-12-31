//
//  CJPayCardOCRServiceImp.m
//  Pods
//
//  Created by 尚怀军 on 2021/6/20.
//

#import "CJPayCardOCRServiceImp.h"
#import "CJPayBankCardOCRViewController.h"
#import "CJPaySDKMacro.h"
#import "CJPayFullPageBaseViewController.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayCardOCRServiceImp

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassToPtocol(self, CJPayCardOCRService)
})

- (void)i_startCardOCRWithParam:(NSDictionary *)param
                completionBlock:(void (^)(CJPayCardOCRResultModel * _Nonnull))completionBlock {
    NSDictionary *ruleDic = [param cj_dictionaryValueForKey:@"rule"] ?: @{};
    NSString *merchantId = [param cj_stringValueForKey:@"merchant_id"];
    NSString *appId = [param cj_stringValueForKey:@"app_id"];
    
    CJPayBankCardOCRViewController *cardOCRVC = [CJPayBankCardOCRViewController new];
    cardOCRVC.appId = CJString(appId);
    cardOCRVC.merchantId = CJString(merchantId);
    cardOCRVC.minLength = [ruleDic cj_intValueForKey:@"min_length"];
    cardOCRVC.maxLength = [ruleDic cj_intValueForKey:@"max_length"];
    cardOCRVC.completionBlock = ^(CJPayCardOCRResultModel * _Nonnull resultModel) {
        CJ_CALL_BLOCK(completionBlock, resultModel);
    };
    cardOCRVC.BPEAData.requestAccessPolicy = @"bpea-caijing_service_ocr_bankcard_camera_permission";
    cardOCRVC.BPEAData.jumpSettingPolicy = @"bpea-caijing_service_ocr_bankcard_available_goto_setting";
    cardOCRVC.BPEAData.startRunningPolicy = @"bpea-caijing_service_ocr_bankcard_avcapturesession_start_running";
    cardOCRVC.BPEAData.stopRunningPolicy = @"bpea-caijing_service_ocr_bankcard_avcapturesession_stop_running";
    id referVC = [param cj_objectForKey:@"refer_vc"];
    UIViewController *topVC;
    if (referVC && [referVC isKindOfClass:[UIViewController class]]) {
        topVC = (UIViewController *)referVC;
    } else {
        topVC = [UIViewController cj_topViewController];
    }
    
    [cardOCRVC presentWithNavigationControllerFrom:topVC useMask:NO completion:nil];
}
@end
