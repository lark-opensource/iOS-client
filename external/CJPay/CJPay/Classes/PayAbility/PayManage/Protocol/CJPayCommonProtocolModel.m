//
//  CJPayCommonProtocolModel.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/5.
//

#import "CJPayCommonProtocolModel.h"

#import "UIFont+CJPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayThemeStyleManager.h"

@implementation CJPayCommonProtocolModel

// 合规模式下，只有后台显式控制隐藏才会隐藏勾选框，其他都会显示勾选框
- (CJPaySelectButtonPattern)selectPattern {
    if (_supportRiskControl) {
        if (Check_ValidString(_protocolCheckBoxStr) && [_protocolCheckBoxStr isEqualToString:@"0"]) {
            return CJPaySelectButtonPatternNone;
        } else {
            return CJPaySelectButtonPatternCheckBox;
        }
    } else {
        return _selectPattern;
    }
}

@end
