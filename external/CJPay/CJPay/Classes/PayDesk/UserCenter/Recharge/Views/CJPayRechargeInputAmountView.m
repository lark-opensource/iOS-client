//
//  BDPayRechargeInputAmountView.m
//  CJPay
//
//  Created by 王新华 on 3/10/20.
//

#import "CJPayRechargeInputAmountView.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayStyleErrorLabel.h"
#import "UIView+CJTheme.h"

@interface CJPayRechargeInputAmountView()<CJPayAmountTextFieldContainerDelegate>

@property (nonatomic, strong) CJPayAmountTextFieldContainer *amountField;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayStyleErrorLabel *limitLabel;
@property (nonatomic, strong) UIView *bottomLineView;
@property (nonatomic, strong) UIView *keyboardContainerView;
@property (nonatomic, assign) BOOL textfieldEnable;
@property (nonatomic, strong) MASConstraint *bottomBaseLimitLabelConstraint;
@property (nonatomic, strong) MASConstraint *bottomBaseAmountFieldConstraint;

@end

@implementation CJPayRechargeInputAmountView

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
        _subTitleLabel.text = CJPayLocalizedStr(@"充值金额");
    }
    return _subTitleLabel;
}

- (CJPayStyleErrorLabel *)limitLabel {
    if (!_limitLabel) {
        _limitLabel = [CJPayStyleErrorLabel new];
        _limitLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _limitLabel;
}

- (CJPayAmountTextFieldContainer *)amountField {
    if (!_amountField) {
        _amountField = [[CJPayAmountTextFieldContainer alloc] init];
        [_amountField setTextFieldPlaceHolderWith:CJPayLocalizedStr(@"请输入充值金额")];
        _amountField.delegate = self;
    }
    return _amountField;
}


#pragma mark: setupView
- (void)setupView {
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.amountField];
    [self addSubview:self.limitLabel];
    
    self.amountField.backgroundColor = [UIColor clearColor];
        
    CJPayMasMaker(self.subTitleLabel, {
        make.left.top.equalTo(self).offset(16);
    });
    CJPayMasMaker(self.amountField, {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(36);
        make.right.equalTo(self).offset(-15);
        make.height.mas_equalTo(47);
        self.bottomBaseAmountFieldConstraint = make.bottom.equalTo(self).offset(-12);
    });
    
    self.bottomLineView = [CJPayLineUtil addBottomLineToView:self.amountField marginLeft:0 marginRight:0 marginBottom:-16
                                                       color:[self cj_getLocalTheme].payRechargeMainViewShadowsColorV2];
    self.bottomLineView.hidden = YES;
    
    CJPayMasMaker(self.limitLabel, {
        make.left.equalTo(self.subTitleLabel);
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self.bottomLineView).offset(14);
        self.bottomBaseLimitLabelConstraint = make.bottom.equalTo(self).offset(-9);
    });
    
    [self p_adapterTheme];
    [self.bottomBaseAmountFieldConstraint activate];
    self.textfieldEnable = YES;
}

-(void)p_adapterTheme {
    CJPayLocalThemeStyle *localTheme = [CJPayLocalThemeStyle defaultThemeStyle];
    self.subTitleLabel.textColor = localTheme.payRechargeViewTextColor;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.subTitleLabel.textColor = localTheme.payRechargeViewTextColor;
        [self.bottomLineView setBackgroundColor:localTheme.payRechargeMainViewShadowsColorV2];
    }
}

- (void)showLimitLabel:(BOOL)isShow {
    if (isShow) {
        self.limitLabel.text = @"超过该卡单笔支付限额";
        self.limitLabel.textColor = [UIColor cj_fe3824ff];
        self.limitLabel.hidden = NO;
        self.bottomLineView.hidden = NO;
        [self.bottomBaseAmountFieldConstraint deactivate];
        [self.bottomBaseLimitLabelConstraint activate];
    } else {
        self.limitLabel.hidden = YES;
        self.bottomLineView.hidden = YES;
    }
}

- (NSString *)getAmountValue {
    return self.amountField.amountText;
}

- (void)setEnabled:(BOOL)enable {
    self.textfieldEnable = enable;
}

#pragma mark:CJPayAmountTextFieldContainerDelegate
- (BOOL)textFieldShouldBeginEditing:(CJPayAmountTextFieldContainer *)textContainer {
    if (textContainer == self.amountField) {
        return self.textfieldEnable;
    }
    return YES;
}

- (void)textFieldContentChange:(NSString *)curText textContainer:(CJPayAmountTextFieldContainer *)textContainer {
    if (curText.length == 0) {
        textContainer.customClearView.hidden = YES;
    }
    CJ_CALL_BLOCK(self.amountDidChangeBlock);
}

- (void)textFieldTapGestureClick {
    CJ_CALL_BLOCK(self.rechargeTextFieldTapGestureClickBlock);
}

- (void)containerKeyBoardClick {
    [self.amountField resignFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.amountField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.amountField resignFirstResponder];
}

@end
