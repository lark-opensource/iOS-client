//
//  BDRLInputCell.m
//  Pods
//
//  Created by Chengmin Zhang on 2022/3/29.
//

#import "BDRLInputCell.h"
#import "BDRLToolItem.h"

@interface BDRLInputCell()<UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;

@end

@implementation BDRLInputCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.textView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.label sizeToFit];
    self.label.frame = CGRectMake(20, (self.contentView.frame.size.height - self.label.frame.size.height) / 2, self.label.frame.size.width, self.label.frame.size.height);
    
    self.textView.frame = CGRectMake(90, 10, self.contentView.frame.size.width - 100, self.contentView.frame.size.height - 20);
}

- (NSString *)inputText {
    return self.textView.text;
}

- (void)setInputText:(NSString *)inputText {
    [self.textView setText:inputText];
}

- (void)configWithData:(BDRLToolItem *)data
{
    [super configWithData:data];
    self.textView.userInteractionEnabled = !data.inputDisable;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.textAlignment = NSTextAlignmentLeft;
        _textView.font = [UIFont systemFontOfSize:14];
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.spellCheckingType = UITextSpellCheckingTypeNo;
        _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        _textView.layer.borderWidth = 0.8;
        _textView.layer.cornerRadius = 5.0;
        _textView.layer.masksToBounds = YES;
        _textView.delegate = self;
    }
    return _textView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark - UITextFieldDelegate
- (void)textViewDidEndEditing:(UITextView *)textView {
    return;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
    return YES;
}

@end
