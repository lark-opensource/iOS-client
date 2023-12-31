//
//  CJPayHKRPTextFieldConfigration.m
//  Pods
//
//  Created by bytedance on 2021/11/8.
//

#import "CJPayHKRPTextFieldConfigration.h"
#import "CJPayUIMacro.h"
#import "CJPayToast.h"

@implementation CJPayHKRPTextFieldConfigration

- (void)bindTextFieldContainer:(CJPayCustomTextFieldContainer *)tfContainer {
    [super bindTextFieldContainer:tfContainer];
    tfContainer.keyBoardType = CJPayKeyBoardTypeCustomNumOnly;
    self.separateArray = @[@"6",@"8",@"4"];
    tfContainer.infoContentStr = @"";
}

- (BOOL)contentISValid {
    NSString *idNumStr = self.userInputContent;
    NSError *error = nil;
    NSString *pattern = @"^[8][12]0000([0-9]{12})$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    if (error) {
        return YES;
    }
    NSRange matchedRang = [regex rangeOfFirstMatchInString:idNumStr options:0 range:NSMakeRange(0, idNumStr.length)];
    if (matchedRang.location != NSNotFound) {
        return YES;
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *targetContent = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSString *allowContextRegexPattern = @"^8[12]0000([0-9]{0,12})$";
    NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:allowContextRegexPattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    if (string.length > 1) {
        NSString *content = [targetContent stringByReplacingOccurrencesOfString:@" " withString:@""];

        NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        
        NSString *res = [[content componentsSeparatedByCharactersInSet:set.invertedSet] componentsJoinedByString:@""];
        NSUInteger cursorLocation = range.location + res.length - textField.text.length + range.length;
        targetContent = [res substringToIndex:MIN(res.length, 18)];
        if ([regularExp matchesInString:targetContent options:NSMatchingReportCompletion range:NSMakeRange(0, targetContent.length)].count >= 1) {
            textField.text = targetContent;
            [self setSelectedRange:NSMakeRange((cursorLocation > 18) ? 18 : cursorLocation, 0)];
        } else {
            [CJToast toastText:@"粘贴内容不合法" inWindow:textField.window];
        }
        return NO;
    }
     
    if (targetContent.length > 18) {
        return NO;
    }
    
    if (Check_ValidString(targetContent) && targetContent.length >= 6 && [regularExp matchesInString:targetContent options:NSMatchingReportCompletion range:NSMakeRange(0, targetContent.length)].count < 1) {
        [self.tfContainer updateTips:CJPayLocalizedStr(@"请输入正确的证件号码")];
    }
    return YES;
}

- (void)textFieldEndEdit {
    self.isLegal = YES;
    if (![self contentISValid] && ![self.userInputContent isEqualToString:@""]) {
        [self.tfContainer updateTips:CJPayLocalizedStr(@"请输入正确的证件号码")];
        self.errorMsg = @"5";//@"证件号输入错误";
        self.isLegal = NO;
    }
    
    // 上传埋点
    [super textFieldEndEdit];
}

@end
