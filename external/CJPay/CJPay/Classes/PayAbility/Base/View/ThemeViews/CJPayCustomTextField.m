//
//  CJPayCustomTextField.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/11.
//

#import "CJPayCustomTextField.h"
#import "CJPayUIMacro.h"
#import "CJPayToast.h"

@interface CJPayCustomTextField() <UITextFieldDelegate>

@end

@implementation CJPayCustomTextField

#pragma mark - 初始化
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        self.keyboardType = UIKeyboardTypeNumberPad;
        self.locationIndex = 0;
        self.supportSeparate = NO;
    }
    return self;
}

- (NSString*)userInputContent {
    if (!self.supportSeparate) {
        return self.text;
    }
    NSString *text = self.text;
    NSMutableString *mutableText = [NSMutableString stringWithString:text];
    NSString *contentStr = [mutableText stringByReplacingOccurrencesOfString:@" " withString:@""];
    return contentStr;
}

#pragma mark - 光标frame
- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    CGRect originalRect = [super caretRectForPosition:position];
    originalRect.size.height = 20;
    originalRect.size.width = 2;
    originalRect.origin.y = (self.frame.size.height - 20) / 2;
    return originalRect;
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds {
    CGRect originalRect = [super clearButtonRectForBounds:bounds];
    CGFloat width = 18;
    originalRect.size.height = width;
    originalRect.size.width = width;
    originalRect.origin.y = (self.frame.size.height - width) / 2;
    originalRect.origin.x = (self.frame.size.width - width);
    return originalRect;
}

#pragma mark - textField代理
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (!self.supportSeparate) {
        return [self.textFieldDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
    }
    
    NSMutableString *inputStr = [[NSMutableString alloc] initWithString:CJString(string.uppercaseString)];
    NSString *inputNoSpaceStr = [inputStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (self.supportCharacterSet) {
        inputNoSpaceStr = [[inputNoSpaceStr componentsSeparatedByCharactersInSet:self.supportCharacterSet.invertedSet] componentsJoinedByString:@""];
        if (!Check_ValidString(inputNoSpaceStr) && Check_ValidString(inputStr)) {
            [CJToast toastText:CJPayLocalizedStr(@"输入内容不合法") inWindow:self.window];
            return NO;
        }
    }
   
    //分割处理之后的字符串
    NSString *dealString = [self changeStringWithOperateString:inputNoSpaceStr withOperateRange:range withOriginString:textField.text];
    textField.text = dealString;
    [self.textFieldDelegate textFieldContentChange];
    
    [self setSelectedRange:NSMakeRange(self.locationIndex, 0)];
    
    return NO;
}

- (BOOL)resignFirstResponder {
    return [super resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.textFieldDelegate textFieldBeginEdit];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self.textFieldDelegate textFieldEndEdit];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self.textFieldDelegate textFieldWillClear];
    return YES;
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
    CGRect originBounds = [super rightViewRectForBounds:bounds];
    if (self.textFieldDelegate && [self.textFieldDelegate respondsToSelector:@selector(textFieldRightViewRectForBounds:)]) {
        return [self.textFieldDelegate textFieldRightViewRectForBounds:originBounds];
    } else {
        return originBounds;
    }
}

#pragma mark - 设置光标

- (void) setSelectedRange:(NSRange) range
{
    UITextPosition* beginning = self.beginningOfDocument;
    
    UITextPosition* startPosition = [self positionFromPosition:beginning offset:range.location];
    UITextPosition* endPosition = [self positionFromPosition:beginning offset:range.location + range.length];
    UITextRange* selectionRange = [self textRangeFromPosition:startPosition toPosition:endPosition];
    //设置光标位置,放到下一个runloop才会生效
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setSelectedTextRange:selectionRange];
    });
}


#pragma mark - 核心处理方法

- (NSString*)changeStringWithOperateString:(NSString*)string withOperateRange:(NSRange)range withOriginString:(NSString*)originString {
    
    self.locationIndex = range.location;
    
    //原始字符串
    NSMutableString *originStr = [NSMutableString stringWithString:originString];
    //截取操作的位置之前的字符串
    NSMutableString *subStr = [NSMutableString stringWithString:[originStr substringToIndex:range.location]];
    //光标前的字符串 剔除空格符号
    NSString *subNoSpace = [subStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //得到操作处前面 空格的总数目
    NSInteger originSpaceCount = subStr.length - subNoSpace.length;
    
    if ([string isEqualToString:@""]) {
        //删除字符
        NSString *deleteStr = [originStr substringWithRange:range];
        if (deleteStr && [deleteStr isEqualToString:@" "]) {
            // 从字符串中间删除空格
            [originStr deleteCharactersInRange:NSMakeRange(range.location - 1, 1)];
        } else {
            [originStr deleteCharactersInRange:range];
        }
    } else {
        
        if (range.length == 0) {
            // 插入字符
            [originStr insertString:string atIndex:range.location];
            if (![self isNewStrSatisfyLimit:originStr]) {
                if (string.length > 1) {
                    [CJToast toastText:CJPayLocalizedStr(@"输入内容不合法") inWindow:self.window];
                }
                return originString;
            }
            self.locationIndex += string.length;
        } else {
            // 替换字符
            [originStr replaceCharactersInRange:range withString:string];
            if (![self isNewStrSatisfyLimit:originStr]) {
                if (string.length > 1) {
                    [CJToast toastText:CJPayLocalizedStr(@"输入内容不合法") inWindow:self.window];
                }
                return originString;
            }
            self.locationIndex += string.length;
        }
    
    }
    
    NSString *originNoSpaceString = [originStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //原始字符串，全部剔除空格
    NSMutableString *newString = [NSMutableString stringWithString:originNoSpaceString];
    
    //均等分割
    if (self.separateCount > 0) {
        for (NSInteger i = newString.length; i > 0; i--) {
            
            if (i % self.separateCount == 0) {
                //插入空格符
                if (i != newString.length) {
                    [newString insertString:@" " atIndex:i];
                }
            }
        }
        
    }
    
    //自定义分割
    if (self.separateArray.count > 0) {
        //应该操作的index
        NSMutableArray *indexArray = [NSMutableArray array];
        NSInteger currentIndex = 0;
        for (int i = 0; i< self.separateArray.count; i++) {
            id object = self.separateArray[i];
            if ([object isKindOfClass:[NSString class]]) {
                NSInteger count = [object integerValue];
                currentIndex += count;
                NSNumber *indexNumber = [NSNumber numberWithInteger:currentIndex];
                [indexArray addObject:indexNumber];
            }
        }
        
        //倒序插入空格符
        for (NSInteger j = indexArray.count-1; j >=0 ; j--) {
            NSNumber *indexObject = indexArray[j];
            NSInteger index = [indexObject integerValue];
            //不可越界
            if (index < newString.length) {
                [newString insertString:@" " atIndex:index];
            }
        }
    }
    
    NSString *newSubString;
    if (self.locationIndex > newString.length) {
        //如果是删除最后一位数字，且数字的左侧为空格时，防止越界
        newSubString = [NSString stringWithFormat:@"%@",newString];
        self.locationIndex -= 1 ;
    }else{
        //添加字符后，光标的左侧文本
        newSubString = [newString substringToIndex:self.locationIndex];
    }
    
    //光标左侧文本
    NSMutableString *newSubMutableString = [NSMutableString stringWithString:newSubString];
    //将操作后的左侧文本 剔除空格
    NSString *newNoSpaceString = [newSubMutableString stringByReplacingOccurrencesOfString:@" " withString:@""];
    //操作后的左侧文本，空格的数量
    NSInteger newSpaceCount = newSubString.length - newNoSpaceString.length;
    //根据操作前后空格数量的变化修正光标的位置
    if (originSpaceCount == newSpaceCount) {
        if ([string isEqualToString:@""]) {
            //删除的时候，如果删了该数字后，左侧为空格，则需要光标再左移1位
            if (range.location > 0) {
                NSString *originSubS = [originStr  substringWithRange:NSMakeRange(range.location-1, 1)];
                if ([originSubS isEqualToString:@" "]) {
                    self.locationIndex -= 1;
                }
            }
        }
    } else {
        //如果操作前的空格数量不等于操作后的空格数量，说明新增文本前，又添加了空格，需要将光标右移
        NSInteger spaceDelta = [self getSpaceDelta:originString newStr:newString];
        if (![string isEqualToString:@""]) {
            self.locationIndex += spaceDelta;
        }
    }
    
    return newString;
}

- (BOOL)isNewStrSatisfyLimit:(NSString *)str {
    NSMutableString *newStr = [[NSMutableString alloc] initWithString:CJString(str)];
    NSString *newStrNoSpace = [newStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (newStrNoSpace.length > self.limitCount) {
        return NO;
    }
    return YES;
}

// 获取输入框改变前后的空格差异
- (NSInteger)getSpaceDelta:(NSString *)oldStr
                    newStr:(NSString *)newStr {
    NSMutableString *oldMutableStr = [NSMutableString stringWithString:oldStr];
    NSMutableString *newMutableStr = [NSMutableString stringWithString:newStr];
    NSInteger oldSpaceCount = oldMutableStr.length - [oldMutableStr stringByReplacingOccurrencesOfString:@" " withString:@""].length;
    NSInteger newSpaceCount = newMutableStr.length - [newMutableStr stringByReplacingOccurrencesOfString:@" " withString:@""].length;
    NSInteger spaceDelta = newSpaceCount >= oldSpaceCount ? newSpaceCount - oldSpaceCount : oldSpaceCount - newSpaceCount;
    
    return spaceDelta;
}


@end
