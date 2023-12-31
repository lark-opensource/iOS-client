//Copyright © 2021 Bytedance. All rights reserved.

#ifndef ACCFilterPrivateService_h
#define ACCFilterPrivateService_h

#import "ACCFilterService.h"

@class AWECameraFilterConfiguration;

@protocol ACCFilterPrivateService <ACCFilterService>

@property (nonatomic, strong) AWECameraFilterConfiguration *filterConfiguration;
@property (nonatomic, strong) NSArray *filterArray;

- (void)applyFilter:(IESEffectModel *)filter indensity:(float)indensity; // not show filter name, not send manual apply message
- (BOOL)hasIndensityRatioForColorEffect:(IESEffectModel *)effectModel;
- (float)filterIndensity:(IESEffectModel *)filter;
- (float)indensityRatioCacheForColorEffect:(IESEffectModel *)effectModel;

- (void)switchFilterWithFilterOne:(IESEffectModel *)filterOne
                        FilterTwo:(IESEffectModel *)filterTwo
                        direction:(IESMMFilterSwitchDirection)direction
                         progress:(CGFloat)progress;

- (AWEColorFilterConfigurationHelper *)currentFilterHelper;

- (void)recoverFilterIfNeeded;
- (IESEffectModel *)prevFilterOfCurrentFilter;
- (IESEffectModel *)nextFilterOfCurrentFilter;


- (void)sendFilterViewWillShowSignal;
- (void)sendApplyFilterSignalWith:(BOOL)isComplete;

@end

#endif /* ACCFilterPrivateService_h */
