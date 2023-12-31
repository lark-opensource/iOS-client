//
//  AWERepoMusicModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/25.
//

#import "AWERepoMusicModel.h"
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCPublishMusicTrackModel.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>

@interface AWEVideoPublishViewModel (AWERepoMusic) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoMusic)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoMusicModel.class];
	return info;
}

- (AWERepoMusicModel *)repoMusic
{
    AWERepoMusicModel *musicModel = [self extensionModelOfClass:AWERepoMusicModel.class];
    NSAssert(musicModel, @"extension model should not be nil");
    return musicModel;
}

@end

@implementation AWERepoMusicModel
@synthesize musicSelectedFrom = _musicSelectedFrom;
@synthesize music = _music;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enableMusicLoop = ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) == ACCMusicLoopModeDeafultLoop;
    }
    return self;
}

#pragma mark - public
- (NSString *)musicEditedFrom
{
    if (ACC_isEmptyString(_musicEditedFrom)) {
        return @"none";
    }
    return _musicEditedFrom;
}

- (NSString *)musicSelectedFrom
{
    NSString *musicFrom = self.music.musicSelectedFrom;
    ACCRepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:ACCRepoCutSameModel.class];
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];

    NSAssert(cutSameModel, @"extension model should not be nil");
    if (musicFrom && self.music.awe_selectPageName) {
        BOOL isReuseFeedMusic = [musicFrom isEqualToString:@"same_prop_music"];
        NSString * music_msf = isReuseFeedMusic ? musicFrom : [NSString stringWithFormat:@"%@_%@",self.music.awe_selectPageName, musicFrom];
        if (!_musicSelectedFrom) {
            _musicSelectedFrom = music_msf;
        } else if (_musicSelectedFrom && ![_musicSelectedFrom isEqualToString:music_msf]) {//从草稿恢复，然后又选了别的音乐
            _musicSelectedFrom = music_msf;
        }
    } else if (cutSameModel.cutSameMusicID &&
               (_musicSelectedFrom == nil || _musicSelectedFrom.length == 0)) {
        if (contextModel.videoType == AWEVideoTypeOneClickFilming) {
            return @"ai_upload_rec";
        } else {
            // Use cut same music
            return @"jianying_mv_default";
        }
    }
    
    return _musicSelectedFrom;
}

- (void)setAudioRange:(HTSAudioRange)audioRange{
    _audioRange = audioRange;
}

- (void)setMusic:(id<ACCMusicModelProtocol>)music
{
    if (_music == music) {
        return;
    }
    
    _music = music;
    
    ACCRepoDraftModel *draftModel = [self.repository extensionModelOfClass:ACCRepoDraftModel.class];
    ACCRepoReshootModel *reshootModel = [self.repository extensionModelOfClass:ACCRepoReshootModel.class];
//    NSAssert(draftModel, @"extension model should not be nil"); lxdtodo: will be fixed on develop
//    NSAssert(reshootModel, @"extension model should not be nil");

    if (reshootModel.isReshoot) { // do not copy music related files for reshooting
        return;
    }
    NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:draftModel.taskID];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:draftFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:draftFolder withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:music.loaclAssetUrl.path]) {
        // 音频路径不存在时，尝试使用拷贝到草稿前的路径
        music.loaclAssetUrl = music.originLocalAssetUrl;
    }
    
    if (music.loaclAssetUrl) {
        NSString *lastPathComponent = [music.loaclAssetUrl lastPathComponent];
        NSString *fileExtension = [music.playURL.URI pathExtension];
        
        if (ACC_isEmptyString(fileExtension)) {
            fileExtension = @"mp3";
        }
        
        fileExtension = [@"." stringByAppendingString:fileExtension];
        
        lastPathComponent = [lastPathComponent stringByReplacingOccurrencesOfString:@".mdl" withString:fileExtension]; //audio file downloaded by TTVideoEngine has a custom extension of 'mdl', which does not work properly
                
        if (music.isLocalScannedMedia && ![music.loaclAssetUrl.path hasPrefix:draftFolder]) {
            // 本地音频可能含有中文路径，中文路径在草稿迁移时会有问题，在拷贝到草稿时需修改文件名
            lastPathComponent = [self generateLocalAudioDraftFileName:lastPathComponent];
        }
        
        NSString *draftMusicPath = [draftFolder stringByAppendingPathComponent:lastPathComponent];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:draftMusicPath]) {
            NSURL *musicURL = [NSURL fileURLWithPath:draftMusicPath];
            NSError *error = nil;
            if (musicURL && [[NSFileManager defaultManager] fileExistsAtPath:music.loaclAssetUrl.path]) {
                [[NSFileManager defaultManager] copyItemAtURL:music.loaclAssetUrl toURL:musicURL error:&error];
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:draftMusicPath] && !error) {
                music.loaclAssetUrl = musicURL;
            }
        }
    }
    
    if (music.localStrongBeatURL) {
        self.strongBeatPath = [AWEDraftUtils strongBeatPathForMusic:music.musicID taskId:draftModel.taskID];
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.strongBeatPath]) {
            NSError *error = nil;
            if (self.strongBeatPath && [[NSFileManager defaultManager] fileExistsAtPath:music.localStrongBeatURL.path]) {
                [[NSFileManager defaultManager] copyItemAtPath:music.localStrongBeatURL.path toPath:self.strongBeatPath error:&error];
            }
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.strongBeatPath] && !error) {
                music.localStrongBeatURL = [NSURL URLWithString:self.strongBeatPath];
            } else {
                self.strongBeatPath = nil;
            }
        }
    } else {
        NSString *strongBeatPath = [AWEDraftUtils strongBeatPathForMusic:music.musicID taskId:draftModel.taskID];
        if ([[NSFileManager defaultManager] fileExistsAtPath:strongBeatPath]) {
            music.localStrongBeatURL = [NSURL URLWithString:strongBeatPath];
        }
    }
}

- (BOOL)shouldEnableMusicLoop:(CGFloat)videoMaxDuration
{
    return [self p_shouldShowMusicLoopComponent:videoMaxDuration] && self.enableMusicLoop;
}

- (BOOL)p_shouldShowMusicLoopComponent:(CGFloat)videoMaxDuration
{
    id<ACCMusicModelProtocol> music = self.music;

    if (!music || !music.shootDuration || !music.videoDuration) {
        return NO;
    }

    if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) == ACCMusicLoopModeOff) {
        return NO;
    }

    if (ACC_FLOAT_LESS_THAN(videoMaxDuration, [music.shootDuration floatValue] + 1)) {
        return NO;
    }

    if (videoMaxDuration > 60 && music.isPGC && [music.videoDuration intValue] <= 60) {
        return NO;
    }

    return YES;
}

- (BOOL)shouldReplaceClipDurationWithMusicShootDuration:(CGFloat)duration
{
    id<ACCMusicModelProtocol> music = self.music;

    // duration 是从音乐 asset 中获取的时长，服务端下发的 shootDuration 会向下取整
    // 比如 duration 是 12.5，此时服务端下发的 shootDuration 是 12
    // 差值大于 1 保证音乐能完整播放
    if (music.shootDuration && [music.shootDuration integerValue] > 0 && (duration - [music.shootDuration integerValue]) >= 1) {
        return YES;
    }

    return NO;
}

- (NSString *)generateLocalAudioDraftFileName:(NSString *)localAudioFile
{
    NSString *extention = [localAudioFile pathExtension];
    NSString *draftAudioName = [localAudioFile stringByDeletingPathExtension];
    draftAudioName = [draftAudioName acc_md5String];
    localAudioFile = [draftAudioName stringByAppendingPathExtension:extention];
    return localAudioFile;
}

#pragma mark - copying

- (id)copyWithZone:(NSZone *)zone {
    AWERepoMusicModel *model = [super copyWithZone:zone];
    model.disableMusicModule = self.disableMusicModule;
    model.repository = self.repository;
    model.musicList = self.musicList;
    model.weakBindMusic = self.weakBindMusic;
    model.useSuggestClipRange = self.useSuggestClipRange;
    model.enableMusicLoop = self.enableMusicLoop;
    model.musicEditedFrom = self.musicEditedFrom;
    model.bgmAssetURL = self.bgmAssetURL;
    model.bgmRelativePath = self.bgmRelativePath;
    model.musicJson = self.musicJson;
    model.strongBeatPath = self.strongBeatPath;
    model.strongBeatRelativePath = self.strongBeatRelativePath;
    model.currentFeedModel = self.currentFeedModel;
    model.shootSameVideoDuration = self.shootSameVideoDuration;
    model.musicMaxRecordableDuration = self.musicMaxRecordableDuration;
    model.musicClipBeginTime = self.musicClipBeginTime;
    model.musicConfigAssembler = self.musicConfigAssembler;
    model.voiceVolumeDisable = self.voiceVolumeDisable;
    model.passthroughMusicID = self.passthroughMusicID;
    return model;
}

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_referExtraParams
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"music_id"] = self.music.musicID;
    params[@"music_selected_from"] = self.musicSelectedFrom ?: self.music.musicSelectedFrom;
    return [params copy];
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *mutableParameter = @{}.mutableCopy;
    // 用户投稿时区分音乐来源
    mutableParameter[@"music_selected_from"] = self.musicSelectedFrom;
    mutableParameter[@"music_show_rank"] = self.musicTrackModel.musicShowRank;;
    mutableParameter[@"music_begin_time"] = @((NSInteger)(self.audioRange.location * 1000));
    mutableParameter[@"music_end_time"] = @((NSInteger)((self.audioRange.location + self.audioRange.length)*1000));
    mutableParameter[@"music_rec_type"] = self.musicTrackModel.musicRecType;
    mutableParameter[@"music_edited_from"] = self.musicEditedFrom;
    if (self.music.categoryId) {
        mutableParameter[@"song_category_id"] = self.music.categoryId;
    }
    // 上报音量信息，转成 0~100，voiceVolume和musicVolume范围为 0~2
    AWERepoVideoInfoModel *videoInfoModel = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
    CGFloat originVolume = (self.voiceVolume / 2.0) * 100;
    if (!videoInfoModel.video.hasRecordAudio) {
        originVolume = 0.f;
    }
    mutableParameter[@"origin_volume"] = [@(originVolume) stringValue];
    
    if (self.music) {
        CGFloat musicVolume = (self.musicVolume / 2.0) * 100;
        mutableParameter[@"music_volume"] = [@(musicVolume) stringValue];
    } else {
        mutableParameter[@"music_volume"] = [@(0) stringValue];
    }
    mutableParameter[@"music_usage_confirmation"] = @(self.musicUsageConfirmation);
    return mutableParameter.copy;
}


@end
