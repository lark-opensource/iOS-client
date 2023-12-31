//
//  CJPayAmountTextField.m
//  CJPay
//
//  Created by 尚怀军 on 2020/3/10.
//

#import "CJPayAmountTextField.h"

@implementation CJPayAmountTextField

#pragma mark - 光标frame
- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    CGRect originalRect = [super caretRectForPosition:position];
    originalRect.origin.y = 4;
    return originalRect;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:))//禁止粘贴
        return NO;
    if (action == @selector(select:))// 禁止选择
        return NO;
    if (action == @selector(selectAll:))// 禁止全选
        return NO;
    if (action == @selector(cut:))// 禁止全选
        return NO;
    return [super canPerformAction:action withSender:sender];
}

#pragma mark - tapGesture

- (void)tapClick {
    if (self.amountTextFieldTapGestureClickBlock && !self.isFirstResponder) {
        self.amountTextFieldTapGestureClickBlock();
    }
    [self becomeFirstResponder];
}

@end
