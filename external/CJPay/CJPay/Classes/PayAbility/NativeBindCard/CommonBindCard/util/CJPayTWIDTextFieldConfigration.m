//
//  CJPayTWIDTextFieldConfigration.m
//  CJPay
//
//  Created by 王新华 on 4/12/20.
//

#import "CJPayTWIDTextFieldConfigration.h"
#import "CJPayBindCardChooseIDTypeCell.h"
#import "CJPayUIMacro.h"
#import "CJPayToast.h"

@implementation CJPayTWIDTextFieldConfigration

- (void)bindTextFieldContainer:(CJPayCustomTextFieldContainer *)tfContainer {
    [super bindTextFieldContainer:tfContainer];
    tfContainer.keyBoardType = CJPayKeyBoardTypeCustomNumOnly;
    tfContainer.textField.supportSeparate = NO;
    tfContainer.infoContentStr = CJPayLocalizedStr(@"请输入《台湾居民来往大陆通行证》号码前8位数字，例如，00997305");
}

- (BOOL)contentISValid {
    NSString *idNumStr = self.userInputContent;
    NSError *error = nil;
    NSString *pattern = @"^[0-9]{0,8}$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    if (error) {
        return YES;
    }
    NSRange matchedRange = [regex rangeOfFirstMatchInString:idNumStr options:0 range:NSMakeRange(0, idNumStr.length)];
    if (matchedRange.location != NSNotFound) {
        if (idNumStr.length == 8) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *targetContent = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSString *allowContextRegexPattern = @"^[0-9]{0,8}$";
    NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:allowContextRegexPattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    if (string.length > 1) {
        NSString *content = [targetContent stringByReplacingOccurrencesOfString:@" " withString:@""];

        NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        
        NSString *res = [[content componentsSeparatedByCharactersInSet:set.invertedSet] componentsJoinedByString:@""];
        NSUInteger cursorLocation = range.location + res.length - textField.text.length + range.length;
        targetContent = [res substringToIndex:MIN(res.length, 8)];
        if ([regularExp matchesInString:targetContent options:NSMatchingReportCompletion range:NSMakeRange(0, targetContent.length)].count >= 1) {
            textField.text = targetContent;
            [self setSelectedRange:NSMakeRange((cursorLocation > 8)?8:cursorLocation, 0)];
        } else {
            [CJToast toastText:@"粘贴内容不合法" inWindow:textField.window];
        }
        return NO;
    }
     
    if (targetContent.length > 8) {
        return NO;
    }
    
    if (Check_ValidString(targetContent) && [regularExp matchesInString:targetContent options:NSMatchingReportCompletion range:NSMakeRange(0, targetContent.length)].count < 1) {
        [self.tfContainer updateTips:CJPayLocalizedStr(@"证件号输入错误，请检查")];
    }
    return YES;
}

- (void)textFieldEndEdit {
    self.isLegal = YES;
    if (self.userInputContent.length == 0) {
        // 空内容，不展示错误提示, do nothing
    } else if (self.userInputContent.length == 8 && [self contentISValid]) {
        // 内容长度和规则都符合，不展示错误提示do nothing
    } else {
        [self.tfContainer updateTips:CJPayLocalizedStr(@"证件号输入错误，请检查")];
//        self.errorMsg = @"证件号输入错误";
        self.errorMsg = @"5";//@"证件号输入错误";
        self.isLegal = NO;
    }
    
    // 上传埋点
    [super textFieldEndEdit];
}

@end
