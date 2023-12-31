//
//  EMAAlertTextView.m
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/12/18.
//

#import "EMAAlertTextView.h"

@interface EMAAlertTextView ()<UITextViewDelegate>

@property (nonatomic, strong) UITextView *placeholderTextView;

@end

@implementation EMAAlertTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.delegate = self;
        [self addPlaceholder];
    }

    return self;
}

- (void)addPlaceholder
{
    UITextView *textview = [UITextView new];
    textview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textview.backgroundColor = [UIColor clearColor];
    textview.userInteractionEnabled = NO;
    textview.editable = NO;
    textview.font = self.font;
    textview.textAlignment = self.textAlignment;
    textview.frame = self.bounds;
    [self addSubview:textview];
    self.placeholderTextView = textview;
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    self.placeholderTextView.font = font;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    self.placeholderTextView.textAlignment = textAlignment;
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self _showOrHidePlaceholderTextView];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self _showOrHidePlaceholderTextView];
}

- (void)layoutSubviews
{
    self.placeholderTextView.frame = self.bounds;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder.copy;
    self.placeholderTextView.text = placeholder;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    _placeholderColor = placeholderColor;
    self.placeholderTextView.textColor = placeholderColor;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self _showOrHidePlaceholderTextView];
}

- (void)textViewDidChange:(UITextView *)textView
{
  [self _showOrHidePlaceholderTextView];
  //  *真实文字输入* 部分(高亮拼音不算做真实文字输入)
  // 有选中的高亮文字为中文输入法，高亮部分不算做文本改变
  NSString *lang = [[UITextInputMode currentInputMode] primaryLanguage]; // 键盘输入模式
  if ([lang isEqualToString:@"zh-Hans"]) { // 简体中文输入，包括简体拼音，健体五笔，简体手写
      UITextRange *selectedRange = [textView markedTextRange];       //获取高亮部分
      UITextPosition *position = [textView positionFromPosition:selectedRange.start offset:0];
      if (position) {
          return;
      }
  }
  if (self.maxLength && textView.text.length > self.maxLength) {
      textView.text = [textView.text substringToIndex:self.maxLength];
  }
  [textView scrollRangeToVisible:textView.selectedRange];
}

#pragma mark - private
- (void)_showOrHidePlaceholderTextView
{
    self.placeholderTextView.hidden = self.text.length > 0 ? YES : NO;
}

@end
