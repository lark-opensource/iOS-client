//
//  CJPayHKIDTextFieldConfigration.m
//  CJPay
//
//  Created by 王新华 on 4/12/20.
//

#import "CJPayHKIDTextFieldConfigration.h"
#import "CJPayUIMacro.h"
#import "CJPayToast.h"

@implementation CJPayHKIDTextFieldConfigration

- (void)bindTextFieldContainer:(CJPayCustomTextFieldContainer *)tfContainer {
    [super bindTextFieldContainer:tfContainer];
    tfContainer.keyBoardType = CJPayKeyBoardTypeSystomDefault;
    tfContainer.textField.supportSeparate = NO;
    tfContainer.infoContentStr = CJPayLocalizedStr(@"请输入《港澳居民来往内地通行证》号码，字母+ 8或10 位数字，例如，H60391234");
}

- (BOOL)contentISValid {
    NSString *idNumStr = self.userInputContent;
    if (!idNumStr.length) {
        return YES;
    }
    
    NSError *error = nil;
    NSString *pattern = @"^[H|M|h|m][0-9]{0,10}$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    if (error) {
        return YES;
    }
    NSRange matchedRange = [regex rangeOfFirstMatchInString:idNumStr options:0 range:NSMakeRange(0, idNumStr.length)];
    if (matchedRange.location != NSNotFound) {
        if (idNumStr.length == 9 || idNumStr.length == 11) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *targetContent = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSString *allowContextRegexPattern = @"^[H|M][0-9]{0,10}$";
    NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:allowContextRegexPattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    // 粘贴
    if (string.length > 1) {
        NSString *content = [targetContent stringByReplacingOccurrencesOfString:@" " withString:@""];

        NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"0123456789HM"];
        
        NSString *res = [[content componentsSeparatedByCharactersInSet:set.invertedSet] componentsJoinedByString:@""];
        NSInteger cursorLocation = range.location + res.length - textField.text.length + range.length;
        targetContent = [res substringToIndex:MIN(res.length, 11)];
        if ([regularExp matchesInString:targetContent options:NSMatchingReportCompletion range:NSMakeRange(0, targetContent.length)].count >= 1) {
            textField.text = targetContent;
            [self setSelectedRange:NSMakeRange((cursorLocation > 11)?11:cursorLocation, 0)];
        } else {
            [CJToast toastText:CJPayLocalizedStr(@"粘贴内容不合法") inWindow:textField.window];
        }
        return NO;
    }
    
    if (targetContent.length > 11) {
        return NO;
    }
    
    if (Check_ValidString(targetContent) && [regularExp matchesInString:targetContent options:NSMatchingReportCompletion range:NSMakeRange(0, targetContent.length)].count < 1) {
        [self.tfContainer updateTips:CJPayLocalizedStr(@"证件号输入错误，请检查")];
    }
    
    return YES;
}

- (void)textFieldEndEdit {
    self.isLegal = YES;
    if ( ![self p_isValidLength] || ![self contentISValid] ) {
        [self.tfContainer updateTips:CJPayLocalizedStr(@"证件号输入错误，请检查")];
        self.errorMsg = @"5";//@"证件号输入错误";
        self.isLegal = NO;
    }
    
    // 上传埋点
    [super textFieldEndEdit];
}

- (BOOL)p_isValidLength {
    NSUInteger contentLength = self.userInputContent.length;
    if (contentLength == 0 ||
        contentLength == 9 ||
        contentLength == 11) {
        return YES;
    }
    
    return NO;
}

@end
