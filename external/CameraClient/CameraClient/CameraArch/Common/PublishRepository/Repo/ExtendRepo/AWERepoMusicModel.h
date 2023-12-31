//
//  AWERepoMusicModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/25.
//

#import <CreationKitArch/ACCRepoMusicModel.h>


NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;
@protocol ACCAwemeModelProtocol;
@class ACCPublishMusicTrackModel, IESMMVideoDataClipRange, AVAsset;
@class ACCEditorMusicConfigAssembler;

@interface AWERepoMusicModel : ACCRepoMusicModel <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol, ACCRepositoryTrackContextProtocol>

/// 新剪裁提供音乐列表
@property (nonatomic, copy) NSArray<id<ACCMusicModelProtocol>> *musicList;

@property (nonatomic, strong) id<ACCAwemeModelProtocol> currentFeedModel;

@property (nonatomic, assign) BOOL useSuggestClipRange;
@property (nonatomic, assign) BOOL enableMusicLoop;
@property (nonatomic, copy) NSString *musicEditedFrom;

@property (nonatomic, assign) BOOL disableMusicModule;
@property (nonatomic, assign) BOOL voiceVolumeDisable;
@property (nonatomic, copy) NSString *passthroughMusicID;

// only for draft
@property (nonatomic, strong, nullable) NSURL *bgmAssetURL;
@property (nonatomic, copy, nullable) NSString *strongBeatPath;

//只用于音乐拍同款主要链路决定开拍landing策略
@property (nonatomic, assign) CGFloat musicMaxRecordableDuration;//此处在repo里赋值 因为一些情况进录制后musicModel还是nil
@property (nonatomic, assign) CGFloat shootSameVideoDuration;//拍同款的视频时长 小数点向下取整了 对齐服务端下发shootduration策略
@property (nonatomic, assign) CGFloat musicClipBeginTime;//同步视频中下发的音乐剪裁字段

// 道具弱绑定音乐延迟到编辑页应用
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> weakBindMusic;

//bach算法模型结果
@property (nonatomic, copy) NSString *binURI;


@property (nonatomic, strong) ACCEditorMusicConfigAssembler *musicConfigAssembler;

- (BOOL)shouldEnableMusicLoop:(CGFloat)videoMaxDuration;

- (BOOL)shouldReplaceClipDurationWithMusicShootDuration:(CGFloat)duration;


@property (nonatomic, strong, nullable) NSString *bgmRelativePath; //relative file path
@property (nonatomic, copy, nullable) NSString *strongBeatRelativePath;
@property (nonatomic, strong, nullable) NSData *musicJson;

@end

@interface AWEVideoPublishViewModel (AWERepoMusic)
 
@property (nonatomic, strong, readonly) AWERepoMusicModel *repoMusic;
 
@end

NS_ASSUME_NONNULL_END
