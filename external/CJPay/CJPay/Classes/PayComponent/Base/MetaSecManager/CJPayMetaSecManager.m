//
//  CJPayMetaSecManager.m
//  Pods
//
//  Created by 易培淮 on 2021/9/13.
//

#import "CJPayMetaSecManager.h"
#import "CJPayMetaSecService.h"
#import "CJPayUIMacro.h"
#import "CJPayProtocolManager.h"

@interface CJPayMetaSecManager ()<CJPayMetaSecService>

@end

@implementation CJPayMetaSecManager


#pragma mark - CJPayInnerService
+ (void)registerProtocol {
    CJPayGaiaRegisterComponentMethod
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayMetaSecService)
}

+ (instancetype)defaultService{
    static CJPayMetaSecManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CJPayMetaSecManager alloc] init];
    });
    return instance;
}

- (void)reportForSceneType:(CJPayRiskMsgType)sceneType {
    switch (sceneType) {
        case CJPayRiskMsgTypeInit:
            [self reportForScene:@"caijing_initialization"];
            break;
        case CJPayRiskMsgTypeInitAgain:
            [self reportForScene:@"caijing_initialization_again"];
            break;
        case CJPayRiskMsgTypeOpenCashdesk:
            [self reportForScene:@"caijing_cashdesk_request"];
            break;
        case CJPayRiskMsgTypeConfirmPay:
            [self reportForScene:@"caijing_pay_request"];
            break;
        case CJPayRiskMsgTypeConfirmWithDraw:
            [self reportForScene:@"caijing_withdraw_request"];
            break;
        case CJPayRiskMsgTypeTwoElementsValidation:
            [self reportForScene:@"caijing_two_elements_validation"];
            break;
        case CJPayRiskMsgTypeTwoElementsFastSign:
            [self reportForScene:@"caijing_two_elements_fast_sign"];
            break;
        case CJPayRiskMsgTypeRiskSignSMSCheckRequest:
            [self reportForScene:@"caijing_risk_sign_sms_check_request"];
            break;
        case CJPayRiskMsgTypeRiskFastSignRequest:
            [self reportForScene:@"caijing_risk_fast_sign_request"];
            break;
        case CJPayRiskMsgTypeRiskSetPayPWDRequest:
            [self reportForScene:@"caijing_risk_set_pay_pwd_request"];
            break;
        case CJPayRiskMsgTypeForgetPayPWDRequest:
            [self reportForScene:@"caijing_forget_pay_pwd_request"];
            break;
        case CJPayRiskMsgTypeRiskUserVerifyResult:
            [self reportForScene:@"caijing_risk_user_verify_result"];
            break;
        case CJPayRiskMsgTypeUnionPayAuthRequest:
            [self reportForScene:@"caijing_risk_bind_unionpay_request"];
            break;
        case CJPayRiskMsgTypeUnionPayCardListRequest:
            [self reportForScene:@"caijing_risk_unionpay_bind_card_request"];
            break;
        default:
            break;
    }
}

#pragma mark - Private Method
- (void)reportForScene:(NSString *)scene {
    if (self.delegate && [self.delegate respondsToSelector:@selector(reportForScene:)]) {
        [self.delegate reportForScene:scene];
    }
}

- (void)registerScenePageNameCallback:(NSInteger)biz cb:(id)cb {
    if (self.delegate && [self.delegate respondsToSelector:@selector(registerScenePageNameCallback:cb:)]) {
        [self.delegate registerScenePageNameCallback:biz cb:cb];
    }
}

#pragma mark - CJPayMetaSecService
- (void)i_registerMetaSecDelegate:(nonnull id<CJMetaSecDelegate>)delegate {
    self.delegate = delegate;
    [self reportForSceneType:CJPayRiskMsgTypeInit]; //SDK初始化上报
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reportForSceneType:CJPayRiskMsgTypeInitAgain]; //再次上报，因为有些数据可能拿不到
    });
}
@end


