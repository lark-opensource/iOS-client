//
//  ACCRecognitionConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/8.
//

#import "ACCRecognitionConfig.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

#define kConfigInt_studio_record_smartscan_entrance \
ACCConfigKeyDefaultPair(@"studio_record_smartscan_entrance", @(0))

#define kConfigInt_studio_record_smartscan_type \
ACCConfigKeyDefaultPair(@"studio_record_smartscan_type", @(0))

typedef NS_OPTIONS(NSUInteger, ACCRecognitionEntryOption) {
    ACCRecognitionEntryNone = 0,
    ACCRecognitionEntryLongPress = 1 << 0,
    ACCRecognitionEntryRightItem = 1 << 1,
};

typedef NS_OPTIONS(NSUInteger, ACCRecognitionFunctionConfig) {
    ACCRecognitionFunctionNone = 0,
    ACCRecognitionFunctionScene = 1 << 0,
    ACCRecognitionFunctionCategory = 1 << 1, /// flower
};


@implementation ACCRecognitionConfig

+ (BOOL)enabled
{
    return [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin] &&
    self.entryConfig != ACCRecognitionEntryNone &&
    self.functionConfig != ACCRecognitionFunctionNone;
}

+ (BOOL)longPressEntry
{
    return self.enabled && self.entryConfig & ACCRecognitionEntryLongPress;
}

+ (BOOL)barItemEntry
{
    return self.enabled && self.entryConfig & ACCRecognitionEntryRightItem;
}

+ (BOOL)supportScene
{
    return self.enabled && self.functionConfig & ACCRecognitionFunctionScene;
}

+ (BOOL)onlySupportCategory
{
    return self.enabled && self.functionAB == 2;
}

+ (BOOL)supportCategory
{
    return self.enabled && self.functionConfig & ACCRecognitionFunctionCategory;
}

+ (ACCRecognitionEntryOption)entryConfig
{
    NSInteger config = self.entryAB;
    if (config == 1) {
        return ACCRecognitionEntryLongPress;
    }
    else if (config == 2) {
        return ACCRecognitionEntryLongPress | ACCRecognitionEntryRightItem;
    }
    return ACCRecognitionEntryNone;
}

+ (ACCRecognitionFunctionConfig)functionConfig
{
    NSInteger config = self.functionAB;
    if (config == 1){
        return ACCRecognitionFunctionScene;
    }
    else if (config == 2){
        return ACCRecognitionFunctionCategory;
    }
    else if (config == 3){
        return ACCRecognitionFunctionScene | ACCRecognitionFunctionCategory;
    }

    return ACCRecognitionFunctionNone;
}

+ (NSInteger)functionAB
{
    return ACCConfigInt(kConfigInt_studio_record_smartscan_type);
}

+ (NSInteger)entryAB
{
    return ACCConfigInt(kConfigInt_studio_record_smartscan_entrance);
}

+ (double)thresholdFor:(ACCRecognitionThreashold)threshold
{
    NSString *key = [self thresholdKey:threshold];
    return [[self.thresholdInfo valueForKey:key] doubleValue];
}

+ (NSString *)thresholdKey:(ACCRecognitionThreashold)threshold
{
    return
    threshold == ACCRecognitionThreasholdClarityFail ? @"failure_threshold_for_image_clarity":
    threshold == ACCRecognitionThreasholdClarityIeal ? @"ideal_threshold_for_image_clarity":
    threshold == ACCRecognitionThreasholdFlower ? @"threshold_for_recognition_as_flower": @"";

}

+ (NSDictionary *)thresholdInfo
{
    static NSDictionary *info;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        info = ACCConfigDict(ACCConfigKeyDefaultPair(@"studio_record_smartscan_model_threshold_settings", @{}));
    });

    return info;
}

+ (BOOL)supportAnimal
{
    return [[[ACCRecognitionConfig smartScanDetectModeFromSettings] componentsSeparatedByString:@","] containsObject:kACCRecognitionDetectModeAnimal];
}

+ (NSString *)smartScanDetectModeFromSettings
{
    /// custom detect mode
    NSString *mode = ACCConfigString(ACCConfigKeyDefaultPair(@"studio_record_smartscan_detect_mode", @""));
    if (mode.length > 0){
        return mode;
    }

    /// legacy detect mode
    NSMutableArray *ma = [NSMutableArray new];

    if ([ACCRecognitionConfig supportCategory]){
        [ma addObject:@1];
    }
    if ([ACCRecognitionConfig supportScene]){
        [ma addObject:@2];
    }
    return [ma componentsJoinedByString:@","];

}


#pragma mark - autoscan settings

+ (BOOL)enableAutoScanForRecogitionOptimize
{
    NSDictionary *autoScanConfig = ACCConfigDict(kConfigDict_tools_smart_recognition_autoscan_config);
    BOOL canAutoScanBySettings = [autoScanConfig acc_boolValueForKey:@"recognition_autoscan_enable"];
    BOOL isInAutoScanExpGroup = ACCConfigEnum(kACCConfigInt_tools_camera_smart_recognition_optimize, ACCRecognitionOptimizeType) != ACCRecognitionOptimizeTypeNOAutoScan;
    
    return isInAutoScanExpGroup || canAutoScanBySettings;
}

+ (NSInteger)autoScanHintDailyShowMaxCount
{
    NSDictionary *autoScanConfig = ACCConfigDict(kConfigDict_tools_smart_recognition_autoscan_config);
    return [autoScanConfig acc_integerValueForKey:@"recognition_autoscan_max_hint_count" defaultValue:3];
}

@end
