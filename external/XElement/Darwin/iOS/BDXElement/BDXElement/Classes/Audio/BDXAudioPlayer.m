//
//  BDXAudioPlayer.m
//  BDXElement-Pods-BDXme
//
//  Created by DylanYang on 2020/9/28.
//

#import "BDXAudioPlayer.h"
#import <TTVideoEngine/TTVideoEngine.h>
#import <TTVideoEngine/TTVideoEngine+Options.h>
#import <ByteDanceKit/BTDMacros.h>

@interface BDXAudioPlayer()<TTVideoEngineDelegate>
@property (nonatomic, strong) TTVideoEngine *engine;
@end

@implementation BDXAudioPlayer
#pragma mark - public
- (NSTimeInterval)duration {
    return self.engine.duration;
}

- (NSTimeInterval)playbackTime {
    return self.engine.currentPlaybackTime;
}

- (NSTimeInterval)playableTime {
    return self.engine.playableDuration;
}

- (BOOL)isPlaying {
    return self.engine.playbackState == TTVideoEnginePlaybackStatePlaying && self.engine.loadState == TTVideoEngineLoadStatePlayable;
}

- (void)prepareToPlay {
    [self.engine prepareToPlay];
}

- (void)play {
    [self.delegate audioEngineStartPlay:self];
    [self.engine play];
}

- (void)pause {
    [self.engine pause];
}

- (void)stop {
    [self.engine stop];
}

- (BOOL)looping {
    return self.engine.looping;
}

- (void)setLooping:(BOOL)looping {
    self.engine.looping = looping;
}

- (NSInteger)playBitrate {
    id playerBitrate = [self.engine getOptionBykey:VEKKEY(VEKGetKeyPlayerBitrate_LongLong)];
    if ([playerBitrate isKindOfClass:[NSNumber class]]) {
        return [(NSNumber*)playerBitrate integerValue];
    }
    return 0;
}

- (void)seekPlaybackTime:(NSTimeInterval)time completion:(nullable void (^)(BOOL))completion {
    [self.engine setCurrentPlaybackTime:time complete:^(BOOL success) {
        if (completion) {
            completion(success);
        }
    }];
}

- (void)setPlayUrl:(NSString *)url {
    [self.engine setDirectPlayURL:url];
}

- (void)setLocalUrl:(NSString *)url {
    [self.engine setLocalURL:url];
}

- (void)setPlayModel:(BDXAudioVideoModel *)videoModel {
    [self.engine setVideoModel:videoModel.videoEngineModel];
    [self.engine configResolution:videoModel.quality params:@{}];
}

#pragma mark - private
- (TTVideoEngine *)engine {
    if (!_engine) {
        _engine = [[TTVideoEngine alloc] initWithOwnPlayer:YES];
        _engine.cacheEnable = true;
        _engine.hardwareDecode = true;
        _engine.looping = YES;
        _engine.delegate = self;
        _engine.looping = NO;
        
        [_engine setOptions:@{
            @(VEKKeyProxyServerEnable_BOOL):@(YES),
            @(VEKKeyPlayerCacheMaxSeconds_NSInteger): @(300)
        }];
        
        @weakify(self)
        [_engine addPeriodicTimeObserverForInterval:0.5 queue:dispatch_get_main_queue() usingBlock:^{
            @strongify(self)
            [self periodicTimeObserverForInterval];
        }];
    }
    return _engine;
}

- (BDXAudioPlayerLoadState)getLoadState:(TTVideoEngineLoadState)loadState {
    if (loadState == TTVideoEngineLoadStateError) {
        return BDXAudioPlayerLoadStateError;
    }
    else if (loadState == TTVideoEngineLoadStateStalled) {
        return BDXAudioPlayerLoadStateStalled;;
    }
    else if (loadState == TTVideoEngineLoadStateUnknown) {
        return BDXAudioPlayerLoadStateUnknown;
    }
    else if (loadState == TTVideoEngineLoadStatePlayable) {
        return BDXAudioPlayerLoadStatePlayable;
    }
    return BDXAudioPlayerLoadStateUnknown;
}

- (BDXAudioPlayerPlaybackState)getPlaybackState:(TTVideoEnginePlaybackState)playbackState {
    if (playbackState == TTVideoEnginePlaybackStateError) {
        return BDXAudioPlayerPlaybackStateError;
    }
    else if (playbackState == TTVideoEnginePlaybackStateStopped) {
        return BDXAudioPlayerPlaybackStateStopped;;
    }
    else if (playbackState == TTVideoEnginePlaybackStatePaused) {
        return BDXAudioPlayerPlaybackStatePaused;
    }
    else if (playbackState == TTVideoEnginePlaybackStatePlaying) {
        return BDXAudioPlayerPlaybackStatePlaying;
    }
    return BDXAudioPlayerPlaybackStateError;
}

- (void)periodicTimeObserverForInterval {
    [self.delegate audioEnginePeriodicTimeObserverForInterval:self];
}

#pragma mark - TTVideoEngineDelegate
//@required
- (void)videoEngineCloseAysncFinish:(nonnull TTVideoEngine *)videoEngine {
    
}

- (void)videoEngineDidFinish:(nonnull TTVideoEngine *)videoEngine error:(nullable NSError *)error {
    [self.delegate audioEngine:self didFinishedWithError:error];
}

- (void)videoEngineDidFinish:(nonnull TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status {
    
}

- (void)videoEngineUserStopped:(nonnull TTVideoEngine *)videoEngine {
    
}

//@optional
- (void)videoEngine:(TTVideoEngine *)videoEngine loadStateDidChanged:(TTVideoEngineLoadState)loadState {
    [self.delegate audioEngine:self loadStateChanged:[self getLoadState:loadState]];
}

- (void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState {
    [self.delegate audioEngine:self playbackStateChanged:[self getPlaybackState:playbackState]];
}

- (void)videoEngineReadyToPlay:(TTVideoEngine *)videoEngine {
    [self.delegate audioEngineReadyToPlay:self];
}

- (void)videoEngine:(TTVideoEngine *)videoEngine mdlKey:(NSString *)key hitCacheSze:(NSInteger)cacheSize {
    
}

@end
