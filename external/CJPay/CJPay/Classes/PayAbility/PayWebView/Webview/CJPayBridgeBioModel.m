//
//  CJPayBridgeBioModel.m
//  CJPay
//
//  Created by liyu on 2020/2/27.
//

#import "CJPayBridgeBioModel.h"

@implementation CJPayBioCheckSateModel

- (NSDictionary *)toJson {
    return @{ @"show": _isShow ? @"1" : @"0",
              @"open": _isOPen ? @"1" : @"0",
              @"msg" : !_msg ? @"" : _msg,
              @"bioType" : !_bioType ? @"" : _bioType,
              @"style": @(_style)
              };
}

@end

@implementation CJPayBioSwitchStateModel

- (NSDictionary *)toJson {
    return @{
             @"code": !_code ? @"" : _code,
             @"bioPaymentState": _isOpen ? @"1" : @"0",
             @"msg": !_msg ? @"" : _msg,
             @"style": @(_style)
             };
}

@end
