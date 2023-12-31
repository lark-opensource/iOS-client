//
//  CJPayOpenBioGuideView.m
//  CJPay
//
//  Created by 王新华 on 2019/3/31.
//

#import "CJPayOpenBioGuideView.h"
#import "CJPayUIMacro.h"
#import "CJPayCurrentTheme.h"
#import "CJPayStyleButton.h"
#import "CJPayTouchIdManager.h"
#import "CJPayStyleImageView.h"
#import "CJPayBioGuideTipsItemView.h"
#import "CJPayAccountInsuranceTipView.h"

@interface CJPayOpenBioGuideView()

@property (nonatomic, strong) UIImageView *bioImgView;
@property (nonatomic, strong) UIView *bioImgBackgroundView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) CJPayStyleButton *openBiopaymentBtn;
@property(nonatomic, strong) UIButton *ignoreBtn;
@property(nonatomic, strong) CJPayBioPaymentInfo *biopaymentInfo;
@property (nonatomic, strong) UIStackView *tipsStackView;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;

@end

@implementation CJPayOpenBioGuideView

- (instancetype)initWithBioInfo:(CJPayBioPaymentInfo *)biopaymentInfo {
    if (self = [super init]) {
        self.biopaymentInfo = biopaymentInfo;
        [self p_setupUIForNewStyle];
    }
    return self;
}

- (void)setBtnTitle:(NSString *)title {
    [self.openBiopaymentBtn setTitle:CJString(title) forState:UIControlStateNormal];
}

- (void)startBtnLoading {
    @CJStartLoading(self.openBiopaymentBtn)
}
- (void)stopBtnLoading {
    @CJStopLoading(self.openBiopaymentBtn)
}

#pragma mark - Private Method

- (void)p_setupUIForNewStyle {
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont cj_boldFontOfSize:22];
    self.titleLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.openBiopaymentBtn = [CJPayStyleButton new];
    [self.openBiopaymentBtn setTitle:CJPayLocalizedStr(@"开启面容支付") forState:UIControlStateNormal];
    [self.openBiopaymentBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.openBiopaymentBtn addTarget:self action:@selector(p_tapOpenBio) forControlEvents:UIControlEventTouchUpInside];
    self.openBiopaymentBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
    self.openBiopaymentBtn.layer.cornerRadius = 2;
    
    [self addSubview:self.bioImgView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.tipsStackView];
    [self addSubview:self.openBiopaymentBtn];
    self.backgroundColor = UIColor.whiteColor;
    
    [self p_makeConstraintsForNewStyle];
    [self p_updateContentForNewStyle];
}

- (void)p_makeConstraintsForNewStyle {
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(164);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    });
    
    [self p_addImgBackgroundView];
    
    CJPayMasMaker(self.bioImgView, {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.titleLabel.mas_top).offset(-33);
        make.width.height.mas_equalTo(54);
    });
    
    CJPayMasMaker(self.tipsStackView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.centerX.equalTo(self).priorityMedium();
        make.left.greaterThanOrEqualTo(self).offset(24);
        make.right.lessThanOrEqualTo(self).offset(-24);
        make.bottom.equalTo(self.openBiopaymentBtn.mas_top).mas_lessThanOrEqualTo(-12);
    });
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.centerX.equalTo(self);
            make.height.mas_equalTo(16);
        });
        
        CJPayMasMaker(self.openBiopaymentBtn, {
            make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-16);
            make.left.equalTo(self).offset(16);
            make.right.equalTo(self).offset(-16);
            make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        });
    } else {
        CJPayMasMaker(self.openBiopaymentBtn, {
            make.bottom.equalTo(self).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.left.equalTo(self).offset(16);
            make.right.equalTo(self).offset(-16);
            make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        });
    }
}

- (void)p_tapOpenBio {
    if ([self.delegate respondsToSelector:@selector(openBioPayment)]) {
        [self.delegate openBioPayment];
    }
}

- (void)p_tapIgnore {
    if ([self.delegate respondsToSelector:@selector(giveUpAction)]) {
        [self.delegate giveUpAction];
    }
}

- (void)p_updateContentForNewStyle {
    self.titleLabel.text = self.biopaymentInfo.guideDesc;
    [self.openBiopaymentBtn setTitle:self.biopaymentInfo.openBioDesc forState:UIControlStateNormal];
    [self.tipsStackView cj_removeAllSubViews];
    [self.biopaymentInfo.subGuide enumerateObjectsUsingBlock:^(CJPayBioPaymentSubGuideModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 3) {
            *stop = YES;
            return;
        }
        CJPayBioGuideTipsItemView *itemView = [CJPayBioGuideTipsItemView new];
        [itemView updateItemWithTitle:CJString(obj.iconDesc) url:CJString(obj.iconUrl)];
        [self.tipsStackView addArrangedSubview:itemView];
    }];
}

- (void)p_addImgBackgroundView {
    [self addSubview:self.bioImgBackgroundView];
    CJPayMasMaker(self.bioImgBackgroundView, {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.titleLabel.mas_top).offset(-16);
        make.width.height.mas_equalTo(88);
    });
}

#pragma mark - Getter

- (UIImageView *)bioImgView {
    if (!_bioImgView) {
        _bioImgView = [UIImageView new];
        if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace) {
            @CJWeakify(self)
            [_bioImgView cj_setImage:@"cj_face_icon" completion:^(BOOL isSuccess) {
                @CJStrongify(self)
                if (isSuccess) {
                    self.bioImgBackgroundView.hidden = NO;
                }
            }];
        } else {
            @CJWeakify(self)
            [_bioImgView cj_setImage:@"cj_finger_icon" completion:^(BOOL isSuccess) {
                @CJStrongify(self)
                if (isSuccess) {
                    CJPayStyleImageView *appearance = [CJPayStyleImageView appearance];
                    self.bioImgView.backgroundColor = appearance.backgroundColor ?: [UIColor cj_fe2c55ff];
                    self.bioImgBackgroundView.hidden = NO;
                }
            }];
        }
    }
    return _bioImgView;
}

- (UIView *)bioImgBackgroundView {
    if (!_bioImgBackgroundView) {
        _bioImgBackgroundView = [UIView new];
        _bioImgBackgroundView.backgroundColor = [UIColor cj_161823WithAlpha:0.03];
        _bioImgBackgroundView.layer.cornerRadius = 44;
        _bioImgBackgroundView.hidden = YES;
    }
    return _bioImgBackgroundView;
}

- (UIStackView *)tipsStackView
{
    if (!_tipsStackView) {
        _tipsStackView = [[UIStackView alloc] init];
        _tipsStackView.axis = UILayoutConstraintAxisVertical;
        _tipsStackView.distribution = UIStackViewDistributionFillProportionally;
        _tipsStackView.spacing = 4;
    }
    return _tipsStackView;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

@end
