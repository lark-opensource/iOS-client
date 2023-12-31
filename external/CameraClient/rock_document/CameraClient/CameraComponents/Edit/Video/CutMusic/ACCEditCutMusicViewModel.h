//
//  ACCEditCutMusicViewModel.h
//  Pods
//
//  Created by liyingpeng on 2020/8/7.
//

#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCEditCutMusicServiceProtocol.h"
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEAudioClipFeatureManager, AVURLAsset, AWEVideoPublishViewModel;
@protocol IESServiceProvider, ACCMusicModelProtocol;
@interface ACCEditCutMusicViewModel : NSObject <ACCEditCutMusicServiceProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, weak) id<IESServiceProvider> serviceProvider;
@property (nonatomic, strong) AWEAudioClipFeatureManager *audioClipFeatureManager;

// repeatCount 设置 -1 代表沿用原 range.repeatCount
- (void)clipMusic:(HTSAudioRange)range repeatCount:(NSInteger)repeatCount;
- (void)clipMusicBeforeAddedIfNeeded:(ACCEditVideoData *)videoData music:(id<ACCMusicModelProtocol>)music asset:(AVURLAsset *)asset;
- (void)clipMusicAfterAddedIfNeeded;

- (void)sendCheckMusicFeatureToastSignal;
- (void)sendDidClickCutMusicButtonSignal;
- (void)sendDidDismissPanelSignal;
- (void)sendCutMusicRangeDidChangeSignal:(ACCCutMusicRangeChangeContext *)context;
- (void)sendDidFinishCutMusicSignal:(ACCCutMusicRangeChangeContext *)context;

@end

NS_ASSUME_NONNULL_END
