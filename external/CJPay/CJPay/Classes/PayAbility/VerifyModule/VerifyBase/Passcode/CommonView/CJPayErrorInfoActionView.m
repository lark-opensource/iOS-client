//
//  CJPayCenterErrorView.m
//  Pods
//
//  Created by 孟源 on 2022/1/25.
//

#import "CJPayErrorInfoActionView.h"
#import "CJPayUIMacro.h"

@interface CJPayErrorInfoActionView()

@property (nonatomic, strong) UIImageView *arrowRigntView;
@property (nonatomic, strong) CJPayStyleErrorLabel *errorLabel;
@property (nonatomic, strong) CJPayLoadingButton *verifyItemBtn;

@property (nonatomic, strong) MASConstraint *errorLabelRightConstraint;
@property (nonatomic, strong) MASConstraint *errorBtnRightConstraint;

@property (nonatomic, assign) CJPayErrorInfoStatusType statusType; //errorInfoActionView当前展示状态

@end


@implementation CJPayErrorInfoActionView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
        self.statusType = CJPayErrorInfoStatusTypeHidden;
    }
    return self;
}

- (void)showActionButton:(BOOL)show {
    if (show) {
        [self.errorBtnRightConstraint activate];
        [self.errorLabelRightConstraint deactivate];
        self.verifyItemBtn.hidden = NO;
//        self.arrowRigntView.hidden = NO;
    } else {
        [self.errorBtnRightConstraint deactivate];
        [self.errorLabelRightConstraint activate];
        self.verifyItemBtn.hidden = YES;
//        self.arrowRigntView.hidden = YES;
    }
}

- (void)updateStatusWithType:(CJPayErrorInfoStatusType)status errorText:(NSString *)text {
    
    self.errorLabel.text = CJString(text);
    CJPayErrorInfoStatusType realType = Check_ValidString(text) ? status : CJPayErrorInfoStatusTypeHidden;
    self.statusType = realType;
    
    switch(realType) {
        case CJPayErrorInfoStatusTypeHidden: {
            self.hidden = YES;
            break;
        }
        case CJPayErrorInfoStatusTypePasswordInputTips:
        case CJPayErrorInfoStatusTypeDowngradeTips: {
            self.hidden = NO;
            self.errorLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
            self.errorLabel.font = [UIFont cj_fontOfSize:13];
            self.errorLabel.numberOfLines = 1;
            [self showActionButton:NO];
            break;
        }
        case CJPayErrorInfoStatusTypePasswordErrorTips: {
            self.hidden = NO;
            self.errorLabel.textColor = [UIColor cj_colorWithHexString:@"FE3824"];
            self.errorLabel.font = [UIFont cj_fontOfSize:13];
            self.errorLabel.numberOfLines = 2;
            break;
        }
        default:
            break;
    }
}

// MARK: - private

- (void)p_setupUI {
    [self addSubview:self.errorLabel];
    [self addSubview:self.verifyItemBtn];
    [self addSubview:self.arrowRigntView];
    
    CJPayMasMaker(self.errorLabel, {
        make.left.top.bottom.equalTo(self);
        self.errorLabelRightConstraint = make.right.equalTo(self);
    });
    
    CJPayMasMaker(self.verifyItemBtn, {
        make.left.equalTo(self.errorLabel.mas_right).offset(12);
        make.centerY.equalTo(self.errorLabel);
        self.errorBtnRightConstraint = make.right.equalTo(self);
    })
    
    CJPayMasMaker(self.arrowRigntView, {
        make.left.equalTo(self.verifyItemBtn.mas_right).offset(6);
        make.centerY.equalTo(self.errorLabel);
        make.width.mas_equalTo(6);
        make.width.height.mas_equalTo(10);
//        self.errorBtnRightConstraint = make.right.equalTo(self);
    })
    
    [self showActionButton:NO];
}

// MARK: - lazy view

- (CJPayStyleErrorLabel *)errorLabel {
    if (!_errorLabel) {
        _errorLabel = [[CJPayStyleErrorLabel alloc] init];
        _errorLabel.font = [UIFont cj_fontOfSize:12];
        _errorLabel.numberOfLines = 2;
        _errorLabel.textColor = [UIColor cj_colorWithHexString:@"FE3824"];
        [_errorLabel setContentHuggingPriority:UILayoutPriorityRequired
                                          forAxis:UILayoutConstraintAxisVertical];
        [_errorLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                          forAxis:UILayoutConstraintAxisVertical];
    }
    return _errorLabel;
}

- (CJPayLoadingButton *)verifyItemBtn {
    if (!_verifyItemBtn) {
        _verifyItemBtn = [[CJPayLoadingButton alloc] init];
        _verifyItemBtn.titleLabel.font = [UIFont cj_fontOfSize:13];
        [_verifyItemBtn setTitleColor:[UIColor cj_04498dff] forState:UIControlStateNormal];
        [_verifyItemBtn cj_setBtnSelectColor:[UIColor cj_forgetPWDSelectColor]];
    }
    return _verifyItemBtn;
}

- (UIImageView *)arrowRigntView {
    if (!_arrowRigntView) {
        _arrowRigntView = [UIImageView new];
        [_arrowRigntView cj_setImage:@"cj_allow_right_denoise_icon"];
        _arrowRigntView.hidden = YES;
    }
    return _arrowRigntView;
}

@end
