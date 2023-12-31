//
//  BDRLParameterCell.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/13.
//

#import "BDRLParameterCell.h"
#import "BDRuleParameterRegistry.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDRLParameterCell()<UITextFieldDelegate>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UISwitch *switcher;
@end

@implementation BDRLParameterCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.subTitleLabel];
        [self.contentView addSubview:self.textField];
        [self.contentView addSubview:self.switcher];
    }
    return self;
}
- (void)configWithData:(BDRuleParameterBuilderModel *)data
{
    _data = data;
    self.titleLabel.text = data.key;
    id value = data.builder(nil);
    NSString *valueText = @"";
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
        valueText = [value btd_jsonStringEncoded];
    } else {
        valueText = [value description];
    }
    self.textField.text = valueText;
    self.textField.hidden = NO;
    self.switcher.hidden = YES;
    self.textField.userInteractionEnabled = NO;
    if (data.type == BDRuleParameterTypeNumberOrBool) {
        self.subTitleLabel.text = @"数字/布尔";
        if ([data.key hasPrefix:@"is"] || [data.key hasPrefix:@"has"] || [data.key hasPrefix:@"enable"]) {
            self.textField.hidden = YES;
            self.switcher.hidden = NO;
            self.switcher.on = ((NSNumber *)value).boolValue;
        } else {
            self.textField.userInteractionEnabled = YES;
        }
    }
    if (data.type == BDRuleParameterTypeString) {
        self.subTitleLabel.text = @"字符串";
        self.textField.userInteractionEnabled = YES;
    }
    if (data.type == BDRuleParameterTypeArray) {
        self.subTitleLabel.text = @"数组";
    }
    if (data.type == BDRuleParameterTypeDictionary) {
        self.subTitleLabel.text = @"字典";
    }
    if (data.type == BDRuleParameterTypeUnknown) {
        self.subTitleLabel.text = @"位置";
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.titleLabel sizeToFit];
    [self.subTitleLabel sizeToFit];
    [self.switcher sizeToFit];
    self.titleLabel.frame = CGRectMake(20,
                                  (self.contentView.frame.size.height - self.titleLabel.frame.size.height) / 2 - 20,
                                  self.titleLabel.frame.size.width,
                                  self.titleLabel.frame.size.height);
    self.subTitleLabel.frame = CGRectMake(20,
                                  self.titleLabel.frame.size.height + self.titleLabel.frame.origin.y + 5,
                                  self.subTitleLabel.frame.size.width,
                                  self.subTitleLabel.frame.size.height);
    
    self.textField.frame = CGRectMake(self.contentView.frame.size.width - 300 - 10, (self.contentView.frame.size.height - 50) / 2.0, 300, 50);
    
    self.switcher.frame = CGRectMake(self.contentView.frame.size.width - self.switcher.frame.size.width - 12,
                                       (self.contentView.frame.size.height - self.switcher.frame.size.height) / 2,
                                       self.switcher.frame.size.width,
                                       self.switcher.frame.size.height);
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.textColor = [UIColor blackColor];
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (_subTitleLabel == nil) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.font = [UIFont systemFontOfSize:12];
        _subTitleLabel.textColor = [UIColor blackColor];
    }
    return _subTitleLabel;
}

- (UITextField *)textField
{
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.textAlignment = NSTextAlignmentRight;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.font = [UIFont systemFontOfSize:14];
        _textField.delegate = self;
    }
    return _textField;
}

- (UISwitch *)switcher
{
    if (_switcher == nil) {
        _switcher = [[UISwitch alloc] init];
        [_switcher addTarget:self action:@selector(handleSwitch) forControlEvents:UIControlEventValueChanged];
    }
    return _switcher;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)handleSwitch
{
    if (_delegate && [_delegate respondsToSelector:@selector(handleParameterValueChanged:value:)]) {
        [_delegate handleParameterValueChanged:_data value:@(self.switcher.isOn).stringValue];
    }
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (_delegate && [_delegate respondsToSelector:@selector(handleParameterValueChanged:value:)]) {
        [_delegate handleParameterValueChanged:_data value:textField.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
@end
