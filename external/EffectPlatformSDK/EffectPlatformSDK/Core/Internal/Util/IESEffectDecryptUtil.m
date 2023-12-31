//
//  IESEffectDecryptUtil.m
//  AAWELaunchOptimization-Pods
//
//  Created by pengzhenhuan on 2020/8/31.
//

#import "IESEffectDecryptUtil.h"
#import <EffectPlatformSDK/IESEffectDefines.h>
#import <EffectPlatformSDK/NSString+Crypto.h>
#import <EffectPlatformSDK/NSString+EffectPlatformUtils.h>
#import <EffectPlatformSDK/IESEffectConfig.h>
#import <EffectPlatformSDK/IESEffectLogger.h>

@implementation IESEffectDecryptUtil

+ (NSString *)decryptString:(NSString *)encryptString {
    static dispatch_once_t onceToken;
    static NSString *decryptKey = nil;
    dispatch_once(&onceToken, ^{
        NSString *deviceString = [@":" stringByAppendingString:[IESEffectConfig devicePlatform]];
        decryptKey = [[IESEffectPlatformSDKVersion stringByAppendingString:deviceString] ep_generateMD5Key];
        EPDebugLog(@"DecryptUtil: platform_sdk_version = %@|devicePlatform = %@|decryptKey = %@", IESEffectPlatformSDKVersion, [IESEffectConfig devicePlatform], decryptKey);
        IESEffectLogInfo(@"DecryptUtil: platform_sdk_version = %@|devicePlatform = %@|decryptKey = %@", IESEffectPlatformSDKVersion, [IESEffectConfig devicePlatform], decryptKey);
    });
    NSString *decryptResult = [encryptString ep_aes128CBCDecryptFromBase64WithKey:decryptKey iv:decryptKey];
    if (decryptResult.length <= 0) {
        IESEffectLogError(@"decrypt encryptString:%@ failed with parameters %@ and %@", encryptString, IESEffectPlatformSDKVersion, [IESEffectConfig devicePlatform]);
        [[IESEffectLogger logger] logEvent:@"effectplatform_decrypt_fail" params:@{@"content":encryptString,
                                                                                   @"platform_sdk_version":IESEffectPlatformSDKVersion,
                                                                                   @"device_platform":[IESEffectConfig devicePlatform]
            
        }];
    }
    return decryptResult;
}

+ (NSArray<NSString *> *)decryptArray:(NSArray<NSString *> *)encryptArray {
    NSMutableArray<NSString *> *decryptResults = [[NSMutableArray alloc] init];
    for (NSString *encryptString in encryptArray) {
        NSString *decryptResultString = [self decryptString:encryptString];
        if (decryptResultString) {
            [decryptResults addObject:decryptResultString];
        } else {
            return nil;
        }
    }
    return [decryptResults copy];
}

@end
