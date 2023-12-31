//
//  ACCImageAlbumAudioPlayer.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/18.
//

#import "ACCImageAlbumAudioPlayer.h"
#import "ACCAudioPlayerProtocol.h"
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>

@interface ACCImageAlbumAudioPlayer ()<ACCPropRecommendMusicProtocol>

@property (nonatomic, strong) id<ACCAudioPlayerProtocol> audioPlayer;

@property (nonatomic, strong) id<ACCMusicModelProtocol>music;

@property (nonatomic, assign) BOOL didStartPlay;

@property (nonatomic, assign) BOOL needResetMusicWhenPlay;

@end

@implementation ACCImageAlbumAudioPlayer

#pragma mark - music
- (void)p_startMusicWithNeedRestart:(BOOL)needRestart
{
    // mark  user did called start
    self.didStartPlay = YES;
    
    if (!self.music) {
        return;
    }

    if (!self.audioPlayer) {
        self.audioPlayer = IESAutoInline(ACCBaseServiceProvider(), ACCAudioPlayerProtocol);
        self.audioPlayer.delegate = self;
    }
    
    if (self.needResetMusicWhenPlay) {
        [self.audioPlayer updateServiceWithMusicModel:self.music audioPlayerPlayingBlock:^{}];
        self.needResetMusicWhenPlay = NO;
        [self.audioPlayer play];
    } else {
        if (needRestart) {
            [self.audioPlayer play];
        } else {
            [self.audioPlayer continuePlay];
        }
    }
}

- (void)replay
{
    [self p_startMusicWithNeedRestart:YES];
}

- (void)continuePlay
{
    [self p_startMusicWithNeedRestart:NO];
}

- (void)pause
{
    self.didStartPlay = NO;
    [self.audioPlayer pause];
}

- (void)replaceMusic:(id<ACCMusicModelProtocol>)music
{
    if (music == self.music) {
        return;
    }
    
    self.music = music;
    self.needResetMusicWhenPlay = YES;
    if (!music) {
        [self.audioPlayer pause];
    } else {
        if (self.didStartPlay) {
            [self p_startMusicWithNeedRestart:YES];
        }
    }
}

- (void)configDelegateViewWithStatus:(ACCAVPlayerPlayStatus)status
{
    // 实现循环播放
    if (status == ACCAVPlayerPlayStatusReachEnd && self.didStartPlay) {
        [self p_startMusicWithNeedRestart:NO];
    }
}


@end
