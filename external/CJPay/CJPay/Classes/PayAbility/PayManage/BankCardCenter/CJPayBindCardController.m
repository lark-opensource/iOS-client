//
//  CJPayBindCardController.m
//  Pods
//
//  Created by wangxiaohong on 2021/1/26.
//

#import "CJPayBindCardController.h"

#import "CJPayLoadingManager.h"
#import "CJPayExceptionViewController.h"
#import "CJPayCardManageModule.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayBindCardManager.h"
#import "CJPayExceptionViewController.h"
#import "CJPaySignCardMap.h"
#import "CJPayUserInfo.h"
#import "CJPayPassKitBizRequestModel.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@interface CJPayBindCardController()

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, strong) CJPayNavigationController *navigationController;

@property (nonatomic, copy) BDPayBindCardCompletion completion;
@property (nonatomic, copy) NSString *bizAuthExperiment;

@end

@implementation CJPayBindCardController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_close) name:BDPayClosePayDeskNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    CJPayLogInfo(@"dealloc");
}

- (void)startBindCardWithParams:(NSDictionary *)params completion:(nonnull BDPayBindCardCompletion)completion {
    self.appId = [params cj_stringValueForKey:@"app_id"];
    self.merchantId = [params cj_stringValueForKey:@"merchant_id"];
    NSString *tradeScene = [params cj_stringValueForKey:@"trade_scene"];
    self.bizAuthExperiment = [CJPayABTest getABTestValWithKey:CJPayABBizAuth];
    NSDictionary *bindCardInfoDic = [params cj_dictionaryValueForKey:@"bind_card_info"];
    self.completion = completion;
    
    if (!Check_ValidString(self.appId) || !Check_ValidString(self.merchantId)) {
        CJ_CALL_BLOCK(self.completion, CJPayBindCardResultFail, @"参数错误");
        return;
    }
    
    CJPayBindCardSharedDataModel *model = [self p_buildCommonModel];
    model.bindCardInfo = bindCardInfoDic;
    model.frontIndependentBindCardSource = [[params cj_dictionaryValueForKey:@"track_info"] cj_stringValueForKey:@"source"];
    model.trackerParams = [params cj_dictionaryValueForKey:@"track_info"];
    model.trackInfo = model.trackerParams;
    model.referVC = params.cjpay_referViewController;
    if (Check_ValidString([params cj_stringValueForKey:@"saas_scene"]) && Check_ValidString([CJPayRequestParam accessToken])) {
        model.isSaasScene = YES;
    }

    if (Check_ValidString(tradeScene)) {
        model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceECLargePay;
    } else {
        model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceTTPayOnlyBind;
    }
    [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:model];
}

- (CJPayBindCardSharedDataModel *)p_buildCommonModel {
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.cardBindSource = CJPayCardBindSourceTypeFrontIndependent;
    model.appId = self.appId;
    model.merchantId = self.merchantId;
    model.bizAuthExperiment = self.bizAuthExperiment;
    @CJWeakify(self);
    model.completion = ^(CJPayBindCardResultModel * _Nonnull cardResult) {
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.completion, cardResult.result, @"");
    };
    return model;
}

- (void)p_close {
    CJ_CALL_BLOCK(self.completion, CJPayBindCardResultCancel, @"实名冲突解决");
}

@end
