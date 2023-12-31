//
//  ACCSwitchLengthCell.m
//  DouYin
//
//  Created by shaohua yang on 6/29/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import "ACCSwitchLengthCell.h"
#import "ACCConfigKeyDefines.h"
#import "ACCRecordContainerMode.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>

@interface ACCSwitchLengthCell ()

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation ACCSwitchLengthCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _textLabel = [[UILabel alloc] initWithFrame:self.bounds];
        if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
            _textLabel.textColor = [UIColor whiteColor];
        } else {
            _textLabel.textColor = [UIColor colorWithWhite:1 alpha:0.7];
        }
        _textLabel.textAlignment = NSTextAlignmentCenter;
        if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
            _textLabel.font = [ACCFont() acc_boldSystemFontOfSize:14];
        } else {
            _textLabel.font = [ACCFont() acc_boldSystemFontOfSize:15];
        }
        _textLabel.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
        _textLabel.layer.shadowOpacity = 1;
        _textLabel.layer.shadowRadius = 8;
        _textLabel.layer.shadowOffset = CGSizeMake(0.5, 3);
        
        [self.contentView addSubview:_textLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (!ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
        if (selected) {
            self.textLabel.textColor = [UIColor whiteColor];
        } else {
            self.textLabel.textColor = [UIColor colorWithWhite:1 alpha:0.7];
        }
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
        self.textLabel.textColor = UIColor.whiteColor;
    } else {
        self.textLabel.textColor = [UIColor colorWithWhite:1 alpha:0.7];
    }
    self.userInteractionEnabled = YES;
    self.text = @"";
}

- (void)setText:(NSString *)text
{
    _text = text;
    self.textLabel.text = text;
}

- (void)setProgress:(CGFloat)progress
{
    self.textLabel.textColor = [UIColor colorWithHue:0 saturation:0 brightness:progress alpha:pow((progress - 0.5) * 2, 2) / 2 + 0.5];
    self.textLabel.layer.shadowOpacity = progress;
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return !ACC_isEmptyString(self.textLabel.text);
}

- (BOOL)isUserInteractionEnabled
{
    return !ACC_isEmptyString(self.textLabel.text);
}

- (NSString *)accessibilityLabel
{
    NSString *switchType = self.textLabel.text;
    if (self.modeId == ACCRecordModeMixHoldTap15SecondsRecord) {
        switchType = @"15秒";
    } else if (self.modeId == ACCRecordModeMixHoldTap60SecondsRecord) {
        switchType = @"60秒";
    } else if (self.modeId == ACCRecordModeMixHoldTap3MinutesRecord) {
        switchType = @"3分钟";
    }

    if (self.isSelected) {
        return [NSString stringWithFormat:@"%@%@",  ACCLocalizedCurrentString(@"com_mig_selected_8i1pf2"), switchType];
    }

    return [NSString stringWithFormat:@"%@%@",  ACCLocalizedCurrentString(@"com_mig_unselected"), switchType];
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end
