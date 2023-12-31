//
//  CJSDKParamConfig.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/29.
//

#import "CJSDKParamConfig.h"
#import "CJPaySDKMacro.h"

#pragma mark - CJSDKParamConfig
@interface CJSDKParamConfig()

@end

@implementation CJSDKParamConfig

+ (CJSDKParamConfig *)defaultConfig {
    CJSDKParamConfig *config = [[CJSDKParamConfig alloc]init];
    config.sdkName = @"CJPay";
    config.version = @"6.8.8"; // 2023-08-31
    config.settingsVersion = @"6.8.8.0";
    return config;
}
@end
