//
//  CJPayDeskTheme.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/27.
//

#import "CJPayDeskTheme.h"
#import "CJPayUIMacro.h"

static NSString * const CJPayBtnBgColorString = @"#F85959";
static NSString * const CJPayBtnFontColorString = @"#FFFFFF";

@implementation CJPayDeskTheme

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"bgColorString" : @"button_color",
                @"fontColorString" : @"font_color",
                @"confirmButtonShapeStr" : @"button_shape",
                @"amountColorStr" : @"amount_color",
                @"tradeNameColorStr" : @"trade_name_color",
                @"payTypeMarkColorStr" : @"pay_type_mark_color",
                @"payTypeMarkShapeStr" : @"pay_type_mark_shape",
                @"payTypeMarkStyleStr" : @"pay_type_mark_style",
                @"payTypeMsgColorStr" : @"pay_type_msg_color"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (UIColor *)bgColor {
    NSString *string = Check_ValidString(self.bgColorString)? self.bgColorString : CJPayBtnBgColorString;
    return [UIColor cj_colorWithHexString:string alpha:1.0];
}

- (UIColor *)disableBgColor {
    NSString *string = Check_ValidString(self.bgColorString)? self.bgColorString : CJPayBtnBgColorString;
    return [UIColor cj_colorWithHexString:string alpha:0.3];
}

- (UIColor *)fontColor {
     NSString *string = Check_ValidString(self.fontColorString)? self.fontColorString : CJPayBtnFontColorString;
     return [UIColor cj_colorWithHexString:string alpha:1.0];
}

- (NSInteger)confirmButtonShape {
    if (!Check_ValidString(self.confirmButtonShapeStr)) {
        return 2;
    }
    
    NSInteger confirmButtonShapeValue = [self.confirmButtonShapeStr integerValue];
    return confirmButtonShapeValue;
}

- (UIColor *)amountColor {
    if (!Check_ValidString(self.amountColorStr)) {
        return [UIColor cj_161823ff];
    }
    
    return [UIColor cj_colorWithHexString:self.amountColorStr];
}

- (UIColor *)tradeNameColor {
    if (!Check_ValidString(self.tradeNameColorStr)) {
        return [UIColor cj_999999ff];
    }
    
    return [UIColor cj_colorWithHexString:self.tradeNameColorStr];
}

- (UIColor *)payTypeMarkColor {
    if (!Check_ValidString(self.payTypeMarkColorStr)) {
        return [UIColor cj_f85959ff];
    }
    
    return [UIColor cj_colorWithHexString:self.payTypeMarkColorStr];
}

- (NSInteger)payTypeMarkShape {
    if (!Check_ValidString(self.payTypeMarkShapeStr)) {
        return 2;
    }
    
    NSInteger payTypeMarkShape = [self.payTypeMarkShapeStr integerValue];
    return payTypeMarkShape;
}

- (NSString *)payTypeMarkStyle {
    if (!Check_ValidString(self.payTypeMarkStyleStr)) {
        return @"1";
    }
    
    return self.payTypeMarkStyleStr;
}

- (UIColor *)payTypeMsgColor {
    if (!Check_ValidString(self.payTypeMsgColorStr)) {
        return [UIColor cj_969ba5ff];
    }
    
    return [UIColor cj_colorWithHexString:self.payTypeMsgColorStr];
}

@end
