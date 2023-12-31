//
//  BDXLynxAudioUI.m
//  BDXElement-Pods-Aweme
//
//  Created by DylanYang on 2020/9/25.
//

#import "BDXLynxAudioUI.h"
#import "BDXAudioDefines.h"
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxRootUI.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <Lynx/LynxLog.h>
#import "BDXAudioQueueModel.h"
#import "BDXAudioService.h"
#import <AVFoundation/AVFoundation.h>
#import "BDXAudioNativeIMPs.h"
#import <objc/runtime.h>
#import "BDXElementResourceManager.h"
#import "BDXElementAdapter.h"
#import "BDXElementMonitorDelegate.h"

typedef NS_ENUM(NSUInteger, BDXAudioPlayerCategory) {
    BDXAudioPlayerCategoryAmbient, // default
    BDXAudioPlayerCategoryPlayback
};

@interface BDXLynxAudioUI()<BDXAudioServiceDelegate, BDXAudioViewLifeCycleDelegate, AVAudioPlayerDelegate>
@property (nonatomic, strong) BDXAudioService *audioService;
@property (nonatomic, assign) BDXAudioPlayerQueueLoopMode loopMode;
@property (nonatomic, copy) NSString *lastAudioId;

@property (nonatomic, assign) BDXAudioPlayerType playerType;
@property (nonatomic, assign) BDXAudioPlayerCategory playerCategory;

@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVAudioPlayer *avAudioPlayer;
@property (nonatomic, assign) AVPlayerStatus avPlayerStatus;
@property (nonatomic, assign) BOOL avPlayerDidInvokePlay;
@property (nonatomic, assign) BOOL avPlayerInPlaying;
@property (nonatomic, assign) BOOL srcFinished; // src finished flag
@property (nonatomic, assign) BOOL srcFinishedNeedPlay; // flag when call play before src finished
@property (nonatomic, assign) NSTimeInterval playableTime;
@property (nonatomic, assign) BOOL stopAutoPlay;
@property (nonatomic, strong) dispatch_queue_t playQueue;
@property (nonatomic, copy) NSString* src;
@property (nonatomic, assign) BOOL enableEvent;
@end

@implementation BDXLynxAudioUI
#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-audio")
#else
LYNX_REGISTER_UI("x-audio")
#endif

- (UIView*)createView {
    BDXAudioView *view = [[BDXAudioView alloc] init];
    view.delegate = self;
    return view;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _playQueue = dispatch_queue_create("BDXLynxAudioUIPlayQueue", DISPATCH_QUEUE_SERIAL);
        _playerType = BDXAudioPlayerTypeDefault;
        _playableTime = -1;
//        [self _initAudioServiceIfNeeded];
        _playerCategory = [[AVAudioSession sharedInstance] category] == AVAudioSessionCategoryPlayback ? BDXAudioPlayerCategoryPlayback : BDXAudioPlayerCategoryAmbient;
    }
    return self;
}

- (void)dealloc {
    if (self.avPlayer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.avPlayer removeObserver:self forKeyPath:@"status"];
    }
    
    [_audioService clear];
    //audioService strong reference eventService for not being dealloced at once, and break reference cycle when audioService stop at last.
    _audioService.eventService = nil;
    
    [self.avPlayer pause];
    self.avPlayerInPlaying = NO;
    self.avPlayer = nil;
    
    if (self.avAudioPlayer) {
        [self.avAudioPlayer stop];
        self.avAudioPlayer.delegate = nil;
        self.avAudioPlayer = nil;
    }
}

#pragma mark - BDXAudioViewLifeCycleDelegate
- (void)audioViewWillAppear:(BDXAudioView *)view {
}

- (void)audioViewDidDisappear:(BDXAudioView *)view {
    
    [self.audioService pause];
    [self.audioService clearCommand];
    [self.avPlayer pause];
    [self.avPlayer seekToTime:kCMTimeZero];
    self.avPlayerInPlaying = NO;
    
    if (self.avAudioPlayer) {
        dispatch_async(self.playQueue, ^{
            [self.avAudioPlayer pause];
            [self.avAudioPlayer setCurrentTime:0];
        });
    }
}

#pragma mark - Setter

LYNX_PROP_SETTER("src", src, NSString *) {
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        self.src = value;
        [self reportALogMessage:[NSString stringWithFormat:@"setSrc:%@", value] detail:nil];
        [self _handleSrc:value];
    } else {
        [self reportALogMessage:@"setSrc:null" detail:nil];
    }
}

LYNX_PROP_SETTER("list", list, NSString *) {
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        if (self.playerType == BDXAudioPlayerTypeDefault) {
            [self _initAudioServiceIfNeeded];
            BDXAudioQueueModel *queueModel = [self _resolveListAsJSON:value];
            if (self.loopMode) {
                queueModel.loopMode = self.loopMode;
            }
            else {
                queueModel.loopMode = BDXAudioPlayerQueueLoopModeDefault;
            }
            if (queueModel) {
                [self.audioService setQueue:queueModel];
                [self listDidChanged];
                if (self.autoPlay) {
                    [self.audioService play];
                } else {
                    [self.audioService prepareToPlay];
                }
            } else {
                [self.audioService prepareToPlay];
            }
            self.srcFinishedNeedPlay = NO;
            [self _srcFinished];
        }
    }
}

LYNX_PROP_SETTER("loop", loop, NSString *) {
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        if ([value isEqualToString:@"single"]) {
            _loopMode = BDXAudioPlayerQueueLoopModeSingle;
        }
        else if ([value isEqualToString:@"order"]) {
            _loopMode = BDXAudioPlayerQueueLoopModeDefault;
        }
        else if ([value isEqualToString:@"list"]) {
            _loopMode = BDXAudioPlayerQueueLoopModeList;
        }
        else {
            _loopMode = BDXAudioPlayerQueueLoopModeDefault;
        }
        
        if ([self.audioService queue]) {
            [self.audioService queue].loopMode = _loopMode;
        }
        
        if ([self _realPlayType] == BDXAudioPlayerTypeShort) {
            if (self.loopMode == BDXAudioPlayerQueueLoopModeSingle) {
                self.avAudioPlayer.numberOfLoops = -1;
            } else {
                self.avAudioPlayer.numberOfLoops = 0;
            }
        }
    }
}

LYNX_PROP_SETTER("autoplay", autoplay, BOOL) {
    [self reportALogMessage:[NSString stringWithFormat:@"setAutoplay:%d", value] detail:nil];
    _autoPlay = value;
    if (self.autoPlay && self.srcFinished) {
        [self play];
    }
    if (!self.srcFinished) {
        [self reportALogMessage:@"setAutoPlay but src not finished" detail:nil];
//        [self reportErrorCode:BDXAudioErrorCodeOtherError message:@"setAutoPlay but src not finished"];
    }
}

LYNX_PROP_SETTER("nativeplugins", nativeplugins, NSString *) {
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        NSError *error = nil;
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        if (data.length == 0) {
            return;
        }
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSString *plugin = [jsonArray btd_objectAtIndex:0];
        if ([plugin isEqualToString:@"MUSIC_METRICS"]) {
            self.enableEvent = YES;
            self.audioService.enableEvent = self.enableEvent;
        }
    }
}

LYNX_PROP_SETTER("playerType", playerType, NSString *) {
    BDXAudioPlayerType playType;
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        [self reportALogMessage:[NSString stringWithFormat:@"setPlayerType:%@", value] detail:nil];
        if ([value isEqualToString:@"default"]) {
            playType = BDXAudioPlayerTypeDefault;
        }
        else if ([value isEqualToString:@"light"]) {
            playType = BDXAudioPlayerTypeLight;
        }
        else if ([value isEqualToString:@"short"]) {
            playType = BDXAudioPlayerTypeShort;
        } else {
            playType = BDXAudioPlayerTypeDefault;
        }
    } else {
        [self reportALogMessage:@"setPlayerType:null" detail:nil];
        playType = BDXAudioPlayerTypeDefault;
    }
    if (self.playerType != playType && self.src.length > 0) {
//        [self reportErrorCode:BDXAudioErrorCodeOtherError message:@"playerType set before src"];
        [self reportALogMessage:[NSString stringWithFormat:@"setPlayerType changed: %@", value] detail:nil];
        self.playerType = playType;
        [self _cleanPlayer];
        [self _handleSrc:self.src];
    }
    self.playerType = playType;
}

LYNX_PROP_SETTER("playmode", playmode, NSString *) {
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        [self reportALogMessage:[NSString stringWithFormat:@"setPlaymode: %@", value] detail:nil];
        if ([value isEqualToString:@"playback"]) {
            self.playerCategory = BDXAudioPlayerCategoryPlayback;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        } else {
            self.playerCategory = BDXAudioPlayerCategoryAmbient;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
        }
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    } else {
        [self reportALogMessage:[NSString stringWithFormat:@"setPlaymode: %@", value] detail:nil];
    }
}

#pragma mark - Method

LYNX_UI_METHOD(play) {
    [self play];
    //    [self reportLogMessage:@"invoke play" detail:nil];
    !callback ?: callback(kUIMethodSuccess, nil);
}
    
- (void)play {
    self.stopAutoPlay = NO;
    if (!self.srcFinished && self.playerType != BDXAudioPlayerTypeDefault) {
        self.srcFinishedNeedPlay = true;
        [self reportErrorCode:BDXAudioErrorCodePlayWithoutSrc message:@"x-audio: cannot play, src load not finished"];
        [self reportALogMessage:@"cannot play, src load not finished" detail:nil];
        return;
    }
    BDXAudioPlayerType playType = [self _realPlayType];
    if (playType == BDXAudioPlayerTypeShort) {
        dispatch_async(self.playQueue, ^{
            if (!self.avAudioPlayer.isPlaying) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   [self didPlay];
               });
               [self.avAudioPlayer play];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self reportErrorCode:BDXAudioErrorCodeOtherError message:@"x-audio: is playing; cant play again"];
                    [self reportALogMessage:@"invoke play; but is in playing" detail:nil];
                });
            }
        });
    } else if (playType == BDXAudioPlayerTypeLight) {
        if (!self.avPlayerInPlaying) {
            self.avPlayerDidInvokePlay = NO;
            self.avPlayerInPlaying = YES;
            if (self.avPlayer.status == AVPlayerStatusReadyToPlay) {
                [self.avPlayer play];
                [self didPlay];
            }
            else {
                self.avPlayerDidInvokePlay = YES;
            }
        } else {
            [self reportErrorCode:BDXAudioErrorCodeOtherError message:@"x-audio: is playing; cant play again"];
        }
    } else {
        if (!self.audioService.isPlaying) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            self.playerCategory = BDXAudioPlayerCategoryPlayback;
            [self.audioService play];
        } else {
            [self reportErrorCode:BDXAudioErrorCodeOtherError message:@"x-audio: is playing; cant play again"];
        }
    }
}

LYNX_UI_METHOD(pause) {
    [self reportALogMessage:@"invoke pause" detail:nil];
    self.srcFinishedNeedPlay = NO;
    self.stopAutoPlay = YES;
    BDXAudioPlayerType playType = [self _realPlayType];
    if (playType == BDXAudioPlayerTypeShort) {
        dispatch_async(self.playQueue, ^{
            [self.avAudioPlayer pause];
        });
    } else if (playType == BDXAudioPlayerTypeLight) {
        [self.avPlayer pause];
        self.avPlayerInPlaying = NO;
    }
    else {
        [self.audioService pause];
    }
    
    !callback ?: callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(stop) {
    [self reportALogMessage:@"invoke stop" detail:nil];
    self.srcFinishedNeedPlay = NO;
    self.stopAutoPlay = YES;
    BDXAudioPlayerType playType = [self _realPlayType];
    if (playType == BDXAudioPlayerTypeShort) {
        dispatch_async(self.playQueue, ^{
            [self.avAudioPlayer stop];
            [self.avAudioPlayer setCurrentTime:0];
        });
    } else if (playType == BDXAudioPlayerTypeLight) {
        [self.avPlayer pause];
        self.avPlayerInPlaying = NO;
    }
    else {
        [self.audioService stop];
    }
    
    !callback ?: callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(seek) {
    NSTimeInterval time = [params btd_doubleValueForKey:@"currentTime"] / 1000;
    [self reportALogMessage:@"invoke seek" detail:params];
    [self.audioService seekToTime:time];
    
    !callback ?: callback(kUIMethodSuccess, nil);
}

#pragma mark - Method With Callback

LYNX_UI_METHOD(duration) {
    if (callback) {
        callback(
                 kUIMethodSuccess,
                 @{@"duration" : @(self.audioService.duration * 1000)}
                 );
    }
}

LYNX_UI_METHOD(status) {
    if (callback) {
        NSString *status = [self statusStringWithStatus:self.audioService.playStatus];
        callback(
                 kUIMethodSuccess,
                 @{@"status" : status ?: @""}
                 );
    }
}

LYNX_UI_METHOD(currentSrcID) {
    if (callback) {
        callback(
                 kUIMethodSuccess,
                 @{@"currentSrcID" : self.audioService.currentPlayModel.modelId ?: @""}
                 );
    }
}

LYNX_UI_METHOD(playBitrate) {
    if (callback) {
        callback(
                 kUIMethodSuccess,
                 @{@"playBitrate" : @(self.audioService.playBitrate)}
                 );
    }
}

LYNX_UI_METHOD(currentTime) {
    if (callback) {
        callback(
                 kUIMethodSuccess,
                 @{@"currentTime" : @(self.audioService.playbackTime * 1000)}
                 );
    }
}

LYNX_UI_METHOD(cacheTime) {
    if (callback) {
        callback(
                 kUIMethodSuccess,
                 @{@"cacheTime" : @(self.audioService.playableTime * 1000)}
                 );
    }
}

#pragma mark - Event Callback

- (void)didPlay {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioPlayEvent targetSign:[self sign] detail:@{
        @"status": [self statusStringWithStatus:self.audioService.playStatus],
        @"currentSrcID": self.audioService.currentPlayModel.modelId ?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didPause {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioPauseEvent targetSign:[self sign] detail:@{
        @"status": [self statusStringWithStatus:self.audioService.playStatus],
        @"currentSrcID": self.audioService.currentPlayModel.modelId ?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didEnd {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioEndedEvent targetSign:[self sign] detail:@{
        @"status": [self statusStringWithStatus:self.audioService.playStatus],
        @"currentSrcID": self.audioService.currentPlayModel.modelId ?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didError {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioErrorEvent targetSign:[self sign] detail:@{
        @"status": [self statusStringWithStatus:self.audioService.playStatus],
        @"currentSrcID": self.audioService.currentPlayModel.modelId ?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didErrorReport:(NSDictionary*)details {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioErrorReportEvent targetSign:[self sign] detail:@{@"category": details}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didStatusChanged {
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    param[@"status"] = [self statusStringWithStatus:self.audioService.playStatus];
    if (self.audioService.inAudioChanging && self.audioService.playStatus == BDXAudioServicePlayStatusStopped) {
        param[@"currentSrcID"] = self.lastAudioId ?:@"";
    }
    else {
        param[@"currentSrcID"] = self.audioService.currentPlayModel.modelId ?:@"";
    }
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioStatusChangedEvent targetSign:[self sign] detail:param];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didTimeUpdate {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioTimeUpdateEvent targetSign:[self sign] detail:@{
        @"currentTime": @(self.audioService.playbackTime * 1000),
        @"currentSrcID": self.audioService.currentPlayModel.modelId ?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didCacheTimeUpdate {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioCacheTimeUpdateEvent targetSign:[self sign] detail:@{
        @"cacheTime": @(self.audioService.playableTime * 1000),
        @"currentSrcID": self.audioService.currentPlayModel.modelId ?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didSeek:(NSTimeInterval)time {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioSeekEvent targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)sourceDidChanged {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioSourceChangedEvent targetSign:[self sign] detail:@{
        @"currentSrcID": self.audioService.currentPlayModel.modelId ?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)listDidChanged {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioListChangedEvent targetSign:[self sign] detail:@{
        @"currentSrcID": self.audioService.currentPlayModel.modelId ?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

#pragma mark - BDXAudioServiceDelegate
- (void)audioServiceReadyToPlay:(BDXAudioService *)service {
    self.lastAudioId = service.currentPlayModel.modelId ?:@"";
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioStatusChangedEvent targetSign:[self sign] detail:@{
        @"status": @"start",
        @"currentSrcID": service.currentPlayModel.modelId ?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)audioServiceDidPlay:(BDXAudioService *)service {
    [self didPlay];
}

- (void)audioServiceDidPause:(BDXAudioService *)service pauseType:(BDXAudioServicePauseType)type {
    [self didPause];
}

- (void)audioServiceDidStop:(BDXAudioService *)service {

}

- (void)audioServiceDidSeek:(BDXAudioService *)service {
    [self didSeek:[service playbackTime]];
}

- (void)audioServiceInPlaying:(BDXAudioService *)service {
    if (self.audioService.playStatus == BDXAudioPlayStatePlay) {
        [self didTimeUpdate];
    }
}

- (void)audioServiceAudioChanged:(BDXAudioService *)service {
    [self sourceDidChanged];
}

- (void)audioService:(BDXAudioService *)service playStatusChanged:(BDXAudioServicePlayStatus)playStatus {
    [self didStatusChanged];
}

- (void)audioService:(BDXAudioService *)service didFinishedWithError:(NSError *)error {
    if (error) {
        [self didError];
      [self reportErrorCode:BDXAudioErrorCodePlayError message:[NSString stringWithFormat:@"AudioService play fail; errorCode:%ld, description:%@", (long)error.code, error.localizedDescription]];
    }
    else {
        [self reportALogMessage:@"default play finished" detail:nil];
        [self didEnd];
    }
}

- (void)audioServicePeriodicTimeObserverForInterval:(BDXAudioService *)service {
    if (self.playerType == BDXAudioPlayerTypeDefault) {
        NSTimeInterval playableTime = [service playableTime];
        if (self.playableTime != playableTime) {
            self.playableTime = playableTime;
            [self didCacheTimeUpdate];
        }
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
  [self reportErrorCode:BDXAudioErrorCodePlayError message:[NSString stringWithFormat:@"AVAudioPlayer Decode Error; errorCode:%ld, description:%@", (long)error.code, error.localizedDescription]];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (!flag) {
        [self reportErrorCode:BDXAudioErrorCodePlayError message:@"AVAudioPlayer play finished error"];
    }
}

#pragma mark - Private

- (void)_initAudioServiceIfNeeded {
    if (!self.audioService) {
        self.audioService = [[BDXAudioService alloc] init];
        self.audioService.enableEvent = self.enableEvent;
        self.audioService.delegate = self;
        Class eventClz = BDXAudioNativeIMPs.audioEventClass;
        if (eventClz && class_conformsToProtocol(eventClz, @protocol(BDXAudioEventServiceDelegate))) {
            id<BDXAudioEventServiceDelegate> service = [[eventClz alloc] init];
            self.audioService.eventService = service;
            [self.audioService.eventService setPlayService:self.audioService];
        }
    }
}

- (void)_cleanPlayer {
    if (self.audioService) {
        [self reportALogMessage:@"_cleanPlayer:default" detail:nil];
        [self.audioService clear];
        self.audioService = nil;
    }
    if (self.avPlayer) {
        [self reportALogMessage:@"_cleanPlayer:light" detail:nil];
        [self.avPlayer pause];
        self.avPlayer = nil;
    }
    if (self.avAudioPlayer) {
        [self reportALogMessage:@"_cleanPlayer:short" detail:nil];
        [self.avAudioPlayer stop];
        self.avAudioPlayer.delegate = nil;
        self.avAudioPlayer = nil;
    }
}

- (void)_handleSrc:(NSString*)value {
    if (value.length > 0) {
        self.srcFinished = NO;
        BDXAudioModel *model = [self _resolveSrcAsJSON:value];
        
        NSMutableDictionary* context = [NSMutableDictionary dictionary];
        context[BDXElementContextContainerKey] = self.context.rootUI.lynxView;
        NSURL *baseURL;
        if ([self.context.rootView isKindOfClass:[LynxView class]]) {
            baseURL = [NSURL URLWithString:[(LynxView *)self.context.rootView url]];
        }
        
        if (self.playerType == BDXAudioPlayerTypeShort) {
            @weakify(self)
            [[BDXElementResourceManager sharedInstance] resourceDataWithURL:[NSURL URLWithString:model.playUrl] baseURL:baseURL context:[context copy] completionHandler:^(NSURL * _Nonnull url, NSData * _Nullable data, NSError * _Nullable error) {
                [self reportALogMessage:[NSString stringWithFormat:@"short: load src finished; url:%@, error:%@, resourceDataWithURL:%@", url, error, model.playUrl] detail:nil];
                @strongify(self)
                if (!error && data.length > 0) {
                    NSError* err;
                    self.avAudioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&err];
                    if (!err) {
                        self.avAudioPlayer.delegate = self;

                        [[AVAudioSession sharedInstance] setActive:YES error:nil];
                        if (self.loopMode == BDXAudioPlayerQueueLoopModeSingle) {
                            self.avAudioPlayer.numberOfLoops = -1;
                        }
                        if (self.autoPlay && !self.stopAutoPlay) {
                            dispatch_async(self.playQueue, ^{
                                if (!self.avAudioPlayer.isPlaying) {
                                    [self.avAudioPlayer play];
                                }
                            });
                        }
                        [self _srcFinished];
                        [self reportALogMessage:@"short src finished" detail:nil];
                        return;
                    } else {
                        [self reportErrorCode:BDXAudioErrorCodeShortCreateError message:@"create short player error; use light"];
                    }
                } else {
                    [self reportErrorCode:BDXAudioErrorCodeDownloadError message:@"short player download src fail; use light"];
                }
                // error use AVPlayer
                self.avAudioPlayer = nil;
                [self _createPlayer:BDXAudioPlayerTypeLight model:model baseUrl:baseURL context:context];
            }];
        } else {
            [self _createPlayer:self.playerType model:model baseUrl:baseURL context:context];
        }
    }
}

- (void)_createPlayer:(BDXAudioPlayerType)playType model:(BDXAudioModel*)model baseUrl:(NSURL*)baseURL  context:(NSMutableDictionary*)context {
    @weakify(self)
    [[BDXElementResourceManager sharedInstance] fetchLocalFileWithURL:[NSURL URLWithString:model.playUrl] baseURL:baseURL context:[context copy] completionHandler:^(NSURL * _Nonnull localUrl, NSURL * _Nonnull remoteUrl, NSError * _Nullable error) {
        @strongify(self)
        if (localUrl) {
            if (!model.localPath) {
                model.localPath = @[localUrl.path];
                if (self.playerType == BDXAudioPlayerTypeLight) {
                    [self reportALogMessage:@"light local src finished" detail:nil];
                    if (self.avPlayer) {
                        [self.avPlayer removeObserver:self forKeyPath:@"status"];
                        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
                    }
                    self.avPlayer = [AVPlayer playerWithURL:localUrl];
                    [self.avPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avPlayerFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
                }
            }
        }
        else if (remoteUrl) {
            if (self.playerType == BDXAudioPlayerTypeLight) {
                [self reportALogMessage:@"light remote src finished" detail:nil];
                if (self.avPlayer) {
                    [self.avPlayer removeObserver:self forKeyPath:@"status"];
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
                }
                self.avPlayer = [AVPlayer playerWithURL:remoteUrl];
                [self.avPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avPlayerFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
            }
            model.playUrl = remoteUrl.absoluteString;
        }
    }];
    
    if (self.playerType == BDXAudioPlayerTypeDefault) {
        [self _initAudioServiceIfNeeded];
        if (BTD_isEmptyString(model.modelId)) {
            [self reportErrorCode:BDXAudioErrorCodeOtherError message:@"BTD_isEmptyString(model.modelId)"];
            return;
        }
        if ([self.audioService.currentPlayModel.modelId isEqualToString:model.modelId]) {
            return;
        }
        else {
            BOOL srcInList = NO;
            for (BDXAudioModel *innerModel in [self.audioService queue].playModelArray) {
                if ([innerModel.modelId isEqualToString:model.modelId]) {
                    [self.audioService updateCurrentModel:innerModel];
                    if (self.autoPlay) {
                        [self.audioService play];
                    } else {
                        [self.audioService prepareToPlay];
                    }
                    srcInList = YES;
                    break;
                }
            }
            if (!srcInList) {
                BDXAudioQueueModel *queueModel = [[BDXAudioQueueModel alloc] initWithModels:@[model] queueId:model.modelId];
                if (self.loopMode) {
                    queueModel.loopMode = self.loopMode;
                }
                else {
                    queueModel.loopMode = BDXAudioPlayerQueueLoopModeDefault;
                }
                if (queueModel) {
                    [self.audioService setQueue:queueModel];
                    if (self.autoPlay) {
                        [self.audioService play];
                    } else {
                        [self.audioService prepareToPlay];
                    }
                }
            }
            [self reportALogMessage:@"default src finished" detail:nil];
        }
    }
    [self _srcFinished];

}

- (void)_srcFinished {
    self.srcFinished = true;
    if (self.srcFinishedNeedPlay) {
        [self play];
        self.srcFinishedNeedPlay = false;
    }
}

- (BDXAudioPlayerType)_realPlayType {
    if (self.playerType == BDXAudioPlayerTypeShort && self.avAudioPlayer != nil) {
        return BDXAudioPlayerTypeShort;
    } else if (self.playerType == BDXAudioPlayerTypeLight || self.playerType == BDXAudioPlayerTypeShort) {
        return BDXAudioPlayerTypeLight;
    }
    return BDXAudioPlayerTypeDefault;
}

- (BDXAudioQueueModel *)_resolveListAsJSON:(NSString *)jsonString {
    if (jsonString.length == 0) {
        [self reportErrorCode:BDXAudioErrorCodeJsonError message:@"list:jsonString.length == 0"];
        return nil;
    }
    NSError *error = nil;
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length == 0) {
        [self reportErrorCode:BDXAudioErrorCodeJsonError message:@"list:data.length == 0"];
        return nil;
    }
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (BTD_isEmptyDictionary(jsonDict)) {
        [self reportErrorCode:BDXAudioErrorCodeJsonError message:@"list:BTD_isEmptyDictionary(jsonDict)"];
        return nil;
    }
    int position = [jsonDict btd_intValueForKey:@"position"];
    NSArray *list = [jsonDict btd_arrayValueForKey:@"list"];
    NSMutableArray *models = [[NSMutableArray alloc] init];
    BDXAudioModel * current;
    for (NSDictionary *dic in list) {
        BDXAudioModel *model = [[BDXAudioModel alloc] initWithJSONDict:dic];
        if (model && [model isVerified]) {
            [models addObject:model];
        }
    }
    if ([models btd_objectAtIndex:position]) {
        current = [models btd_objectAtIndex:position];
    }
    BDXAudioQueueModel * queue = [[BDXAudioQueueModel alloc] initWithModels:models queueId:@"audio"];
    if (current) {
        [queue updateCurrentModel:current];
    }
    return queue;
}

- (BDXAudioModel *)_resolveSrcAsJSON:(NSString *)jsonString {
    if (jsonString.length == 0) {
        [self reportErrorCode:BDXAudioErrorCodeJsonError message:@"jsonString.length == 0"];
        return nil;
    }
    NSError *error = nil;
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length == 0) {
        [self reportErrorCode:BDXAudioErrorCodeJsonError message:@"data.length == 0"];
        return nil;
    }
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (BTD_isEmptyDictionary(jsonDict)) {
        [self reportErrorCode:BDXAudioErrorCodeJsonError message:@"BTD_isEmptyDictionary(jsonDict)"];
        return nil;
    }
    BDXAudioModel *model = [[BDXAudioModel alloc] initWithJSONDict:jsonDict];
    if (!model || ![model isKindOfClass:[BDXAudioModel class]]) {
        [self reportErrorCode:BDXAudioErrorCodeJsonError message:@"create model error"];
        return nil;
    }
    return model;
}

- (NSString *)statusStringWithStatus:(BDXAudioServicePlayStatus)status {
    NSString *statusStr;
    switch (status) {
        case BDXAudioServicePlayStatusError:
            statusStr = @"error";
            break;
        case BDXAudioServicePlayStatusStopped:
            statusStr = @"stop";
            break;
        case BDXAudioServicePlayStatusPlaying:
            statusStr = @"play";
            break;
        case BDXAudioServicePlayStatusPaused:
            statusStr = @"pause";
            break;
        case BDXAudioServicePlayStatusLoading:
            statusStr = @"loading";
            break;
    }
    return statusStr ?: @"";
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object == nil) {
        return;
    }
    
    if ([object isKindOfClass: [AVPlayer class]]) {
        if ([keyPath isEqualToString:@"status"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self reportALogMessage:[NSString stringWithFormat:@"light player status changed:%ld", (long)self.avPlayer.status] detail:nil];
                if (self.playerType != BDXAudioPlayerTypeLight) {
                  [self reportErrorCode:BDXAudioErrorCodePlayError message:[NSString stringWithFormat:@"playerType:%lu != Light", (unsigned long)self.playerType]];
                    return;;
                }
                if(self.avPlayer.status == AVPlayerStatusReadyToPlay && (self.avPlayerDidInvokePlay || self.autoPlay) && !self.stopAutoPlay) {
                    self.avPlayerDidInvokePlay = NO;
                    self.avPlayerInPlaying = YES;
                    [self.avPlayer play];
                    [self didPlay];
                }
                if (self.avPlayer.status == AVPlayerStatusUnknown || self.avPlayer.status == AVPlayerStatusFailed) {
                  [self reportErrorCode:BDXAudioErrorCodePlayError message:[NSString stringWithFormat:@"avPlayer.status:%ld", (long)self.avPlayer.status]];
                }
            });
        }
    }
}

-(void)avPlayerFinished:(NSNotification*)note {
    [self reportALogMessage:@"light player finished" detail:nil];
    [self.avPlayer seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            if (self.loopMode != BDXAudioPlayerQueueLoopModeSingle) {
                [self.avPlayer pause];
                self.avPlayerInPlaying = NO;
            }
            else if (self.avPlayerInPlaying) {
                [self.avPlayer play];
            }
        }
    }];
}

#pragma mark - Report

- (NSMutableDictionary*)reportCommonParams {
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    params[@"playerType"] = @(self.playerType);
    params[@"autoPlay"] = @(self.autoPlay);
    params[@"playMode"] = @(self.playerCategory);
    params[@"src"] = self.src;
    params[@"srcFinished"] = @(self.srcFinished);
    params[@"srcFinishedNeedPlay"] = @(self.srcFinishedNeedPlay);
    params[@"stopAutoPlay"] = @(self.stopAutoPlay);
    return params;
}

- (void)reportErrorCode:(BDXAudioErrorCode)code message:(NSString *)message {
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:[self reportCommonParams]];
    params[@"code"] = @(code);
    params[@"message"] = message;
    params[@"eventName"] = @"x_audio_error";
    
    [self didErrorReport:params];

    LLogError(@"BDXLynxLottieView.mm reportErrorCode: code: %@, params: %@", @(code), params);
    
    id<BDXElementMonitorDelegate> delegate = BDXElementAdapter.sharedInstance.monitorDelegate;
    if ([delegate respondsToSelector:@selector(reportWithEventName:lynxView:metric:category:extra:)]) {
        [delegate reportWithEventName:@"x_audio_error"
                             lynxView:self.context.rootUI.lynxView
                               metric:nil
                             category:params
                                extra:nil];
    }
}

- (void)reportALogMessage:(NSString *)message detail:(NSDictionary*)detail {
    NSMutableDictionary* params = [self reportCommonParams];
    if (detail) {
        [params addEntriesFromDictionary:detail];
    }
    LLogInfo(@"x-audio message:%@ params:%@", message, params);
}

@end
