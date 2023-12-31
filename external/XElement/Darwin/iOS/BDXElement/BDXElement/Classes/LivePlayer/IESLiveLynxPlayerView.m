//
//  IESLiveLynxPlayerView.m
//  BDXElement
//
//  Created by chenweiwei.luna on 2020/10/13.
//

#import "IESLiveLynxPlayerView.h"
#import <BDWebImage/BDWebImage.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <IESLivePlayer/IESLivePlayerTrackerConfig.h>
#import "BDXElementAdapter.h"

@interface IESLiveLynxPlayerView () <IESLivePlayerControllerDelegate>

@property (nonatomic, strong) id<IESLivePlayerProtocol> innerPlayer;

@property (nonatomic, strong) UIImageView *coverImageView;

@property (nonatomic, assign) IESLivePlayerPlaybackState currentPlayState;

@property (nonatomic, weak) id<IESLiveLynxPlayerDelegate> delegate;

@property (nonatomic, assign) BOOL respondsSEI;

@end

@implementation IESLiveLynxPlayerView

- (instancetype)initWithDelegate:(id)delegate
{
    if (self =[super initWithFrame:CGRectZero]) {
        self.delegate = delegate;
        _fitMode = @"contain";
        self.currentPlayState = IESLivePlayerPlaybackStateUnknow;
        [self __configFitMode];
    }
    return self;
}

- (void)dealloc
{
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

- (void)pause
{
    [self.innerPlayer pause];
}

- (void)play
{
    [self.innerPlayer play];
}

- (void)stop
{
    [self.innerPlayer stop];
}

- (void)reloadWithStreamData:(NSString *)streamData defaultSDKKey:(NSString *)sdkKey
{
    [self configCoverHidden:NO];
    [self.innerPlayer reloadWithStreamData:streamData defaultSDKKey:sdkKey];
}

- (void)updateVideoQuality:(NSString *)quality
{
    if (BTD_isEmptyString(quality)) {
        return;
    }
    
    [self.innerPlayer updateSDKKey:quality];
}

#pragma mark - private
- (void)layoutSubviews
{
    [super layoutSubviews];
    self.coverImageView.frame = self.bounds;
    self.innerPlayer.playerView.frame = self.bounds;
}

- (void)__configPoster:(NSString *)posterURL
{
    if (BTD_isEmptyString(posterURL)) {
        [_coverImageView setHidden:YES];
        return;
    }

    [_coverImageView setHidden:self.currentPlayState == IESLivePlayerPlaybackStatePlaying];
    NSURL *url = [NSURL URLWithString:self.posterURL];
    if (url) {
        [_coverImageView bd_setImageWithURL:url options:BDImageRequestSetAnimationFade];
    }
}

- (void)__configFitMode
{
    if ([self.fitMode isEqualToString:@"contain"]) {
        self.innerPlayer.scaleType = IESLivePlayerScaleTypeAspectFit;
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else if ([self.fitMode isEqualToString:@"cover"]) {
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.innerPlayer.scaleType = IESLivePlayerScaleTypeAspectFill;
    }
}

- (void)configCoverHidden:(BOOL)hidden
{
    if (self.coverImageView.hidden != hidden) {
        self.coverImageView.hidden = hidden;
    }
}

#pragma mark - IESLivePlayerControllerDelegate
- (void)player:(id<IESLivePlayerProtocol>)player loadStateDidChange:(IESLivePlayerLoadState)loadState
{
    switch (loadState) {
        case IESLivePlayerLoadStateFirstFrame:
        {
            [self configCoverHidden:YES];
            if ([self.delegate respondsToSelector:@selector(didPlay)]) {
                [self.delegate didPlay];
            }
        }
            break;
        case IESLivePlayerLoadStateFinishPlay:
            break;
        case IESLivePlayerLoadStatePlayError:
            break;
        case IESLivePlayerLoadStateStartBuffering:
            break;
        case IESLivePlayerLoadStateFinishBuffering:
            break;
        default:
            break;
    }
}

- (void)player:(id<IESLivePlayerProtocol>)player playbackStateDidChange:(IESLivePlayerPlaybackState)playbackState
{
    self.currentPlayState = playbackState;
    
    switch (playbackState) {
        case IESLivePlayerPlaybackStatePlaying:
        {
            if (self.innerPlayer.rendered) {
                [self configCoverHidden:YES];
            }
        }
            break;
            
        case IESLivePlayerPlaybackStatePaused:
        {
            [self configCoverHidden:NO];
            if ([self.delegate respondsToSelector:@selector(didPause)]) {
                [self.delegate didPause];
            }
        }
            break;
        case IESLivePlayerPlaybackStateStopped:
        {
            [self configCoverHidden:NO];
            if ([self.delegate respondsToSelector:@selector(didStop)]) {
                [self.delegate didStop];
            }
        }
            break;
        default:
            break;
    }
    
//    NSLog(@"!========= IESLiveNewPlayerPlaybackState :%@",@(playbackState));
}

- (void)player:(id<IESLivePlayerProtocol>)player didReceiveMetaInfo:(NSDictionary *)metaInfo processed:(BOOL)processed
{
    if (self.delegate && self.respondsSEI) {
        [self.delegate didReceiveSEI:metaInfo];
    }
}

- (void)player:(id<IESLivePlayerProtocol>)player didReceiveError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(didError:)]) {
        [self.delegate didError:@{
            @"code" : @(error.code),
            @"msg"  : error ?: @"",
        }];
    }
}

// 播放器卡顿
- (void)playerFrozen:(id<IESLivePlayerProtocol>)player
{
    if ([self.delegate respondsToSelector:@selector(didStall)]) {
        [self.delegate didStall];
    }
}

// 恢复播放
- (void)playerResume:(id<IESLivePlayerProtocol>)player
{
    if ([self.delegate respondsToSelector:@selector(didResume)]) {
        [self.delegate didResume];
    }
}

#pragma mark - setter & getter
- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        // 初始使用视频封面
        _coverImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [_coverImageView setClipsToBounds:YES];
        [self insertSubview:_coverImageView aboveSubview:self.innerPlayer.playerView];
    }
    return _coverImageView;
} 

- (id<IESLivePlayerProtocol>)innerPlayer
{
    if (!_innerPlayer) {
        IESLivePlayerTrackerConfig *trackerConfig = [[IESLivePlayerTrackerConfig alloc] init];
        trackerConfig.stainedTrackInfo.bizDomain = @"X-Element";
        trackerConfig.stainedTrackInfo.pageName = @"Unknown";
        trackerConfig.stainedTrackInfo.blockName = @"x-live";
        trackerConfig.stainedTrackInfo.index = @"lynx_player_view";
        IESLivePlayerControllerConfig *config = [[IESLivePlayerControllerConfig alloc] initWithTrackConfig:trackerConfig];
        _innerPlayer = [[IESLivePlayerManager sharedInstance] createIESLivePlayerWithConfig:config];
        _innerPlayer.delegate = self;
        
        id<BDXElementLivePlayerDelegate> liveDelegate = [BDXElementAdapter sharedInstance].liveDelegate;
        if ([liveDelegate respondsToSelector:@selector(tvlSetting)]) {
            [_innerPlayer updateTVLSettings:[liveDelegate tvlSetting]];
        }
        
        __weak __typeof(self) weakSelf = self;
        _innerPlayer.reportStateBlock = ^(NSString *url, NSDictionary *reportParam) {
            __strong __typeof(weakSelf) self = weakSelf;
            if ([self.delegate respondsToSelector:@selector(reportLivePlayerLog:reportParams:)]) {
                [self.delegate reportLivePlayerLog:url reportParams:reportParam];
            }
        };
        
        [self addSubview:_innerPlayer.playerView];
    }
    
    return _innerPlayer;
}

- (void)setDelegate:(id<IESLiveLynxPlayerDelegate>)delegate
{
    if (_delegate == delegate) {
        return;;
    }
    _delegate = delegate;
    _respondsSEI = [delegate respondsToSelector:@selector(didReceiveSEI:)];
}

- (void)setMute:(BOOL)mute
{
    self.innerPlayer.muted = mute;
}

- (BOOL)mute
{
    return self.innerPlayer.muted;
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

- (void)setEnableHardDecode:(BOOL)enableHardDecode
{
    self.innerPlayer.hardwareDecode = enableHardDecode;
}

- (BOOL)enableHardDecode
{
    return self.innerPlayer.hardwareDecode;
}

- (void)setPosterURL:(NSString *)posterURL
{
    if ([_posterURL isEqualToString:posterURL]) {
        return;
    }
    _posterURL = posterURL;
    [self __configPoster:posterURL];
}

- (void)setFitMode:(NSString *)fitMode
{
    if ([fitMode isEqualToString:_fitMode]) {
        return;
    }
    
    _fitMode = fitMode;
    [self __configFitMode];
}


//- (void)setAutoPlay:(BOOL)autoPlay
//{
//    if (_autoPlay != autoPlay) {
//        _autoPlay = autoPlay;
//    }
//}
@end
