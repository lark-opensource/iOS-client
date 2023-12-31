//
//  BDRLButtonCell.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/3/29.
//

#import "BDRLButtonCell.h"
#import "BDRLToolItem.h"

@interface BDRLButtonCell()

@property (nonatomic, strong) UIButton *button;

@end

@implementation BDRLButtonCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.label removeFromSuperview];
        [self.contentView addSubview:self.button];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.button.frame = CGRectMake(self.contentView.frame.size.width - 100, 10, 90, self.contentView.frame.size.height - 20);
}

- (void)configWithData:(BDRLToolItem *)data
{
    [super configWithData:data];
    [self.button setTitle:data.itemTitle forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (UIButton *)button
{
    if (!_button) {
        _button = [[UIButton alloc]init];
        _button.backgroundColor = [UIColor systemBlueColor];
        _button.layer.cornerRadius = 5.0;
        _button.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _button.layer.masksToBounds = YES;
        _button.userInteractionEnabled = NO;
        _button.titleLabel.textColor = [UIColor whiteColor];
    }
    return _button;
}

@end

