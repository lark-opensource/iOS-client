//
//  CJPayPasswordBaseContentView.m
//  arkcrypto-minigame-iOS
//
//  Created by chenbocheng on 2022/4/14.
//

#import "CJPayPasswordBaseContentView.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayCombineDetailView.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
@interface CJPayPasswordBaseContentView ()

@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, copy) NSString *tipsStr;
@property (nonatomic, strong) CJPayCombineDetailView *combineDetailView;
@property (nonatomic, assign) BOOL isForceNormal;

@end

@implementation CJPayPasswordBaseContentView

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    self = [self initWithViewModel:viewModel isForceNormal:NO];
    return self;
}

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel isForceNormal:(BOOL)isForceNormal {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.isForceNormal = isForceNormal;
        self.tipsStr = [viewModel tipText];
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.viewModel.inputPasswordView];
    
    [self addSubview:self.combineDetailView];
    
    [self.combineDetailView updateWithCombineShowInfo:self.viewModel.response.payInfo.combineShowInfo];
    self.combineDetailView.hidden = !self.viewModel.response.payInfo.combineShowInfo;

    if ([self p_shouldShowMarketingView]) {
        [self p_setupUIForMarketing];
        [self p_updateMarketingViewByDefaultConfig];
    } else {
        [self p_setupUIForNormal];
    }
    CJPayMasMaker(self, {
        make.bottom.equalTo(self.viewModel.inputPasswordView);
    });
}

- (void)p_setupUIForNormal {
    if (Check_ValidString(self.tipsStr)) {
        [self addSubview:self.viewModel.tipsLabel];
        self.viewModel.tipsLabel.text = self.tipsStr;
        
        CJPayMasMaker(self.viewModel.tipsLabel, {
            make.top.equalTo(self).offset(12);
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.height.mas_equalTo(16);
        });
        
        CJPayMasMaker(self.viewModel.inputPasswordView, {
            make.top.equalTo(self.viewModel.tipsLabel.mas_bottom).offset(12);
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.height.mas_equalTo(48);
        });
    } else {
        CJPayMasMaker(self.viewModel.inputPasswordView, {
            make.top.equalTo(self).offset(24.5);
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.height.mas_equalTo(48);
        });
    }
}

- (void)p_setupUIForMarketing {
    CJPayMasMaker(self.combineDetailView, {
        if (self.viewModel.response.skipPwdGuideInfoModel || self.viewModel.response.preBioGuideInfo) {
            make.top.equalTo(self).offset(82);
        } else {
            make.top.equalTo(self).offset(86);
        }
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(38);
    });
    
    [self addSubview:self.viewModel.marketingMsgView];
    if (Check_ValidString(self.tipsStr)) {
        [self addSubview:self.viewModel.tipsLabel];
        self.viewModel.tipsLabel.text = self.tipsStr;
        
        CJPayMasMaker(self.viewModel.tipsLabel, {
            make.top.equalTo(self).offset(12);
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.height.mas_equalTo(16);
        });
        
        CJPayMasMaker(self.viewModel.marketingMsgView, {
            make.top.equalTo(self.viewModel.tipsLabel.mas_bottom).offset(12);
            make.left.right.equalTo(self);
            make.centerX.equalTo(self);
        });
    } else {
        CJPayMasMaker(self.viewModel.marketingMsgView, {
            make.top.equalTo(self).offset(12);
            make.left.right.equalTo(self);
            make.centerX.equalTo(self);
        });
    }
    
    CJPayMasMaker(self.viewModel.inputPasswordView, {
        if (self.viewModel.response.payInfo.combineShowInfo.count) {
            if (self.viewModel.response.skipPwdGuideInfoModel || self.viewModel.response.preBioGuideInfo) {
                make.top.mas_equalTo(136);
            } else {
                make.top.mas_equalTo(148);
            }
        } else {
            if (Check_ValidString(self.tipsStr) || self.viewModel.response.skipPwdGuideInfoModel || self.viewModel.response.preBioGuideInfo) {
                make.top.equalTo(self.viewModel.marketingMsgView.mas_bottom).offset(12);
            } else {
                make.top.equalTo(self).offset(78).priorityMedium();
                make.top.greaterThanOrEqualTo(self.viewModel.marketingMsgView.mas_bottom).offset(12);
            }
        }
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(48);
    });
}

- (BOOL)p_shouldShowMarketingView {
    return !self.isForceNormal && (self.viewModel.response.payInfo || self.viewModel.isPaymentForOuterApp);
}

- (void)p_updateMarketingViewByDefaultConfig {
    if (!self.viewModel.isPaymentForOuterApp) {
        return;
    }
    CJPayDefaultChannelShowConfig *config = self.viewModel.defaultConfig;
    NSDictionary *standardParams = [config getStandardAmountAndVoucher];
    NSString *payVoucherMsg = [standardParams cj_stringValueForKey:@"pay_voucher"];
    NSString *payAmount = [standardParams cj_stringValueForKey:@"pay_amount"];
    
    if (!Check_ValidString(payVoucherMsg)) {
        return;
    }
    
    if (!Check_ValidString(payAmount)) {
        CJPayLogAssert(YES, @"下发数据异常，请与后端同学确认数据格式.");
        payAmount = [NSString stringWithFormat:@"%.2f", self.viewModel.response.tradeInfo.tradeAmount / (double)100];
    }
    [self.viewModel.marketingMsgView updateWithPayAmount:payAmount voucherMsg:payVoucherMsg];
}

- (CJPayCombineDetailView *)combineDetailView {
    if (!_combineDetailView) {
        _combineDetailView = [[CJPayCombineDetailView alloc] init];
    }
    return _combineDetailView;
}

@end
