//
//  BDRLStrategyButtonCell.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 24.4.22.
//

#import "BDRLStrategyButtonCell.h"
#import "BDStrategyCenter+Debug.h"
#import "BDRLToolItem.h"
#import "BDStrategyProvider.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDRLStrategyButtonCell()

@property (nonatomic, strong) UIButton *button;

@end

@implementation BDRLStrategyButtonCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self __setupButtonAction];
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
    [self.button setTitle:@"Copy" forState:UIControlStateNormal];
}

#pragma mark - private

- (void)__setupButtonAction
{
    [self.button addTarget:self action:@selector(__copyJson) forControlEvents:UIControlEventTouchUpInside];
}

// TODO 添加复制成功之后的提示
- (void)__copyJson
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *json;
    if ([self.label.text hasPrefix:@"Final Strategy"]) {
        json = [[BDStrategyCenter mergedStrategies] btd_jsonStringPrettyEncoded];
    } else {
        for (id provider in [BDStrategyCenter providers]) {
            NSString *providerName = NSStringFromClass([provider class]);
            if ([provider respondsToSelector:@selector(displayName)]) {
                providerName = [provider displayName];
            }
            if ([self.label.text isEqualToString:providerName]) {
                json = [[provider strategies] btd_jsonStringPrettyEncoded];
            }
        }
    }
    pasteboard.string = json;
}

#pragma mark - Init

- (UIButton *)button
{
    if (!_button) {
        _button = [[UIButton alloc]init];
        _button.backgroundColor = [UIColor systemBlueColor];
        _button.layer.cornerRadius = 5.0;
        _button.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _button.layer.masksToBounds = YES;
        _button.userInteractionEnabled = YES;
        _button.titleLabel.textColor = [UIColor whiteColor];
    }
    return _button;
}

@end
