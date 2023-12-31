//
//  NSAttributedString+ACCUIDynamicColor.m
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/23.
//

#import "NSAttributedString+ACCUIDynamicColor.h"
#import "ACCUIDynamicColor.h"

@implementation NSAttributedString (ACCUIDynamicColor)

- (BOOL)acc_attributeContainsDynamicColor
{
    __block BOOL containsDynamicColor = NO;
    [self enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, self.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:ACCUIDynamicColor.class]) {
            containsDynamicColor = YES;
            *stop = YES;
        }
    }];
    return containsDynamicColor;
}

- (NSAttributedString *)acc_invalidateAttributedTextForegroundColor
{
    __block NSMutableAttributedString *mutableAttributedText;
    if ([self isKindOfClass:NSMutableAttributedString.class]) {
        mutableAttributedText = (NSMutableAttributedString *)self;
    } else {
        mutableAttributedText = [self mutableCopy];
    }
    [self enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, self.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:ACCUIDynamicColor.class]) {
            [mutableAttributedText addAttribute:NSForegroundColorAttributeName value:value range:range];
        }
    }];
    return mutableAttributedText;
}

@end
