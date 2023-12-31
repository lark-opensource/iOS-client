//
//  CJPayNameModel.m
//  CJPay
//
//  Created by 王新华 on 2018/12/26.
//

#import "CJPayNameModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayNameModel

- (NSString *)payName {
    if (_payName == nil || _payName.length < 1) {
        return CJPayLocalizedStr(@"支付");
    }
    return _payName;
}

@end
