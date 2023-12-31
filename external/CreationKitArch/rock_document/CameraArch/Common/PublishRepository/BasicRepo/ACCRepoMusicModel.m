//
//  ACCRepoMusicModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/25.
//

#import "ACCRepoMusicModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCPublishMusicTrackModel.h>
#import <AVFoundation/AVFoundation.h>

@interface AWEVideoPublishViewModel (RepoMusic) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoMusic)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoMusicModel.class];
    return info;
}

- (ACCRepoMusicModel *)repoMusic
{
    ACCRepoMusicModel *musicModel = [self extensionModelOfClass:ACCRepoMusicModel.class];
    NSAssert(musicModel, @"extension model should not be nil");
    return musicModel;
}

@end

@implementation ACCRepoMusicModel

@synthesize repository = _repository;

- (instancetype)init
{
    if (self = [super init]) {
        _musicVolume = 1;
        _voiceVolume = 1;
        _musicTrackInfo = @{};
    }
    return self;
}

#pragma mark - public

- (ACCPublishMusicTrackModel *)musicTrackModel
{
    if (!_musicTrackModel) {
        _musicTrackModel = [[ACCPublishMusicTrackModel alloc]init];
    }
    return _musicTrackModel;
}

- (NSString *)musicSelectedFrom
{
    ASSERT_IN_SUB_CLASS
    return @"";
}

- (void)setMusic:(id<ACCMusicModelProtocol>)music
{
    ASSERT_IN_SUB_CLASS
}

- (BOOL)hasEditMusicRange
{
    return self.audioRange.location > 0;
}

- (AVAsset *)musicAsset
{
    return self.bgmAsset;
}

- (void)resetMusicRange {
    HTSAudioRange range = {
        0
    };
    self.audioRange = range;
    self.bgmClipRange = nil;
}

#pragma mark - setter

- (void)setMusicVolume:(CGFloat)musicVolume
{
    _musicVolume = musicVolume;
}


#pragma mark - copying

- (id)copyWithZone:(NSZone *)zone {
    ACCRepoMusicModel *model = [[[self class] alloc] init];
    model.repository = self.repository;
    model.music = self.music;
    model.musicSelectedFrom = self.musicSelectedFrom;
    model.musicTrackModel = self.musicTrackModel;
    model.audioRange = self.audioRange;
    model.voiceVolume = self.voiceVolume;
    model.musicVolume = self.musicVolume;
    model.musicSelectFrom = self.musicSelectFrom;
    model.zipURI = self.zipURI;
    model.isLVAudioFrameModel = self.isLVAudioFrameModel;
    model.bgmAsset = self.bgmAsset.copy;
    model.bgmClipRange = self.bgmClipRange;
    model.musicTrackInfo = self.musicTrackInfo;
    return model;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{};
}

- (NSDictionary *)acc_publishTrackEventParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
    [paramDict addEntriesFromDictionary:publishViewModel.repoMusic.musicTrackInfo];
    return paramDict;
}

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_referExtraParams {
    NSMutableDictionary *extrasDict = @{}.mutableCopy;
    extrasDict[@"music_id"] = self.music.musicID ? : @"";
    return extrasDict.copy;
}

- (NSDictionary *)acc_errorLogParams {
    return @{
        @"music_id":self.music.musicID?:@"",
        @"voice_volume":@(self.voiceVolume),
        @"music_volume":@(self.musicVolume),
        @"audio_location":@(self.audioRange.location),
        @"audio_length":@(self.audioRange.length),
    };
}

@end
