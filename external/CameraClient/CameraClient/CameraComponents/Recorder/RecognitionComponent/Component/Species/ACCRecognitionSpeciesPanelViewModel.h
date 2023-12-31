//
//  ACCRecognitionSpeciesPanelViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/20.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCSpeciesInfoCardsView.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCPropPickerItem, IESEffectModel;
@class SSRecommendResult, SSImageTags, SSRecognizeResult;

@interface ACCRecognitionSpeciesPanelViewModel : ACCRecorderViewModel<ACCSpeciesInfoCardsViewDelegate>

@property (nonatomic, strong, readonly) SSImageTags *recognizeResultData;
@property (nonatomic, strong, readonly) RACSignal *closePanelSignal;
@property (nonatomic, strong, readonly) RACSignal *checkGrootSignal;
@property (nonatomic, strong, readonly) RACSignal *slideCardSignal;
@property (nonatomic, strong, readonly) RACSignal<RACThreeTuple<SSRecognizeResult *, NSNumber *, NSNumber *> *> *selectItemSignal;
@property (nonatomic, strong, readonly) RACSignal<RACTwoTuple<SSRecognizeResult *, NSNumber *> *> *stickerSelectItemSignal;

@property (nonatomic, assign, readonly) BOOL allowResearch;

@property (nonatomic, assign) BOOL isShowingPanel;
@property (nonatomic, assign) BOOL isNeedRedisplay;

- (void)updateRecommendResult:(SSRecommendResult *)recommendResult;

- (BOOL)canShowSpeciesPanel;

- (nullable SSRecognizeResult *)itemAtIndex:(NSUInteger)index;

#pragma mark - Track

- (void)trackClickChangeSpecies:(BOOL)isSticker;

#pragma mark - flower track

- (void)flowerTrackForClickChangeSpecies;

@end

NS_ASSUME_NONNULL_END
