//
//  CJPayBizDYPayModel.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/11/7.
//

#import "CJPayBizDYPayModel.h"

@implementation CJPayBizDYPayModel

- (BOOL)isNeedQueryBizOrder {
    return  [self.jhResultPageStyle isEqualToString:@"1"] && Check_ValidString(self.intergratedTradeIdentify) && Check_ValidString(self.processStr);
}

@end
