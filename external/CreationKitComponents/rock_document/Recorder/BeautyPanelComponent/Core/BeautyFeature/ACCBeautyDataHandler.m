//
//  ACCBeautyDataHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/6/2.
//

#import "ACCBeautyDataHandler.h"
#import "ACCBeautyComponentConfigProtocol.h"
#import "ACCBeautyConfigKeyDefines.h"

@interface ACCBeautyDataHandler()

@property (nonatomic, strong) id<ACCBeautyComponentConfigProtocol> beautyConfig;

@end

@implementation ACCBeautyDataHandler

IESAutoInject(ACCBaseServiceProvider(), beautyConfig, ACCBeautyComponentConfigProtocol)

- (NSInteger)currentABGroup {
    return ACCConfigInt(kConfigInt_beauty_effect_composer_group);
}

- (BOOL)filterBeautyWithCategoryWrapper:(id)categoryWrapper {
    BOOL availableForCurrentProduct = [self.beautyConfig availableFilterBeautyWithCategoryWrapper:categoryWrapper];
    return availableForCurrentProduct;
}

- (BOOL)filterBeautyWithEffectWrapper:(nonnull AWEComposerBeautyEffectWrapper *)effectWrapper {
    if (!ACCConfigBool(kConfigBool_enable_advanced_composer)) {
        return ![effectWrapper isEffectSet];
    }
    return YES;
}


@end
