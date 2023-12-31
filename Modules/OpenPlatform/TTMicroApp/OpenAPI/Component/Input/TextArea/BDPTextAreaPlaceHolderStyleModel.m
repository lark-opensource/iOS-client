//
//  BDPTextAreaPlaceHolderStyleModel.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import "BDPTextAreaPlaceHolderStyleModel.h"
#import <OPFoundation/BDPUtils.h>

#import <OPFoundation/UIFont+BDPExtension.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

@implementation BDPTextAreaPlaceHolderStyleModel

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSDictionary *)attributedStyle
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:2];
    [dic setValue:[UIColor colorWithHexString:self.color] forKey:NSForegroundColorAttributeName];
    [dic setValue:self.font forKey:NSFontAttributeName];
    return [dic copy];
}

- (UIFont *)font
{
    UIFont *font = [UIFont cssWithFontFamily:self.fontFamily fontSize: self.fontSize fontWeight: self.fontWeight];
    return font;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    if (!BDPIsEmptyDictionary(dict)) {
        if ([dict valueForKey:@"fontSize"]) self.fontSize = [dict bdp_doubleValueForKey:@"fontSize"];
        if ([dict valueForKey:@"fontWeight"]) self.fontWeight = [dict bdp_stringValueForKey:@"fontWeight"];
        if ([dict valueForKey:@"fontFamily"]) self.fontFamily = [dict bdp_stringValueForKey:@"fontFamily"];
        if ([dict valueForKey:@"color"]) self.color = [dict bdp_stringValueForKey:@"color"];
    }
}

@end
