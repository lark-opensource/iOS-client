//
//  CJPayCustomTextFieldConfigration.m
//  CJPay
//
//  Created by 王新华 on 4/12/20.
//

#import "CJPayCustomTextFieldConfigration.h"
#import "CJPayUIMacro.h"

@implementation CJPayCustomTextFieldConfigration

- (void)bindTextFieldContainer:(CJPayCustomTextFieldContainer *)tfContainer {
    self.tfContainer = tfContainer;
    tfContainer.keyBoardType = CJPayKeyBoardTypeSystomDefault;
}

- (NSString *)userInputContent {
    return self.tfContainer.textField.text;
}

- (BOOL)contentISValid {
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (void)textFieldBeginEdit {}

- (void)textFieldEndEdit {
    // 上传埋点用 block
    CJ_CALL_BLOCK(self.textFieldEndEditCompletionBlock, self.isLegal);
}

- (void)textFieldWillClear {}
- (void)textFieldContentChange {}

#pragma mark - 设置光标

- (void)setSelectedRange:(NSRange) range
{
    UITextPosition* beginning = self.tfContainer.textField.beginningOfDocument;
    
    UITextPosition* startPosition = [self.tfContainer.textField positionFromPosition:beginning offset:range.location];
    UITextPosition* endPosition = [self.tfContainer.textField positionFromPosition:beginning offset:range.location + range.length];
    UITextRange* selectionRange = [self.tfContainer.textField textRangeFromPosition:startPosition toPosition:endPosition];
    //设置光标位置,放到下一个runloop才会生效
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tfContainer.textField setSelectedTextRange:selectionRange];
    });
}

@end
