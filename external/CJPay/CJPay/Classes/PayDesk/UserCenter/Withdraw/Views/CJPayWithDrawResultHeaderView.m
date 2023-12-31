//
//  CJWithdrawResultHeaderView.m
//  CJPay
//
//  Created by liyu on 2019/10/8.
//

#import "CJPayWithDrawResultHeaderView.h"

#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayThemeStyleManager.h"
#import "UIView+CJTheme.h"

@interface CJPayWithDrawResultHeaderView ()

@property (nonatomic, strong) UIImageView *stateImageView;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UILabel *amountValueLabel;
@property (nonatomic, strong) UILabel *amountTitleLabel;
@property (nonatomic, strong) UILabel *reasonLabel;
@property (nonatomic, strong) UILabel *defaultReasonLabel;
@property (nonatomic, strong) UIImageView *disclosureIcon;
@property (nonatomic, strong) NSString *errorMsg;

@end

@implementation CJPayWithDrawResultHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - Private

- (void)p_setupUI {
    [self addSubview:self.stateImageView];
    [self addSubview:self.stateLabel];
    [self addSubview:self.amountValueLabel];
    [self addSubview:self.amountTitleLabel];
    [self addSubview:self.reasonLabel];
    [self addSubview:self.defaultReasonLabel];
    [self addSubview:self.disclosureIcon];

    CJPayMasMaker(self.stateImageView, {
        make.top.equalTo(self).offset(20);
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(40);
    });
    
    CJPayMasMaker(self.stateLabel, {
        make.left.equalTo(self).offset(15);
        make.right.equalTo(self).offset(-15);
        make.top.equalTo(self.stateImageView.mas_bottom).offset(13);
    });
    
    CJPayMasMaker(self.reasonLabel, {
        make.left.equalTo(self).offset(44);
        make.right.equalTo(self).offset(-44);
        make.top.equalTo(self.stateLabel.mas_bottom).offset(12);
    });
    
    CJPayMasMaker(self.defaultReasonLabel, {
        make.centerX.equalTo(self);
        make.width.lessThanOrEqualTo(self).offset(-20);
        make.top.equalTo(self.stateLabel.mas_bottom).offset(12);
    });
    
    CJPayMasMaker(self.disclosureIcon, {
        make.left.equalTo(self.defaultReasonLabel.mas_right);
        make.width.height.mas_equalTo(20);
        make.centerY.equalTo(self.defaultReasonLabel);
    });
    
    CJPayMasMaker(self.amountValueLabel, {
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(42));
        make.top.mas_equalTo(self.stateLabel.mas_bottom).offset(24);
        make.centerX.equalTo(self);
    });
    
    CJPayMasMaker(self.amountTitleLabel, {
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(28));
        make.width.mas_equalTo(CJ_SIZE_FONT_SAFE(28));
        make.bottom.equalTo(self.amountValueLabel).offset(-2);
        make.right.equalTo(self.amountValueLabel.mas_left).offset(-4);
    });
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        [self p_adapterTheme];
    }
}

- (void)p_adapterTheme {
    CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
    
    self.stateLabel.textColor = localTheme.withdrawTitleTextColor;
    self.amountTitleLabel.textColor = localTheme.withdrawAmountTextColor;
    self.amountValueLabel.textColor = localTheme.withdrawAmountTextColor;
    switch (self.style) {
        case kCJWithdrawResultHeaderViewFailed: {
            [self.stateLabel setText:CJPayLocalizedStr(@"提现失败")];
            self.stateLabel.font = [UIFont cj_boldFontOfSize:20];
            self.reasonLabel.hidden = NO;
            self.amountTitleLabel.hidden = self.amountValueLabel.hidden = YES;
            [self.stateImageView cj_setImage:localTheme.resultFailIconName];
            if (self.errorMsg) {
                self.defaultReasonLabel.hidden = YES;
                self.disclosureIcon.hidden = YES;
                self.reasonLabel.hidden = NO;
            } else {
                self.defaultReasonLabel.hidden = NO;
                self.disclosureIcon.hidden = NO;
                self.reasonLabel.hidden = YES;
            }
            break;
        }
        case kCJWithdrawResultHeaderViewSuccess: {
            [self.stateLabel setText:CJPayLocalizedStr(@"提现成功")];
            self.stateLabel.font = [UIFont cj_fontOfSize:16];
            [self.stateImageView cj_setImage:localTheme.resultSuccessIconName];
            self.disclosureIcon.hidden = YES;
            break;
        }
        case kCJWithdrawResultHeaderViewProcessing: {
            [self.stateLabel setText:CJPayLocalizedStr(@"处理中，预计2小时到账")];
            self.stateLabel.font = [UIFont cj_fontOfSize:16];
            [self.stateImageView cj_setImage:localTheme.resultProcessIconName];
            self.disclosureIcon.hidden = YES;
            break;
        }
      }
}

#pragma mark - Views

- (UILabel *)amountValueLabel {
    if (!_amountValueLabel) {
        _amountValueLabel = [[UILabel alloc] init];
        _amountValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _amountValueLabel.textAlignment = NSTextAlignmentCenter;
        _amountValueLabel.font = [UIFont cj_denoiseBoldFontOfSize:40];
    }
    return _amountValueLabel;
}

- (UILabel *)amountTitleLabel {
    if (!_amountTitleLabel) {
        _amountTitleLabel = [[UILabel alloc] init];
        _amountTitleLabel.font = [UIFont cj_boldFontOfSize:28];
        _amountTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _amountTitleLabel.textAlignment = NSTextAlignmentCenter;
        _amountTitleLabel.text = @"¥";
    }
    return _amountTitleLabel;
}

- (UIImageView *)stateImageView {
    if (!_stateImageView) {
        _stateImageView = [UIImageView new];
    }
    return _stateImageView;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [UILabel new];
        _stateLabel.textAlignment = NSTextAlignmentCenter;
        _stateLabel.font = [UIFont cj_fontOfSize:16];
    }
    return _stateLabel;
}

- (UILabel *)reasonLabel {
    if (!_reasonLabel) {
        _reasonLabel = [UILabel new];
        _reasonLabel.font = [UIFont cj_fontOfSize:14];
        [_reasonLabel setTextColor:[UIColor cj_fe3824ff]];
        _reasonLabel.hidden = YES;
        _reasonLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _reasonLabel.textAlignment = NSTextAlignmentCenter;
        _reasonLabel.numberOfLines = 2;
    }
    return _reasonLabel;
}

- (UILabel *)defaultReasonLabel {
    if (!_defaultReasonLabel) {
        _defaultReasonLabel = [UILabel new];
        _defaultReasonLabel.font = [UIFont cj_fontOfSize:14];
        [_defaultReasonLabel setTextColor:[UIColor cj_fe3824ff]];
        _defaultReasonLabel.hidden = YES;
        _defaultReasonLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _defaultReasonLabel.textAlignment = NSTextAlignmentCenter;
        _defaultReasonLabel.numberOfLines = 0;
        if (CJ_SCREEN_WIDTH <= 320) {
            _defaultReasonLabel.font = [UIFont cj_fontOfSize:11];
        }
        [self addDisclosureEventToView:_defaultReasonLabel];
        _defaultReasonLabel.text = CJPayLocalizedStr(@"提现失败，查看原因");
    }
    return _defaultReasonLabel;
}

- (UIImageView *)disclosureIcon {
    if (!_disclosureIcon) {
        _disclosureIcon = [UIImageView new];
        [_disclosureIcon cj_setImage:@"cj_disclosure_icon"];
        _disclosureIcon.translatesAutoresizingMaskIntoConstraints = NO;
        _disclosureIcon.hidden = YES;
        [self addDisclosureEventToView:_disclosureIcon];
    }
    return _disclosureIcon;
}

- (void)addDisclosureEventToView:(UIView *)targetView {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disclosureReasonEvent:)];
    targetView.userInteractionEnabled = YES;
    [targetView addGestureRecognizer:tap];
}

#pragma mark - Events

- (void)disclosureReasonEvent:(id)sender {
    if (self.style == kCJWithdrawResultHeaderViewFailed) {
        CJ_CALL_BLOCK(self.didTapReasonBlock);
    }
}

#pragma mark - Update

- (void)setStyle:(CJWithdrawResultHeaderViewStyle)style {
    _style = style;
    
    [self p_adapterTheme];
}

- (void)updateWithAmountText:(NSString *)amountText {
    self.amountValueLabel.text = amountText;
}

- (void)updateWithErrorMsg:(NSString *)errorMsg {
    self.errorMsg = errorMsg;
    self.reasonLabel.text = errorMsg;
}

@end
