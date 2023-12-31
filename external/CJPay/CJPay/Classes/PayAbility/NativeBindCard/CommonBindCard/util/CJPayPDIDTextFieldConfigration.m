//
//  CJPayPDIDTextFieldConfigration.m
//  Pods
//
//  Created by renqiang on 2020/8/3.
//

#import "CJPayPDIDTextFieldConfigration.h"
#import "CJPayBindCardChooseIDTypeCell.h"
#import "CJPayUIMacro.h"

@implementation CJPayPDIDTextFieldConfigration

- (void)bindTextFieldContainer:(CJPayCustomTextFieldContainer *)tfContainer {
    [super bindTextFieldContainer:tfContainer];
    tfContainer.keyBoardType = CJPayKeyBoardTypeSystomDefault;
    tfContainer.textField.supportSeparate = NO;
    tfContainer.infoContentStr = CJPayLocalizedStr(@"护照号码");
}

- (BOOL)contentISValid {
    NSString *idNumStr = self.userInputContent;
    NSError *error = nil;
    NSString *pattern = @"^[A-Z0-9]{0,9}$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    if (error) {
        return YES;
    }
    NSRange matchedRange = [regex rangeOfFirstMatchInString:idNumStr options:0 range:NSMakeRange(0, idNumStr.length)];
    if (matchedRange.location != NSNotFound) {
        return YES;
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *targetContent = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSString *allowContextRegexPattern = @"^[A-Z0-9]{0,9}$";
    NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:allowContextRegexPattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    if (string.length > 1) {
        NSString *content = [targetContent stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSMutableCharacterSet *set = [NSMutableCharacterSet letterCharacterSet];
        [set formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]];
        
        NSString *res = [[content componentsSeparatedByCharactersInSet:set.invertedSet] componentsJoinedByString:@""];
        NSUInteger cursorLocation = range.location + res.length - textField.text.length + range.length;
        
        targetContent = [[res substringToIndex:MIN(res.length, 9)] uppercaseString];
        if ([regularExp matchesInString:targetContent options:NSMatchingReportCompletion range:NSMakeRange(0, targetContent.length)].count >= 1) {
            textField.text = targetContent;
            [self setSelectedRange:NSMakeRange((cursorLocation > 9)?9:cursorLocation, 0)];
        }
        return NO;
    }
    if (targetContent.length > 9) {
        return NO;
    }
    
    if (self.tfContainer.delegate && [self.tfContainer.delegate respondsToSelector:@selector(textFieldContentChange:textContainer:)]) {
        [self.tfContainer.delegate textFieldContentChange:self.tfContainer.textField.userInputContent textContainer:self.tfContainer];
    }
    
    if (Check_ValidString(targetContent) && [regularExp matchesInString:targetContent options:NSMatchingReportCompletion range:NSMakeRange(0, targetContent.length)].count < 1) {
        [self.tfContainer updateTips:CJPayLocalizedStr(@"请输入正确的证件号码")];
    }
    return YES;
}

- (void)textFieldEndEdit {
    self.isLegal = YES;
    if (![self contentISValid] && ![self.userInputContent isEqualToString:@""]) {
        [self.tfContainer updateTips:CJPayLocalizedStr(@"请输入正确的证件号码")];
        self.isLegal = NO;
        self.errorMsg = @"5";//@"证件号输入错误";
    }
    
    // 上传埋点
    [super textFieldEndEdit];
}

@end
