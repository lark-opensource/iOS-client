//
//  CJPayNormalIDTextFieldConfigration.m
//  CJPay2
//
//  Created by 王新华 on 4/12/20.
//

#import "CJPayNormalIDTextFieldConfigration.h"
#import "CJPayUIMacro.h"

@implementation CJPayNormalIDTextFieldConfigration

- (void)bindTextFieldContainer:(CJPayCustomTextFieldContainer *)tfContainer {
    [super bindTextFieldContainer:tfContainer];
    tfContainer.keyBoardType = CJPayKeyBoardTypeCustomXEnable;
    tfContainer.infoContentStr = @"";
    tfContainer.textField.supportSeparate = YES;
    self.separateArray = @[@"6",@"8",@"4"];
    self.limitCount = 18;
    self.supportCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789xX"];
}

- (BOOL)contentISValid {
    NSString *idNumStr = self.userInputContent;
    NSString *text = [idNumStr uppercaseString];
    NSRange xRange = [text rangeOfString:@"X"];
    if (text.length == 15) {
        return xRange.length == 0;
    } else if (text.length == 18) {
        NSString *allowContextRegexPattern = @"^[1-9][0-9]{5}(19|20)[0-9]{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)[0-9]{3}[0-9Xx]$";
        NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:allowContextRegexPattern options:NSRegularExpressionCaseInsensitive error:nil];
        if ([regularExp matchesInString:idNumStr options:NSMatchingReportCompletion range:NSMakeRange(0, idNumStr.length)].count >= 1) {
            if ([self p_isValidThe18CheckBit]) {
                return YES;
            }
        }
        [self.tfContainer updateTips:CJPayLocalizedStr(@"身份证号输入错误，请检查")];
        return NO;
    } else {
        return NO;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    return [super textField:textField shouldChangeCharactersInRange:range replacementString:string];
}

- (void)textFieldEndEdit {
    self.isLegal = YES;
    self.errorMsg = @"";
    // errorMsg 类型，1:身份证位数错误、2:身份证年龄错误、3:身份证校验位错误、4:身份证输入错误
    if (![self contentISValid] && ![self.userInputContent isEqualToString:@""]) {
        if (self.userInputContent.length == 15 || self.userInputContent.length == 18) {
            [self.tfContainer updateTips:CJPayLocalizedStr(@"身份证号输入错误，请检查")];
            self.errorMsg = @"4";//@"身份证输入错误";
            [self p_updateExactErrorMsg];
        } else {
            self.errorMsg = @"1";//@"身份证位数错误";
            [self.tfContainer updateTips:CJPayLocalizedStr(@"身份证位数错误，请检查")];
        }
        self.isLegal = NO;
    }
    
    // 上传埋点
    [super textFieldEndEdit];
}

// 更新更准确的身份证号校验错误信息
- (void)p_updateExactErrorMsg {
    if (self.userInputContent.length == 18) {
        // 如果是校验位错误、年龄错误，更新一下 errorMsg
        NSRange theYearRange = NSMakeRange(6,2);
        NSString *yearString = [self.userInputContent substringWithRange:theYearRange];
        if (![yearString isEqualToString:@"19"] && ![yearString isEqualToString:@"20"]) {
            self.errorMsg = @"2";//@"身份证年龄错误";
            return;
        }
        
        if (![self p_isValidThe18CheckBit]) {
            self.errorMsg = @"3";//@"身份证校验位错误";
        }
    }
}

// 判断校验位是否正确
- (BOOL)p_isValidThe18CheckBit {
    NSString *identityString = self.userInputContent;
    if(identityString.length != 18) {
        return NO;
    }
    
    //加权因子存储
    NSArray *idCardWeightArray = @[@"7", @"9", @"10", @"5", @"8", @"4", @"2", @"1", @"6", @"3", @"7", @"9", @"10", @"5", @"8", @"4", @"2"];
    
    //除11位后的余数
    NSArray *idCardArray = @[@"1", @"0", @"10", @"9", @"8", @"7", @"6", @"5", @"4", @"3", @"2"];
    
    //用来保存前17位各自乖以加权因子后的总和
    NSInteger weightSum =0;
    for(int i = 0; i < 17; i++) {
        NSInteger subIndex = [[identityString substringWithRange:NSMakeRange(i,1)] integerValue];
        NSInteger weightIndex = [[idCardWeightArray objectAtIndex:i]integerValue];
        weightSum += subIndex * weightIndex;
    }

    //计算出校验码所在数组的位置
    NSInteger mod = weightSum % 11;
    
    //得到最后一位身份证号码
    NSString *idCardLastNumber = [identityString substringWithRange:NSMakeRange(17,1)];
    
    if (mod == 2) { //等于2，说明校验码是10，身份证号码最后一位是X
        if(![idCardLastNumber isEqualToString:@"X"] && ![idCardLastNumber isEqualToString:@"x"]) {
            return NO;
        }
    } else {
        //用计算出的验证码与最后一位身份证号码匹配，如果一致，说明通过，否则是无效的身份证号码
        if( ![idCardLastNumber isEqualToString:[idCardArray objectAtIndex:mod]] ) {
            return NO;
        }
    }
    
    return YES;
}

@end
