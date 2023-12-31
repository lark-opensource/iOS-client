//
//  BDABTestPanelTableViewCell.m
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/27.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestPanelTableViewCell.h"

@interface BDABTestPanelTableViewCell ()

@property (nonatomic, strong) UILabel *keyLabel;
@property (nonatomic, strong) UILabel *ownerLabel;
@property (nonatomic, strong) UILabel *descLabel;

@end

@implementation BDABTestPanelTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        const float kScreenWidth = [UIScreen mainScreen].bounds.size.width;
        self.ownerLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth - 15 - 60 - 15, 0, 60, 20)];
        self.ownerLabel.font = [UIFont systemFontOfSize:15];
        self.keyLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, kScreenWidth - 30 -60 - 15, 20)];
        self.keyLabel.font = [UIFont systemFontOfSize:15];
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, kScreenWidth - 30, 20)];
        self.descLabel.font = [UIFont systemFontOfSize:15];
        self.descLabel.numberOfLines = 0;
        [self.contentView addSubview:self.keyLabel];
        [self.contentView addSubview:self.ownerLabel];
        [self.contentView addSubview:self.descLabel];
    }
    return self;
}

- (void)setOwner:(NSString *)owner
{
    _owner = owner;
    self.ownerLabel.text = owner;
}

- (void)setKey:(NSString *)key
{
    _key = key;
    self.keyLabel.text = key;
}

- (void)setDesc:(NSString *)desc
{
    _desc = desc;
    self.descLabel.text = desc;
}

@end
