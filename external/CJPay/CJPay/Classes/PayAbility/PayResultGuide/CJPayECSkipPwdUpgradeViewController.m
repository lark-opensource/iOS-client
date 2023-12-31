//
//  CJPayECSkipPwdUpgradeViewController.m
//  Pods
//
//  Created by 孟源 on 2021/10/12.
//

#import "CJPayECSkipPwdUpgradeViewController.h"
#import "CJPayECUpgradeSkipPwdRequest.h"
#import "CJPayECUpgrateSkipPwdResponse.h"
#import "CJPaySkippwdAfterpayGuideView.h"
#import "CJPayKVContext.h"
#import "CJPayNameModel.h"
#import "CJPayUIMacro.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayStyleButton.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayToast.h"

@interface CJPayECSkipPwdUpgradeViewController ()

@property (nonatomic, weak) CJPayBaseVerifyManager *verifyManager;

@property (nonatomic, strong) CJPaySkippwdAfterpayGuideView *skippwdGuideView;
@property (nonatomic, strong) CJPayButton *skipButton;
@property (nonatomic, strong) UILabel *subGuideLabel;

@property (nonatomic, strong) CJPayBDCreateOrderResponse *createOrderResponse;
@property (nonatomic, strong) CJPayBDOrderResultResponse *orderResultResponse;

@end

@implementation CJPayECSkipPwdUpgradeViewController

#pragma mark - Lifecycle

- (instancetype)initWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager {
    self = [super init];
    if (self) {
        self.verifyManager = verifyManager;
        self.orderResultResponse = verifyManager.resResponse;
        self.createOrderResponse = verifyManager.response;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setNavTitle];
    [self p_setupUI];
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_imp"
                        params:@{@"title" : CJString(self.orderResultResponse.skipPwdGuideInfoModel.title)}];
    
}

#pragma mark - Override

- (void)back {
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_click"
                        params:@{@"icon_name": @"关闭"}];
    
    [self closePage];
}

- (void)closePage {
    if (self.cjBackBlock) {
        self.cjBackBlock();
    } else {
        // 新转场无需关闭自身再给回调
        CJ_CALL_BLOCK(self.completion);
    }
}

#pragma mark - Private Method

- (void)p_setupUI {
    self.navigationBar.title = CJString(@"支付成功");
    self.navigationBar.viewType = CJPayViewTypeDenoise;
    
    [self.navigationBar addSubview:self.skipButton];
    CJPayMasMaker(self.skipButton, {
        make.left.equalTo(self.navigationBar).offset(16);
        make.centerY.equalTo(self.navigationBar.titleLabel);
        make.height.mas_equalTo(18);
        make.right.lessThanOrEqualTo(self.navigationBar.titleLabel.mas_left);
    });
    self.navigationBar.backBtn.hidden = YES;

    [self.contentView addSubview:self.skippwdGuideView];
    [self.skippwdGuideView addSubview:self.subGuideLabel];
    
    CJPayMasMaker(self.skippwdGuideView, {
        make.edges.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.subGuideLabel, {
        make.centerX.equalTo(self.skippwdGuideView);
        make.left.greaterThanOrEqualTo(self.skippwdGuideView).offset(16);
        make.right.lessThanOrEqualTo(self.skippwdGuideView).offset(-16);
        make.top.equalTo(self.skippwdGuideView.mainTitleLabel.mas_bottom).offset(8);
    });
    
    [self p_setText];
}

- (void)p_setText {
    self.skippwdGuideView.mainTitleLabel.font = [UIFont cj_boldFontOfSize:22];
    self.skippwdGuideView.mainTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
    self.skippwdGuideView.mainTitleLabel.text = Check_ValidString(self.orderResultResponse.skipPwdGuideInfoModel.title)? self.orderResultResponse.skipPwdGuideInfoModel.title : CJPayLocalizedStr(@"支付成功, 可提升免密额度");
    
    NSString *buttonText = Check_ValidString(self.orderResultResponse.skipPwdGuideInfoModel.buttonText)? self.orderResultResponse.skipPwdGuideInfoModel.buttonText : CJPayLocalizedStr(@"确认提升 免密额度");
    [self.skippwdGuideView.confirmButton setTitle: buttonText forState:UIControlStateNormal];
    
    if (self.orderResultResponse.skipPwdGuideInfoModel.subGuide.count > 0) {
        id obj = [self.orderResultResponse.skipPwdGuideInfoModel.subGuide cj_objectAtIndex:0];
        if ([obj isKindOfClass:BDPaySkipPwdSubGuideInfoModel.class]) {
            BDPaySkipPwdSubGuideInfoModel *subGuideObj = (BDPaySkipPwdSubGuideInfoModel *)obj;
            self.subGuideLabel.attributedText = [self p_subGuideAttributeStrWithGuideModel:subGuideObj];
        }
    }
}

- (void)p_setNavTitle {
    CJPayNameModel *nameModel = [CJPayKVContext kv_valueForKey:CJPayDeskTitleKVKey];
    if (nameModel.payName) {
        [self setTitle:nameModel.payName];
    } else {
        if(Check_ValidString([CJPayBrandPromoteABTestManager shared].model.cashierTitle)) {
            [self setTitle:CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.cashierTitle)];
        } else {
            [self setTitle:CJPayLocalizedStr(@"支付")];
        }
    }
}

- (void)p_cancelBtnClick {
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_click"
                        params:@{@"icon_name": @"关闭"}];
    [self closePage];
}

- (void)p_onConfirmClick {
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_click"
                        params:@{@"icon_name": @"开启免密支付"}];
    [self.skippwdGuideView.confirmButton startLoading];

    @CJWeakify(self)
    [CJPayECUpgradeSkipPwdRequest startWithUpgradeResponse:self.createOrderResponse
                                          bizParams:@{}
                                         completion:^(NSError * _Nonnull error, CJPayECUpgrateSkipPwdResponse * _Nonnull response) {
        @CJStrongify(self)
        if (response && [response isSuccess]) {
            if(Check_ValidString(response.buttonText))
            {
                [self.skippwdGuideView.confirmButton stopLoadingWithTitle:response.buttonText];
            } else {
                [self.skippwdGuideView.confirmButton stopLoadingWithTitle:CJPayLocalizedStr(@"已提升 免密额度")];
            }
        } else {
            if(Check_ValidString(response.buttonText))
            {
                [self.skippwdGuideView.confirmButton stopLoadingWithTitle:response.buttonText];
            } else {
                [self.skippwdGuideView.confirmButton stopLoading];
            }
        }
        self.skippwdGuideView.confirmButton.userInteractionEnabled = NO;
        NSString *msg = Check_ValidString(response.modifyResult)? CJPayLocalizedStr(response.modifyResult): CJPayLocalizedStr(response.msg);
        [CJToast toastText:CJPayLocalizedStr(msg) inWindow:self.cj_window];
        // 收起页面
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @CJStrongify(self)
            [self closePage];
        });
        [self p_trackWithEventName:@"wallet_onesteppswd_setting_result"
                            params:@{@"result": response && [response isSuccess] ? @"1" : @"0",
                                     @"error_code": CJString(response.code),
                                     @"error_message": CJString(response.msg)}];
    }];
}

- (NSAttributedString *)p_subGuideAttributeStrWithGuideModel:(BDPaySkipPwdSubGuideInfoModel *)guideModel {
    if ([self.orderResultResponse.skipPwdGuideInfoModel.guideStyle isEqualToString:@"UpQuotaV2"]) { //提额实验组样式
        if ([guideModel.iconDesc containsString:@"$"]) {
            return [guideModel.iconDesc attributedStringWithDollarSeparated];
        } else {
            return [[NSAttributedString alloc] initWithString:CJString(guideModel.iconDesc)];
        }
    } else {
        NSArray *stringArray = [guideModel.iconDesc componentsSeparatedByString:@"$"];
        id regularString = [stringArray cj_objectAtIndex:0] ?: @"";
        id mediumString = [stringArray cj_objectAtIndex: 1] ?: @"";
        if (![regularString isKindOfClass:NSString.class] || ![mediumString isKindOfClass:NSString.class]) {
            return [[NSAttributedString alloc] initWithString:CJString(guideModel.iconDesc)];
        }
        NSMutableAttributedString *descStr = [[NSMutableAttributedString alloc]
                                              initWithString:((NSString *)regularString)
                                              attributes:@{
            NSFontAttributeName: [UIFont cj_fontOfSize:17],
            NSForegroundColorAttributeName: [UIColor cj_161823WithAlpha:0.75],
        }];
        [descStr appendAttributedStringWith:((NSString *)mediumString) textColor:[UIColor cj_161823WithAlpha:0.75] font:[UIFont cj_boldFontOfSize:17]];
        return [descStr copy];
    }
}

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *paramDic = [NSMutableDictionary new];
    if (params) {
        [paramDic addEntriesFromDictionary:params];
    }
    NSString *sourceName = self.verifyManager.isBindCardAndPay ? @"新卡引导页" : @"支付完成后";
    NSString *pswdSourceName = self.isTradeCreateAgain ? @"二次支付成功" : @"支付完成后";
    [paramDic cj_setObject:sourceName forKey:@"source"];
    [paramDic cj_setObject:pswdSourceName forKey:@"pswd_source"];
    [paramDic cj_setObject:@"promote_quota" forKey:@"pswd_guide_type"];
    [paramDic cj_setObject:@"words_style" forKey:@"pswd_type"];
    [paramDic cj_setObject:CJString(self.orderResultResponse.resultPageGuideInfoModel.title) forKey:@"title"];
    [paramDic cj_setObject:CJString(self.orderResultResponse.resultPageGuideInfoModel.guideShowStyle) forKey:@"guide_show_style"];
    [paramDic cj_setObject:@(self.orderResultResponse.skipPwdGuideInfoModel.quota / 100.0) forKey:@"pswd_quota"];
    [self.verifyManager.verifyManagerQueen trackCashierWithEventName:eventName params:paramDic];
}

#pragma mark - lazy View

- (CJPaySkippwdAfterpayGuideView *)skippwdGuideView {
    if (!_skippwdGuideView) {
        _skippwdGuideView = [[CJPaySkippwdAfterpayGuideView alloc] initWithOrderResponse:self.verifyManager.resResponse];
        [_skippwdGuideView.confirmButton addTarget:self action:@selector(p_onConfirmClick) forControlEvents:UIControlEventTouchUpInside];
        @CJWeakify(self)
        _skippwdGuideView.protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_click"
                                params:@{@"icon_name": @"免密协议"}];
            [self p_trackWithEventName:@"wallet_onesteppswd_setting_agreement_imp"
                                params:@{}];
        };
    }
    return _skippwdGuideView;
}

- (CJPayButton *)skipButton {
    if (!_skipButton) {
        _skipButton = [CJPayButton new];
        _skipButton.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_skipButton setTitle:CJPayLocalizedStr(@"跳过") forState:UIControlStateNormal];
        [_skipButton setTitleColor:[UIColor cj_161823WithAlpha:0.75] forState:UIControlStateNormal];
        _skipButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [_skipButton addTarget:self action:@selector(p_cancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _skipButton;
}

- (UILabel *)subGuideLabel {
    if (!_subGuideLabel) {
        _subGuideLabel = [UILabel new];
        _subGuideLabel.textAlignment = NSTextAlignmentCenter;
        _subGuideLabel.numberOfLines = 0;
    }
    return _subGuideLabel;
}
@end
