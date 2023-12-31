//
//  VCABRConfig.h
//  test
//
//  Created by baidonghui on 2020/5/20.
//  Copyright © 2020 gkz. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef VCABRConfig_h
#define VCABRConfig_h

typedef NS_ENUM(NSInteger, ABRModuleKey) {
    ABRKeyIsLogLevel = 0,
    ABRKeyIsSwitchSensitivity = 1,
    ABRKeyIs4GMaxBitrate = 2,
    ABRKeyIsSwitchModel = 3,
    ABRKeyIsFixedLevel = 4,
    ABRKeyIsStartupModel = 5,
    ABRKeyIsPlayerDisplayWidth = 6,
    ABRKeyIsPlayerDisplayHeight = 7,
    ABRKeyIsStartupBandwidthParameter = 8,
    ABRKeyIsStallPenaltyParameter = 9,
    ABRKeyIsSwitchPenaltyParameter = 10,
    ABRKeyIsBandwidthParameter = 11,
    ABRKeyIsDefaultWifiBitrate = 12,
    ABRKeyIsStartupMaxBitrate = 13,
    ABRKeyIsSelectScene = 14,
    ABRKeyIsABRMaxCacheBitrate = 15,
    ABRKeyIsStartupSpeed = 16,
    ABRKeyIsStartupPredictSpeed = 17,
    ABRKeyIsStartupAverageSpeed = 18,
    ABRKeyIsAbrAlgorithmType = 19,
    ABRKeyIsPlaySpeed = 20,
    ABRKeyIsNetworkState = 21,
    ABRKeyIsUserExpectedBitrate = 22,
    ABRKeyIsNetworkSpeed = 23,
    ABRKeyIsNetworkSpeedConfidence = 24,
    ABRKeyIsDownloadSpeed = 25,
    ABRKeyIsStartTime = 26,
    ABRKeyIsAverageNetworkSpeed = 27,
    ABRKeyIsAverageStartupEndNetworkSpeed = 28,
    ABRKeyIsStartupModelFirstParam = 29,
    ABRKeyIsStartupModelSecondParam = 30,
    ABRKeyIsStartupModelThirdParam = 31,
    ABRKeyIsStartupModelFourthParam = 32,
    ABRKeyIsDowngradeBitrate = 33,
    ABRKeyIsScreenWidth = 34,
    ABRKeyIsScreenHeight = 35,
    ABRKeyIsScreenMaxSizeBitrate = 36,
    ABRKeyIsStartupUseCache = 37,
    ABRKeyIsDefault4GBitrate = 38,
    ABRKeyIsSREnabled = 39,
    ABRKeyIsSRSatisfied = 40,
    ABRKeyIsSRStatus = 41,
    ABRKeyIsBitrateBeforeSRDowngrade = 42,
    ABRKeyIsExpectedFitScreen = 43,
    ABRKeyIsPreloadJsonParams = 50,
    ABRKeyIsStartupJsonParams = 51,
    ABRKeyIsFlowJsonParams    = 52,
    ABRKeyIsABRSwitchReason = 53,
    ABRKeyIsStartupMinBitrate = 54,
    ABRKeyIsPallasVidLabels = 69,
};

typedef NS_ENUM(NSInteger, ABRSwitchSensitivity) {
    ABRSwitchSensitivityNormal = 0,
    ABRSwitchSensitivityHigh = 1,
};

@interface VCABRConfig : NSObject

+ (void)set4GMaxBitrate:(NSInteger)maxbitrate;
   
+ (NSInteger)get4GMaxBitrate;

@end

#endif /* VCABRConfig_h */
