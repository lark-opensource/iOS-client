//
//  CJPayBindCardValidateManager.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/16.
//

#import "CJPayBindCardValidateManager.h"
#import "CJPayUIMacro.h"

@implementation CJPayBindCardValidateManager

// 校验身份证证件id(严格校验，16位和17位的身份证不可以过)提交表单时校验
+ (BOOL)isNormalIDCardNumExtremeValid:(NSString *)idNumStr {
    NSString *text = [idNumStr uppercaseString];
    NSRange xRange = [text rangeOfString:@"X"];
    if (text.length == 15) {
        return xRange.length == 0;
    } else if (text.length == 18) {
        if (xRange.length == 0) {
            return YES;
        } else if (xRange.location == text.length - 1 && xRange.length == 1) {
            return YES;
        }
        return NO;
    } else {
        return NO;
    }
}

// 校验姓名中是否只含有汉字、字母、空格以及·在中间
+ (BOOL)isNameValid:(NSString *)nameStr {
    NSError *error = nil;
    // 只能包含下面的字符
    NSString *pattern = @"^[\u4E00-\u9FBF\uF900-\uFAFF\u3400-\u4DBFA-Za-z\\s]+(·[\u4E00-\u9FBF\uF900-\uFAFF\u3400-\u4DBFA-Za-z]+)*$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    if (error) {
        return YES;
    }
    NSRange matchedRange = [regex rangeOfFirstMatchInString:nameStr options:0 range:NSMakeRange(0, nameStr.length)];
    if (matchedRange.location == 0 && matchedRange.length == nameStr.length) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)isContainSpecialCharacterInString:(NSString *)string {
    BOOL isContainSpecialCharacter = NO;
    NSString *nameStr = string;
        // 身份证实名时校验姓名是否没有特殊字符、英文、数字
    NSString *specialCharacterList =
    @"[＿`～＠＃＄％＾＆＊（）＋＝｜｛｝＇：；＼［］．＜＞／？！￥…×—「」【】『』‘”“。，、@_~!#$%^&*()+=|\\\\{}':;,\\[\\].<>/?’0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]|\\s+";
        
    for (int i=0; i<nameStr.length; i++) {
        if ([specialCharacterList containsString:[nameStr substringWithRange:NSMakeRange(i, 1)]]) {
            isContainSpecialCharacter = YES;
            break;
        }
    }
    
    
    return isContainSpecialCharacter;
}

@end
