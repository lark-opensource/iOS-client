//
//  CJPayAmountTextFieldContainer.m
//  CJPay
//
//  Created by 尚怀军 on 2020/3/10.
//

#import "CJPayAmountTextFieldContainer.h"
#import "CJPayUIMacro.h"
#import "CJPayAmountTextField.h"
#import "CJPayStyleButton.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "UIView+CJTheme.h"
#import "CJPayDouyinKeyboard.h"
#import "CJPayCustomKeyboardTopView.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPaySettingsManager.h"

@interface CJPayAmountTextFieldContainer()<UITextFieldDelegate>

@property (nonatomic, strong) UILabel *moneyIconLabel;
@property (nonatomic, strong) UIView *boardContainerView;
@property (nonatomic, strong) UIView *boardAccessoryView;
@property (nonatomic, strong) CJPayCustomKeyboardTopView *boardAccessoryTopView;
@property (nonatomic, copy) NSString *titleContent;
@property (nonatomic, strong) CJPayDouyinKeyboard *safeKeyBoard;

@end

@implementation CJPayAmountTextFieldContainer

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_installDefaultAppearance];
        [self p_setupUI];
    }
    return self;
}

- (void)setCursorColor:(UIColor *)cursorColor {
    if (cursorColor == nil) {
        return;
    }
    _cursorColor = cursorColor;
    self.textField.tintColor = cursorColor;
}

- (void)p_setupUI {
    [self addSubview:self.moneyIconLabel];
    [self addSubview:self.textField];
    [self addSubview:self.placeHolderLabel];
             
    self.textField.rightView = self.customClearView;
    self.textField.rightViewMode = UITextFieldViewModeWhileEditing;
    self.textField.keyboardType = UIKeyboardTypeDecimalPad;
    self.textField.inputView = self.boardContainerView;

    if ([CJPayAccountInsuranceTipView shouldShow]) {
        self.textField.inputAccessoryView = self.boardAccessoryView;
    }
    [self p_setupKeyBoard];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self.textField action:@selector(tapClick)];
    [self.textField addGestureRecognizer:tapGesture];
    
    CJPayMasMaker(self.moneyIconLabel, {
        make.left.equalTo(self);
        make.bottom.equalTo(self).offset(-4);
        make.width.mas_equalTo(CJ_SIZE_FONT_SAFE(20));
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(28));
    });
    [self.moneyIconLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    
    CJPayMasMaker(self.textField, {
        make.top.equalTo(self);
        make.left.equalTo(self.moneyIconLabel.mas_right).offset(8);
        make.right.equalTo(self);
        make.height.equalTo(self);
    });
    
    CJPayMasMaker(self.placeHolderLabel, {
        make.centerY.equalTo(self.moneyIconLabel);
        make.left.equalTo(self.textField);
        make.right.equalTo(self.textField);
        make.height.mas_equalTo(21);
    });
    
    CJPayMasMaker(self.safeKeyBoard, {
        make.left.right.top.height.equalTo(self.boardContainerView);
    });
    
    [self p_adapterTheme];
}

-(void)p_adapterTheme {
    self.textField.textColor = [CJPayLocalThemeStyle defaultThemeStyle].payRechargeViewTextColor;
    self.moneyIconLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].payRechargeViewTextColor;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        
        self.textField.textColor = localTheme.payRechargeViewTextColor;
        self.moneyIconLabel.textColor = localTheme.payRechargeViewTextColor;
        self.placeHolderLabel.textColor = localTheme.textFieldPlaceHolderColor;
        [self.customClearView setRightButtonImageWithName:localTheme.inputClearImageStr];
        
        self.boardContainerView.backgroundColor = localTheme.amountKeyboardBgColor;
        self.boardAccessoryView.backgroundColor = localTheme.amountKeyboardBgColor;
        
        CJPayABSettingsModel *model = [CJPaySettingsManager shared].currentSettings.abSettingsModel;
        if ([localTheme.amountKeyboardTopBgColor isEqualToString:@"light"]) {
            [self.boardAccessoryTopView setInsuranceURLString:model.amountKeyboardInsuranceUrl];
        } else {
            [self.boardAccessoryTopView setInsuranceURLString:model.amountKeyboardDarkInsuranceUrl];
        }
    }
}

- (double)amountValue {
    return self.textField.text.doubleValue;
}

- (NSString *)amountText {
    return self.textField.text;
}

- (UILabel *)moneyIconLabel {
    if (!_moneyIconLabel) {
        _moneyIconLabel = [UILabel new];
        _moneyIconLabel.font = [UIFont cj_boldFontOfSize:32];
        _moneyIconLabel.textColor = [UIColor cj_161823ff];
        _moneyIconLabel.text = @"¥";
    }
    return _moneyIconLabel;
}

- (UILabel *)placeHolderLabel {
    if (!_placeHolderLabel) {
        _placeHolderLabel = [UILabel new];
        _placeHolderLabel.font = [UIFont cj_fontOfSize:15];
        _placeHolderLabel.textColor = [UIColor cj_161823WithAlpha:0.34];
    }
    return _placeHolderLabel;
}

- (CJPayAmountTextField *)textField {
    if (!_textField) {
        _textField = [[CJPayAmountTextField alloc] initWithFrame:CGRectZero];
        _textField.delegate = self;
        _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _textField.textColor = [UIColor cj_161823ff];
        _textField.tintColor  = [UIColor cj_fe2c55ff];
        _textField.font = [UIFont cj_denoiseBoldFontOfSize:44];
        
        @CJWeakify(self)
        _textField.amountTextFieldTapGestureClickBlock = ^{
            @CJStrongify(self)
            if ([self.delegate respondsToSelector:@selector(textFieldTapGestureClick)]) {
                [self.delegate textFieldTapGestureClick];
            };
        };
    }
    return _textField;
}

- (UIView *)boardContainerView {
    if (!_boardContainerView) {
        _boardContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CJ_SCREEN_WIDTH, kKeyboardHeight)];
        _boardContainerView.backgroundColor = [UIColor cj_colorWithHexString:@"F1F1F2"];
        [_boardContainerView addSubview:self.safeKeyBoard];
    }
    return _boardContainerView;
}

- (UIView *)boardAccessoryView {
    if (!_boardAccessoryView) {
        _boardAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CJ_SCREEN_WIDTH, 24)];
        _boardAccessoryView.backgroundColor = [UIColor cj_colorWithHexString:@"F1F1F2"];
        CJPayCustomKeyboardTopView *topView = [[CJPayCustomKeyboardTopView alloc] initWithFrame:CGRectMake(0, 0, CJ_SCREEN_WIDTH, 24)];
        self.boardAccessoryTopView = topView;
        [topView setCompletionBtnHidden:YES];
        [_boardAccessoryView addSubview:topView];
    }
    return _boardAccessoryView;
}

- (CJPayDouyinKeyboard *)safeKeyBoard {
    if (!_safeKeyBoard) {
        _safeKeyBoard = [[CJPayDouyinKeyboard alloc] init];
    }
    return _safeKeyBoard;
}

- (CJPayCustomRightView *)customClearView {
    if (!_customClearView) {
        _customClearView = [[CJPayCustomRightView alloc] initWithFrame:CGRectMake(0, 0, 24, 44)];
        [_customClearView setRightButtonImageWithName:@"cj_clear_button_icon"];
        [_customClearView setRightButtonCenterOffset:3];
        
        [_customClearView.rightButton addTarget:self action:@selector(p_clearButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _customClearView;
}

- (void)setTextFieldPlaceHolderWith:(NSString *)placeHolderText{
    self.placeHolderLabel.text = placeHolderText;
}

- (void)p_clearButtonClick {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldWillClear:)]) {
        [self.delegate textFieldWillClear:self];
    }
    self.textField.text = @"";
    self.placeHolderLabel.hidden = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldContentChange:textContainer:)]) {
        [self.delegate textFieldContentChange:self.textField.text textContainer:self];
    }
}

- (BOOL)resignFirstResponder {
    return [self.textField resignFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.customClearView.hidden = [self.textField.text isEqualToString:@""];
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldBeginEdit:)]) {
        [self.delegate textFieldBeginEdit:self];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldEndEdit:)]) {
        [self.delegate textFieldEndEdit:self];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *allowCharSet;
    NSUInteger nDotLoc = [textField.text rangeOfString:@"."].location;
    if (nDotLoc == NSNotFound && range.location != 0 ) {
        allowCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    } else {
        allowCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    }
    
    NSRange tmpRange = [string rangeOfCharacterFromSet:allowCharSet.invertedSet];
    NSMutableString *curText = [textField.text mutableCopy];
    [curText replaceCharactersInRange:range withString:string];
    
    //如果第一位输入.则转化为0.
    if ([curText hasPrefix:@"."]){
        curText = [[curText stringByReplacingOccurrencesOfString:@"." withString:@"0."] mutableCopy];
    }else{
        //检查是不是允许输入的字符
       if (![string isEqualToString:@""] && tmpRange.location != NSNotFound) {
             return NO;
        }
    }
    
    //如果第一位输入0则第二位必须是.，否则只显示0
    if ([curText hasPrefix:@"0"] && ![curText hasPrefix:@"0."]) {
        curText = [@"0" mutableCopy];
    }
    
    nDotLoc = [curText rangeOfString:@"."].location;
    // 检查是不是满足小数点后小于等于两位,不满足就进行截取
    if (nDotLoc != NSNotFound && curText.length > nDotLoc + 3) {
        curText = [[curText substringToIndex:nDotLoc + 3] mutableCopy];
    }
    
    if ([curText doubleValue] - 99999999.99 > 0.0001) {
        return NO;
    }
    
    textField.text = curText;
    
    self.customClearView.hidden = [self.textField.text isEqualToString:@""];
    self.placeHolderLabel.hidden = Check_ValidString(self.textField.text);
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldContentChange:textContainer:)]) {
        [self.delegate textFieldContentChange:self.textField.text textContainer:self];
    }
    return NO;
}

- (void)p_installDefaultAppearance {
    CJPayAmountTextFieldContainer *appearance = [CJPayAmountTextFieldContainer appearance];
    
    if (appearance.textField.tintColor == nil) {
        self.textField.tintColor = [UIColor cj_fe2c55ff];
    }
}

- (void)p_setupKeyBoard {
    @CJWeakify(self)
    self.safeKeyBoard.deleteBlock = ^{
        [weak_self p_deleteBackWord];
    };
    
    self.safeKeyBoard.inputStrBlock = ^(NSString * _Nonnull string) {
        [weak_self p_inputStr:string];
    };
}

- (void)p_deleteBackWord {
    BOOL allowInput = NO;
    NSString *oldStr = self.textField.text;
    NSRange selectRange = [self p_selectedRange];
    NSRange newRange = NSMakeRange(0, 0);
    
    if (selectRange.length == 0 && selectRange.location > 0) {
        // 删除一个字符
        newRange = NSMakeRange(selectRange.location - 1, 1);
        allowInput =  [self textField:self.textField shouldChangeCharactersInRange:newRange replacementString:@""];
    } else if (selectRange.length > 0) {
        // 删除多个字符
        newRange = selectRange;
        allowInput =  [self textField:self.textField shouldChangeCharactersInRange:newRange replacementString:@""];
    }
    
    if (allowInput) {
        self.textField.text = [oldStr stringByReplacingCharactersInRange:newRange withString:@""];
        if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldContentChange:textContainer:)]) {
            [self.delegate textFieldContentChange:self.textField.text textContainer:self];
        }
    }
}

- (void)p_inputStr:(NSString *)str {
    BOOL allowInput = NO;
    NSString *oldStr = self.textField.text;
    NSRange selectRange = [self p_selectedRange];
    if (selectRange.location >= 0) {
        if (selectRange.length == 0) {
            allowInput = [self textField:self.textField
        shouldChangeCharactersInRange:NSMakeRange(selectRange.location, 0)
                    replacementString:str];
        } else {
            allowInput = [self textField:self.textField
        shouldChangeCharactersInRange:NSMakeRange(selectRange.location, selectRange.length)
                    replacementString:str];
        }
    }
    if (allowInput) {
        self.textField.text = [oldStr stringByReplacingCharactersInRange:selectRange withString:str];
        if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldContentChange:textContainer:)]) {
            [self.delegate textFieldContentChange:self.textField.text textContainer:self];
        }
    }
}

- (NSRange)p_selectedRange {
    UITextPosition* beginning = self.textField.beginningOfDocument;
    
    UITextRange* selectedRange = self.textField.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    
    const NSInteger location = [self.textField offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self.textField offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

@end
