//
//  TTVideoEngineStartUpSelector.h
//  TTVideoEngine
//
//  Created by haocheng on 2021/7/14.
//

#import <Foundation/Foundation.h>
#import <ABRInterface/IVCABRModule.h>
#import "TTVideoEnginePlaySource.h"
#import "TTVideoEngineInfoModel.h"
#import "TTVideoEngine+AutoRes.h"
#import "TTVideoNetUtils.h"

typedef NS_ENUM(int, TTVideoEngineSelectorScene) {
    TTVideoEngineSelectorScenePreLoad = 0,
    TTVideoEngineSelectorSceneStartUp = 1
};

NS_ASSUME_NONNULL_BEGIN

@interface _TTVideoEngineSelectorParams : NSObject

- (instancetype)initWithParams:(TTVideoEngineAutoResolutionParams *)params;

- (void)configBitrateWithPlaySource:(id<TTVideoEnginePlaySource>)playSource;

- (void)configBitrateWithInfoModel:(TTVideoEngineInfoModel *)infoModel;

- (void)configPallasVidLabelsWithPlaySource:(id<TTVideoEnginePlaySource>)playSource;

- (void)configPallasVidLabelsWithInfoModel:(TTVideoEngineInfoModel *)infoModel;

@end

@interface _TTVideoEngineStartUpSelector : NSObject

- (instancetype)initWithScene:(TTVideoEngineSelectorScene)scene PredictType:(ABRPredictAlgoType)PredictAlgo;

- (TTVideoEngineURLInfo *_Nullable)selectWithPlaySource:(NSArray<TTVideoEngineURLInfo *>*)urlInfo
                                                 params:(_TTVideoEngineSelectorParams *)params
                                           onceAlgoType:(ABROnceAlgoType)onceAlgoType
                                        isAddBufferInfo:(BOOL)isAddBufferInfo;

+ (ABRNetworkState)convertToABRNetworkState:(TTVideoEngineNetWorkStatus)state;

@end

NS_ASSUME_NONNULL_END
