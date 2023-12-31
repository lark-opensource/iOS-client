//
//  ACCRecordSelectMusicServiceImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by liuqing on 2020/3/25.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VERecorder.h>

#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import "ACCRecordConfigService.h"
#import "ACCRecordSelectMusicService.h"

NS_ASSUME_NONNULL_BEGIN
@class IESEffectModel;
@class ACCRecordMode;

// first parameter: show / hidden
// second parameter: non-stitch / stitch
typedef RACTwoTuple<NSNumber *, NSNumber *> *ACCRecordSelectMusicShowType;

// first parameter: tip
// second paramater: isFirstEmbeded
typedef RACTwoTuple<NSString *, NSNumber *> *ACCRecordSelectMusicTipType;

@interface ACCRecordSelectMusicCoverInfo : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) BOOL hasMusic;

@end

@interface ACCRecordSelectMusicServiceImpl : ACCRecorderViewModel <ACCRecordConfigDurationHandler, ACCRecordConfigAudioHandler, ACCRecordSelectMusicService>

@property (nonatomic, strong, readonly) RACSignal *cancelMusicSignal;
@property (nonatomic, strong, readonly) RACSignal *pickMusicSignal;
@property (nonatomic, strong, readonly) RACSignal<ACCRecordSelectMusicCoverInfo *> *musicCoverSignal;
@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *selectMusicAnimationSignal;
@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *selectMusicPanelShowSignal;
@property (nonatomic, strong, readonly) RACSignal<NSError *> *bindMusicErrorSignal;
@property (nonatomic, strong, readonly) RACSignal<ACCRecordSelectMusicTipType> *musicTipSignal;
@property (nonatomic, strong, readonly) RACSignal<NSString *> *muteTipSignal;
@property (nonatomic, strong, readonly) RACSignal *downloadMusicForStickerSignal;
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> propRecommendMusic;

- (void)refreshMusicCover;
- (void)startBGMIfNeeded;
- (BOOL)supportSelectMusic;
- (BOOL)hasSelectedMusic;
- (void)handlePickMusic:(id<ACCMusicModelProtocol>)music error:(NSError *)error completion:(void (^)(void))completion;
- (void)handleCancelMusic:(id<ACCMusicModelProtocol>)music;
- (void)applyForceBindMusic:(id<ACCMusicModelProtocol>)musicModel;
- (void)pickForceBindMusic:(id<ACCMusicModelProtocol>)musicModel isForceBind:(BOOL)isForceBind error:(NSError * _Nullable)musicError;
- (void)cancelForceBindMusic:(id<ACCMusicModelProtocol>)musicModel;
- (void)switchAIRecordFrameTypeIfNeeded;
- (void)updateCurrentSticker:(IESEffectModel *)currentSticker;
- (void)removeFrames:(BOOL)confirm;
- (void)trackChangeMusic:(BOOL)enabled;
- (void)showTip:(nullable NSString *)tip isFirstEmbed:(BOOL)isFirstEmbed;
- (void)updateAudioRangeWithStartLocation:(double)startLocation;
- (void)startReuseFeedMusicFlowIfNeed;
- (void)showSelectMusicPanel;
- (void)downloadPropRecommendedMusic;
- (void)handleAutoSelectWeakBindMusic:(id<ACCMusicModelProtocol>)music error:(NSError *)error completion:(dispatch_block_t)completion;

- (IESEffectModel *)currentSticker;
- (id<ACCMusicModelProtocol>)sameStickerMusic;
- (AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
