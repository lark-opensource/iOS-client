//
//  BDRLSwitchCell.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/13.
//

#import "BDRLSwitchCell.h"
#import "BDRLToolItem.h"

@implementation BDRLSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:[self switchCtrl]];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.switchCtrl sizeToFit];
    self.switchCtrl.frame = CGRectMake(self.contentView.frame.size.width - self.switchCtrl.frame.size.width - 12,
                                       (self.contentView.frame.size.height - self.switchCtrl.frame.size.height) / 2,
                                       self.switchCtrl.frame.size.width,
                                       self.switchCtrl.frame.size.height);
}

- (void)configWithData:(BDRLToolItem *)data
{
    [super configWithData:data];
    self.switchCtrl.on = data.isOn;
}

- (void)handleSwitch
{
    if ([self.delegate respondsToSelector:@selector(handleSwitchChange:itemTitle:)]) {
        [self.delegate handleSwitchChange:self.switchCtrl.isOn itemTitle:self.data.itemTitle];
    }
    if ([self.delegate respondsToSelector:@selector(handleCellSwitchChange:)]) {
        [self.delegate handleCellSwitchChange:self];
    }
}

- (UISwitch *)switchCtrl
{
    if (_switchCtrl == nil) {
        _switchCtrl = [[UISwitch alloc] init];
        [_switchCtrl addTarget:self action:@selector(handleSwitch) forControlEvents:UIControlEventValueChanged];
    }
    return _switchCtrl;
}

@end
