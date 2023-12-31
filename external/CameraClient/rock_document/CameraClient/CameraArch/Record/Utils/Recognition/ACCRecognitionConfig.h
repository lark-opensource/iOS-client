//
//  ACCRecognitionConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/8.
//

#import <Foundation/Foundation.h>
#import "ACCRecognitionEnumerate.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const kACCRecognitionDetectModeAnimal;
FOUNDATION_EXPORT NSString * const kACCRecognitionDetectModeQRCode;

@interface ACCRecognitionConfig : NSObject

+ (BOOL)enabled;

+ (BOOL)longPressEntry;
+ (BOOL)barItemEntry;

+ (BOOL)supportScene;
+ (BOOL)onlySupportCategory;
+ (BOOL)supportCategory;
+ (BOOL)supportAnimal;

+ (double)thresholdFor:(ACCRecognitionThreashold)threshold;

+ (NSString *)smartScanDetectModeFromSettings;

#pragma mark - autoscan settings
+ (BOOL)enableAutoScanForRecogitionOptimize;
+ (NSInteger)autoScanHintDailyShowMaxCount;

@end

NS_ASSUME_NONNULL_END
