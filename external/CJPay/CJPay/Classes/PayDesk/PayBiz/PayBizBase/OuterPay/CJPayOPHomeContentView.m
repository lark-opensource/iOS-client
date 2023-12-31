//
//  CJPayOPHomeContentView.m
//  AwemeInhouse
//
//  Created by xutianxi on 2022/3/29.
//

#import "CJPayOPHomeContentView.h"
#import "CJPayBDPayMainMessageView.h"
#import "CJPayMarketingMsgView.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayLineUtil.h"
#import "CJPayCreateOrderResponse.h"

@interface CJPayOPHomeContentView()

@property (nonatomic, strong) UIView *subContainer;
@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong) UILabel *amountDetailLabel;

@property (nonatomic, strong) CJPayBDPayMainMessageView *tradeMesageView;
@property (nonatomic, strong) CJPayBDPayMainMessageView *payTypeMessageView;

@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;

@end

@implementation CJPayOPHomeContentView

- (void)setupUI {
    [super setupUI];
    [self.subContainer addSubview:self.marketingMsgView];
    [self.subContainer addSubview:self.amountDetailLabel];
    [self addSubview:self.subContainer];
    
    [self addSubview:self.tradeMesageView];
    [self addSubview:self.payTypeMessageView];
    [self addSubview:self.safeGuardTipView];

    CJPayMasMaker(self.marketingMsgView, {
        make.left.right.top.equalTo(self.subContainer);
    });
    
    CJPayMasMaker(self.amountDetailLabel, {
        make.top.equalTo(self.marketingMsgView.mas_bottom).offset(2);
        make.left.right.bottom.equalTo(self.subContainer);
    });
    
    CJPayMasMaker(self.subContainer, {
        make.centerY.equalTo(self.mas_top).offset(68);
        make.left.right.equalTo(self.confirmPayBtn);
    });
    
    [CJPayLineUtil addTopLineToView:self.tradeMesageView marginLeft:16 marginRight:16 marginTop:1];
    CJPayMasMaker(self.tradeMesageView, {
        make.top.equalTo(self).offset(136);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(56);
    });
    
    CJPayMasMaker(self.payTypeMessageView, {
        make.top.equalTo(self.tradeMesageView.mas_bottom);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(60);
    });

    CJPayMasReMaker(self.confirmPayBtn, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-13);
        } else {
            make.bottom.equalTo(self).offset(CJ_IPhoneX ? -50 : -20);
        }
    });
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        self.safeGuardTipView.hidden = NO;
        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self).offset(-11);
            make.centerX.equalTo(self);
            make.height.mas_equalTo(18);
        });
    }
    
    self.clipsToBounds = NO;
}

#pragma mark - Getter

- (UIView *)subContainer {
    if (!_subContainer) {
        _subContainer = [UIView new];
    }
    
    return _subContainer;
}

- (CJPayMarketingMsgView *)marketingMsgView {
    if (!_marketingMsgView) {
        _marketingMsgView = [[CJPayMarketingMsgView alloc] initWithViewStyle:MarketingMsgViewStyleCompact isShowVoucherMsg:NO];
        UIColor *priceColor = [self.response.deskConfig.theme amountColor];
        [_marketingMsgView updatePriceColor:priceColor];
    }
    return _marketingMsgView;
}

- (UILabel *)amountDetailLabel {
    if (!_amountDetailLabel) {
        _amountDetailLabel = [UILabel new];
        _amountDetailLabel.font = [UIFont cj_fontOfSize:12];
        _amountDetailLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _amountDetailLabel.textAlignment = NSTextAlignmentCenter;
        [_amountDetailLabel setText:CJString(self.response.tradeInfo.tradeName)];
    }
    return _amountDetailLabel;
}

- (CJPayBDPayMainMessageView *)tradeMesageView
{
    if (!_tradeMesageView) {
        _tradeMesageView = [[CJPayBDPayMainMessageView alloc] init];
        [_tradeMesageView updateTitleLabelText:CJPayLocalizedStr(@"收款方信息")];
        _tradeMesageView.style = CJPayBDPayMainMessageViewStyleNone;
    }
    return _tradeMesageView;
}

- (CJPayBDPayMainMessageView *)payTypeMessageView
{
    if (!_payTypeMessageView) {
        _payTypeMessageView = [[CJPayBDPayMainMessageView alloc] init];
        [_payTypeMessageView updateTitleLabelText:CJPayLocalizedStr(@"付款方式")];
        _payTypeMessageView.userInteractionEnabled = YES;
        _payTypeMessageView.style = CJPayBDPayMainMessageViewStyleArrow;
    }
    return _payTypeMessageView;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.hidden = YES;
    }
    return _safeGuardTipView;
}

@end
