// Copyright 2020 The Lynx Authors. All rights reserved.
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/IESEffectManager.h>
#include <memory>
#import "LynxKryptonEffect.h"

extern "C" int bef_effect_get_sdk_version(char *, const int);

@implementation LynxKryptonEffect (Demo)
+ (void)initEffectPlatformForDemoApp {
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    constexpr int32_t alloc_size = 1024;
    std::unique_ptr<char[]> version_buffer = std::make_unique<char[]>(alloc_size);
#if !TARGET_IPHONE_SIMULATOR
    bef_effect_get_sdk_version(version_buffer.get(), alloc_size);
#endif
    NSData *data =
        [[NSData alloc] initWithBase64EncodedString:@"aHR0cHM6Ly9lZmZlY3Quc25zc2RrLmNvbQ=="
                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];
    [EffectPlatform setDomain:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    [EffectPlatform startWithAccessKey:@"68d32050064f11e891efe7cc07299bc5"];
    [EffectPlatform setAppId:@"1128"];
    [EffectPlatform setOsVersion:[[UIDevice currentDevice] systemVersion]];
    [EffectPlatform setRegion:@"zh_CN"];
    [EffectPlatform setChannel:@"test"];
    [EffectPlatform setEffectSDKVersion:[NSString stringWithUTF8String:version_buffer.get()]];
    [EffectPlatform sharedInstance].enableNewEffectManager = YES;
    [[IESEffectManager manager] setUp];
  });
}
@end
