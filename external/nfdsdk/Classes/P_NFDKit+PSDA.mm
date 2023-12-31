//
//  P_NFDKit+PSDA.m
//  nfdsdk
//
//  Created by lujunhui.2nd on 2023/8/25.
//

#import <Foundation/Foundation.h>
#import <P_NFDKit+PSDA.h>

@implementation NFDKit (PSDA)

#if __has_include(<LarkSensitivityControl/LarkSensitivityControl-Swift.h>)
static Token* p_bleScanPSDAToken = nullptr;
+ (Token *)p_getBleScanPSDAToken {
    return p_bleScanPSDAToken;
}
+ (void)p_setBleScanPSDAToken:(nullable Token *)newValue {
    // 不可覆盖但可清空
    if (p_bleScanPSDAToken != nullptr && newValue != nullptr) {
        return;
    }
    p_bleScanPSDAToken = newValue;
}

#endif

@end
