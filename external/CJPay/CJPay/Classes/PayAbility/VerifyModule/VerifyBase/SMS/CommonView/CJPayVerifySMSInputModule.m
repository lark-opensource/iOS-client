//
//  CJPayVerifySMSInputModule.m
//  Pods
//
//  Created by 张海阳 on 2019/10/16.
//

#import "CJPayVerifySMSInputModule.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleTextField.h"

@interface CJPayVerifySMSInputModule () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayStyleTextField *textField;
@property (nonatomic, strong) UIButton *button;

@end


@implementation CJPayVerifySMSInputModule

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:16];
        _titleLabel.textColor = UIColor.cj_222222ff;
    }
    return _titleLabel;
}

- (CJPayStyleTextField *)textField {
    if (!_textField) {
        _textField = [CJPayStyleTextField new];
        _textField.textColor = UIColor.cj_222222ff;
        _textField.font = [UIFont cj_fontOfSize:16];
        _textField.keyboardType = UIKeyboardTypeNumberPad;
        _textField.delegate = self;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    return _textField;
}

- (UIButton *)button {
    if (!_button) {
        _button = [UIButton new];
        [_button setTitleColor:[UIColor cj_douyinBlueColor] forState:UIControlStateNormal];
        [_button setTitleColor:UIColor.cj_cacacaff forState:UIControlStateDisabled];
        [_button setTitle:@"重新发送" forState:UIControlStateNormal];
        _button.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_button addTarget:self action:@selector(buttonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button;
}

- (void)setBigTitle:(NSString *)bigTitle {
    _bigTitle = bigTitle;
    _titleLabel.text = bigTitle;
}

- (NSString *)textValue {
    return self.textField.text;
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder;
    _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:CJString(placeholder)
                                                                       attributes:@{NSForegroundColorAttributeName: UIColor.cj_cacacaff,
                                                                                    NSFontAttributeName: [UIFont cj_fontOfSize:16]
                                                                       }];
}

- (void)setButtonEnable:(BOOL)enable title:(NSString *)title {
    self.button.enabled = enable;
    [self.button setTitle:title forState:(enable ? UIControlStateNormal : UIControlStateDisabled)];
    [self setFrames];
}

- (void)clearText {
    self.textField.text = @"";
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLabel];
        [self addSubview:self.textField];
        [self addSubview:self.button];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textFieldTextDidChange:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:self.textField];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setFrames];
}

- (void)setFrames {
    [self.titleLabel sizeToFit];
    self.titleLabel.cj_left = 16;
    self.titleLabel.cj_centerY = self.cj_height / 2;

    [self.button sizeToFit];
    self.button.cj_left = self.cj_width - 16 - self.button.cj_width;
    self.button.cj_centerY = self.cj_height / 2;

    self.textField.frame = CGRectMake(self.titleLabel.cj_right + 20,
            0,
            self.cj_width - 16 * 2 - 20 * 2 - self.titleLabel.cj_width - self.button.cj_width,
            self.cj_height);
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
};

- (BOOL)resignFirstResponder {
    return [self.textField resignFirstResponder];
}

- (void)buttonClicked {
    CJ_DelayEnableView(self.button);
    if (self.buttonAction) {
        self.buttonAction(self.button.isEnabled);
    }
}

#pragma mark - UITextFieldDelegate
- (void)textFieldTextDidChange:(NSNotification *)notification {
    UITextField *textField = (UITextField *)notification.object;

    if (![textField isKindOfClass:UITextField.class]) { return; }

    if (textField.text.length == self.textCount) {
        if ([self.delegate respondsToSelector:@selector(inputModule:completeInputWithText:)]) {
            [self.delegate inputModule:self completeInputWithText:textField.text];
        }
    }
    if ([self.delegate respondsToSelector:@selector(inputModule:textDidChange:)]) {
        [self.delegate inputModule:self textDidChange:textField.text];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length == 0) { return YES; }
    if (textField.text.length + string.length > self.textCount) { return NO; }
    return YES;
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
