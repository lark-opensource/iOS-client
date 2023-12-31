//
//  EMAAudioPlayer.m
//  TimorImpl
//
//  Created by MacPu on 2019/5/27.
//

#import "EMAAudioPlayer.h"
#import <TTVideoEngine/TTVideoEngine.h>
#import <TTVideoEngine/TTVideoEngine+Options.h>
#import <TTVideoEngine/TTVideoEngineUtil.h>
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPCommonManager.h>
#import <TTMicroApp/BDPAudioControlManager.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/BDPAudioModel.h>

static NSString * const kScenarioNamePrefix = @"com.audio-player.gadget";

typedef void(^AudioFireEventBlock)(NSString *event , NSInteger sourceID, NSDictionary *data);

@interface EMAAudioPlayer () <TTVideoEngineDelegate, OPMediaResourceInterruptionObserver>

@property (nonatomic, strong) TTVideoEngine *player;
@property (nonatomic, strong) BDPAudioPluginModel *model;

// 当前播放的音频是否被打断
@property (nonatomic, assign) BOOL isInterruption;

/// AudioSession 管理对象
@property (nonatomic, strong) BDPScenarioObj *scenario;

/// 被打断后恢复需要和 uniqueID 对应起来
@property (nonatomic, strong) BDPUniqueID *uniqueID;

/// fireEvent的block
@property (nonatomic, copy) AudioFireEventBlock fireEventBlock;
@property (nonatomic, copy) void(^errorBlock)(id<BDPAudioPlayer> player, NSError * _Nullable error);
@end

@implementation EMAAudioPlayer

@synthesize audioID = _audioID;
@synthesize wrapper = _wrapper;

- (instancetype _Nonnull)initWithUniqueID:(OPAppUniqueID *)uniqueID
{
    self = [super init];
    if (self) {
        _uniqueID = uniqueID;
        _player = [[TTVideoEngine alloc] initWithOwnPlayer:YES];
        [_player setTag:@"miniapp"];
        [self setupObserver];
        [self p_audioSessionInit];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (void)setAudioState:(BDPAudioModel *)model
{
    if (![self.model.src isEqualToString:model.src]) {
        [_player setVideoID:model.src];
        [_player setDirectPlayURL:model.src];
        if (!BDPIsEmptyString(model.encryptToken)) {
            [_player setOptions:@{VEKKEY(VEKKeyDecryptDecryptionKey_NSString):model.encryptToken}];
        }
    }

    [_player setLooping:model.loop];
    _player.delegate = self;
    _player.volume = [model.volume floatValue];

    if (model.obeyMuteSwitch != self.model.obeyMuteSwitch) {
        [self p_resetAudioSession:model.obeyMuteSwitch];
    }

    if (model.autoplay && !self.playing) {
        [self playWithCompletion:nil];
    }

    self.model = model;
}

- (void)fireEvent:(void (^)(NSString *, NSInteger, NSDictionary *))block
{
    _fireEventBlock = block;
}

- (void)onError:(void(^)(id<BDPAudioPlayer> player, NSError * _Nullable error))errorBlock
{
    _errorBlock = errorBlock;
}

- (void)setupObserver
{
    // kBDPAudioInterruptionNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:kBDPAudioInterruptionNotification
                                               object:nil];
}

- (void)handleInterruption:(NSNotification *)notification
{
    BDPAudioInterruptionOperationType type = [notification.userInfo bdp_integerValueForKey:kBDPAudioInterruptionOperationUserInfoKey];
    
    if (type == BDPAudioInterruptionOperationTypeBackground || type == BDPAudioInterruptionOperationTypeSystemBegan) {
        // 收到音频打断事件通知，如果正在播放，暂停播放并标记为被打断
        if (self.playing) {
            [self pause];
            self.isInterruption = YES;
        }
    } else if (type == BDPAudioInterruptionOperationTypeForeground || type == BDPAudioInterruptionOperationTypeSystemEnd) {
        // 收到音频恢复事件通知
        BDPUniqueID *uniqueId = [notification.userInfo bdp_objectForKey:kBDPUniqueIDUserInfoKey ofClass:[BDPUniqueID class]];
        if (uniqueId && ![uniqueId isEqual:self.uniqueID]) {
            // 如果 uniqueID 存在，说明是某个特定小程序进入前台；如果这个小程序不是 player 的 owner，不恢复
            return;
        }
        // 如果 uniqueID 不存在，或者和 player 的 uniqueID 相同，说明被打断的小程序可能需要恢复
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
        
        if (common.isActive && self.isInterruption) {
            // 只有小程序处于前台，并且被打断过，才恢复音频播放
            self.isInterruption = NO;
            [self playWithCompletion:nil];
        }
    }
}

- (void)playWithCompletion:(void (^ _Nullable)(BOOL, NSString * _Nullable))completion
{
    WeakSelf;
    [OPMediaMutex tryLockAsyncWithScene:OPMediaMutexSceneAudioPlay observer:self completion:^(BOOL success, NSString * _Nullable errorInfo) {
        StrongSelf;
        if (!self) {
            !completion ?: completion(NO, @"internalError");
            return;
        }
        if (success) {
            [self p_audioSessionEntry];
            [self.player play];
            !completion ?: completion(YES, nil);
        } else {
            !completion ?: completion(NO, errorInfo);
        }
    }];
}

- (BOOL)pause
{
    [_player pause];
    [self p_audioSessionLeave];
    return YES;
}

- (BOOL)stop
{
    [_player stop];
    [self p_audioSessionLeave];
    [OPMediaMutex unlockWithScene:OPMediaMutexSceneAudioPlay wrapper:self.wrapper];
    return YES;
}

- (void)seek:(CGFloat)time completion:(void (^)(BOOL))completion
{
    [self stateChange:@"seeking" data:nil];
    __weak typeof(self) self_ = self;
    [_player setCurrentPlaybackTime:time complete:^(BOOL success) {
        __strong typeof(self_) self = self_;
        [self stateChange:@"seeked" data:nil];
        !completion ?: completion(success);
    }];
}

- (NSDictionary *)getAudioState
{
    BDPAudioPluginModel *model = [self.model copy];
    model.duration = [self duration];
    model.currentTime = [self currentTime];
    model.buffered = self.duration ? (self.buffered / self.duration) * 100.0 : 0.0;;
    model.paused = [self paused] || [self ended];
    return [model toDictionary];
}

#pragma mark - Audio Session

/// 根据是否遵循系统静音键生成对应的 Scenario
- (BDPScenarioObj *)p_generateScenarioObjBasedOnObeyMuteSwitch:(BOOL)obeyMuteSwitch {
    NSString *name = [NSString stringWithFormat:@"%@-%p", kScenarioNamePrefix, self];
    if (obeyMuteSwitch) {
        return [[BDPScenarioObj alloc] initWithName:name
                                           category:AVAudioSessionCategorySoloAmbient
                                               mode:AVAudioSessionModeDefault
                                            options:kNilOptions];
    } else {
        return [[BDPScenarioObj alloc] initWithName:name
                                           category:AVAudioSessionCategoryPlayback
                                               mode:AVAudioSessionModeDefault
                                            options:kNilOptions];
    }
}

/// 初始化时根据 self.mode.obeyMuteSwitch 初始化 scenario 对象
- (void)p_audioSessionInit {
    _scenario = [self p_generateScenarioObjBasedOnObeyMuteSwitch:self.model.obeyMuteSwitch];
}

/// 进入音频场景
- (void)p_audioSessionEntry {
    [BDPAudioSessionProxy entryWithObj:self.scenario scene:OPMediaMutexSceneAudioPlay observer:self];
}

/// 离开音频场景
- (void)p_audioSessionLeave {
    [BDPAudioSessionProxy leaveWithObj:self.scenario scene:OPMediaMutexSceneAudioPlay wrapper:self.wrapper];
}

/// 重置音频场景设置
- (void)p_resetAudioSession:(BOOL)obeyMuteSwitch {
    // 重置 category 设置
    [self p_audioSessionLeave];
    _scenario = [self p_generateScenarioObjBasedOnObeyMuteSwitch:obeyMuteSwitch];
    
    // 如果已经在播放中，更新 AudioSession 的 Category
    if (self.playing) {
        [self p_audioSessionEntry];
    }
}

#pragma mark - Variables Getters & Setters

- (BOOL)paused
{
    return _player.playbackState == TTVideoEnginePlaybackStatePaused;
}

- (BOOL)playing
{
    return _player.playbackState == TTVideoEnginePlaybackStatePlaying;
}

- (BOOL)ended
{
    return _player.playbackState == TTVideoEnginePlaybackStateStopped;
}

- (CGFloat)currentTime
{
    return _player.currentPlaybackTime * 1000;
}

- (CGFloat)duration
{
    return _player.duration * 1000;
}

- (CGFloat)buffered
{
    return _player.playableDuration * 1000;
}

- (void)stateChange:(NSString *)state data:(NSDictionary *)data
{
    if (![state isKindOfClass:[NSString class]]) {
        return;
    }

    NSMutableDictionary *mutableData = [[NSMutableDictionary alloc] initWithDictionary:data? :@{}];
    [mutableData setValue:@(self.audioID) forKey:@"audioId"];
    [mutableData setValue:state forKey:@"state"];
    if (self.fireEventBlock) {
        self.fireEventBlock(@"onAudioStateChange", NSNotFound, [mutableData copy]);
    }
}

#pragma mark - OPMediaResourceInterruptionObserver

- (void)mediaResourceWasInterruptedBy:(NSString *)scene msg:(NSString * _Nullable)msg
{
    BDPLogInfo(@"mediaResourceWasInterruptedBy: %@, msg: %@", scene, msg ?: @"");
    [self pause];
}

- (void)mediaResourceInterruptionEndFrom:(NSString *)scene
{
    BDPLogInfo(@"mediaResourceInterruptionEndFrom: %@", scene);
}

#pragma mark - TTVideoEngineDelegate

- (void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState
{
    static NSDictionary *stateMap = nil;
    if (!stateMap) {
        stateMap = @{@(TTVideoEnginePlaybackStateStopped): @"stop",
                     @(TTVideoEnginePlaybackStatePaused): @"pause",
                     @(TTVideoEnginePlaybackStatePlaying): @"play",
                     @(TTVideoEnginePlaybackStateError) :@"error"
                     };
    }
    if (_player == videoEngine && stateMap[@(playbackState)]) {
        if (playbackState == TTVideoEnginePlaybackStateStopped && !videoEngine.looping && self.currentTime == self.duration) {
            [self stateChange:@"ended" data:nil];
        } else if (playbackState == TTVideoEnginePlaybackStateError) {
            if (self.errorBlock) {
                self.errorBlock(self, [[NSError alloc] initWithDomain:kTTVideoErrorDomainOwnPlayer code:-1 userInfo:nil]);
            }
        } else {
            [self stateChange:stateMap[@(playbackState)] data:nil];
        }
    }
}

- (void)videoEngine:(TTVideoEngine *)videoEngine loadStateDidChanged:(TTVideoEngineLoadState)loadState
{
    static NSDictionary *loadStateMap = nil;
    if (!loadStateMap) {
        loadStateMap = @{@(TTVideoEngineLoadStateStalled): @"waiting",
                         @(TTVideoEngineLoadStatePlayable): @"canplay",
                         @(TTVideoEngineLoadStateError): @"error"};
    }

    if (_player == videoEngine && loadStateMap[@(loadState)]) {
        [self stateChange:loadStateMap[@(loadState)] data:nil];
    }
}


- (void)videoEngineDidFinish:(nonnull TTVideoEngine *)videoEngine error:(nullable NSError *)error {
    if (self.errorBlock) {
        self.errorBlock(self, error);
    }
}

- (void)videoEngineDidFinish:(nonnull TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status {
    if (self.errorBlock) {
        self.errorBlock(self, [[NSError alloc] initWithDomain:NSURLErrorDomain code:status userInfo:nil]);
    }
}

- (void)videoEngineCloseAysncFinish:(nonnull TTVideoEngine *)videoEngine { }
- (void)videoEngineUserStopped:(nonnull TTVideoEngine *)videoEngine { }

@end
