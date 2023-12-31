//
//  CJPayBizResultPageView.m
//  CJPaySandBox
//
//  Created by 高航 on 2022/11/25.
//

#import "CJPayFullResultPageView.h"
#import "CJPayUIMacro.h"
#import "CJPayResultPageModel.h"
#import "CJPayResultDetailItemView.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayLynxInfoView.h"
#import "UIView+CJPay.h"
#import "CJPayButton.h"
#import "CJPayFullResultCardView.h"

@interface CJPayFullResultPageView()<UIScrollViewDelegate,CJPayLynxViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIImageView *payLogo;
@property (nonatomic, strong) UILabel *payStateLabel;//支付状态，目前仅在成功状态下展现
@property (nonatomic, strong) UIView *amountView;//支付金额
@property (nonatomic, strong) UILabel *voucherLabel;
@property (nonatomic, strong) UIStackView *payInfoStackView;
@property (nonatomic, strong) CJPayButton *bottomButton;
@property (nonatomic, strong) CJPayButton *topRightButton;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) UIView *naviView;

@property (nonatomic, assign) BOOL isShowAllInfo;
@property (nonatomic, copy) NSString *orderType;//other | bytepay区分抖音支付还是at

@property (nonatomic, strong) CJPayResultPageModel *model;
@property (nonatomic, strong) CJPayResultPageInfoModel *pageinfoModel;
@property (nonatomic, copy) NSDictionary *orderResponse;

@property (nonatomic, strong) NSMutableArray<CJPayFullResultCardView *> *lynxCard;
@property (nonatomic, strong) CJPayLynxInfoView *lynxInfoView;

@end


@implementation CJPayFullResultPageView

- (instancetype)initWithCJOrderModel:(CJPayResultPageModel *)model {
    self = [super init];
    if (self) {
        _model = model;
        _pageinfoModel = model.resultPageInfo;
        _lynxCard = [NSMutableArray new];
//        _orderType = model.tradeInfo.ptCode;
        _orderType = model.orderType;
        _orderResponse = model.orderResponse ? [model.orderResponse copy] : @{};
        [self p_refresh];
    }
    return self;
}

- (void)loadLynxCard {
    if (Check_ValidArray(self.lynxCard)) {
        [self.lynxCard enumerateObjectsUsingBlock:^(CJPayFullResultCardView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj reload];
        }];
    }
}

#pragma mark private
- (void)p_refresh {
    [self p_setupUI];
    
    [self p_setupBottomButtonUI];
    
    [self p_setAmountTitle];//设置金额label
    
    self.isShowAllInfo = YES;
    if (self.pageinfoModel.moreShowInfo && [self.pageinfoModel.moreShowInfo.showNum isEqualToString:@"1"]) {
        self.isShowAllInfo = NO;
    }
    
    [self p_updatePayInfo];
    
    if ([self.model.resultPageInfo.buttonInfo.type isEqualToString:@"top"]) {
        self.bottomButton.hidden = YES;
        self.topRightButton.hidden = NO;
    }
    
    if (!Check_ValidString(self.orderType) || [self.orderType isEqualToString:@"bytepay"]) {//O项目只有抖音支付不会下发ptcode
        NSURL *bgImgUrl = [NSURL URLWithString:CJString(self.pageinfoModel.assets.bgImage)];
        if (bgImgUrl) {
            [self.bgImageView cj_setImageWithURL:bgImgUrl];
        }
    }
    
    NSString *buttonTitle = CJString(self.model.resultPageInfo.buttonInfo.desc);
    buttonTitle = Check_ValidString(buttonTitle)? buttonTitle : @"完成";
    
    [self.bottomButton cj_setBtnTitle:CJPayLocalizedStr(buttonTitle)];
    [self.topRightButton cj_setBtnTitle:CJPayLocalizedStr(buttonTitle)];
    self.voucherLabel.text = CJString(self.pageinfoModel.voucherOptions.desc);
    self.voucherLabel.hidden = !Check_ValidString(self.pageinfoModel.voucherOptions.desc);
    self.safeGuardTipView.hidden = [self.pageinfoModel.assets.showImage isEqualToString:@"hidden"];
    [self.payLogo cj_setImageWithURL:[NSURL URLWithString:CJString(self.pageinfoModel.assets.tipImage)]];
    [self.payStateLabel setText:@"支付成功"];
}


- (void)p_setupUI {
    
    self.scrollView.delegate = self;
    
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.scrollContentView];
    [self.scrollContentView addSubview:self.bgImageView];
    [self addSubview:self.naviView];
    [self.scrollContentView addSubview:self.payLogo];
    [self.scrollContentView addSubview:self.payStateLabel];
    [self.scrollContentView addSubview:self.amountView];
    [self.scrollContentView addSubview:self.voucherLabel];
    [self.scrollContentView addSubview:self.payInfoStackView];
    [self addSubview:self.bottomButton];
    [self addSubview:self.topRightButton];
    [self addSubview:self.safeGuardTipView];
    
    
    self.topRightButton.hidden = [self.pageinfoModel.buttonInfo.type isEqualToString:@"bottom"];
    self.bottomButton.hidden = !self.topRightButton.hidden;//两个按钮只会存在一个
    self.backgroundColor = [UIColor cj_f8f8f8ff];
    
    CJPayMasMaker(self.scrollView, {
        make.edges.equalTo(self);
    });
    
    CJPayMasMaker(self.scrollContentView, {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self);
        make.height.greaterThanOrEqualTo(self.scrollView);
    });
    
    CJPayMasMaker(self.bgImageView, {
        make.top.left.right.equalTo(self.scrollContentView);
        make.height.equalTo(self.bgImageView.mas_width).multipliedBy(360.0 / 375.0);
    });
    
    CJPayMasMaker(self.naviView, {
        make.height.mas_equalTo(88);
        make.top.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self.payLogo, {
        make.top.equalTo(self.naviView.mas_bottom);
        make.height.width.mas_equalTo(32);
        make.centerX.equalTo(self.scrollContentView);
    });
    
    CJPayMasMaker(self.payStateLabel, {
        make.top.equalTo(self.payLogo.mas_bottom).offset(10);
        make.centerX.equalTo(self.scrollContentView);
    });
    
    CJPayMasMaker(self.amountView, {
        make.top.equalTo(self.payStateLabel.mas_bottom).offset(24);
        make.centerX.equalTo(self.scrollContentView);
    });
    
    CJPayMasMaker(self.voucherLabel, {
        make.top.equalTo(self.amountView.mas_bottom);
        make.centerX.equalTo(self.scrollContentView);
    });
    
    CJPayMasMaker(self.payInfoStackView, {
        make.top.equalTo(self.amountView.mas_bottom).offset(46);
        make.left.right.equalTo(self.scrollContentView);
        make.centerX.equalTo(self.scrollContentView);
    });
    
    CJPayMasMaker(self.bottomButton, {
        make.bottom.equalTo(self).offset(-90);
        make.centerX.equalTo(self.scrollContentView);
        make.width.greaterThanOrEqualTo(@(160));
        make.height.mas_equalTo(42);
    });
    
    CJPayMasMaker(self.topRightButton, {
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(21);
        make.top.equalTo(self).offset(55);
        make.right.equalTo(self).offset(-12);
    });
    
    CJPayMasMaker(self.safeGuardTipView, {
        make.bottom.equalTo(self).offset(-10-CJ_TabBarSafeBottomMargin);
        make.centerX.equalTo(self);
    });

    [self p_buildLynxCardView];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
}

- (void)p_setupBottomButtonUI { //底部按钮吸底样式
    if ([self.pageinfoModel.buttonInfo.type isEqualToString:@"bottom"] && Check_ValidArray(self.lynxCard)) {
        return;
    }
    
    if ([self.pageinfoModel.assets.showImage isEqualToString:@"show"]) {
        CJPayMasUpdate(self.bottomButton, {
            make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-16);
        });
    } else {
        CJPayMasUpdate(self.bottomButton, {
            make.bottom.equalTo(self.mas_bottom).offset(-16-CJ_TabBarSafeBottomMargin);
        });
    }
    
    CJPayMasReMaker(self.scrollView, {
        make.top.left.right.equalTo(self);
        make.bottom.equalTo(self.bottomButton.mas_top).offset(-16);
    });
    
}

- (void)p_updatePayInfo {
    //业务进度文案
    [self.payInfoStackView cj_removeAllSubViews];
    
    NSArray<CJPayResultDetailItemView *> *itemViewList = [self p_buildInfoItemView];
    if (!self.isShowAllInfo) {
        self.isShowAllInfo = YES;
        [self.payInfoStackView addArrangedSubview:itemViewList.firstObject];
        if (itemViewList.count < 2) {//1个就没必要折叠了
            return;
        }
        CJPayPayInfoDesc *moreDesc = self.pageinfoModel.moreShowInfo;
        CJPayResultDetailItemView *moreDescItem = [CJPayResultDetailItemView new];
        moreDescItem.needScaleFont = NO;
        [moreDescItem updateFoldViewWithTitle:moreDesc.name detail:moreDesc.desc];
        [moreDescItem addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_updatePayInfo)]];//点击展开
        [self.payInfoStackView addArrangedSubview:moreDescItem];
    } else {
        [itemViewList enumerateObjectsUsingBlock:^(CJPayResultDetailItemView *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.payInfoStackView addArrangedSubview:obj];
        }];
    }
}


- (NSArray<CJPayResultDetailItemView *> *)p_buildInfoItemView {
    NSMutableArray<CJPayResultDetailItemView *> *itemViewList = [NSMutableArray new];
    [self.pageinfoModel.showInfos enumerateObjectsUsingBlock:^(CJPayPayInfoDesc * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayResultDetailItemView *itemView = [self p_getItemViewWithPayInfo:obj];
        [itemViewList btd_addObject:itemView];
    }];
    return itemViewList;
}

- (CJPayResultDetailItemView *)p_getItemViewWithPayInfo:(CJPayPayInfoDesc *)payInfo {
    CJPayResultDetailItemView *itemView = [CJPayResultDetailItemView new];
    itemView.needScaleFont = NO;
    [itemView updateWithTitle:payInfo.name detail:payInfo.desc iconUrl:payInfo.iconUrl];//只有银行卡方式有icon
    return itemView;
}

- (void)p_setAmountTitle {
    NSString *amountStr = [NSString stringWithFormat:@"%.2f", self.model.amount/(double)100];
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.minimumLineHeight = 40;
        
    NSDictionary *symbolStyle = @{
        NSFontAttributeName:[UIFont cj_denoiseBoldFontWithoutFontScaleOfSize:28],
        NSForegroundColorAttributeName:[UIColor cj_161823ff],
        NSParagraphStyleAttributeName:paragraphStyle
    };
    
    NSMutableAttributedString *symbolAttr = [[NSMutableAttributedString alloc] initWithString:@"¥" attributes:symbolStyle];
        
    NSDictionary *dinStyle = @{
        NSFontAttributeName:[UIFont cj_denoiseBoldFontWithoutFontScaleOfSize:40],
        NSForegroundColorAttributeName:[UIColor cj_161823ff],
        NSParagraphStyleAttributeName:paragraphStyle,
        NSKernAttributeName:@-2
    };
    NSMutableAttributedString *amountAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", amountStr] attributes:dinStyle];
    
    UILabel *symbolLabel = [UILabel new];
    [symbolLabel setAttributedText:symbolAttr];
    
    UILabel *amountLabel = [UILabel new];
    [amountLabel setAttributedText:amountAttr];
    [self.amountView addSubview:symbolLabel];
    [self.amountView addSubview:amountLabel];
    CJPayMasMaker(symbolLabel, {
        make.left.equalTo(self.amountView);
        make.centerY.equalTo(amountLabel).offset(2);
    });
    CJPayMasMaker(amountLabel, {
        make.top.bottom.equalTo(self.amountView);
        make.left.equalTo(symbolLabel.mas_right).offset(2);
        make.right.equalTo(self.amountView);
        make.height.mas_equalTo(52);
    });
    
 }


- (BOOL)p_buildLynxCardView {
    NSArray<CJPayDynamicComponents *> *dynamicInfo = self.pageinfoModel.dynamicComponents;
    if (!Check_ValidArray(dynamicInfo)) {
        return NO;
    }
    [dynamicInfo enumerateObjectsUsingBlock:^(CJPayDynamicComponents * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (Check_ValidString(obj.schema)) {
            CJPayFullResultCardView *lynxItem = [self p_createLynxCardItem:obj];
            [self.lynxCard btd_addObject:lynxItem];
        }
    }];
    
    if (self.lynxCard.count > 0) {
        self.lynxInfoView = [[CJPayLynxInfoView alloc] initWithLynxItem:self.lynxCard];
        [self.scrollContentView addSubview:self.lynxInfoView];

        CJPayMasMaker(self.lynxInfoView, {
            make.top.equalTo(self.payInfoStackView.mas_bottom).offset(28);
            make.left.right.equalTo(self.scrollContentView);
            make.bottom.lessThanOrEqualTo(self.scrollContentView.mas_bottom).offset(-12);
        });
                
        return YES;
    }
    
    return NO;
}
- (UIView *)p_createLynxCardItem:(CJPayDynamicComponents *)componentsInfo {
    
    NSString *responseJsonString = [[self.orderResponse cj_dictionaryValueForKey:@"data"] btd_jsonStringEncoded];
    NSDictionary *params = @{@"cj_sdk_version" : CJString([CJSDKParamConfig defaultConfig].settingsVersion),
                                 @"cj_version" : @"1",
                                    @"cj_data" : CJString(responseJsonString)};
    
    CGRect frame = CGRectMake(0, 0, CJ_SCREEN_WIDTH, 200);
    CJPayFullResultCardView *lynxCard = [[CJPayFullResultCardView alloc] initWithFrame:frame scheme:componentsInfo.schema initDataStr:CJString(responseJsonString)];
    lynxCard.delegate = self;
    return lynxCard;
}

- (void)p_completeButtonClick {
    [self p_buttonClickEvent];
    CJ_CALL_BLOCK(self.completion);
}

- (void)p_buttonClickEvent {
    CJPayResultPageInfoModel *pageInfo = self.model.resultPageInfo;
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params cj_setObject:CJString(pageInfo.voucherOptions.desc) forKey:@"voucher_options"];
    [params cj_setObject:CJString(pageInfo.buttonInfo.desc) forKey:@"button_name"];
    [params addEntriesFromDictionary:self.trackerParams];
    NSMutableDictionary *buttonExtra = [NSMutableDictionary new];
    [buttonExtra cj_setObject:CJString([pageInfo.buttonInfo toJSONString]) forKey:@"button_info"];
    [buttonExtra cj_setObject:@"0" forKey:@"components_action"];
    [self.lynxCard enumerateObjectsUsingBlock:^(CJPayFullResultCardView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.isLynxViewButtonClickStr isEqualToString:@"1"]) {
            [buttonExtra cj_setObject:@"1" forKey:@"components_action"];
        }
    }];
    [buttonExtra cj_setObject:CJString(self.model.openUrl) forKey:@"url"];
    [params cj_setObject:[buttonExtra cj_toStr] forKey:@"button_extra"];
    [params cj_setObject:@"native支付结果页" forKey:@"project"];
    [CJTracker event:@"wallet_cashier_result_page_action" params:params];
}

#pragma mark CJPayLynxViewDelegate

- (void)lynxView:(UIView *)lynxView receiveEvent:(NSString *)event withData:(NSDictionary *)data {
    if (![lynxView isKindOfClass:CJPayFullResultCardView.class]) {
        return;
    }
    CJPayFullResultCardView *cardView = (CJPayFullResultCardView *)lynxView;
    if ([event isEqualToString:@"cj_component_action"]) {
        cardView.isLynxViewButtonClickStr = @"1";
    }
    
    if ([event isEqualToString:@"cj_set_component_height"]) {
        CGFloat height = [[data cj_stringValueForKey:@"height"] floatValue];
        CGSize size = CGSizeMake(0, height);
        [cardView resetLynxCardSize:size];
    }
}


#pragma mark delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = self.scrollView.contentOffset.y;
    CGFloat maxOffset = self.scrollContentView.cj_height - self.scrollView.cj_height + 1.0;
    maxOffset = (maxOffset > 20.0 ? 20.0 : maxOffset);
    self.naviView.backgroundColor =  [UIColor cj_colorWithHexString:@"#dfe6f7" alpha:offsetY/maxOffset];
}

#pragma mark lazy init
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.clipsToBounds = YES;
        _scrollView.bounces = NO;
        if (@available(iOS 11.0, *)) {
            [_scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _scrollView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [[UIView alloc] init];
    }
    return _scrollContentView;
}

- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [UIImageView new];
    }
    return _bgImageView;
}

- (UIImageView *)payLogo {
    if (!_payLogo) {
        _payLogo = [UIImageView new];
    }
    return _payLogo;
}

- (UILabel *)payStateLabel {
    if (!_payStateLabel) {
        _payStateLabel = [UILabel new];
        _payStateLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:16];
        _payStateLabel.textColor = [UIColor cj_161823ff];
    }
    return _payStateLabel;
}

- (UIView *)amountView {
    if (!_amountView) {
        _amountView = [UIView new];
    }
    return _amountView;
}

- (UILabel *)voucherLabel {
    if (!_voucherLabel) {
        _voucherLabel = [UILabel new];
        _voucherLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _voucherLabel.textColor = [UIColor cj_ff6e26ff];
    }
    return _voucherLabel;
}

- (UIStackView *)payInfoStackView {
    if (!_payInfoStackView) {
        _payInfoStackView = [UIStackView new];
        _payInfoStackView.axis = UILayoutConstraintAxisVertical;
        _payInfoStackView.distribution = UIStackViewDistributionFillProportionally;
        _payInfoStackView.spacing = 12;
    }
    return _payInfoStackView;
}

- (CJPayButton *)bottomButton {
    if(!_bottomButton) {
        _bottomButton = [CJPayButton new];
        [_bottomButton cj_setBtnBGColor:[UIColor cj_161823WithAlpha:0.05]];
        [_bottomButton cj_setBtnTitleColor:[UIColor cj_161823ff]];
        _bottomButton.titleLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:15];
        _bottomButton.layer.cornerRadius = 4;
        _bottomButton.clipsToBounds = YES;
        [_bottomButton addTarget:self action:@selector(p_completeButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _bottomButton.hidden = NO;
    }
    return _bottomButton;
}

- (CJPayButton *)topRightButton {
    if(!_topRightButton) {
        _topRightButton = [CJPayButton new];
        [_topRightButton cj_setBtnBGColor:[UIColor clearColor]];
        [_topRightButton cj_setBtnTitleColor:[UIColor cj_161823ff]];
        _topRightButton.titleLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:15];
        [_topRightButton addTarget:self action:@selector(p_completeButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _topRightButton.disableHightlightState = YES;
        _topRightButton.hidden = YES;
    }
    return _topRightButton;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

- (UIView *)naviView {
    if(!_naviView) {
        _naviView = [UIView new];
        _naviView.backgroundColor = [UIColor cj_colorWithHexString:@"#dfe6f7" alpha:0];
    }
    return _naviView;
}

@end
