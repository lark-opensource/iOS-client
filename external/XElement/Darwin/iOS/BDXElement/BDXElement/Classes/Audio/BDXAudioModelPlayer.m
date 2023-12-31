//
//  Copyright 2020 The Lynx Authors. All rights reserved.
//  BDXAudioModelPlayer.m
//  XElement-Pods-Aweme
//
//  Created by bytedance on 2021/9/17.
//

#import "BDXAudioModelPlayer.h"
#import <TTVideoEngine/TTVideoEngine.h>
#import <TTVideoEngine/TTVideoEngine+Options.h>
#import <ByteDanceKit/BTDMacros.h>
#import <Lynx/LynxLog.h>
#import <MediaPlayer/MediaPlayer.h>
#import <BDWebImage/BDWebImage.h>
#import <TTVideoEngine/TTVideoEngine.h>


@interface BDXAudioModelPlayer ()<TTVideoEngineDelegate>

@property (nonatomic, strong) TTVideoEngine *engine;
@property (nonatomic, assign) BDXAudioPlayerType curPlayerType;
@property (nonatomic, strong) NSMutableDictionary *nowPlayingInfo;
@property (nonatomic, strong) BDWebImageRequest *req;
@property (nonatomic, assign) BOOL wasInteraction;
@property (nonatomic, strong ,readwrite) id playCommandTarget;
@property (nonatomic, strong ,readwrite) id pauseCommandTarget;
@property (nonatomic, strong ,readwrite) id previousCommandTarget;
@property (nonatomic, strong ,readwrite) id nextCommandTarget;
@property (nonatomic, strong ,readwrite) id seekCommandTarget;

@property (nonatomic, assign) BOOL globalPlayCommandEnable;
@property (nonatomic, assign) BOOL globalPauseCommandEnable;
@property (nonatomic, assign) BOOL globalPreviousTrackCommandEnable;
@property (nonatomic, assign) BOOL globalNextTrackCommandEnable;
@property (nonatomic, assign) BOOL globalPlaybackPositionCommand;


@end

@implementation BDXAudioModelPlayer

- (instancetype)initWithPlayerType:(BDXAudioPlayerType)type{
    self = [super init];
    if (self) {
        self.curPlayerType = type;
//        [self setupNotifications];
    }
    return self;
}

- (void)storeGlobalCommandStatus {
  MPRemoteCommandCenter *command = [MPRemoteCommandCenter sharedCommandCenter];
  self.globalPlayCommandEnable = command.playCommand.isEnabled;
  self.globalPauseCommandEnable = command.pauseCommand.isEnabled;
  self.globalPreviousTrackCommandEnable = command.previousTrackCommand.isEnabled;
  self.globalNextTrackCommandEnable = command.nextTrackCommand.isEnabled;
  if (@available(iOS 9.1, *)) {
    self.globalPlaybackPositionCommand = command.changePlaybackPositionCommand.isEnabled;
  }
}

- (void)restoreGlobalCommandStatus {
  MPRemoteCommandCenter *command = [MPRemoteCommandCenter sharedCommandCenter];
  command.playCommand.enabled = self.globalPlayCommandEnable;
  command.pauseCommand.enabled = self.globalPauseCommandEnable;
  command.previousTrackCommand.enabled = self.globalPreviousTrackCommandEnable;
  command.nextTrackCommand.enabled = self.globalNextTrackCommandEnable;
  if (@available(iOS 9.1, *)) {
    command.changePlaybackPositionCommand.enabled = self.globalPlaybackPositionCommand;
  }
}


- (void)setPlayModel:(BDXAudioModel *)m{
    NSParameterAssert(m);
    self.curModel = m;

    if (m.playModel.encryptType == BDXAudioPlayerEncryptTypeModel) {
        [self.engine setVideoModel:m.playModel.videoEngineModel];
        [self.engine configResolution:m.playModel.quality params:@{}];
    }
    else if (m.localUrl){
        [self.engine setLocalURL:m.localUrl];
    }
    else if (m.playUrl){
        [self.engine setDirectPlayURL:m.playUrl];
    }
    else{
        NSAssert(false, @"playModel is error");
    }

   if (self.needNowPlayingInfo) [self setupNowPlayingInfo:m];
}

- (void)setHeaders:(NSDictionary *)headers{
    if (headers) {
        for (NSString *k in headers) {
            [self.engine setCustomHeaderValue:headers[k] forKey:k];
        }
    }
}

- (void)setUpdateInterval:(NSTimeInterval)updateInterval{
    _updateInterval = updateInterval;
    if (_updateInterval <= 0.0) return;
    @weakify(self)
    [self.engine addPeriodicTimeObserverForInterval:updateInterval queue:dispatch_get_main_queue() usingBlock:^{
        @strongify(self)
        if (self.engine.playbackState != TTVideoEnginePlaybackStatePlaying) {
            return;
        }
        [self.delegate player:self progressChanged:self.currentTime];
        if (self.needNowPlayingInfo) {
            self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.currentTime);
            self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(self.duration);
            [self refreshNowPlayingInfo];
        }
    }];
}

- (void)updateTag:(NSString *)tag {
  [self.engine setTag:tag];
}

- (void)setLoop:(BOOL)loop{
    _loop = loop;
    self.engine.looping = loop;
}

- (void)prepare{
    [self.engine prepareToPlay];
}

- (void)play{
  self.wasInteraction = NO;
  if (self.currentTime != 0) {
    [self.engine stop]; // play from start
  }
  [self.engine play];
}

- (void)pause{
  self.wasInteraction = NO;
    [self.engine pause];
}

- (void)resume{
  self.wasInteraction = NO;
    [self.engine play];
}

- (void)stop{
  self.wasInteraction = NO;
    [self.engine stop];
    [self clearRemoteCommand];
}

- (void)seekTo:(NSTimeInterval)offset{
  self.wasInteraction = NO;
    @weakify(self);
    [self.engine setCurrentPlaybackTime:offset complete:^(BOOL success) {
        @strongify(self);
        [self.delegate playerDidSeeked:self success:success];
    }];
}

- (void)mute:(BOOL)muted{
    self.engine.muted = muted;
}

- (NSTimeInterval)duration{
    return self.engine.duration;
}

- (NSTimeInterval)currentTime{
    return self.engine.currentPlaybackTime;
}

- (NSTimeInterval)cacheTime{
    return  self.engine.playableDuration;
}

- (NSInteger)status{
    return self.engine.playbackState;
}

- (NSString *)transferStatusDesByStatus:(NSInteger)status{
    switch (status) {
        case TTVideoEnginePlaybackStateStopped:
            return @"stopped";
            break;
        case TTVideoEnginePlaybackStatePlaying:
            return @"playing";
            break;
        case TTVideoEnginePlaybackStatePaused:
            return @"paused";
            break;
        case TTVideoEnginePlaybackStateError:
            return @"error";
            break;
        default:
            break;
    }
    return @"";
}

- (NSString *)transferLoadStatusDesByStatus:(NSInteger)status{
    switch (status) {
        case TTVideoEngineLoadStateUnknown:
            return @"init";
            break;
        case TTVideoEngineLoadStatePlayable:
            return @"playable";
            break;
        case TTVideoEngineLoadStateStalled:
            return @"stalled";
            break;
        case TTVideoEngineLoadStateError:
            return @"error";
            break;
        default:
            break;
    }
    return @"";
}

- (NSInteger)loadStatus{
    return self.engine.loadState;
}

-(NSInteger)playBitrate{
    id playerBitrate = [self.engine getOptionBykey:VEKKEY(VEKGetKeyPlayerBitrate_LongLong)];
    if ([playerBitrate isKindOfClass:[NSNumber class]]) {
        return [(NSNumber*)playerBitrate integerValue];
    }
    return 0;
}
#pragma mark - getters
- (TTVideoEngine *)engine{
    if (!_engine) {
        _engine = [[TTVideoEngine alloc] initWithOwnPlayer:self.curPlayerType == BDXAudioPlayerTypeDefault];
        _engine.cacheEnable = true;
        _engine.hardwareDecode = true;
        _engine.radioMode = true;
        _engine.delegate = self;
        _engine.looping = NO;
        [_engine setTag:@"AudioEnginePlayer"];
        [_engine setOptions:@{
            @(VEKKeyProxyServerEnable_BOOL):@(YES),
            @(VEKKeyPlayerCacheMaxSeconds_NSInteger): @(300),
            @(VEKKeyPlayerSeekEndEnabled_BOOL): @(YES),
            @(VEKKEYPlayerKeepFormatAlive_BOOL): @(YES)
        }];
      // Notice: AudioUnitPoolEnable must be true
      [_engine setOptionForKey:VEKKeyPlayerAudioUnitPoolEnable_BOOL value:@(YES)];
    }
    return _engine;
}

#pragma mark - TTVideoEngineDelegate
- (void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState{
    [self.delegate player:self playbackStateChanged:playbackState];
    [self debugLog:NSStringFromSelector(_cmd)];
    [self debugLog:@(playbackState).stringValue];
    if (self.needNowPlayingInfo) {
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.engine.playbackState == TTVideoEnginePlaybackStatePlaying ? @(1.0) : @(0.0);
        [self refreshNowPlayingInfo];
    }
}

- (void)videoEngine:(TTVideoEngine *)videoEngine loadStateDidChanged:(TTVideoEngineLoadState)loadState{
    [self.delegate player:self loadingStateChanged:loadState];
    [self debugLog:NSStringFromSelector(_cmd)];
    [self debugLog:@(loadState).stringValue];
}

- (void)videoEnginePrepared:(TTVideoEngine *)videoEngine{
    [self debugLog:NSStringFromSelector(_cmd)];
    [self.delegate playerPrepared:self];
}

- (void)videoEngineReadyToPlay:(TTVideoEngine *)videoEngine{
    [self debugLog:NSStringFromSelector(_cmd)];
    [self.delegate playerReadyToPlay:self];
}

- (void)videoEngineUserStopped:(TTVideoEngine *)videoEngine{
    [self debugLog:NSStringFromSelector(_cmd)];
    [self.delegate playerUserStopped:self];
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine error:(nullable NSError *)error{
    [self debugLog:NSStringFromSelector(_cmd)];
    [self.delegate playerDidFinish:self error:error];
    [self debugLog:error.description];
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status{
    [self debugLog:NSStringFromSelector(_cmd)];
}

- (void)videoEngineCloseAysncFinish:(TTVideoEngine *)videoEngine{
    [self debugLog:NSStringFromSelector(_cmd)];
}

- (void)debugLog:(NSString *)msg{
    LLogInfo(@"%@:%@",NSStringFromClass(self.class),msg);
}

#pragma mark - Interruption
//- (void)setupNotifications {
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotes:) name:AVAudioSessionInterruptionNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotes:) name:AVAudioSessionRouteChangeNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotes:) name:UIApplicationDidBecomeActiveNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotes:) name:UIApplicationWillEnterForegroundNotification object:nil];
//}
//
//- (void)clearNotifications{
//    [NSNotificationCenter.defaultCenter removeObserver:self];
//}

//- (void)receiveNotes:(NSNotification *)note {
//    if ([note.name isEqualToString:AVAudioSessionInterruptionNotification]) {
//        NSDictionary *userInfo = note.userInfo;
//        NSInteger type = [userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
//        if (type == AVAudioSessionInterruptionTypeBegan) {
//            if (self.engine.playbackState == TTVideoEnginePlaybackStatePlaying) {
//                self.wasInteraction = YES;
//                [self pause];
//            }
//            else{
//                if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
//                    return;
//                }
//                
//              if (self.wasInteraction) {
//                [self resume];
//                self.wasInteraction = NO;
//              }
//            }
//        }
//    }
//    else if ([note.name isEqualToString:AVAudioSessionRouteChangeNotification]) {
//        NSDictionary *userInfo = note.userInfo;
//        AVAudioSessionRouteChangeReason reason = [userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
//        if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {  //旧音频设备断开
//            //获取上一线路描述信息
//            AVAudioSessionRouteDescription *previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey];
//            if (!BTD_isEmptyArray(previousRoute.outputs)) {
//                //获取上一线路的输出设备类型
//                AVAudioSessionPortDescription *previousOutput = [previousRoute.outputs firstObject];
//                NSString *portType = previousOutput.portType;
//                if ([portType isEqualToString:AVAudioSessionPortHeadphones]) {
//                    if (self.engine.playbackState == TTVideoEnginePlaybackStatePlaying) {
//                        [self pause];
//                    }
//                }
//            }
//        }
//    }
//    else if ([note.name isEqualToString:UIApplicationWillEnterForegroundNotification]) {
//        if (self.wasInteraction) {
//            [self resume];
//            self.wasInteraction = NO;
//        }
//    }
//    else if ([note.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
//        if (self.wasInteraction) {
//            [self resume];
//            self.wasInteraction = NO;
//        }
//    }
//}
#pragma mark - NowPlayingInfo
- (void)setupNowPlayingInfo:(BDXAudioModel *)m{
    NSParameterAssert(m);
    if (m) {
        [self.nowPlayingInfo removeAllObjects];
        NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
        nowPlayingInfo[MPMediaItemPropertyTitle] = m.title;
        nowPlayingInfo[MPMediaItemPropertyArtist] = m.artist;
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = m.albumTitle;
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(self.engine.playableDuration);
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0;
        [self.nowPlayingInfo addEntriesFromDictionary:nowPlayingInfo];
        [self refreshNowPlayingInfo];
        NSURL *artworkURL = [NSURL URLWithString:m.albumCoverUrl];
        [self.req cancel];
        if (artworkURL) {
            @weakify(self);
           self.req = [[BDWebImageManager sharedManager] requestImage:artworkURL options:BDImageRequestDefaultPriority complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                @strongify(self);
                if (!error) {
                    if (self.needNowPlayingInfo) {
                        self.nowPlayingInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:image];
                        [self refreshNowPlayingInfo];
                    }
                }
            }];
        }
    }
}

- (void)refreshNowPlayingInfo{
    if (self.nowPlayingInfo.allKeys.count > 0) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.nowPlayingInfo];
    if (self.nowPlayingInfo.allKeys.count == 0) {
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    }
}

- (void)setupRemoteCommand{
  [self storeGlobalCommandStatus];
    MPRemoteCommand* playCommand = [MPRemoteCommandCenter sharedCommandCenter].playCommand;
    [playCommand setEnabled:YES];
    @weakify(self)
    self.playCommandTarget = [playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self);
        [self play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    MPRemoteCommand* pauseCommand = [MPRemoteCommandCenter sharedCommandCenter].pauseCommand;
    [pauseCommand setEnabled:YES];
    self.pauseCommandTarget = [pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self);
        [self pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    MPRemoteCommand* previousTrackCommand = [MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand;
    [previousTrackCommand setEnabled:false];
    self.previousCommandTarget = [previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self);
        [self.delegate playerDidTapPreRemoteCommand:self];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    MPRemoteCommand* nextTrackCommand = [MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand;
    [nextTrackCommand setEnabled:false];
    self.nextCommandTarget = [nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self);
        [self.delegate playerDidTapNextRemoteCommand:self];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    if (@available(iOS 9.1, *)) {
        MPChangePlaybackPositionCommand* changePlaybackPositionCommand = [MPRemoteCommandCenter sharedCommandCenter].changePlaybackPositionCommand;
        [changePlaybackPositionCommand setEnabled:YES];
        self.seekCommandTarget = [changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            @strongify(self);
            if ([event isKindOfClass:[MPChangePlaybackPositionCommandEvent class]]) {
                MPChangePlaybackPositionCommandEvent *e = (MPChangePlaybackPositionCommandEvent*)event;
                [self seekTo:e.positionTime];
                return MPRemoteCommandHandlerStatusSuccess;
            } else {
                return MPRemoteCommandHandlerStatusCommandFailed;
            }
        }];
    }
}

- (void)clearRemoteCommand{
    if (self.playCommandTarget) {
//        [MPRemoteCommandCenter sharedCommandCenter].playCommand.enabled = NO;
        [[MPRemoteCommandCenter sharedCommandCenter].playCommand removeTarget: self.playCommandTarget];
    }

    if (self.pauseCommandTarget) {
//        [MPRemoteCommandCenter sharedCommandCenter].pauseCommand.enabled = NO;
        [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand removeTarget: self.pauseCommandTarget];
    }

    if (self.previousCommandTarget) {
//        [MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand.enabled = NO;
        [[MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand removeTarget: self.previousCommandTarget];
    }

    if (self.nextCommandTarget) {
//        [MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand.enabled = NO;
        [[MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand removeTarget: self.nextCommandTarget];
    }

    if (self.seekCommandTarget) {
        if (@available(iOS 9.1, *)) {
//            [MPRemoteCommandCenter sharedCommandCenter].changePlaybackPositionCommand.enabled = NO;
            [[MPRemoteCommandCenter sharedCommandCenter].changePlaybackPositionCommand removeTarget: self.seekCommandTarget];
        }
    }
}

- (void)preRemoteCommandEnable:(BOOL)enable{
    [MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand.enabled = enable;
}

- (void)nextRemoteCommandEnable:(BOOL)enable{
    [MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand.enabled = enable;
}

- (NSMutableDictionary *)nowPlayingInfo{
    if (!_nowPlayingInfo) {
        _nowPlayingInfo = [NSMutableDictionary dictionary];
    }
    return _nowPlayingInfo;
}

- (void)dealloc{
    [self clearRemoteCommand];
//    [self clearNotifications];
    [_engine stop];
    [_engine removeTimeObserver];
}



@end
