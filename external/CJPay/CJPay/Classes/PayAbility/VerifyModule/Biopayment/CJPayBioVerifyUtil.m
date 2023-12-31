//
//  CJPayBioVerifyUtil.m
//  aweme_transferpay_opt
//
//  Created by shanghuaijun on 2023/6/3.
//

#import "CJPayBioVerifyUtil.h"
#import <LocalAuthentication/LocalAuthentication.h>

@implementation CJPayBioVerifyUtil

+ (NSString *)bioCNErrorMessageWithError:(NSError * _Nonnull)error {
    switch (error.code) {
        case LAErrorAuthenticationFailed: {
            return @"验证失败";
        }
        case LAErrorUserCancel:{
            return @"用户手动取消";
        }
        case LAErrorUserFallback:{
            return @"用户手动降级";
        }
        case LAErrorSystemCancel:{
            return @"被系统取消(如遇到来电,锁屏,按了Home键等)";
        }
        case LAErrorPasscodeNotSet:{
            return @"用户未设置密码";
        }
        case LAErrorAppCancel:{
            return @"当前软件被挂起并取消了授权(如App进入了后台等)";
        }
        case LAErrorInvalidContext:{
            return @"当前软件被挂起并取消了授权(LAContext对象无效)";
            
        }
        default:
            break;
    }
    
    if (@available(iOS 11.0, *)) {
        switch (error.code) {
            case LAErrorBiometryNotEnrolled:{
                return @"未注册生物信息";
            }
            case LAErrorBiometryNotAvailable:{
                return @"生物验证未授权（关闭或拒绝）";
            }
            case LAErrorBiometryLockout:{
                return @"生物验证已锁定";
            }
            default:
                break;
        }
    } else {
        switch (error.code) {
            case LAErrorBiometryNotEnrolled:{
                return @"未注册生物信息";
            }
            case LAErrorBiometryNotAvailable:{
                return @"生物验证未授权（关闭或拒绝）";
            }
            case LAErrorBiometryLockout:{
                return @"生物验证已锁定";
            }
            default:
                break;
        }
    }
    
    return @"未知错误";
}

@end
