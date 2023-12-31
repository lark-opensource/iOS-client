//
//  BDRLTextCell.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/3/29.
//

#import "BDRLTextCell.h"
#import "BDRLToolItem.h"

@interface BDRLTextCell()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation BDRLTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.label removeFromSuperview];
        [self.contentView addSubview:self.textView];
    }
    return self;
}

- (void)setText:(NSString *)text
{
    [self.textView setText:text];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.textView.frame = CGRectMake(20, 10, self.contentView.frame.size.width - 25, self.contentView.frame.size.height - 20);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)configWithData:(BDRLToolItem *)data
{
    [super configWithData:data];
    self.textView.text = data.itemTitle;
}

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.textAlignment = NSTextAlignmentLeft;
        _textView.font = [UIFont systemFontOfSize:14];
        _textView.editable = NO;
        _textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        _textView.layer.borderWidth = 0.8;
        _textView.layer.cornerRadius = 5.0;
        _textView.layer.masksToBounds = YES;
    }
    return _textView;
}

@end
