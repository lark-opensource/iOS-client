//
//  BDRLBaseCell.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/13.
//

#import "BDRLBaseCell.h"
#import "BDRLToolItem.h"

@interface BDRLBaseCell()
@property (nonatomic, strong) BDRLToolItem *data;

@end

@implementation BDRLBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:[self label]];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.label sizeToFit];
    self.label.frame = CGRectMake(20,
                                  (self.contentView.frame.size.height - self.label.frame.size.height) / 2,
                                  self.label.frame.size.width,
                                  self.label.frame.size.height);
}

- (UILabel *)label
{
    if (_label == nil) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:14];
        _label.textColor = [UIColor blackColor];
    }
    return _label;
}


- (void)configWithData:(BDRLToolItem *)data
{
    self.data = data;
    self.label.text = data.itemTitle;
}


@end
