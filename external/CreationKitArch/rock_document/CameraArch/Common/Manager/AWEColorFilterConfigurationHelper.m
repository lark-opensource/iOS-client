//
//  AWEColorFilterConfigurationHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/9/15.
//

#import "AWEColorFilterConfigurationHelper.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

// AWEColorFilterConfigurationHelper
NSString *const AWEColorFilterCaptureConfigurationKey = @"kAWEColorFilterCaptureConfigurationKey";
NSString *const AWEColorFilterEditorConfigurationKey = @"kAWEColorFilterEditorConfigurationKey";
NSString *const AWEColorFilterMvConfigurationKey = @"kAWEColorFilterMvConfigurationKey";
NSString *const AWEColorFilterPhotoConfigurationKey = @"kAWEColorFilterPhotoConfigurationKey";
NSString *const AWEColorFilterStoryConfigurationKey = @"kAWEColorFilterPhotoConfigurationKey";

@interface AWEColorFilterConfigurationHelper ()

@property (nonatomic, strong) NSMutableDictionary *ratioMapForBeautifyItems;
@property (nonatomic, assign) AWEColorFilterConfigurationType  filterConfigurationType;

@end

@implementation AWEColorFilterConfigurationHelper

- (instancetype)initWithBeautyConfiguration:(AWEColorFilterConfigurationType)type {
    self = [super init];
    if (self) {
        self.filterConfigurationType = type;
        NSMutableDictionary *ratioMapForBeautifyItems = [ACCCache() dictionaryForKey:[AWEColorFilterConfigurationHelper configurationKeyWithType:type]].mutableCopy;
               if (!ratioMapForBeautifyItems) {
                   ratioMapForBeautifyItems = [@{} mutableCopy];
               }
               _ratioMapForBeautifyItems = ratioMapForBeautifyItems;
    }
    return self;
}

+ (NSString *)configurationKeyWithType:(AWEColorFilterConfigurationType)type {
    switch (type) {
        case AWEColorFilterCaptureConfigurationType:
            return AWEColorFilterCaptureConfigurationKey;
            break;
        case AWEColorFilterEditorConfigurationType:
            return AWEColorFilterEditorConfigurationKey;
            break;
        case AWEColorFilterMvConfigurationType:
            return AWEColorFilterMvConfigurationKey;
            break;
        case AWEColorFilterPhotoConfigurationType:
            return AWEColorFilterPhotoConfigurationKey;
            break;
        case AWEColorFilterStoryConfigurationType:
            return AWEColorFilterStoryConfigurationKey;
            break;
        default:
            return AWEColorFilterCaptureConfigurationKey;
            break;
    } ;
}

- (void)setIndensityRatioForColorEffect:(IESEffectModel *)effectModel ratio:(float)ratio {
    if (effectModel.resourceId) {
        self.ratioMapForBeautifyItems[effectModel.resourceId] = @(ratio);
         [ACCCache() setDictionary:self.ratioMapForBeautifyItems.copy forKey:[AWEColorFilterConfigurationHelper configurationKeyWithType:self.filterConfigurationType]];
    }
}

- (float)indensityRatioForColorEffect:(IESEffectModel *)effectModel {
    NSDictionary *colorFilterRatioDic = [ACCCache() dictionaryForKey:[AWEColorFilterConfigurationHelper configurationKeyWithType:self.filterConfigurationType]];
    id ratio = [colorFilterRatioDic objectForKey:effectModel.resourceId];
    if (ratio) {
        return [colorFilterRatioDic acc_floatValueForKey:effectModel.resourceId];
    } else {
        return [colorFilterRatioDic acc_floatValueForKey:effectModel.effectIdentifier];
    }
}

- (BOOL)hasIndensityRatioForColorEffect:(IESEffectModel *)effectModel {
    NSDictionary *colorFilterRatioDic = [ACCCache() dictionaryForKey:[AWEColorFilterConfigurationHelper configurationKeyWithType:self.filterConfigurationType]];
    id ratio = [colorFilterRatioDic objectForKey:effectModel.resourceId];
    if (ratio != nil) {
        return YES;
    } else {
        ratio = [colorFilterRatioDic objectForKey:effectModel.effectIdentifier];
        return ratio != nil;
    }
}

- (float)getEffectIndensityWithDefaultIndensity:(float)defaultIndensity Ratio:(float)ratio {
    // The filter strength is configured according to the default strength of the resource package
    float maxIndensity;
    if (defaultIndensity == 1) { // 1. If the default strength is 1, the sliding rod can be changed from 0 to 1, and two decimal places will be rounded
        maxIndensity = defaultIndensity;
    } else { // 2. If the default strength is not 1, assume that the default value is 0.9, accounting for 80%, and the variable range of sliding rod is 0-1.125 (0.9 / 0.8 = 1.125)
        maxIndensity = defaultIndensity / 0.8;
    }
    return ratio * maxIndensity;
}

@end
