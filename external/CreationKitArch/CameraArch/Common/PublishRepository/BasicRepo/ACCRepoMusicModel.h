//
//  ACCRepoMusicModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/25.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreationKitArch/ACCStudioDefines.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAwemeModelProtocol;
@class ACCPublishMusicTrackModel, IESMMVideoDataClipRange, AVAsset;

@interface ACCRepoMusicModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol, ACCRepositoryTrackContextProtocol> {
    @protected
    HTSAudioRange _audioRange;
}

@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> music;

//music track model
@property (nonatomic, strong) ACCPublishMusicTrackModel *musicTrackModel;

@property (nonatomic, assign) HTSAudioRange audioRange;
@property (nonatomic, assign) CGFloat voiceVolume;
@property (nonatomic, assign) CGFloat musicVolume;
@property (nonatomic, assign) AWERecordMusicSelectSource musicSelectFrom;
@property (nonatomic, assign) NSInteger musicUsageConfirmation;

@property (nonatomic, copy) NSString *zipURI;

@property (nonatomic, assign) BOOL isLVAudioFrameModel;
@property (nonatomic, strong, nullable) AVAsset *bgmAsset;
@property (nonatomic, copy, nullable) IESMMVideoDataClipRange *bgmClipRange;

@property (nonatomic,   copy, nullable) NSString *musicSelectedFrom;

//
@property (nonatomic, strong) NSDictionary *musicTrackInfo;

- (BOOL)hasEditMusicRange;
- (AVAsset *)musicAsset;
- (void)resetMusicRange;
@end

@interface AWEVideoPublishViewModel (RepoMusic)
 
@property (nonatomic, strong, readonly) ACCRepoMusicModel *repoMusic;
 
@end

NS_ASSUME_NONNULL_END
