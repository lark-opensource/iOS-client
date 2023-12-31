//
//  AWEStickerPickerSearchBar.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/31.
//

#import "AWEStickerPickerSearchBar.h"
#import "AWEStickerPickerSearchBarConfig.h"

#import <CreativeKit/UIFont+ACCAdditions.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEStickerPickerSearchBar () <UITextFieldDelegate>

@property (nonatomic, strong) UIImageView *lensImageView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UILabel *tagLabel;

@property (nonatomic, assign) BOOL isRightButtonHidden;

@end

@implementation AWEStickerPickerSearchBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubviews];
    }
    return self;
}

- (void)addSubviews
{
    [self addSubview:self.rightButton];
    [self addSubview:self.contentView];

    [self.rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        if (self.type != AWEStickerPickerSearchBarTypeRightButtonShow) {
            make.left.equalTo(self.mas_right);
        } else {
            make.right.equalTo(self).offset(-16);
        }
        make.centerY.equalTo(self.contentView);
    }];

    self.isRightButtonHidden = (self.type != AWEStickerPickerSearchBarTypeRightButtonShow);

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(self).offset(4);
        make.bottom.equalTo(self).offset(-8);
        make.right.equalTo(self.rightButton.mas_left).offset(-16);
    }];
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = [AWEStickerPickerSearchBarConfig sharedConfig].searchFiledBackgroundColor;
        _contentView.layer.cornerRadius = 2;

        [_contentView addSubview:self.lensImageView];
        [self.lensImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@24);
            make.centerY.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(6);
        }];

        [_contentView addSubview:self.tagLabel];
        [self.tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.lensImageView.mas_right).offset(2);
            make.height.equalTo(self.contentView);
            make.centerY.equalTo(self.contentView);
            make.width.mas_lessThanOrEqualTo(@120).priority(999);
        }];

        [_contentView addSubview:self.textField];
        [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.tagLabel.mas_right).offset(2);
            make.height.equalTo(self.contentView);
            make.centerY.equalTo(self.contentView);
            make.right.equalTo(self.contentView).offset(-36);
        }];

        [_contentView addSubview:self.clearButton];
        [self.clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@24);
            make.centerY.equalTo(self.contentView);
            make.right.equalTo(self.contentView).offset(-4).priorityMedium();
        }];
    }
    return _contentView;
}

- (UILabel *)tagLabel
{
    if (!_tagLabel) {
        _tagLabel = [[UILabel alloc] init];
        [_tagLabel setContentHuggingPriority:UILayoutPriorityRequired
                                     forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _tagLabel;
}

- (UIImageView *)lensImageView
{
    if (!_lensImageView) {
        _lensImageView = [[UIImageView alloc] initWithImage:[AWEStickerPickerSearchBarConfig sharedConfig].lensImage];
        _lensImageView.tintColor = [AWEStickerPickerSearchBarConfig sharedConfig].lensImageTintColor;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lensImageClicked)];
        [_lensImageView addGestureRecognizer:tapGesture];
        _lensImageView.userInteractionEnabled = YES;
    }
    return _lensImageView;
}

- (UIButton *)clearButton
{
    if (!_clearButton) {
        _clearButton = [[UIButton alloc] init];
        [_clearButton setImage:[AWEStickerPickerSearchBarConfig sharedConfig].clearImage forState:UIControlStateNormal];
        [_clearButton addTarget:self action:@selector(clearButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _clearButton.isAccessibilityElement = YES;
        _clearButton.accessibilityLabel = @"清除";
        _clearButton.accessibilityTraits = UIAccessibilityTraitButton;
        _clearButton.hidden = YES;
    }
    return _clearButton;
}

- (UITextField *)textField
{
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.delegate = self;
        _textField.textColor = [AWEStickerPickerSearchBarConfig sharedConfig].textColor;
        _textField.tintColor = [AWEStickerPickerSearchBarConfig sharedConfig].tintColor;
        _textField.font = [UIFont acc_systemFontOfSize:15];
        _textField.textAlignment = NSTextAlignmentLeft;
        [_textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        [_textField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _textField;
}

- (UIButton *)rightButton
{
    if (!_rightButton) {
        _rightButton = [[UIButton alloc] init];
        [_rightButton setTitle:@"cancel" forState:UIControlStateNormal];
        [_rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _rightButton.titleLabel.font = [UIFont acc_systemFontOfSize:15];
        [_rightButton addTarget:self action:@selector(rightButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_rightButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_rightButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _rightButton;
}

- (void)animatedShowCancelButton:(BOOL)show
{
    if (show) {
        if (self.isRightButtonHidden) {
            [self.rightButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self).offset(-16);
                make.centerY.equalTo(self);
            }];
            [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self setNeedsLayout];
                [self layoutIfNeeded];
            } completion:nil];
            self.isRightButtonHidden = NO;
        }
    } else {
        if (!self.isRightButtonHidden) {
            [self.rightButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.mas_right);
                make.centerY.equalTo(self);
            }];
            [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self setNeedsLayout];
                [self layoutIfNeeded];
            } completion:nil];
            self.isRightButtonHidden = YES;
        }
    }
}

- (void)showClearButtonWithText:(NSString *)text
{
    if (text && ![text isEqualToString:@""]) {
        self.clearButton.hidden = NO;
    } else {
        self.clearButton.hidden = YES;
    }
}

- (void)clearSearchBar
{
    [self clearButtonClicked:self.clearButton];
}

#pragma mark - setter/getter

- (void)setPlaceHolder:(NSString *)placeHolder
{
    self.textField.placeholder = placeHolder;
}

- (NSString *)placeHolder
{
    return self.textField.placeholder;
}

- (void)setAttributedPlaceHolder:(NSAttributedString *)attributedPlaceHolder
{
    self.textField.attributedPlaceholder = attributedPlaceHolder;
}

- (NSAttributedString *)attributedPlaceHolder
{
    return self.textField.attributedPlaceholder;
}

- (void)setTextColor:(UIColor *)textColor
{
    self.textField.textColor = textColor;
}

- (UIColor *)textColor
{
    return self.textField.textColor;
}

- (void)setSearchTintColor:(UIColor *)searchTintColor
{
    self.textField.tintColor = searchTintColor;

}

- (UIColor *)searchTintColor
{
    return self.textField.tintColor;
}

- (void)setText:(NSString *)text
{
    self.textField.text = text;

    [self showClearButtonWithText:text];
}

- (NSString *)text
{
    return self.textField.text;
}

- (void)setType:(AWEStickerPickerSearchBarType)type
{
    _type = type;

    [self.rightButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (type != AWEStickerPickerSearchBarTypeRightButtonShow) {
            make.left.equalTo(self.mas_right);
        } else {
            make.right.equalTo(self).offset(-16);
        }
        make.centerY.equalTo(self.contentView);
    }];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.isRightButtonHidden = (type != AWEStickerPickerSearchBarTypeRightButtonShow);
}

- (void)setIsHiddenRightButton:(BOOL)isHiddenRightButton
{
    _isHiddenRightButton = isHiddenRightButton;
    self.rightButton.hidden = YES;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.type == AWEStickerPickerSearchBarTypeRightButtonAuto) {
        [self animatedShowCancelButton:YES];
    }
    if (textField.text && ![textField.text isEqualToString:@""]) {
        self.clearButton.hidden = NO;
    }

    if ([self.delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        [self.delegate textFieldDidBeginEditing:self.textField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.type == AWEStickerPickerSearchBarTypeRightButtonAuto) {
        [self animatedShowCancelButton:NO];
    }

    if (!textField.text || [textField.text isEqualToString:@""]) {
        self.clearButton.hidden = YES;
    }

    if ([self.delegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
        [self.delegate textFieldDidEndEditing:self.textField];
    }
}

- (void)textFieldDidChange:(UITextField *)textField
{
    [self showClearButtonWithText:textField.text];
    if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [self.delegate searchBar:self textDidChange:textField.text];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (self.isTab) {
        if (self.didTapTextFieldBlock) {
            self.didTapTextFieldBlock();
        }
        return NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        return [self.delegate textFieldShouldBeginEditing:self.textField];
    } else {
        return YES;
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
        return [self.delegate textFieldShouldEndEditing:self.textField];
    } else {
        return YES;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        return [self.delegate textField:self.textField shouldChangeCharactersInRange:range replacementString:string];
    } else {
        return YES;
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(textFieldShouldClear:)]) {
        return [self.delegate textFieldShouldClear:self.textField];
    } else {
        return YES;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
        return [self.delegate textFieldShouldReturn:self.textField];
    } else {
        return YES;
    }
}

#pragma mark - actions

- (void)rightButtonClicked:(UIButton *)button
{
    if (self.rightButtonClickedBlock) {
        self.rightButtonClickedBlock();
    }

    if (!self.textField.text || [self.textField.text isEqualToString:@""]) {
        self.clearButton.hidden = YES;
    }
}

- (void)clearButtonClicked:(UIButton *)button
{
    if ([self textFieldShouldClear:self.textField]) {
        self.textField.text = nil;
        [self.textField sendActionsForControlEvents:UIControlEventEditingChanged];
        self.clearButton.hidden = YES;
    }

    if (self.clearButtonClickedBlock) {
        self.clearButtonClickedBlock();
    }
}

- (void)lensImageClicked
{
    [self.textField becomeFirstResponder];
    if ([self respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        [self textFieldDidBeginEditing:self.textField];
    }
}

@end
