//
//  CJPayOuterSignLoadingViewController.m
//  Pods
//
//  Created by wangxiaohong on 2022/7/14.
//

#import "CJPayOuterSignLoadingViewController.h"

#import "CJPayUIMacro.h"
#import "CJPayOuterPayUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayAPI.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayLoadingManager.h"

@interface CJPayOuterSignLoadingViewController ()<CJPayAPIDelegate>

@end

@implementation CJPayOuterSignLoadingViewController

- (void)didFinishParamsCheck:(BOOL)isSuccess {
    if (!isSuccess) {
        return;
    }
    if (self.isSignOnly) {
        [self p_requestSignOnlySignInfo];
    } else {
        [self p_requestQuerySignInfo];
    }
}

- (void)p_requestQuerySignInfo {
    NSString *token = [self.schemaParams cj_stringValueForKey:@"token"]; //浏览器
    if (!Check_ValidString(token)) {
        // 未取到 token，可能是抖音以外 App 拉起
        token = [self.schemaParams cj_stringValueForKey:@"pay_token"];
    }
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinOpenDeskLoading vc:self];
    [CJ_OBJECT_WITH_PROTOCOL(CJPaySignDYPayModule) i_requestSignAndPayInfoWithBizParams:@{@"token": token} completion:^(BOOL isSuccess, JSONModel  *_Nonnull response, NSDictionary * _Nonnull extraData) {
        [[CJPayLoadingManager defaultService] stopLoading];
        @CJWeakify(self)
        if (isSuccess) {
            [self p_signAndPayWithResponse:response];
        } else {
            NSString *errorMsg = [extraData cj_stringValueForKey:@"error_msg"];
            [self alertRequestErrorWithMsg:CJString(errorMsg) clickAction:^{
                @CJStrongify(self)
                [self closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeFailed];
            }];
        }
    }];
}

- (void)p_requestSignOnlySignInfo {
    NSString *zgAppId = [self.schemaParams cj_stringValueForKey:@"zg_app_id"];
    NSString *zgMerchantId = [self.schemaParams cj_stringValueForKey:@"zg_merchant_id"];
    NSString *bizOrderNo = [self.schemaParams cj_stringValueForKey:@"member_biz_order_no"];
    
    NSDictionary *params = @{
        @"member_biz_order_no": CJString(bizOrderNo),
        @"app_id" : CJString(zgAppId),
        @"merchant_id" : CJString(zgMerchantId)
    };
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinOpenDeskLoading vc:self];
    [CJ_OBJECT_WITH_PROTOCOL(CJPaySignDYPayModule) i_requestSignOnlyInfoWithBizParams:params completion:^(BOOL isSuccess, JSONModel * _Nonnull response, NSDictionary * _Nonnull extraData) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if (isSuccess) {
            NSString *appId = [self.schemaParams cj_stringValueForKey:@"app_id"]; // 宿主的aid
            NSDictionary *params = @{
                @"zg_app_id" : CJString(zgAppId),
                @"zg_merchant_id" : CJString(zgMerchantId),
                @"member_biz_order_no": CJString(bizOrderNo),
                @"sign_page_info":CJString([response toJSONString]),
                @"sign_type":  Check_ValidString(appId) ? @"outer_app" : @"outer_web",
                @"return_url": CJString(self.jumpBackUrlStr),
            };
            params.cjpay_referViewController = self;
            [CJ_OBJECT_WITH_PROTOCOL(CJPaySignDYPayModule) i_signOnlyWithDataDict:params delegate:self];
        } else {
            NSString *alertText = CJString([extraData cj_stringValueForKey:@"error_msg"]);
            @CJWeakify(self)
            [self alertRequestErrorWithMsg:alertText clickAction:^{
                @CJStrongify(self)
                [self closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeFailed];
            }];
        }
    }];
}

- (void)p_signAndPayWithResponse:(JSONModel *)response {
    NSString *appId = [self.schemaParams cj_stringValueForKey:@"app_id"];
    NSDictionary *params = @{
        @"sign_page_info": CJString([response toJSONString]),
        @"token": CJString([self.schemaParams cj_stringValueForKey:@"token"]),
        @"app_id": CJString([self.schemaParams cj_stringValueForKey:@"app_id"]),
        @"sign_type":  Check_ValidString(appId) ? @"outer_app" : @"outer_web",
        @"return_url": CJString(self.jumpBackUrlStr),
    };
    params.cjpay_referViewController = self;
    [CJ_OBJECT_WITH_PROTOCOL(CJPaySignDYPayModule) i_signAndPayWithDataDict:params delegate:self];
}

#pragma mark - CJPayAPIDelegate
- (void)callState:(BOOL)success fromScene:(CJPayScene)scene {
    if (scene == CJPaySceneSign) {
        CJPayLogInfo(@"signStatue: %@", success ? @"1" : @"0");
    }
}

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    CJPayLogInfo(@"%@",response);
}


@end
