//
//  CJPaySeparateTextFieldConfigration.m
//  CJPay
//
//  Created by 王新华 on 4/12/20.
//

#import "CJPaySeparateTextFieldConfigration.h"
#import "CJPayUIMacro.h"
#import "CJPayToast.h"
#import "CJPayCustomTextField.h"

@interface CJPaySeparateTextFieldConfigration()

@property (nonatomic, assign) NSInteger locationIndex;
@property (nonatomic, strong) CJPayCustomTextField *separator;


@end

@implementation CJPaySeparateTextFieldConfigration

- (void)bindTextFieldContainer:(CJPayCustomTextFieldContainer *)tfContainer {
    [super bindTextFieldContainer:tfContainer];
    self.locationIndex = 0;
    self.separateCount = 0;
    self.limitCount = 21;
    self.supportCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    self.separator.locationIndex = 0;
    self.separator.separateCount = 0;
    self.separator.limitCount = 21;
    self.separator.supportCharacterSet = self.supportCharacterSet;
}

- (NSString*)userInputContent {
    NSString *text = self.tfContainer.textField.text;
    NSMutableString *mutableText = [NSMutableString stringWithString:text];
    NSString *contentStr = [mutableText stringByReplacingOccurrencesOfString:@" " withString:@""];
    return contentStr;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (self.disableSeparate) {
        return YES;
    }
    
    NSMutableString *inputStr = [[NSMutableString alloc] initWithString:CJString(string.uppercaseString)];
     NSString *inputNoSpaceStr = [inputStr stringByReplacingOccurrencesOfString:@" " withString:@""];
     if (self.supportCharacterSet) {
         NSRange range = [inputNoSpaceStr rangeOfCharacterFromSet:self.supportCharacterSet.invertedSet];
         if (![inputNoSpaceStr isEqualToString:@""] && range.length > 0) {
             if (inputNoSpaceStr.length > 1) {
                 [CJToast toastText:CJPayLocalizedStr(@"粘贴内容不合法") inWindow:textField.window];
             }
             return NO;
         }
     }
    
     //分割处理之后的字符串
    NSString *dealString = [self.separator changeStringWithOperateString:inputNoSpaceStr
                                                        withOperateRange:range
                                                        withOriginString:textField.text];
     textField.text = dealString;
    
    if (self.tfContainer.delegate && [self.tfContainer.delegate respondsToSelector:@selector(textFieldContentChange:textContainer:)]) {
        [self.tfContainer.delegate textFieldContentChange:self.tfContainer.textField.userInputContent textContainer:self.tfContainer];
    }
     
     [self setSelectedRange:NSMakeRange(self.separator.locationIndex, 0)];
     
     return NO;
}

- (CJPayCustomTextField *)separator {
    if (!_separator) {
        _separator = [[CJPayCustomTextField alloc] init];
    }
    return _separator;
}

@end
