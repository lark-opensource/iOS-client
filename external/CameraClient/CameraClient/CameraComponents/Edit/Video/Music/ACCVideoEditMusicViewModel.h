//
//  ACCVideoEditMusicViewModel.h
//  CameraClient
//
//  Created by liuqing on 2020/2/23.
//

#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCEditMusicServiceProtocol.h"
#import "ACCMusicSelectViewProtocol.h"
#import "HTSVideoSoundEffectPanelView.h"
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <CoreMedia/CoreMedia.h>
#import "ACCMusicPanelViewModel.h"
#import "ACCRecommendMusicRequestManager.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEMusicSelectItem, ACCCutMusicRangeChangeContext;
@protocol IESServiceProvider;
@class AWEVideoPublishViewModel;
@class ACCEditMusicBizModule;

typedef NS_ENUM(NSUInteger, ACCVideoEditSelectMusicType) {
    ACCVideoEditSelectMusicTypeNone,
    ACCVideoEditSelectMusicTypePanel,
    ACCVideoEditSelectMusicTypeLibrary
};

typedef NS_ENUM(NSUInteger, ACCVideoEditMusicDisableType) {
    ACCVideoEditMusicDisableTypeUnknow = 0,
    ACCVideoEditMusicDisableTypeAIClip,
    ACCVideoEditMusicDisableTypeLongVideo,
};

@protocol ACCVideoEditMusicPlayerDelegate <NSObject>

// player
- (void)play;
- (void)pause;
- (void)continuePlay;
- (void)setVolumeForAudio:(float)volume;
- (void)updateVideoData:(ACCEditVideoData* _Nullable)videoData updateType:(VEVideoDataUpdateType)updateType completeBlock:(void(^ _Nullable)(NSError* error)) completeBlock;
- (ACCEditVideoData *)videoData;
- (void)seekToTimeAndRender:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

// playerservice
- (void)replaceAudio:(nullable NSURL *)url completeBlock:(void (^ __nullable)(void))completeBlock;
- (void)replaceAudioForPhotoVideo:(NSURL *)url completeBlock:(void (^ __nullable)(void))completeBlock;

@end

@interface ACCVideoEditMusicViewModel : NSObject <ACCEditMusicServiceProtocol, AWEVideoPublishMusicSelectViewUserCollectedMusicDelegate, ACCVideoEditMusicPlayerDelegate>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, weak) id<IESServiceProvider> serviceProvider;
@property (nonatomic, strong) ACCEditMusicBizModule *musicBizModule;

@property (nonatomic, copy, readonly) NSArray<AWEMusicSelectItem *> *musicList;
@property (nonatomic, strong, readonly) id<ACCMusicModelProtocol> musicWhenEnterEditPage;

@property (nonatomic, strong, readonly) id<ACCMusicModelProtocol> challengeOrPropMusic;
@property (nonatomic, assign, readonly) BOOL isCommerceLimitPanel;
@property (nonatomic, copy, nullable) BOOL(^musicPanelShowingProvider)(void);
@property (nonatomic, strong, readonly) RACSignal *refreshMusicRelatedUISignal;
@property (nonatomic, strong, readonly) RACSignal<id<ACCMusicModelProtocol>> *didRequestMusicSignal;
@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *mvChangeMusicLoadingSignal;
@property (nonatomic, strong, readonly) RACSignal<NSString *> *changeMusicTipsSignal;
@property (nonatomic, strong, readonly) RACSignal<NSArray<AWEMusicSelectItem *> *> *musicListSignal;
@property (nonatomic, strong, readonly) RACSignal<NSArray<AWEMusicSelectItem *> *> *collectedMusicListSignal;
@property (nonatomic, strong, readonly) RACSignal <RACTwoTuple<NSString *, NSError *> *> *featchFramesUploadStatusSignal;

@property (nonatomic, strong, readonly) RACSubject<RACThreeTuple<NSNumber *, NSString *, id<ACCMusicModelProtocol>> *> *toggleLyricsButtonSubject;

@property (nonatomic, assign, readonly) NSTimeInterval showMusicPanelTime;
@property (nonatomic, assign) NSTimeInterval showMusicDurationTime;

- (void)generalFetchFramesAndUpload;
- (BOOL)shouldUploadFramesForRecommendation;
+ (BOOL)shouldUploadBachOrFrameForRecommendation;
- (void)fetchFramesAndUPload;
- (void)fetchFramesAndUPloadIfNeeded;
- (void)reFetchFramesAndUpload;
- (void)fetchAIRecommendMuiscListIfNeeded;
- (void)fetchHotMuiscListIfNeeded;

- (void)updateMusicList;
- (void)markShowIfNeeded;

- (ACCVideoEditSelectMusicType)selectMusic;
- (ACCVideoEditSelectMusicType)selectMusicInPanel;
- (ACCVideoEditSelectMusicType)selectMusicInLibrary;

- (void)deselectMusic:(id<ACCMusicModelProtocol> _Nullable)music;
- (void)deselectMusic:(id<ACCMusicModelProtocol> _Nullable)music autoPlay:(BOOL)play;
- (void)deselectMusic:(id<ACCMusicModelProtocol>)music autoPlay:(BOOL)autoPlay completeBlock:(void (^ __nullable)(void))completeBlock;

- (void)handleSelectMusic:(id<ACCMusicModelProtocol>)music
                    error:(NSError *)error
       removeMusicSticker:(BOOL)removeMusicSticker
            completeBlock:(void (^ __nullable)(void))completeBlock;
- (void)handleSelectMusic:(id<ACCMusicModelProtocol>)music
                    error:(nullable NSError *)error
       removeMusicSticker:(BOOL)removeMusicSticker;


- (void)setNeedResetInitialMusic:(BOOL)needResetInitialMusic;
- (void)handleSmartMVInitialMusic:(id<ACCMusicModelProtocol>)music;
- (void)setMusicWhenEnterEditPage:(id<ACCMusicModelProtocol>)music;

- (void)resetCollectedMusicListIfNeeded;
- (void)collectMusic:(id<ACCMusicModelProtocol>)music collect:(BOOL)collect;
- (void)updateCollectStateWithMusicId:(NSString *)musicId collect:(BOOL)collect;
- (void)updateMusicFeatureDisable:(BOOL)disable;
- (void)updateChallengeOrPropRecommendMusic:(id<ACCMusicModelProtocol>)music;

- (NSArray<AWEMusicSelectItem *> *)userCollectedMusicList;
- (AWEVideoPublishViewModel *)publishModel;
- (BOOL)AIMusicDisableWithType:(ACCVideoEditMusicDisableType * _Nullable)typeRef;
- (nullable NSArray <id<ACCChallengeModelProtocol>> *)currentBindChallenges;
- (void)requestMusicDetailIfNeeded:(id<ACCMusicModelProtocol>)music;

- (void)didSelectCutMusicSignal:(HTSAudioRange)range;
- (void)sendMusicChangedSignal;
- (void)sendRefreshMusicRelatedUISignal;
- (void)sendVoiceVolumeChangedSignal:(HTSVideoSoundEffectPanelView *)panel;
- (void)sendMusicVolumeChangedSignal:(HTSVideoSoundEffectPanelView *)panel;
- (void)sendRefreshVolumeViewSignal:(HTSVideoSoundEffectPanelView *)panel;
- (void)sendCutMusicButtonClickedSignal;
- (void)sendSmartMovieDidAddMusicSignal;
- (void)sendUpdateChallengeModelSignal;

#pragma mark - music panel
@property (nonatomic, strong, readonly) ACCMusicPanelViewModel *musicPanelViewModel;
@property (nonatomic, strong, readonly) ACCRecommendMusicRequestManager *recommendMusicRequestManager;

- (BOOL)canDeselectMusic;

#pragma mark - track

- (void)clickShowMusicPanelTrack;

@end

NS_ASSUME_NONNULL_END
