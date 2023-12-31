//
//  MODModuleConfig.m
//  Modeo
//
//  Created by liyingpeng on 2020/12/30.
//

#import "MODModuleConfig.h"
#import <CameraClient/ACCLocationProtocol.h>
#import <CameraClient/ACCPOIServiceProtocol.h>
#import <EffectPlatformSDK/EffectPlatform.h>

@implementation MODModuleConfig

- (NSString *)effectRequestDomainString {
    // TODO: 关注 海外配置
    return @"https://effect.snssdk.com";
}

- (NSString *)effectPlatformAccessKey {
    return @"a03655506ea411ecbd816989d6147891";
}

- (BOOL)shouldEffectSetPoiParameters {
    return YES;
}

- (void)effectDealWithRegionDidChange {
    
}

- (void)configureExtraInfoForEffectPlatform
{
    [EffectPlatform setExtraPerRequestNetworkParametersBlock:^NSDictionary *{
        return @{
            @"city_code" : [ACCLocation() currentSelectedCityCode] ?: @""
        };
    }];
}

- (BOOL)shouldUploadServiceSetOptimizationPatameter {
    return NO;
}

- (NSString *)routerTitleUserDisplayName:(id)user {
    return @"";
}

- (BOOL)needCheckLoginStatusWhenStartRecording {
    return YES;
}

- (BOOL)shouldTitleColorUseDefaultConfigColor {
    return NO;
}

- (BOOL)disableFilterEffectWhenUseNormalFilter {
    return NO;
}

- (BOOL)useBoldTextForCellTitle
{
    return NO;
}

- (BOOL)allowCommerceChallenge
{
    return NO;
}

- (BOOL)useDefaultFormatNumberPolicy {
    return YES;
}

- (nullable NSDictionary *)effectPlatformExtraCustomParameters {
    return nil;
}


- (nullable NSDictionary * _Nonnull (^)(void))effectPlatformIOPParametersBlock {
    return nil;
}

@end
