//
//  CJPayIDCardLast6DigitsInputView.m
//  CJPay
//
//  Created by liyu on 2020/3/24.
//

#import "CJPayIDCardLast6DigitsInputView.h"

#import "CJPayUIMacro.h"
#import "CJPayBaseSafeInputView.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayButton.h"

@interface CJPayIDCardLast6DigitsInputView ()<UITextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) CJPayBaseSafeInputView *textField;

@property (nonatomic, strong) UIView *keyboardContainerView;
@property (nonatomic, strong) CJPaySafeKeyboard *safeKeyBoard;
@property (nonatomic, strong) NSCharacterSet *supportedCharacterSet;
@property (nonatomic, strong) CJPayButton *customClearBtn;

@end

@implementation CJPayIDCardLast6DigitsInputView

#pragma mark - Public

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.titleLabel];
        [self addSubview:self.textField];
        [self addSubview:self.customClearBtn];

        [self p_makeConstraints];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 56);
}

#pragma mark - Subviews

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:16];
        _titleLabel.textColor = UIColor.cj_222222ff;
        _titleLabel.text = CJPayLocalizedStr(@"身份证后6位");
        _titleLabel.clipsToBounds = NO;
    }
    return _titleLabel;
}

- (CJPayBaseSafeInputView *)textField {
    if (!_textField) {
        _textField = [[CJPayBaseSafeInputView alloc] init];
        _textField.allowPaste = NO;
        _textField.textColor = UIColor.cj_222222ff;
        _textField.font = [UIFont cj_fontOfSize:16];
        _textField.delegate = self;
        _textField.clearButtonMode = UITextFieldViewModeNever;
        _textField.placeholder = CJPayLocalizedStr(@"在此输入");
        _textField.clipsToBounds = NO;
        _textField.inputView = self.keyboardContainerView;
    }
    return _textField;
}

- (UIView *)keyboardContainerView {
    if (!_keyboardContainerView) {
        _keyboardContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, CJ_SCREEN_HEIGHT - 224 - CJ_TabBarSafeBottomMargin, CJ_SCREEN_WIDTH, 224 + CJ_TabBarSafeBottomMargin)];
        _keyboardContainerView.backgroundColor = [UIColor cj_colorWithHexString:@"d1d3d8"];
        [_keyboardContainerView addSubview:self.safeKeyBoard];
    }
    return _keyboardContainerView;
}

- (CJPaySafeKeyboard *)safeKeyBoard {
    if (!_safeKeyBoard) {
        _safeKeyBoard = [[CJPaySafeKeyboard alloc] initWithFrame: CGRectMake(0, 0, CJ_SCREEN_WIDTH, 224)];
        _safeKeyBoard.keyboardType = CJPaySafeKeyboardTypeIDCard;
        [_safeKeyBoard setupUI];
        @CJWeakify(self)
        _safeKeyBoard.characterClickedBlock = ^(NSString * _Nonnull string) {
            [weak_self inputString:string];
        };
        _safeKeyBoard.deleteClickedBlock = ^{
            [weak_self deleteBackward];
        };
    }
    return _safeKeyBoard;
}

- (CJPayButton *)customClearBtn {
    if (!_customClearBtn) {
        _customClearBtn = [CJPayButton new];
        [_customClearBtn addTarget:self action:@selector(p_tapClear) forControlEvents:UIControlEventTouchUpInside];
        [_customClearBtn cj_setBtnImageWithName:@"cj_pm_clear_button_icon"];
        [_customClearBtn setHidden:YES];
    }
    return _customClearBtn;
}

#pragma mark - Private

- (void)p_makeConstraints
{
    [self.titleLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                       forAxis:UILayoutConstraintAxisHorizontal];
    CJPayMasMaker(self.titleLabel, {
        make.leading.equalTo(self).offset(16);
        make.centerY.equalTo(self);
    });
    
    CJPayMasMaker(self.textField, {
        make.leading.equalTo(self.titleLabel.mas_trailing).offset(20);
        make.trailing.equalTo(self).offset(-16);
        make.centerY.equalTo(self.titleLabel);
    });
    
    [self bringSubviewToFront:self.customClearBtn];
    CJPayMasMaker(self.customClearBtn, {
        make.width.height.equalTo(@(24));
        make.right.equalTo(self).offset(-12);
        make.centerY.equalTo(self.textField);
    });
}

- (void)p_tapClear {
    [self textField:self.textField shouldChangeCharactersInRange:NSMakeRange(0, self.textField.text.length) replacementString:@""];
}

- (void)p_changeClearBtnHiddenStatus {
    self.customClearBtn.hidden = [self.textField.text isEqualToString:@""];
}

#pragma mark - UITextFieldDelegate

- (void)inputString:(NSString *)string
{
    NSRange selectRange = [self selectedRange];
    if (selectRange.location < 0) {
        return;
    }

    [self textField:self.textField shouldChangeCharactersInRange:selectRange  replacementString:string];
}

- (void)deleteBackward {
    NSRange selectRange = [self selectedRange];
    if (selectRange.location <= 0) {
        return;
    }
    if (selectRange.length == 0) {
        selectRange = NSMakeRange(selectRange.location - 1, 1);
    }

    [self textField:self.textField shouldChangeCharactersInRange:selectRange replacementString:@""];
}


- (NSRange)selectedRange
{
    UITextPosition* beginning = self.textField.beginningOfDocument;
    
    UITextRange* selectedRange = self.textField.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    
    const NSInteger location = [self.textField offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self.textField offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (void)setSelectedRange:(NSRange)range
{
    UITextPosition* beginning = self.textField.beginningOfDocument;
    
    UITextPosition* startPosition = [self.textField positionFromPosition:beginning offset:range.location];
    UITextPosition* endPosition = [self.textField positionFromPosition:beginning offset:range.location + range.length];
    if (startPosition == nil || endPosition == nil) {
        CJPayLogInfo(@"无法设置光标位置 self.textField.text: %@ | range: %@", self.textField.text, NSStringFromRange(range));
        return;
    }
    UITextRange* selectionRange = [self.textField textRangeFromPosition:startPosition toPosition:endPosition];
    //设置光标位置,放到下一个runloop才会生效
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textField setSelectedTextRange:selectionRange];
    });
}


static NSUInteger const kMaxCount = 6;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)inputString {
    NSString *oldValue = textField.text;
    NSString *trimmedString = [[inputString.uppercaseString
                                componentsSeparatedByCharactersInSet:self.supportedCharacterSet.invertedSet]
                               componentsJoinedByString:@""];
    
    NSUInteger maxAllowedCount = kMaxCount + range.length - self.textField.text.length;
    if (maxAllowedCount == 0) {
        return NO;
    }
    
    NSUInteger allowedCount = MIN(maxAllowedCount, trimmedString.length);
    NSString *limitedString = [trimmedString substringToIndex:allowedCount];
    
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:limitedString];
    textField.text = newString;

    [self setSelectedRange:NSMakeRange(range.location + limitedString.length, 0)];
    
    if (oldValue.length == 0 && [newString length] > 0) {
        CJ_CALL_BLOCK(self.didStartInputBlock);
    }
    
    if (![newString isEqualToString:oldValue] && newString.length == kMaxCount) {
        CJ_CALL_BLOCK(self.completion, newString);
    }
    [self p_changeClearBtnHiddenStatus];
    return NO;
}

- (NSCharacterSet *)supportedCharacterSet
{
    if (!_supportedCharacterSet) {
        _supportedCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789xX"];
    }
    return _supportedCharacterSet;
}

#pragma mark - Setter

- (void)setCursorColor:(UIColor *)cursorColor {
    if (cursorColor == nil) {
        return;
    }
    _cursorColor = cursorColor;
    self.textField.tintColor = cursorColor;
}

@end
