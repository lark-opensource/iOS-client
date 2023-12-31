//
//  BDNativeLiveVideoView.m
//  BDNativeWebComponent
//
//  Created by Bytedance on 2021/9/23.
//

#import "BDNativeLiveVideoView.h"
#import <BDWebImage/BDImageView.h>
#import <TTVideoLive/TVLManager.h>
#import <AVFoundation/AVFoundation.h>

@interface BDNativeLiveVideoView () <TVLDelegate>

@property (nonatomic, strong) TVLManager *innerPlayer;
@property (nonatomic, strong) BDImageView *posterImageView;

@property (nonatomic, strong) NSMutableSet *observerSet;
@property (nonatomic, assign) BOOL registeredObservers;
@property (nonatomic, assign) BOOL interrputed;

@end

@implementation BDNativeLiveVideoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        TVLManager *liveManager = [[TVLManager alloc] initWithOwnPlayer:YES];
        liveManager.delegate = self;
        self.innerPlayer = liveManager;
        self.couldPlay = YES;
        [self addSubview:self.innerPlayer.playerView];;
        [self addSubview:self.posterImageView];
        
        self.observerSet = [NSMutableSet set];
        [self registerObserver];
    }
    return self;
}

- (void)dealloc
{
    [self removeObservers];
    [self.innerPlayer stop];
    [self.innerPlayer.playerView removeFromSuperview];
    self.innerPlayer = nil;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (!self.window) {
        [self pause];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.innerPlayer.playerView.frame = self.bounds;
    self.posterImageView.frame = self.bounds;
}

- (void)registerObserver
{
    __weak typeof (self) weakSelf = self;
    [self.observerSet addObject:[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf stop];
        }
    }]];
    
    [self.observerSet addObject:[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf stop];
            [strongSelf play];
        }
    }]];
    
    [self.observerSet addObject:[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.interrputed) return;
        [TVLManager startOpenGLESActivity];
        [strongSelf play];
        strongSelf.interrputed = NO;
    }]];
    
    [self.observerSet addObject:[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.interrputed) return;
        [TVLManager stopOpenGLESActivity];
    }]];
    
    [self.observerSet addObject:[[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionInterruptionNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        AVAudioSessionInterruptionType type = [[note.userInfo objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];

        if (type == AVAudioSessionInterruptionTypeBegan && strongSelf.innerPlayer.isPlaying) {
            [strongSelf stop];
            strongSelf.interrputed = YES;
        } else if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && strongSelf.interrputed) {
            [strongSelf play];
            strongSelf.interrputed = NO;
        }
    }]];
    self.registeredObservers = YES;
}

- (void)removeObservers
{
    if (!self.registeredObservers) {
        return;
    }
    [self.observerSet enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        [[NSNotificationCenter defaultCenter] removeObserver:obj];
    }];
    [self.observerSet removeAllObjects];
    self.registeredObservers = NO;
}

- (void)setupSrc:(NSString *)src {
    if (src.length > 0) {
        if (self.innerPlayer.isPlaying) {
            if ([self.delegate respondsToSelector:@selector(didIdle)]) {
                [self.delegate didIdle];
            }
        }
        NSURL *playURL = [NSURL URLWithString:src];
        TVLPlayerItem *playerItem = [TVLPlayerItem playerItemWithURL:playURL];
        [self.innerPlayer replaceCurrentItemWithPlayerItem:playerItem];
        if (self.autoPlay && self.couldPlay) {
            [self.innerPlayer play];
        }
    }
}

- (void)pause {
    [self.innerPlayer pause];
}

- (void)play {
    if (self.couldPlay) {
        [self.innerPlayer play];
    }
}

- (void)stop {
    [self.innerPlayer stop];
}

- (void)configCoverHidden:(BOOL)hidden {
    if (self.posterImageView.hidden != hidden) {
        self.posterImageView.hidden = hidden;
    }
}

- (void)setMute:(BOOL)mute
{
    self.innerPlayer.muted = mute;
}

- (void)setVolume:(CGFloat)volume
{
    if (volume >= 0 && volume <= 1) {
        self.innerPlayer.volume = volume;
    }
}

- (CGFloat)volume
{
    return self.innerPlayer.volume;
}

- (void)setFitMode:(NSString *)fitMode
{
    if ([fitMode isEqualToString:_fitMode]) {
        return;
    }
    
    _fitMode = fitMode;
    [self __configFitMode];
}

- (void)__configFitMode
{
    if ([self.fitMode isEqualToString:@"contain"]) {
        self.innerPlayer.playerViewScaleMode = TVLViewScalingModeAspectFit;
        self.posterImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else if ([self.fitMode isEqualToString:@"cover"]) {
        self.posterImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.innerPlayer.playerViewScaleMode = TVLViewScalingModeAspectFill;
    } else if ([self.fitMode isEqualToString:@"fill"]) {
        self.posterImageView.contentMode = UIViewContentModeScaleToFill;
        self.innerPlayer.playerViewScaleMode = TVLViewScalingModeFill;
    } else if ([self.fitMode isEqualToString:@"none"]){
        self.posterImageView.contentMode = UIViewContentModeCenter;
        self.innerPlayer.playerViewScaleMode = TVLViewScalingModeNone;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    if (cornerRadius > 0) {
        self.layer.cornerRadius = cornerRadius;
        self.layer.masksToBounds = YES;
    } else {
        self.layer.cornerRadius = 0.0;
        self.layer.masksToBounds = NO;
    }
}

- (BDImageView *)posterImageView {
    if (!_posterImageView) {
        _posterImageView = [[BDImageView alloc] init];
    }
    return _posterImageView;
}

#pragma mark - TVLDelegate

- (void)manager:(TVLManager *)manager playerItemStatusDidChange:(TVLPlayerItemStatus)status {
    switch (status) {
        case TVLPlayerItemStatusReadyToPlay: {
            if ([self.delegate respondsToSelector:@selector(didReady)]) {
                [self.delegate didReady];
            }
        }
            break;
        case TVLPlayerItemStatusReadyToRender: {
            if ([self.delegate respondsToSelector:@selector(didPlay)]) {
                [self.delegate didPlay];
            }
        }
            break;
        case TVLPlayerItemStatusCompleted: {
            if ([self.delegate respondsToSelector:@selector(didStop)]) {
                [self.delegate didStop];
            }
        }
            break;
        case TVLPlayerItemStatusFailed: {
           
        }
            break;
        case TVLPlayerItemStatusReadyToPlay | TVLPlayerItemStatusCompleted: {
            if ([self.delegate respondsToSelector:@selector(didIdle)]) {
                [self.delegate didIdle];
            }
            break;
        }
        default:
            
            break;
       }
}

- (void)manager:(TVLManager *)manager didReceiveSEI:(NSDictionary *)SEI {
    
}

- (void)manager:(TVLManager *)manager videoSizeDidChange:(CGSize)size {
    if ([self.delegate respondsToSelector:@selector(didVideoSizChange:)]) {
        [self.delegate didVideoSizChange:size];
    }
}

- (void)manager:(TVLManager *)manager videoCropAreaDidAutomaticallyChange:(CGRect)frame {
    
}

- (void)recieveError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(didError:)]) {
        [self.delegate didError:@{
            @"code": @(error.code),
            @"description" : error.localizedDescription
        }];
    }
}

- (void)startRender {
    [self configCoverHidden:YES];
}

- (void)stallStart {
    if ([self.delegate respondsToSelector:@selector(didStall)]) {
        [self.delegate didStall];
    }
}

- (void)stallEnd {
    if ([self.delegate respondsToSelector:@selector(didResume)]) {
        [self.delegate didResume];
    }
}

- (void)onStreamDryup:(NSError *)error {
    
}

- (void)onMonitorLog:(NSDictionary*) event{
    
}

- (void)loadStateChanged:(NSNumber*)state {

}


@end
