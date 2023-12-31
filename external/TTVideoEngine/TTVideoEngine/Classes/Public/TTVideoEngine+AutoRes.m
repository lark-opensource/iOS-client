//
//  TTVideoEngine+StartUp.m
//  TTVideoEngine
//
//  Created by haocheng on 2021/7/15.
//

#import "TTVideoEngine+AutoRes.h"
#import "TTVideoEngineStartUpSelector.h"
#import "TTVideoEngine+Private.h"
#import "TTVideoEngine+Options.h"
#import "TTVideoEngineUtilPrivate.h"

@implementation TTVideoEngine (AutoRes)

+ (TTVideoEngineURLInfo *)_getAutoResolutionInfo:(TTVideoEngineAutoResolutionParams *)autoResParams playSource:(id<TTVideoEnginePlaySource>)playSource {
    _TTVideoEngineStartUpSelector *selector = [[_TTVideoEngineStartUpSelector alloc] initWithScene:TTVideoEngineSelectorSceneStartUp PredictType:[TTVideoEngine getPredictAlgoType]];
    if (!selector) {
        TTVideoEngineLog(@"auto res: create selector failed")
        return nil;
    }
    
    if (!autoResParams) {
        TTVideoEngineLog(@"auto res: empty auto res params")
        return nil;
    }
    
    _TTVideoEngineSelectorParams *params = [[_TTVideoEngineSelectorParams alloc] initWithParams:autoResParams];
    [params configBitrateWithPlaySource:playSource];
    [params configPallasVidLabelsWithPlaySource:playSource];
    
    TTVideoEngineURLInfo *info = [selector selectWithPlaySource:[playSource getVideoList]
                                                         params:params
                                                   onceAlgoType:[TTVideoEngine getOnceSelectAlgoType]
                                                isAddBufferInfo:YES];
    return info;
}

+ (TTVideoEngineURLInfo *)_getAutoResolutionInfo:(TTVideoEngineAutoResolutionParams *)autoResParams infoModel:(TTVideoEngineInfoModel *)infoModel {
    _TTVideoEngineStartUpSelector *selector = [[_TTVideoEngineStartUpSelector alloc] initWithScene:TTVideoEngineSelectorScenePreLoad PredictType:[TTVideoEngine getPredictAlgoType]];
    if (!selector) {
        TTVideoEngineLog(@"auto res: create selector failed")
        return nil;
    }
    
    if (!autoResParams) {
        TTVideoEngineLog(@"auto res: empty auto res params")
        return nil;
    }
    
    _TTVideoEngineSelectorParams *params = [[_TTVideoEngineSelectorParams alloc] initWithParams:autoResParams];
    [params configBitrateWithInfoModel:infoModel];
    [params configPallasVidLabelsWithInfoModel:infoModel];
    
    NSArray<TTVideoEngineURLInfo *> *urlInfoList = [infoModel getValueArray:VALUE_VIDEO_LIST];
    if (!urlInfoList) {
        TTVideoEngineLog(@"auto res: ls empty info list")
        return nil;
    }
    
    TTVideoEngineURLInfo *info = [selector selectWithPlaySource:urlInfoList
                                                         params:params
                                                   onceAlgoType:[TTVideoEngine getOnceSelectAlgoType]
                                                isAddBufferInfo:YES];
    return info;
}

@end

@implementation TTVideoEngineAutoResolutionParams

- (instancetype)init {
    self = [super init];
    if (self) {
        self.expectedResolution = -1;
        self.defaultWifiResolution = -1;
        self.startUpMaxResolution = -1;
        self.cellularMaxResolution = -1;
        self.downgradeResolution = -1;
        self.defaultCellularResolution = -1;
        self.startupMinResolution = -1;
        
        self.startupModel = 0;
        self.brandwidthFactor = 0.9;
        
        self.useCustomStartupParams = NO;
        self.firstStartupParam = 0.0;
        self.secondStartupParam = 0.0;
        self.thirdStartupParam = 1.0;
        self.fourthStartupParam = 0.0;
    }
    return self;
}

@end
