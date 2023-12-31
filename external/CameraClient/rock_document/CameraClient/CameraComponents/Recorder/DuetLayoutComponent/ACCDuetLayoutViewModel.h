

//
//  ACCDuetLayoutViewModel.h
//  Pods
//
//  Created by guochenxiang on 2020/6/10.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import "ACCDuetLayoutService.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCDuetLayoutViewModel : ACCRecorderViewModel <ACCDuetLayoutService>

- (void)startDuetIfNecessary;

- (void)didSelectDuetLayoutAtIndex:(NSInteger)index;

- (void)sendUpdateIconSignal:(UIImage *)image;

- (void)retryDownloadDuetEffects;

- (void)handleMessageOfFigureAppearanceDurationReachesThreshold;

- (void)updateFigureAppearanceDurationInMS;

- (void)sendMessageOfRemovingSegmentsToEffectWithID:(NSInteger)messageId;

- (BOOL)isDuetGreenScreenEverShot;

- (BOOL)isDuetLandscapeVideoAndNeedOptimizeLayout;

@end

NS_ASSUME_NONNULL_END
