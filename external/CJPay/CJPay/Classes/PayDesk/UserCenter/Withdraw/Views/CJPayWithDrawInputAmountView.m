//
//  CJPayWithDrawInputAmountView.m
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import "CJPayWithDrawInputAmountView.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayThemeStyleManager.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayLocalThemeStyle.h"
#import "CJPayButton.h"
#import "UIView+CJTheme.h"
#import "CJPayUserCenter.h"

@interface CJPayWithDrawInputAmountView()<CJPayAmountTextFieldContainerDelegate>

@property (nonatomic, strong) CJPayAmountTextFieldContainer *withDrawAmountField;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UILabel *limitLabel;
@property (nonatomic, strong) CJPayButton *totalWithDrawBtn;
@property (nonatomic, strong) UIView *bottomLineView;
@property (nonatomic, strong) UIView *topLineView;

@property (nonatomic, assign) BOOL isShowLimitText; //当前是否超出限额

@property (nonatomic, strong) MASConstraint *withdrawAllButtonLeftConstraint;
@property (nonatomic, strong) MASConstraint *withdrawAllButtonRightConstraint;

@end

@implementation CJPayWithDrawInputAmountView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}
#pragma mark: get method

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_fontOfSize:15];
        _subTitleLabel.textColor = [UIColor cj_161823ff];
        _subTitleLabel.text = CJPayLocalizedStr(@"提现金额");
    }
    return _subTitleLabel;
}

- (UILabel *)limitLabel {
    if (!_limitLabel) {
        _limitLabel = [UILabel new];
        _limitLabel.font = [UIFont cj_fontOfSize:13];
    }
    return _limitLabel;
}

- (CJPayButton *)totalWithDrawBtn{
    if (!_totalWithDrawBtn) {
        _totalWithDrawBtn = [CJPayButton new];
        [_totalWithDrawBtn cj_setBtnTitle:CJPayLocalizedStr(@"全部提现")];
        [_totalWithDrawBtn setBackgroundColor:[UIColor clearColor]];
        [_totalWithDrawBtn.titleLabel setFont:[UIFont cj_fontOfSize:13]];
        [_totalWithDrawBtn addTarget:self action:@selector(totalWithDrawClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _totalWithDrawBtn;
}

- (CJPayAmountTextFieldContainer *)withDrawAmountField {
    if (!_withDrawAmountField) {
        _withDrawAmountField = [[CJPayAmountTextFieldContainer alloc] init];
        [_withDrawAmountField setTextFieldPlaceHolderWith:CJPayLocalizedStr(@"请输入提现金额")];
        _withDrawAmountField.delegate = self;
    }
    return _withDrawAmountField;
}

#pragma mark: setupView
- (void)setupView {
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.withDrawAmountField];
    [self addSubview:self.limitLabel];
    [self addSubview:self.totalWithDrawBtn];
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self).offset(14);
        make.left.equalTo(self).offset(16);
        make.height.mas_equalTo(21);
    });
    
    CJPayMasMaker(self.withDrawAmountField, {
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(36);
        make.left.equalTo(self.subTitleLabel);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(47);
    });
    
    self.bottomLineView = [CJPayLineUtil addBottomLineToView:self.withDrawAmountField marginLeft:0 marginRight:0 marginBottom:-18 color:[self cj_getLocalTheme].withdrawSegmentBackgroundColor];

    CJPayMasMaker(self.limitLabel, {
        make.left.equalTo(self.subTitleLabel);
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(14));
        make.top.equalTo(self.bottomLineView.mas_bottom).offset(13);
    });

    CJPayMasMaker(self.totalWithDrawBtn, {
        self.withdrawAllButtonLeftConstraint = make.left.equalTo(self.limitLabel.mas_right).offset(10);
        self.withdrawAllButtonRightConstraint = make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self.limitLabel);
        make.bottom.equalTo(self).offset(-12);
    });
    
    [self.withdrawAllButtonRightConstraint deactivate];

    self.totalWithDrawBtn.hidden = YES;
    [self p_adapterTheme];
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        [self.totalWithDrawBtn cj_setBtnTitleColor:localTheme.withDrawAllbtnTextColor];
        
        self.subTitleLabel.textColor = localTheme.withdrawTitleTextColor;
        [self showLimitLabel:self.isShowLimitText];
        [self.bottomLineView setBackgroundColor:[self cj_getLocalTheme].withdrawSegmentBackgroundColor];
    }
}

-(void)p_adapterTheme {
    CJPayLocalThemeStyle *defaultTheme = [CJPayLocalThemeStyle defaultThemeStyle];
    [self.totalWithDrawBtn cj_setBtnTitleColor:defaultTheme.withDrawAllbtnTextColor];

    self.subTitleLabel.textColor = defaultTheme.withdrawTitleTextColor;
    self.limitLabel.textColor = defaultTheme.withdrawLimitTextColor;
}

- (void)totalWithDrawClick {
    NSString *amountText = [NSString stringWithFormat:@"%.2f",(double)([self.userInfo.balanceAmount doubleValue]/100)];
    self.withDrawAmountField.textField.text = amountText;
    self.withDrawAmountField.customClearView.hidden = NO;
    self.withDrawAmountField.placeHolderLabel.hidden = Check_ValidString(amountText);
    [self p_updateFrame];
    CJ_CALL_BLOCK(self.amountDidChangeBlock);
    CJ_CALL_BLOCK(self.amountWithdrawAllBlock);
}

- (void)p_updateFrame {
    self.limitLabel.text = [self getLimitLabelText];
    [self showLimitLabel:NO];
}

- (void)renderBalanceWithUserInfo:(CJPayUserInfo *)userInfo {
    self.userInfo = userInfo;
    self.limitLabel.text = [self getLimitLabelText];
    [self showTotalWithDrawBtn];
}

- (void)showLimitLabel:(BOOL)isShow {
    self.isShowLimitText = isShow;
    [self showTotalWithDrawBtn];
    CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
    
    if (isShow) {
        self.limitLabel.text = CJPayLocalizedStr(@"输入金额超出可用余额");
        self.limitLabel.textColor = [UIColor cj_fe3824ff];
        
        [self.withdrawAllButtonLeftConstraint deactivate];
        [self.withdrawAllButtonRightConstraint activate];
        
    } else {
        self.limitLabel.text = [self getLimitLabelText];
        self.limitLabel.textColor = localTheme.withdrawLimitTextColorV2;
        
        [self.withdrawAllButtonRightConstraint deactivate];
        [self.withdrawAllButtonLeftConstraint activate];
    }
}

- (void)showTotalWithDrawBtn {
    if ([self.userInfo.balanceAmount doubleValue] == 0) {
        self.totalWithDrawBtn.hidden = YES;
    }else{
        self.totalWithDrawBtn.hidden = NO;
    }
}

- (NSString *)getLimitLabelText {
    NSString *amountText = [CJPayCommonUtil getMoneyFormatStringFromDouble:(double)([self.userInfo.balanceAmount doubleValue]/100) formatString:nil];
    return [NSString stringWithFormat:CJPayLocalizedStr(@"可提现金额 ￥%@"),amountText];
}

- (NSString *)getAmountValue {
    return self.withDrawAmountField.amountText;
}

#pragma mark - CJPayAmountTextFieldContainerDelegate
- (void)textFieldContentChange:(NSString *)curText textContainer:(CJPayAmountTextFieldContainer *)textContainer {
    if (curText.length == 0) {
        [self p_updateFrame];
        textContainer.customClearView.hidden = YES;
    }
    CJ_CALL_BLOCK(self.amountDidChangeBlock);
}

- (void)containerKeyBoardClick {
    [self.withDrawAmountField resignFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.withDrawAmountField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.withDrawAmountField resignFirstResponder];
}

- (void)textFieldTapGestureClick {
    CJ_CALL_BLOCK(self.withdrawTextFieldTapGestureClickBlock);
}

@end
