//
//  CJPaySignPayView.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/28.
//

#import "CJPaySignPayView.h"
#import "CJPaySignPayHeaderView.h"
#import "CJPaySignPayModel.h"
#import "CJPayMarketingMsgView.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayStyleButton.h"
#import "CJPaySignPayDescView.h"
#import "CJPaySignPayDeductMethodView.h"
#import "CJPaySignPayDeductDetailView.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayChooseDyPayMethodManager.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayAccountInsuranceTipView.h"

#import "CJPayUIMacro.h"

@interface CJPaySignPayView ()

@property (nonatomic, strong) CJPaySignPayHeaderView *headerView;

@property (nonatomic, strong) CJPayCommonProtocolView *kindSwitchView;

@property (nonatomic, strong) UIView *topDivideLine;

@property (nonatomic, strong) CJPaySignPayDeductDetailView *deductDetailView;

@property (nonatomic, strong) CJPayStyleButton *confirmBtn;
@property (nonatomic, strong) MASConstraint *confirmBtnPositionToDivideLine;

@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;

@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;

@end

@implementation CJPaySignPayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

#pragma mark - public func

- (void)updateInitialViewWithSignPayModel:(CJPaySignPayModel *)model {
    [self.headerView updateHeaderViewWithModel:model];
    CJPayCommonProtocolModel *kindSwitchModel = [CJPayCommonProtocolModel new];
    kindSwitchModel.selectPattern = CJPaySelectButtonPatternSwitch;
    kindSwitchModel.guideDesc = CJString(model.switchDesc);
    kindSwitchModel.protocolFont = [UIFont cj_boldFontOfSize:15];
    kindSwitchModel.protocolColor = [UIColor cj_161823ff];
    [self.kindSwitchView updateWithCommonModel:kindSwitchModel];
    self.deductDetailView.isNewUser = self.isNewUser;
    @CJWeakify(self)
    [self.deductDetailView updateDeductDetailViewWithModel:model payMethodClick:^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.payMethodClick);
    }];
    CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
    protocolModel.guideDesc = CJPayLocalizedStr(@"阅读并同意");
    protocolModel.groupNameDic = model.protocolGroupNames;
    protocolModel.agreements = model.protocolInfo;
    [self.protocolView updateWithCommonModel:protocolModel];
    
    if ([model.signPaySwitch isEqualToString:@"close"]) { // 如果没有按钮就不存在UI的变化问题
        [self p_changeCommonPay:model animate:NO];
    } else {
        [self.kindSwitchView setCheckBoxSelected:YES];
        [self p_changeSignPay:model animate:NO];
    }
    
    self.kindSwitchView.checkBoxClickBlock = ^{
        @CJStrongify(self)
        BOOL isOn = [self.kindSwitchView isCheckBoxSelected];
        CJ_CALL_BLOCK(self.trackerBlock, @"wallet_withhold_open_page_payment_switch_click", @{
            @"button_name" : @(!isOn)
        });
        if (isOn) {
            [self p_changeSignPay:model animate:YES];
        } else {
            [self p_changeCommonPay:model animate:YES];
        }
    };
}

- (BOOL)obtainSwitchStatus {
    return [self.kindSwitchView isCheckBoxSelected];
}

#pragma mark - private func

- (void)updateDeductMethodView:(CJPayDefaultChannelShowConfig *)defaultConfig buttonTitle:(nullable NSString *)buttonTitle {
    [self.deductDetailView updateDeductMethodView:defaultConfig];
    
    if ([self obtainSwitchStatus]) {
        [self.confirmBtn setTitle:CJString(buttonTitle) forState:UIControlStateNormal];
    }
}

- (void)p_changeCommonPay:(CJPaySignPayModel *)model animate:(BOOL)animate {
    self.protocolView.hidden = YES;
    [self.confirmBtn setTitle:CJPayLocalizedStr(@"确认支付") forState:UIControlStateNormal];
    [self.headerView updateMarketingMsgWithPayAmount:model.closePayAmount voucherMsg:@""];
    [self.kindSwitchView cj_setUserInteractionEnabled:NO];
    self.deductDetailView.alpha = 0;
    [self layoutIfNeeded];
    
    [self.confirmBtnPositionToDivideLine activate];
    if (animate) {
        [UIView animateWithDuration:0.25 animations:^{
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.kindSwitchView cj_setUserInteractionEnabled:YES];
            }
        }];
    } else {
        [self layoutIfNeeded];
    }
}

- (void)p_changeSignPay:(CJPaySignPayModel *)model animate:(BOOL)animate {
    if ([model.signPaySwitch isEqualToString:@"none"]) { //没有开关的情况下也是开通并支付
        self.kindSwitchView.hidden = YES;
        self.topDivideLine.hidden = YES;
        CJPayMasReMaker(self.deductDetailView, {
            make.top.mas_equalTo(self.headerView.mas_top).mas_offset(132);
            make.left.right.mas_equalTo(self);
        });
    }
    self.protocolView.hidden = NO;
    [self.headerView updateMarketingMsgWithPayAmount:model.openPayAmount voucherMsg:model.voucherMsg];
    [self.confirmBtn setTitle:CJString(model.buttonDesc) forState:UIControlStateNormal];
    [self.kindSwitchView cj_setUserInteractionEnabled:NO];
    [self layoutIfNeeded];
    
    [self.confirmBtnPositionToDivideLine deactivate];
    if (animate) {
        [UIView animateWithDuration:0.25 animations:^{
            [self layoutIfNeeded];
        }];
        [UIView animateWithDuration:0.1 delay:0.25 options:UIViewAnimationOptionLayoutSubviews animations:^{
            self.deductDetailView.alpha = 1;
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.kindSwitchView cj_setUserInteractionEnabled:YES];
            }
        }];
    } else {
        self.deductDetailView.alpha = 1;
        [self layoutIfNeeded];
    }
}

- (void)p_onConfirmAction {
    CJ_CALL_BLOCK(self.confirmBtnClickBlock, self.confirmBtn);
}

- (void)setupUI {
    [self addSubview:self.headerView];
    [self addSubview:self.kindSwitchView];
    [self addSubview:self.topDivideLine];
    [self addSubview:self.deductDetailView];
    [self addSubview:self.confirmBtn];
    [self addSubview:self.protocolView];
    [self addSubview:self.safeGuardTipView];
}

- (void)setupConstraints {
    
    CJPayMasMaker(self.headerView, {
        make.top.mas_equalTo(self).mas_offset(20);
        make.centerX.mas_equalTo(self);
        make.left.right.mas_equalTo(self);
    });
    
    CJPayMasMaker(self.kindSwitchView, {
        make.top.mas_equalTo(self.headerView.mas_top).mas_offset(165);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
    });
    
    CJPayMasMaker(self.topDivideLine, {
        make.left.right.mas_equalTo(self.kindSwitchView);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
        make.bottom.mas_equalTo(self.kindSwitchView).mas_offset(21);
    });
    
    CJPayMasMaker(self.deductDetailView, {
        make.top.mas_equalTo(self.topDivideLine.mas_bottom).mas_offset(24);
        make.left.right.mas_equalTo(self);
    });
    
    CJPayMasMaker(self.confirmBtn, {
        self.confirmBtnPositionToDivideLine = make.top.mas_equalTo(self.topDivideLine.mas_bottom).mas_offset(40);
        make.top.mas_equalTo(self.deductDetailView.mas_bottom).mas_offset(50);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.height.mas_equalTo(44);
    });
    
    CJPayMasMaker(self.protocolView, {
        make.left.right.equalTo(self.confirmBtn);
        make.top.equalTo(self.confirmBtn.mas_bottom).offset(12);
    });
    
    CJPayMasMaker(self.safeGuardTipView, {
        make.left.right.mas_equalTo(self);
        make.bottom.mas_equalTo(self).mas_offset(-46);
        make.height.mas_equalTo(18);
    })
}

#pragma mark - lazy load

- (CJPaySignPayHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [CJPaySignPayHeaderView new];
    }
    return _headerView;
}


- (UIView *)topDivideLine {
    if (!_topDivideLine) {
        _topDivideLine = [UIView new];
        _topDivideLine.backgroundColor = [UIColor cj_divideLineColor];
    }
    return _topDivideLine;
}

- (CJPaySignPayDeductDetailView *)deductDetailView {
    if (!_deductDetailView) {
        _deductDetailView = [CJPaySignPayDeductDetailView new];
    }
    return _deductDetailView;
}

- (CJPayStyleButton *)confirmBtn {
    if (!_confirmBtn) {
        _confirmBtn = [[CJPayStyleButton alloc] init];
        _confirmBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmBtn.titleLabel.textColor = [UIColor whiteColor];
        
        [_confirmBtn cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        [_confirmBtn addTarget:self action:@selector(p_onConfirmAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmBtn;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
    }
    return _protocolView;
}

- (CJPayCommonProtocolView *)kindSwitchView {
    if (!_kindSwitchView) {
        _kindSwitchView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
    }
    return _kindSwitchView;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}


@end
