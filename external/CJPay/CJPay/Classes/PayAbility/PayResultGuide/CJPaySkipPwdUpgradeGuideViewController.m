//
//  CJPaySkipPwdUpgradeGuideViewController.m
//  Pods
//
//  Created by bytedance on 2022/7/27.
//

#import "CJPaySkipPwdUpgradeGuideViewController.h"

#import "CJPayECUpgradeSkipPwdRequest.h"
#import "CJPayECUpgrateSkipPwdResponse.h"
#import "CJPayKVContext.h"
#import "CJPayNameModel.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayStyleButton.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayResultFigureGuideView.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayToast.h"

@interface CJPaySkipPwdUpgradeGuideViewController ()

@property (nonatomic, strong) CJPayResultFigureGuideView *figureGuideView;
@property (nonatomic, strong) CJPayButton *cancelButton;

@end

@implementation CJPaySkipPwdUpgradeGuideViewController

- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model {
    if (self = [super init]) {
        self.model = model;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_imp" params:@{@"title" : CJString(self.model.title)}];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.figureGuideView confirmButtonAnimation];
    });
}

#pragma mark - Override

- (void)back {
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_click"
                        params:@{@"icon_name": @"关闭"}];
    
    [self closePage];
}

- (void)closePage {
    if (self.completion) {
        CJ_CALL_BLOCK(self.completion);
    } else {
        [super back];
    }
}

#pragma mark - Private Method

- (void)p_setupUI {
    if (Check_ValidString(self.model.cancelBtnDesc)) {
        self.navigationBar.backBtn.hidden = YES;
        [self.navigationBar addSubview:self.cancelButton];
        CJPayMasMaker(self.cancelButton, {
            make.centerY.equalTo(self.navigationBar);
            make.height.mas_equalTo(18);
            if ([self.model.cancelBtnLocation isEqualToString:@"right"]) {
                make.right.equalTo(self.navigationBar).offset(-24);
                make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right);
            } else {
                make.left.equalTo(self.navigationBar).offset(24);
                make.right.lessThanOrEqualTo(self.navigationBar.titleLabel.mas_left);
            }
        });
    } else {
        [self useCloseBackBtn];
    }
    [self p_setNavbarTitle];
    [self.contentView addSubview:self.figureGuideView];
    CJPayMasMaker(self.figureGuideView, {
        make.edges.equalTo(self.contentView);
    });
    
}

- (void)p_setNavbarTitle {
    if (self.model.headerPicUrl.length) {
        // 同时显示图片和文字
        self.navigationBar.titleImageView.hidden = NO;
        [self.navigationBar.titleImageView cj_setImageWithURL:[NSURL URLWithString:self.model.headerPicUrl]];
        CJPayMasReMaker(self.navigationBar.titleImageView, {
            make.centerY.equalTo(self.navigationBar);
            make.right.equalTo(self.navigationBar.titleLabel.mas_left).offset(-5);
            make.size.mas_equalTo(CGSizeMake(17, 17));
        });
        
        self.navigationBar.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        CJPayMasReMaker(self.navigationBar.titleLabel, {
            make.centerX.equalTo(self.navigationBar).offset(20);
            make.centerY.equalTo(self.navigationBar);
            make.width.lessThanOrEqualTo(self.navigationBar).offset(-96);
        });
    }
    
    self.navigationBar.titleLabel.text = Check_ValidString(self.model.headerDesc) ? self.model.headerDesc : CJPayLocalizedStr(@"支付成功");
}

- (void)p_onConfirmClick {
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_click"
                        params:@{@"icon_name": @"开启免密支付"}];
    [self.figureGuideView.confirmButton startLoading];

    @CJWeakify(self)
    [CJPayECUpgradeSkipPwdRequest startWithUpgradeResponse:self.verifyManager.response
                                          bizParams:@{}
                                         completion:^(NSError * _Nonnull error, CJPayECUpgrateSkipPwdResponse * _Nonnull response) {
        @CJStrongify(self)
        if (response && [response isSuccess]) {
            if(Check_ValidString(response.buttonText))
            {
                [self.figureGuideView.confirmButton stopLoadingWithTitle:response.buttonText];
            } else {
                [self.figureGuideView.confirmButton stopLoadingWithTitle:CJPayLocalizedStr(@"已提升 免密额度")];
            }
        } else {
            if(Check_ValidString(response.buttonText))
            {
                [self.figureGuideView.confirmButton stopLoadingWithTitle:response.buttonText];
            } else {
                [self.figureGuideView.confirmButton stopLoading];
            }
        }
        self.figureGuideView.confirmButton.userInteractionEnabled = NO;
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


- (void)p_cancelBtnClick {
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_click"
                        params:@{@"icon_name": @"关闭"}];
    [self closePage];
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
    [paramDic cj_setObject:CJString(self.model.pictureUrl) forKey:@"pswd_type"];
    [paramDic cj_setObject:@(self.model.quota / 100.0) forKey:@"pswd_quota"];
    [paramDic cj_setObject:@"1" forKey:@"is_awards_show"];
    [paramDic cj_setObject:CJString(self.model.title) forKey:@"title"];
    [paramDic cj_setObject:CJString(self.model.voucherDisplayText) forKey:@"awards_info"];
    [paramDic cj_setObject:CJString(self.model.guideShowStyle) forKey:@"guide_show_style"];
    [self.verifyManager.verifyManagerQueen trackCashierWithEventName:eventName params:paramDic];
}

#pragma mark - lazy View

- (CJPayResultFigureGuideView *)figureGuideView {
    if (!_figureGuideView) {
        _figureGuideView = [[CJPayResultFigureGuideView alloc] initWithGuideInfoModel:self.model];
        @CJWeakify(self)
        _figureGuideView.confirmBlock = ^{
            @CJStrongify(self)
            [self p_onConfirmClick];
        };
        _figureGuideView.protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            [self p_trackWithEventName:@"wallet_cashier_onesteppswd_setting_guide_page_click"
                               params:@{@"icon_name": @"免密协议"}];
            [self p_trackWithEventName:@"wallet_onesteppswd_setting_agreement_imp" params:@{}];
        };
    }
    return _figureGuideView;
}

- (CJPayButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [CJPayButton new];
        [_cancelButton.titleLabel setFont:[UIFont cj_fontOfSize:14]];
        [_cancelButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_cancelButton setTitle:CJString(self.model.cancelBtnDesc) forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor cj_161823WithAlpha:0.75] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(p_cancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

@end
