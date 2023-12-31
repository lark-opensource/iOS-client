//
//  CJPaySignView.m
//  Pods
//
//  Created by chenbocheng on 2022/7/11.
//

#import "CJPaySignView.h"
#import "CJPayUIMacro.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayStyleButton.h"
#import "CJPaySignPayQuerySignInfoResponse.h"
#import "CJPaySignDescView.h"
#import "CJPayProtocolDetailViewController.h"
#import "CJPaySignHeaderView.h"
#import "CJPayAccountInsuranceTipView.h"

@interface CJPaySignView ()

#pragma mark - views
@property (nonatomic, strong) CJPaySignHeaderView *headerView;

@property (nonatomic, strong) CJPaySignDescView *serverDetailView;
@property (nonatomic, strong) CJPaySignDescView *deductTimeView;

@property (nonatomic, strong) UIView *divideLine;

@property (nonatomic, strong) UILabel *deductMethodTitleLabel;
@property (nonatomic, strong) UILabel *deductMethodLabel;
@property (nonatomic, strong) UIImageView *deductArrowImage;

@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;

@property (nonatomic, strong) MASConstraint *divideLineTopToTime;
@property (nonatomic, strong) MASConstraint *divideLineTopToDetail;

#pragma mark - data
@property (nonatomic, strong) CJPaySignModel *signModel;

@end

@implementation CJPaySignView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithViewType:(CJPaySignViewType)viewType {
    self.viewType = viewType;
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - public method

- (void)updateWithSignModel:(CJPaySignModel *)model {
    self.signModel = model;
    if (self.viewType == CJPaySignViewTypeSignOnly) {
        self.headerView.isSignOnly = YES;
        [self.headerView.logoImageView cj_setImageWithURL:[NSURL URLWithString:CJString(model.signTemplateInfo.icon)]];
        self.headerView.logoDescLabel.text = CJString(model.signTemplateInfo.serviceName);
        self.headerView.logoSubDescLabel.text = CJString(model.signTemplateInfo.zgMerchantName);
    } else {
        self.headerView.isSignOnly = NO;
        [self.headerView.titleIconImageView cj_setImageWithURL:[NSURL URLWithString:CJString(model.signTemplateInfo.icon)]];
        self.headerView.titleLabel.text = model.signTemplateInfo.serviceName;
        self.headerView.descLabel.text = model.signTemplateInfo.zgMerchantName;
        NSString *payAmount = [NSString stringWithFormat:@"%.2f", @(model.realTradeAmount).floatValue * 0.01];
        [self.headerView.marketingMsgView updateWithPayAmount:payAmount voucherMsg:CJString(model.promotionDesc)];
    }
    
    [self.serverDetailView updateTitle:CJPayLocalizedStr(@"服务详情") subDesc:model.signTemplateInfo.serviceDesc];
    
    if (Check_ValidString(model.nextDeductDate)) {
        [self.deductTimeView updateTitle:CJPayLocalizedStr(@"扣款周期") subDesc:model.nextDeductDate];
    } else {
        self.deductTimeView.hidden = YES;
        [self.divideLineTopToTime deactivate];
        [self.divideLineTopToDetail activate];
    }
    
    self.deductMethodLabel.text = model.deductMethodDesc;
    
    CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
    protocolModel.guideDesc = CJPayLocalizedStr(@"阅读并同意");
    protocolModel.groupNameDic = model.protocolGroupNames;
    protocolModel.agreements = model.protocolInfo;
    [self.protocolView updateWithCommonModel:protocolModel];
    
    NSString *btnDesc = model.hasBankCard ? CJPayLocalizedStr(@"支付并开通") : CJPayLocalizedStr(@"添加银行卡开通");
    if (Check_ValidString(model.signTemplateInfo.buttonDesc)) {
        btnDesc = model.signTemplateInfo.buttonDesc;
    }
    [self.confirmButton setTitle:btnDesc forState:UIControlStateNormal];
}

#pragma mark - private method

- (void)p_setupUI {
    [self addSubview:self.headerView];
    
    [self addSubview:self.serverDetailView];
    [self addSubview:self.deductTimeView];
    [self addSubview:self.divideLine];
    [self addSubview:self.deductMethodTitleLabel];
    [self addSubview:self.deductMethodLabel];
    [self addSubview:self.deductArrowImage];
    [self addSubview:self.protocolView];
    [self addSubview:self.confirmButton];
    [self addSubview:self.safeGuardTipView];
    
    CJPayMasMaker(self.headerView, {
        make.top.equalTo(self).offset(40);
        make.centerX.equalTo(self);
        make.left.right.equalTo(self);
    })
    
    CJPayMasMaker(self.serverDetailView, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self.headerView.mas_bottom).offset(58);
    });
    
    CJPayMasMaker(self.deductTimeView, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self.serverDetailView.mas_bottom).offset(14);
    });
    
    CJPayMasMaker(self.divideLine, {
        make.left.right.equalTo(self.deductTimeView);
        make.height.equalTo(@0.5);
        self.divideLineTopToTime = make.top.equalTo(self.deductTimeView.mas_bottom).offset(24);
        self.divideLineTopToDetail = make.top.equalTo(self.serverDetailView.mas_bottom).offset(24);
    });
    
    [self.divideLineTopToTime activate];
    [self.divideLineTopToDetail deactivate];
    
    CJPayMasMaker(self.deductMethodTitleLabel, {
        make.left.equalTo(self.serverDetailView);
        make.top.equalTo(self.divideLine.mas_bottom).offset(24.5);
    });
    
    CJPayMasMaker(self.deductMethodLabel, {
        make.centerY.equalTo(self.deductMethodTitleLabel);
        make.left.greaterThanOrEqualTo(self.deductMethodTitleLabel.mas_right).offset(24);
    });
    
    CJPayMasMaker(self.deductArrowImage, {
        make.size.mas_equalTo(CGSizeMake(20, 20));
        make.left.equalTo(self.deductMethodLabel.mas_right);
        make.centerY.equalTo(self.deductMethodLabel);
        make.right.equalTo(self.serverDetailView);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self.mas_right).offset(-16);
        make.height.equalTo(@44);
    });
    
    CJPayMasMaker(self.protocolView, {
        make.left.right.equalTo(self.confirmButton);
        make.bottom.equalTo(self.confirmButton.mas_top).offset(-16);
    });
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        CJPayMasMaker(self.safeGuardTipView, {
            make.centerX.width.equalTo(self);
            make.bottom.equalTo(self).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.height.mas_equalTo(18);
        });
        
        CJPayMasMaker(self.confirmButton, {
            make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-12);
        });
    } else {
        CJPayMasMaker(self.confirmButton, {
            make.bottom.equalTo(self).offset(-16 - CJ_TabBarSafeBottomMargin);
        });
    }
}

- (void)p_arrowClick {
    if (self.signModel.hasBankCard) {
        CJ_CALL_BLOCK(self.changePayMethodBlock);
    } else {
        CJ_CALL_BLOCK(self.confirmActionBlock);
    }
}

#pragma mark - lazy views

- (CJPaySignDescView *)serverDetailView {
    if (!_serverDetailView) {
        _serverDetailView = [CJPaySignDescView new];
    }
    return _serverDetailView;
}

- (CJPaySignDescView *)deductTimeView {
    if (!_deductTimeView) {
        _deductTimeView = [CJPaySignDescView new];
    }
    return _deductTimeView;
}

- (UIView *)divideLine {
    if (!_divideLine) {
        _divideLine = [UIView new];
        _divideLine.backgroundColor = [UIColor cj_divideLineColor];
    }
    return _divideLine;
}

- (UILabel *)deductMethodTitleLabel {
    if (!_deductMethodTitleLabel) {
        _deductMethodTitleLabel = [UILabel new];
        _deductMethodTitleLabel.textColor = [UIColor cj_161823ff];
        _deductMethodTitleLabel.font = [UIFont cj_fontOfSize:14];
        _deductMethodTitleLabel.text = CJPayLocalizedStr(@"扣款方式");
    }
    return _deductMethodTitleLabel;
}

- (UILabel *)deductMethodLabel {
    if (!_deductMethodLabel) {
        _deductMethodLabel = [UILabel new];
        _deductMethodLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _deductMethodLabel.font = [UIFont cj_fontOfSize:14];
        [_deductMethodLabel cj_viewAddTarget:self action:@selector(p_arrowClick) forControlEvents:UIControlEventTouchUpInside];
        _deductMethodLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _deductMethodLabel;
}

- (UIImageView *)deductArrowImage {
    if (!_deductArrowImage) {
        _deductArrowImage = [UIImageView new];
        [_deductArrowImage cj_setImage:@"cj_arrow_icon"];
        [_deductArrowImage cj_viewAddTarget:self action:@selector(p_arrowClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deductArrowImage;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
    }
    return _protocolView;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        @CJWeakify(self)
        [_confirmButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.confirmActionBlock);
        }];
    }
    return _confirmButton;
}

- (CJPaySignHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [CJPaySignHeaderView new];
    }
    return _headerView;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.hidden = YES;
    }
    return _safeGuardTipView;
}

@end
