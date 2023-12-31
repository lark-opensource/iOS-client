//
//  CJPayBioConfirmHomeView.m
//  Pods
//
//  Created by wangxiaohong on 2020/11/15.
//

#import "CJPayBioConfirmHomeView.h"
#import "CJPayMarketingMsgView.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayLineUtil.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPaySkipPwdGuideInfoModel.h"
#import "CJPayBioPaymentPlugin.h"

@interface  CJPayBioConfirmHomeView()

@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView;//显示原价、折后价、优惠活动
@property (nonatomic, strong) UILabel *tradeTitleLabel;//订单标题
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *tradeDetailLabel;//订单支付方式
@property (nonatomic, strong) UIImageView *tipsImageView;//还款说明的小三角形
@property (nonatomic, strong) UIView *tipsBackgroundView;//还款说明背景
@property (nonatomic, strong) UILabel *tipsLabel;//分期还款详情说明
@property (nonatomic, strong) UIView *lineView;//分割线
@property (nonatomic, strong) UILabel *verifyDescLabel;

@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;//分割线
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;//分割线
@property (nonatomic, strong) CJPayStyleButton *confirmButton;

@end

@implementation CJPayBioConfirmHomeView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    [self addSubview:self.marketingMsgView];
    [self addSubview:self.tradeTitleLabel];
    [self addSubview:self.iconImageView];
    [self addSubview:self.tradeDetailLabel];
    [self addSubview:self.lineView];
    [self addSubview:self.tipsImageView];
    [self addSubview:self.tipsBackgroundView];
    [self.tipsBackgroundView addSubview:self.tipsLabel];
    [self addSubview:self.confirmButton];
    [self addSubview:self.protocolView];
    
    CJPayMasMaker(self.marketingMsgView, {
        make.top.equalTo(self).offset(40);
        make.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self.tradeTitleLabel, {
        make.top.equalTo(self.marketingMsgView.mas_bottom).offset(53);
        make.left.equalTo(self).offset(16);
        make.height.mas_equalTo(22);
    });
    
    CJPayMasMaker(self.iconImageView, {
        make.right.equalTo(self.tradeDetailLabel.mas_left).offset(-8);
        make.width.height.mas_equalTo(20);
        make.centerY.equalTo(self.tradeDetailLabel);
    });
    
    CJPayMasMaker(self.tradeDetailLabel, {
        make.right.equalTo(self).offset(-16);
        make.left.mas_greaterThanOrEqualTo(self).offset(107);
        make.centerY.equalTo(self.tradeTitleLabel);
        make.height.mas_equalTo(22);
    });
    
    CJPayMasMaker(self.lineView, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self.tradeDetailLabel.mas_top).offset(-17);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
    
    CJPayMasMaker(self.tipsImageView, {
        make.top.equalTo(self.tradeTitleLabel.mas_bottom).offset(8);
        make.left.equalTo(self).offset(37);
        make.height.mas_equalTo(7);
        make.width.mas_equalTo(18);
    });

    CJPayMasMaker(self.tipsBackgroundView, {
        make.top.equalTo(self.tipsImageView.mas_bottom);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    });

    
    CJPayMasMaker(self.tipsLabel, {
        make.top.equalTo(self.tipsBackgroundView).offset(11);
        make.left.equalTo(self.tipsBackgroundView).offset(16);
        make.right.equalTo(self.tipsBackgroundView).offset(-16);
        make.bottom.equalTo(self.tipsBackgroundView).offset(-11);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.bottom.equalTo(self);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
    });
    
    CJPayMasMaker(self.protocolView, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.bottom.equalTo(self.confirmButton.mas_top).offset(-20);
    });
    
    [self p_resetButtonTitle];
}

- (void)updateUI:(CJPayBDCreateOrderResponse *)model {
    self.response = model;
    [self.marketingMsgView updateWithModel:model];
    self.tradeDetailLabel.text = CJString(model.payInfo.payName);
    [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:model.payInfo.iconUrl]
                               placeholder:[UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]]];
    // 组合支付隐藏图标
    CJPayChannelType channelType = [CJPayBDTypeInfo getChannelTypeBy:self.response.payInfo.businessScene];
    self.iconImageView.hidden = channelType == BDPayChannelTypeCombinePay;
    if (!Check_ValidString(model.payInfo.tradeDesc)) {
        self.lineView.hidden = NO;
    } else {
        self.tipsImageView.hidden = NO;
        self.tipsBackgroundView.hidden = NO;
        self.tipsLabel.hidden = NO;
        self.tipsLabel.text = CJString(model.payInfo.tradeDesc);
    }
    
    CJPayCommonProtocolModel *commonModel = [CJPayCommonProtocolModel new];
    commonModel.guideDesc = model.skipPwdGuideInfoModel.guideMessage;
    commonModel.groupNameDic = model.skipPwdGuideInfoModel.protocolGroupNames;
    commonModel.agreements = model.skipPwdGuideInfoModel.protocoList;
    commonModel.isSelected = model.skipPwdGuideInfoModel.isChecked;
    commonModel.protocolFont = [UIFont cj_fontOfSize:12];
    commonModel.selectPattern = CJPaySelectButtonPatternCheckBox;
    [self.protocolView updateWithCommonModel:commonModel];
    self.protocolView.hidden = !model.skipPwdGuideInfoModel.needGuide;
    [self p_resetButtonTitle];
    [self p_updateWithVerifyDesc:[self p_tipTextWiht:model.payInfo]];
}

- (BOOL)isCheckBoxSelected {
    return [self.protocolView isCheckBoxSelected];
}

- (void)p_resetButtonTitle {
    if ([self isCheckBoxSelected]) {
        NSString *buttonText = Check_ValidString(self.response.skipPwdGuideInfoModel.buttonText) ? self.response.skipPwdGuideInfoModel.buttonText : CJPayLocalizedStr(@"开通免密并支付");
        [self.confirmButton cj_setBtnTitle:buttonText];
    } else {
        [self.confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"确认支付")];
    }
    self.response.skipPwdGuideInfoModel.isSelectedManually = [self.protocolView isCheckBoxSelected];
}

- (void)p_updateWithVerifyDesc:(NSString *)verifyDesc {
    if (!Check_ValidString(verifyDesc)) {
        return;
    }
    
    [self addSubview:self.verifyDescLabel];
    self.verifyDescLabel.text = verifyDesc;
    
    CJPayMasMaker(self.verifyDescLabel, {
        make.top.equalTo(self).offset(16);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    });
    
    CJPayMasReMaker(self.marketingMsgView, {
        make.top.equalTo(self.verifyDescLabel.mas_bottom).offset(16);
        make.left.right.equalTo(self);
    });
}

- (NSString *)p_tipTextWiht:(CJPayInfo *)payInfo {
    NSInteger verifyDescType = self.response.payInfo.verifyDescType;
    // 验证方式降级（具体含义参考： verifyDescType 字段注释）
    if (verifyDescType == 3 || (verifyDescType == 2)) {
        // 后端下发生物验证，客户端也没有被降级，不显示兜底文案
        if (verifyDescType == 2 && [self p_isBioVerifyAvailable]) {
            return @"";
        }
        return payInfo.verifyDesc;
    }
    return payInfo.verifyDesc;
}

//检查指纹/面容是否可用
- (BOOL)p_isBioVerifyAvailable {
    return [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBioPayAvailableWithResponse:self.response];
}

- (void)p_confirmButtonTapped
{
    if (self.confirmButtonClickBlock) {
        CJ_DelayEnableView(self);
        self.confirmButtonClickBlock();
    }
}

- (CJPayMarketingMsgView *)marketingMsgView
{
    if (!_marketingMsgView) {
        _marketingMsgView = [[CJPayMarketingMsgView alloc] initWithViewStyle:MarketingMsgViewStyleNormal];
    }
    return _marketingMsgView;
}

- (UILabel *)tradeTitleLabel
{
    if (!_tradeTitleLabel) {
        _tradeTitleLabel = [UILabel new];
        _tradeTitleLabel.text = CJPayLocalizedStr(@"付款方式");
        _tradeTitleLabel.font = [UIFont cj_fontOfSize:15];
        _tradeTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
    }
    return _tradeTitleLabel;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
    }
    return _iconImageView;
}

- (UILabel *)tradeDetailLabel
{
    if (!_tradeDetailLabel) {
        _tradeDetailLabel = [UILabel new];
        _tradeDetailLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _tradeDetailLabel.font = [UIFont cj_fontOfSize:15];
        _tradeDetailLabel.textColor = [UIColor cj_161823ff];
    }
    return _tradeDetailLabel;
}

- (void)p_trackWithEventName:(NSString *)event
                      params:(NSDictionary *)params {
    CJ_CALL_BLOCK(self.trackerBlock, CJString(event), params);
}

- (UIImageView *)tipsImageView
{
    if (!_tipsImageView) {
        _tipsImageView = [UIImageView new];
        [_tipsImageView cj_setImage:@"cj_tips_arrow_triangle_icon"];
        _tipsImageView.hidden = YES;
    }
    return _tipsImageView;
}

- (UIView *)tipsBackgroundView
{
    if (!_tipsBackgroundView) {
        _tipsBackgroundView = [UIView new];
        _tipsBackgroundView.backgroundColor = [UIColor cj_colorWithHexString:@"#F8F8F8"];
        [_tipsBackgroundView cj_showCornerRadius:4];
        _tipsBackgroundView.hidden = YES;
    }
    return _tipsBackgroundView;
}

- (UILabel *)tipsLabel
{
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.numberOfLines = 0;
        _tipsLabel.font = [UIFont cj_fontOfSize:13];
        _tipsLabel.textColor = [UIColor cj_161823ff];
        _tipsLabel.hidden = YES;
    }
    return _tipsLabel;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
        @CJWeakify(self)
        _protocolView.checkBoxClickBlock = ^{
            @CJStrongify(self)
            [self p_resetButtonTitle];
            NSString *buttonName = [self.protocolView isCheckBoxSelected] ? @"2" : @"3";
            [self p_trackWithEventName:@"wallet_fingerprint_verify_pay_confirm_click"
                                params:@{@"button_name": buttonName}];
        };
        _protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            [self p_trackWithEventName:@"wallet_fingerprint_verify_pay_confirm_click"
                                params:@{@"button_name": @"4"}];
            [self p_trackWithEventName:@"wallet_onesteppswd_setting_agreement_imp"
                                params:@{@"pswd_source": @"支付验证页"}];
        };
    }
    return _protocolView;
}

- (CJPayStyleButton *)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"确认支付")];
        [_confirmButton addTarget:self action:@selector(p_confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UIView *)lineView
{
    if (!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = [UIColor cj_161823WithAlpha:0.12];
        _lineView.hidden = YES;
    }
    return _lineView;
}

- (UILabel *)verifyDescLabel {
    if (!_verifyDescLabel) {
        _verifyDescLabel = [UILabel new];
        _verifyDescLabel.font = [UIFont cj_fontOfSize:13];
        _verifyDescLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _verifyDescLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _verifyDescLabel;
}

@end
