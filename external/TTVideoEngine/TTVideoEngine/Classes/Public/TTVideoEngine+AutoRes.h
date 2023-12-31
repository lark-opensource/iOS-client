//
//  TTVideoEngine+AutoRes.h
//  TTVideoEngine
//
//  Created by haocheng on 2021/7/15.
//

#import "TTVideoEngine.h"
#import "TTVideoEngineModelDef.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TTVideoEngineStartupModel) {
    TTVideoEngineStartupModelNormal = 0,
    TTVideoEngineStartupModelHigh,
    TTVideoEngineStartupModelHigher,
    TTVideoEngineStartupModelDynamic,
    TTVideoEngineStartupModelCompatible,
    TTVideoEngineStartupModelCache,
    TTVideoEngineStartupModelAvgnet,
    TTVideoEngineStartupModelAvgsenet,
    TTVideoEngineStartupModelBandBit,
    TTVideoEngineStartupModelScreen,
    TTVideoEngineStartupModelBandBitLimit,
    TTVideoEngineStartupModelBandBitNear,
};

typedef NS_ENUM(NSUInteger, TTVideoEngineAutoResUseCacheMode) {
    TTVideoEngineAutoResUseCacheModeDisable,
    TTVideoEngineAutoResUseCacheModeDefault,
    TTVideoEngineAutoResUseCacheModeStrict,
};

typedef NS_ENUM(NSUInteger, TTVideoEngineAutoResExpectedFitScreen) {
    TTVideoEngineAutoResExpectedFitScreenDisable,
    TTVideoEngineAutoResExpectedFitScreenDefault,
};

@interface TTVideoEngineAutoResolutionParams : NSObject
//required
@property (nonatomic, assign) int displayWidth;
@property (nonatomic, assign) int displayHeight;
@property (nonatomic, assign) TTVideoEngineAutoResUseCacheMode useCacheMode;
@property (nonatomic, assign) TTVideoEngineAutoResExpectedFitScreen fitScreenMode;

//optional
@property (nonatomic, assign) TTVideoEngineResolutionType expectedResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType defaultWifiResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType startUpMaxResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType cellularMaxResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType downgradeResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType defaultCellularResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType startupMinResolution;

@property (nonatomic, assign) TTVideoEngineStartupModel startupModel;
@property (nonatomic, assign) float brandwidthFactor;
/** use custom param only when useCustomStartupParams switcher is on */
@property (nonatomic, assign) BOOL useCustomStartupParams;
@property (nonatomic, assign) double firstStartupParam;
@property (nonatomic, assign) double secondStartupParam;
@property (nonatomic, assign) double thirdStartupParam;
@property (nonatomic, assign) double fourthStartupParam;

//optional
@property (nonatomic, copy) NSDictionary *expectedQuality;
@property (nonatomic, copy) NSDictionary *defaultWifiQuality;
@property (nonatomic, copy) NSDictionary *startUpMaxQuality;
@property (nonatomic, copy) NSDictionary *cellularMaxQuality;
@property (nonatomic, copy) NSDictionary *downgradeQuality;
@property (nonatomic, copy) NSDictionary *defaultCellularQuality;
@property (nonatomic, copy) NSDictionary *startupMinQuality;

@end

@interface TTVideoEngine()

@property (nonatomic, strong) TTVideoEngineAutoResolutionParams *startUpParams;

@end

@interface TTVideoEngine (AutoRes)

- (TTVideoEngineResolutionType)getStartUpAutoResolutionResult:(TTVideoEngineAutoResolutionParams *)params
                                            defaultResolution:(TTVideoEngineResolutionType)defaultResolution;

@end

NS_ASSUME_NONNULL_END
