//
//  ACCEditMusicServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2020/12/30.
//

#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import "ACCEditVideoData.h"

#ifndef ACCEditMusicServiceProtocol_h
#define ACCEditMusicServiceProtocol_h

NS_ASSUME_NONNULL_BEGIN

@class AVURLAsset;
@protocol ACCEditMusicServiceProtocol <NSObject>

@property (nonatomic, assign, readonly) BOOL musicFeatureDisable;
@property (nonatomic, assign, readonly) BOOL musicPanelShowing;
@property (nonatomic, assign, readonly) BOOL useMusicSelectPanel;

@property (nonatomic, strong, readonly) RACSignal *willSelectMusicSignal;

@property (nonatomic, strong, readonly) RACSignal *willAddMusicSignal;
@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *didAddMusicSignal;
@property (nonatomic, strong, readonly) RACSignal *didDeselectMusicSignal;

@property (nonatomic, strong, readonly) RACSignal<RACThreeTuple<ACCEditVideoData *, id<ACCMusicModelProtocol>, AVURLAsset *> *> *mvWillAddMusicSignal;
@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *mvDidChangeMusicSignal;

@property (nonatomic, strong, readonly) RACSignal *cutMusicButtonClickedSignal;
@property (nonatomic, strong, readonly) RACSignal<NSValue *> *didSelectCutMusicSignal;

@property (nonatomic, strong, readonly) RACSignal *volumeChangedSignal;
@property (nonatomic, strong, readonly) RACSignal *refreshVolumeViewSignal;
@property (nonatomic, strong, readonly) RACSignal<id<ACCMusicModelProtocol>> *didUpdateChallengeModelSignal;
@property (nonatomic, strong, readonly) RACSignal<RACThreeTuple<NSNumber *, NSString *, id<ACCMusicModelProtocol>> *> *toggleLyricsButtonSignal;
@property (nonatomic, strong, readonly) RACSignal <RACTwoTuple<NSString *, NSError *> *> *featchFramesUploadStatusSignal;
@property (nonatomic, strong, readonly, nullable) RACSignal *musicChangedSignal;

- (BOOL)shouldUploadFramesForRecommendation;
- (void)generalFetchFramesAndUpload;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCEditMusicServiceProtocol_h */
