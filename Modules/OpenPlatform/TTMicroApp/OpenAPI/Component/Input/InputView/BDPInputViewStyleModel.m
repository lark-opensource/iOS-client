//
//  BDPInputViewStyleModel.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import "BDPInputViewStyleModel.h"
#import <OPFoundation/BDPUtils.h>

#import <OPFoundation/UIFont+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

@implementation BDPInputViewStyleModel

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CGRect)frame
{
    return CGRectMake(self.left, self.top, self.width, self.height);
}

- (UIFont *)font
{
    UIFont *font = [UIFont cssWithFontFamily:self.fontFamily fontSize: self.fontSize fontWeight: self.fontWeight];
    return font;
}

- (NSTextAlignment)textAlignment
{
    if ([self.textAlign isEqualToString:@"left"]) {
        return NSTextAlignmentLeft;
    } else if ([self.textAlign isEqualToString:@"center"]) {
        return NSTextAlignmentCenter;
    } else if ([self.textAlign isEqualToString:@"right"]) {
        return NSTextAlignmentRight;
    }
    return NSTextAlignmentLeft;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    if (!BDPIsEmptyDictionary(dict)) {
        if ([dict valueForKey:@"width"]) self.width = [dict bdp_doubleValueForKey:@"width"];
        if ([dict valueForKey:@"height"]) self.height = [dict bdp_doubleValueForKey:@"height"];
        if ([dict valueForKey:@"left"]) self.left = [dict bdp_doubleValueForKey:@"left"];
        if ([dict valueForKey:@"top"]) self.top = [dict bdp_doubleValueForKey:@"top"];
        if ([dict valueForKey:@"fontFamily"]) self.fontFamily = [dict bdp_stringValueForKey:@"fontFamily"];
        if ([dict valueForKey:@"fontWeight"]) self.fontWeight = [dict bdp_stringValueForKey:@"fontWeight"];
        if ([dict valueForKey:@"fontSize"]) self.fontSize = [dict bdp_doubleValueForKey:@"fontSize"];
        if ([dict valueForKey:@"color"]) self.color = [dict bdp_stringValueForKey:@"color"];
        if ([dict valueForKey:@"backgroundColor"]) self.backgroundColor = [dict bdp_stringValueForKey:@"backgroundColor"];
        if ([dict valueForKey:@"textAlign"]) self.textAlign = [dict bdp_stringValueForKey:@"textAlign"];
        if ([dict valueForKey:@"marginBottom"]) self.marginBottom = [dict bdp_doubleValueForKey:@"marginBottom"];
    }
}

@end
