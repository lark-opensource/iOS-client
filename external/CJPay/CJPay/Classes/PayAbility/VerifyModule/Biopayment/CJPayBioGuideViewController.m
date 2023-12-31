//
//  CJPayBioGuideViewController.m
//  CJPay
//
//  Created by renqiang on 2020/9/6.
//

#import "CJPayBioGuideViewController.h"
#import "CJPayBaseVerifyManager.h"

#import "CJPayOpenBioGuideView.h"
#import "CJPayUIMacro.h"
#import "CJPayBioManager.h"
#import "CJPayTouchIdManager.h"
#import "CJPaySafeManager.h"
#import "CJPayRequestParam.h"
#import "CJPayTracker.h"
#import "CJPaySafeUtil.h"
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayCashdeskEnableBioPayRequest.h"
#import "CJPayBrandPromoteABTestManager.h"

@interface CJPayBioGuideViewController()<CJPayOpenBioGuideViewDelegate>

@property (nonatomic, strong) CJPayOpenBioGuideView *openBioGuideView;
@property (nonatomic, strong) CJPayBioPaymentInfo *bioPaymentInfo;
@property (nonatomic, copy) void (^completionBlock)(void);
@property (nonatomic, strong) CJPayButton *skipGuideButton;

@end

@implementation CJPayBioGuideViewController


+ (instancetype)createWithWithParams:(NSDictionary *)params completionBlock:(void (^)(void))completionBlock
{
    CJPayBioPaymentInfo *bioPaymentInfo = [params cj_objectForKey:@"payment_info"];
    CJPayBaseVerifyManager *verifyManager = [params cj_objectForKey:@"verify_manager"];
    BOOL useCloseBtn = [params cj_boolValueForKey:@"use_close_btn"];
    
    CJPayBioGuideViewController *vc = [[self alloc] initWithPaymentInfo:bioPaymentInfo completionBlock:completionBlock];
    vc.manager = verifyManager;
    vc.isTradeCreateAgain = verifyManager.resResponse.tradeInfo.isTradeCreateAgain;
    if (useCloseBtn) {
        [vc useCloseBackBtn];
    }
    return vc;
}

- (instancetype)initWithPaymentInfo:(CJPayBioPaymentInfo *)bioPaymentInfo completionBlock:(void (^)(void))completionBlock {
    self = [super init];
    if (self) {
        self.bioPaymentInfo = bioPaymentInfo;
        self.completionBlock = [completionBlock copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self p_setupUI];
    [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_pop_imp"
                        params:@{@"bio_guide_type" : @"bio_guide"}];
}

- (void)p_setupUI {
    [self.contentView addSubview:self.openBioGuideView];

    if (Check_ValidString(self.bioPaymentInfo.showType) && [self.bioPaymentInfo.showType isEqualToString:@"1"]) {
        [self.navigationBar addSubview:self.skipGuideButton];
        CJPayMasMaker(self.skipGuideButton, {
            make.right.equalTo(self.navigationBar.mas_right).offset(-16);
            make.centerY.equalTo(self.navigationBar.titleLabel);
            make.height.mas_equalTo(18);
            make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right);
        });
        if (Check_ValidString([CJPayBrandPromoteABTestManager shared].model.cashierTitle)) {
            [self.navigationBar setTitle:CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.cashierTitle]);
        } else {
            [self.navigationBar setTitle:CJPayDYPayTitleMessage];
        }
    } else {
        [self.navigationBar setTitle:CJString(self.bioPaymentInfo.openBioDesc)];
    }
    
    CJPayMasMaker(self.openBioGuideView, {
        make.edges.equalTo(self.contentView);
    });
}

#pragma mark - Override

- (void)back
{
    if (self.cjBackBlock) {
        self.cjBackBlock();
    } else {
        // 新转场无需关闭自身再给回调
        CJ_CALL_BLOCK(self.completionBlock);
    }
}

#pragma mark - CJPayOpenBioGuideViewDelegate

- (void)giveUpAction {
    [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_pop_click" params:@{
        @"button_name" : CJString(self.bioPaymentInfo.cancelBtnDesc),
        @"bio_guide_type" : @"bio_guide"
    }];
    [self back];
}

- (void)openBioPayment {
    [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_pop_click" params:@{
            @"button_name": CJString(self.bioPaymentInfo.openBioDesc),
            @"bio_guide_type" : @"bio_guide"
    }];
    
    NSMutableDictionary *requestModel = [NSMutableDictionary new];
    [requestModel cj_setObject:self.manager.response.merchant.appId forKey:@"app_id"];
    [requestModel cj_setObject:self.manager.response.merchant.merchantId forKey:@"merchant_id"];
    [requestModel cj_setObject:self.manager.response.userInfo.uid forKey:@"uid"];
    [requestModel cj_setObject:self.manager.response.tradeInfo.tradeNo forKey:@"trade_no"];
    [requestModel cj_setObject:[self.manager.response.processInfo dictionaryValue] forKey:@"process_info"];
    [requestModel cj_setObject:[CJPaySafeManager buildEngimaEngine:@""] forKey:@"engimaEngine"];
    [requestModel cj_setObject:self.manager.lastPWD forKey:@"lastPwd"];
    
    @CJWeakify(self)
    [CJPayBioManager openBioPaymentOnVC:self
                      withBioRequestDic:requestModel
                        completionBlock:^(BOOL result, BOOL needBack) {
        
        @CJStrongify(self)
        if (result) {
            //生物识别开通成功
            [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_result"
                                params:@{@"result": @"成功"}];
            
            NSString *btnTitle = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? CJPayLocalizedStr(@"已开通 指纹支付") : CJPayLocalizedStr(@"已开通 面容支付");
            [self.openBioGuideView setBtnTitle:btnTitle];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @CJStrongify(self)
                [self back];
            });
        } else {
            //生物识别开通失败
            [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_result"
                                params:@{@"result": @"失败"}];
            
            if (needBack) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    @CJStrongify(self)
                    [self back];
                });
            }
        }
    }];
}

- (void)stateButtonClick:(NSString *)buttonName {
    [self back];
}

#pragma mark - CJPayBaseLoadingProtocol

- (void)startLoading {
    if (![self.bioPaymentInfo.showType isEqualToString:@"1"]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:self.navigationBar.title];
    } else {
        [self.openBioGuideView startBtnLoading];
    }
}

- (void)stopLoading {
    [self.openBioGuideView stopBtnLoading];
}

#pragma mark - Tracker

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *paramDic = [NSMutableDictionary new];
    if (params) {
        [paramDic addEntriesFromDictionary:params];
    }
    NSString *from = self.isTradeCreateAgain ? @"wallet_cashier_payafter_second" : @"wallet_cashier_payafter";
    [paramDic cj_setObject:from forKey:@"from"];
    [paramDic cj_setObject:@"words_style" forKey:@"fingerprint_type"];
    if ([self.manager.verifyManagerQueen respondsToSelector:@selector(trackVerifyWithEventName:params:)]) {
        [self.manager.verifyManagerQueen performSelector:@selector(trackVerifyWithEventName:params:) withObject:eventName withObject:paramDic];
    }
}

#pragma mark - lazy

- (CJPayOpenBioGuideView *)openBioGuideView {
    if (!_openBioGuideView) {
        _openBioGuideView = [[CJPayOpenBioGuideView alloc] initWithBioInfo:self.bioPaymentInfo];
        _openBioGuideView.delegate = self;
    }
    return _openBioGuideView;
}

- (CJPayButton *)skipGuideButton {
    if (!_skipGuideButton) {
        _skipGuideButton = [CJPayButton new];
        _skipGuideButton.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_skipGuideButton setTitle:CJPayLocalizedStr(self.bioPaymentInfo.cancelBtnDesc) forState:UIControlStateNormal];
        [_skipGuideButton setTitleColor:[UIColor cj_douyinBlueColor] forState:UIControlStateNormal];
        [_skipGuideButton addTarget:self action:@selector(giveUpAction) forControlEvents:UIControlEventTouchUpInside];
        _skipGuideButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _skipGuideButton;
}

@end
