//
//  AWEAudioClipFeatureManager.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/10.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEAudioClipFeatureManager.h"
#import "ACCConfigKeyDefines.h"
#import "ACCCutMusicPanelView.h"
#import "ACCCutMusicBarChartView.h"
#import <CreationKitInfra/ACCLogProtocol.h>

#import <TTVideoEditor/IESAudioVolumConvert.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <KVOController/NSObject+FBKVOController.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CameraClient/ACCEditVideoDataConsumer.h>
#import <CameraClient/ACCSelectMusicProtocol.h>

#if __has_feature(modules)
@import CoreMedia;
@import AVFoundation;
@import UIKit;
#else
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#endif

const static NSInteger kAWEAudioBarMaxCount = 90 * 74;
const static NSTimeInterval kAWEAudioBarMaxDuration = 90.f;

@interface AWEAudioClipFeatureManager ()

@property (nonatomic, strong) UIView *clearView;

@property (nonatomic, strong) ACCCutMusicPanelView *cutMusicPanel;

@property (nonatomic, weak) UIViewController *controller;
@property (nonatomic, strong) id<ACCVideoConfigProtocol> config;

@property (nonatomic, strong) AVPlayer *internalPlayer;
@property (nonatomic, assign) CGFloat startLocation;
@property (nonatomic, assign) CGFloat totalDuration;

@property (nonatomic, assign) CGFloat videoMaxDuration;
@property (nonatomic, assign) double videoMusicShootRatio;
@property (nonatomic, assign) NSUInteger repeatPlayCount;
@property (nonatomic, assign) CGFloat totalPlayTime;
@property (nonatomic, assign) BOOL canRepeatCountChange;

@end

@implementation AWEAudioClipFeatureManager
IESAutoInject(ACCBaseServiceProvider(), config, ACCVideoConfigProtocol)

- (void)dealloc
{
    [self.KVOController unobserveAll];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    if (self = [super init]) {
        _allowUsingVideoDurationAsMaxMusicDuration = NO;
        [self p_resetMusicLoopParameter];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)addAudioCLipViewForViewController:(UIViewController *)controller
{
    self.controller = controller;
    @weakify(self);
    self.cutMusicPanel.confirmBlock = ^{
        @strongify(self);
        [self p_clearState];
        BOOL isMusicLoopOpen = [self isMusicLoopOpen];
        NSInteger repeatCount = self.shouldShowMusicLoopComponent && isMusicLoopOpen ? ceil(self.videoMusicShootRatio) : -1;
        ACCBLOCK_INVOKE(self.audioClipDoneBlock, self.cutMusicPanel.currentRange, AWEAudioClipRangeChangeTypeUnknown, isMusicLoopOpen, repeatCount);
    };
    
    self.cutMusicPanel.cancelBlock = ^{
        @strongify(self);
        [self p_clearState];
        HTSAudioRange range = {self.startLocation, self.cutMusicPanel.currentRange.length};
        ACCBLOCK_INVOKE(self.audioRangeChangeBlock, range, AWEAudioClipRangeChangeTypeUnknown, -1);
        ACCBLOCK_INVOKE(self.audioClipCancelBlock, range, AWEAudioClipRangeChangeTypeUnknown);
        ACCBLOCK_INVOKE(self.suggestSelectedChangeBlock, self.useSuggestInitial);
    };

    self.cutMusicPanel.suggestBlock = ^(BOOL selected) {
        @strongify(self);
        if (selected) {
            [self.cutMusicPanel updateStartLocation:self.music.climax.startPoint.integerValue / 1000.f animated:YES];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_replayBarFromRangeLocation];
                [self p_updateAudioSliderStartTimeIndicator];
                ACCBLOCK_INVOKE(self.audioRangeChangeBlock, [self p_currentSelectedRange], AWEAudioClipRangeChangeTypeChange, -1);
            });
        }
        ACCBLOCK_INVOKE(self.suggestSelectedChangeBlock, selected);
    };

    self.cutMusicPanel.replayMusicBlock = ^{
        @strongify(self);
        [self p_resetMusicLoopParameter];
        [self p_updateAudioSliderStartTimeIndicator];
        [self p_replayBarFromRangeLocation];
    };

    self.cutMusicPanel.setLoopMusicForEditPageBlock = ^(HTSAudioRange range, NSInteger repeatCount) {
        @strongify(self);
        // 在编辑页上剪音乐，需要重置视频播放
        ACCBLOCK_INVOKE(self.audioRangeChangeBlock, range, AWEAudioClipRangeChangeTypeChange, repeatCount);
        // 在歌词贴纸面板上剪音乐，仍需要使用内置播放器
        [self p_resetMusicLoopParameter];
        [self p_updateAudioSliderStartTimeIndicator];
        [self p_replayBarFromRangeLocation];
    };

    self.cutMusicPanel.trackAfterClickMusicLoopSwitchBlock = ^(BOOL currentIsOn) {
        @strongify(self);
        NSMutableDictionary *trackInfo = [self.audioClipCommonTrackDic mutableCopy];
        trackInfo[@"to_status"] = currentIsOn ? @"on" : @"off";
        [ACCTracker() track:@"click_loop_sound" params:[trackInfo copy]];
    };

    [self p_addAudioSliderObserver];
    self.showingAudioClipView = NO;
}

- (void)updateAudioClipViewWithTime:(Float64)time
{
    [self.cutMusicPanel updateTimestamp:time];
}

- (CMTime)getBarStartLocation
{
    return CMTimeMakeWithSeconds(self.cutMusicPanel.currentRange.location, NSEC_PER_SEC);
}

- (void)updateAudioBarWithURL:(NSURL *)assetURL
                totalDuration:(CGFloat)totalDuration
                startLocation:(CGFloat)startLocation
   exsitingVideoTotalDuration:(CGFloat)exsitingVideoTotalDuration
              enableMusicLoop:(BOOL)enableMusicLoop
{
    self.startLocation = startLocation;
    self.totalDuration = totalDuration;
    
    BOOL showDefaultFullLength = NO;
    CGFloat maxLength = 0;
    
    if (self.isFixDurationMode) {
        maxLength = MIN([self.music.shootDuration floatValue], self.fixDuration);
    } else if (self.sceneType == ACCMusicEnterScenceTypeRecorder) { // from record
        maxLength = [self.config standardVideoMaxSeconds];
        if (self.music.shootDuration && [self.music.shootDuration integerValue] > 0) {
            CGFloat videoMaxDuration = [self.config currentVideoLenthMode] == ACCRecordLengthModeStandard ? [self.config standardVideoMaxSeconds] : [self.config videoMaxSeconds];
            if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) == ACCMusicLoopModeOff) {
                maxLength = MIN([self.music.shootDuration floatValue], videoMaxDuration);
            } else {
                maxLength = videoMaxDuration;
            }
        }
    } else if (self.sceneType == ACCMusicEnterScenceTypeAIClip) { // old AIClip upload
        maxLength = ACCConfigInt(kConfigInt_AI_video_clip_max_duration);//这个实验过期了 一直取的默认值20
    } else { // edit/unknow/Lyric
        maxLength = self.config.longVideoMaxSeconds;
        if (!isnan(exsitingVideoTotalDuration)) {
            CGFloat allowedAudioDuration = exsitingVideoTotalDuration;
            if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) != ACCMusicLoopModeOff ||
                self.sceneType == ACCMusicEnterScenceTypeEditor ||
                self.sceneType == ACCMusicEnterScenceTypeLyric) {
                self.allowUsingVideoDurationAsMaxMusicDuration = YES;
            }
            maxLength = self.allowUsingVideoDurationAsMaxMusicDuration ?  allowedAudioDuration : MIN(maxLength, allowedAudioDuration);
            if (self.shouldAccommodateVideoDurationToMusicDuration) {
                maxLength = MAX(self.maximumMusicDurationToAccommodate, maxLength);
            }
        }
    }
    if (maxLength == 0) {
        // max时长不对走兜底
        showDefaultFullLength = YES;
    }
    self.videoMaxDuration = maxLength;
    self.videoMusicShootRatio = [self p_calculateVideoMusicShootRatio];

    [self p_configPropertyForCutMusicPanelView];
    [self p_updateClipInfoWithCutDuration:maxLength totalDuration:self.totalDuration];
    
    NSInteger barCount = ceil([self p_barCountForFullWidth]);
    if (!showDefaultFullLength && !isnan(self.totalDuration) && self.totalDuration > 0) {
        barCount = (NSInteger)(ceil(barCount * self.totalDuration / maxLength));
    }
    
    if (barCount > kAWEAudioBarMaxCount || isnan(self.totalDuration) || !assetURL || self.totalDuration == 0 || self.totalDuration > kAWEAudioBarMaxDuration) {
        // 点数过长走兜底];
        NSArray *volumes = [self p_defaultVolumesForBarCount:barCount];
        [self p_updateClipInfoWithVolumns:volumes startLocation:startLocation enableMusicLoop:enableMusicLoop];
        [self p_updateAudioSliderStartTimeIndicator];
        return;
    }
    
    BOOL validVolume = NO;
    NSArray *points = [ACCEditVideoDataConsumer getVolumnWaveWithAudioURL:assetURL
                                                         waveformduration:self.totalDuration
                                                              pointsCount:barCount];
    for (NSNumber *number in points) {
        CGFloat volume = [number floatValue];
        if (volume > 0) {
            validVolume = YES;
            break;
        }
    }
    if (!validVolume) {
        points = [self p_defaultVolumesForBarCount:barCount];
    }
    [self p_updateClipInfoWithVolumns:points startLocation:startLocation enableMusicLoop:enableMusicLoop];
    [self p_updateAudioSliderStartTimeIndicator];
}

- (void)configPlayerWithMusic:(id<ACCMusicModelProtocol>)music
{
    self.music = music;
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:music.loaclAssetUrl options:@{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES }];
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:asset];
    self.internalPlayer = [[AVPlayer alloc] initWithPlayerItem:item];
    @weakify(self);
    [self.KVOController observe:self.internalPlayer.currentItem keyPath:FBKVOClassKeyPath(AVPlayerItem, status) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, AVPlayerItem *  _Nonnull playerItem, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        switch (playerItem.status) {
            case AVPlayerItemStatusReadyToPlay:
                [self p_replayBarFromRangeLocation];
                break;
                
            case AVPlayerItemStatusUnknown:
                AWELogToolError(AWELogToolTagMusic, @"clip music inner player AVPlayerItemStatusUnknown");
                break;
                
            case AVPlayerItemStatusFailed:
                AWELogToolError(AWELogToolTagMusic, @"clip music inner player AVPlayerItemStatusFailed");
                break;
                
            default:
                break;
        }
    }];

    [self.internalPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        @strongify(self);
        [self p_updateBarChartViewAndPlayerProgress:CMTimeGetSeconds(self.internalPlayer.currentTime)];
    }];
}

- (void)showMusicClipView
{
    [self showMusicClipViewWithCompletion:nil];
}

- (void)showMusicClipViewWithCompletion:(void(^)(void))completion
{
    [self.cutMusicPanel showPanelAnimatedInView:self.controller.view withCompletion:completion];
    self.showingAudioClipView = YES;
}

- (BOOL)isMusicLoopOpen
{
    return self.cutMusicPanel.isMusicLoopOpen;
}

#pragma mark - private method

- (void)p_resetMusicLoopParameter
{
    self.repeatPlayCount = 0;
    self.totalPlayTime = 0;
    self.canRepeatCountChange = YES;
}

- (void)p_updateBarChartViewAndPlayerProgress:(CGFloat)currentTime
{
    if (ACC_FLOAT_LESS_THAN(currentTime, 0)) {
        return;
    }
    CGFloat musicPlayStartLocation = self.cutMusicPanel.currentRange.location;
    CGFloat musicShootDuration = [self.music.shootDuration floatValue];
    CGFloat musicPlayEndLocation = musicPlayStartLocation + musicShootDuration;
    if (self.cutMusicPanel.isMusicLoopOpen) {
        // canRepeatCountChange 变量为了防止短时间内 repeatPlayCount 自增两次
        if (fabs(currentTime - musicPlayEndLocation) < 0.01 && self.totalPlayTime > 0 && self.canRepeatCountChange) {
            self.repeatPlayCount += 1;
            self.canRepeatCountChange = NO;
            [self p_replayBarFromRangeLocation];
        } else if ((currentTime - musicPlayStartLocation) > 0.1) {
            self.canRepeatCountChange = YES;
        }

        if (currentTime > musicPlayEndLocation) {
            currentTime = musicPlayStartLocation;
        }
        CGFloat alreadyPlayTime = currentTime - musicPlayStartLocation;
        self.totalPlayTime = musicShootDuration * self.repeatPlayCount + alreadyPlayTime;
        [self updateAudioClipViewWithTime:self.totalPlayTime];

        // 总播放时长大于视频最大时长，直接停止最后一次循环
        if (self.totalPlayTime >= self.videoMaxDuration) {
            [self p_resetMusicLoopParameter];
            [self p_replayBarFromRangeLocation];
        }
    } else {
        // else 里面是原有逻辑
        [self updateAudioClipViewWithTime:currentTime];
        if (self.isReachEndOfClipedFragment || currentTime >= self.totalDuration) {
            [self p_replayBarFromRangeLocation];
        }
    }
}

- (void)p_configPropertyForCutMusicPanelView
{
    self.cutMusicPanel.shouldShowMusicLoopComponent = [self shouldShowMusicLoopComponent];
    self.cutMusicPanel.isForbidLoopForLongVideo = [self isForbidLoopForLongVideo];

    self.cutMusicPanel.musicDuration = [self.music.auditionDuration floatValue];
    self.cutMusicPanel.musicShootDuration = [self.music.shootDuration floatValue];
    self.cutMusicPanel.videoMusicRatio = [self p_calculateVideoMusicRatio];
    self.cutMusicPanel.videoMusicShootRatio = self.videoMusicShootRatio;
    self.cutMusicPanel.musicMusicShootRatio = [self p_calculateMusicMusicShootRatio];
}

- (void)p_addAudioSliderObserver
{
    @weakify(self);
    [self.KVOController observe:self.cutMusicPanel.barChartView
                        keyPath:FBKVOClassKeyPath(ACCCutMusicBarChartView, currentRange)
                        options:NSKeyValueObservingOptionNew
                          block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.audioRangeChangeBlock, [self p_currentSelectedRange], AWEAudioClipRangeChangeTypeChange, -1);
        [self p_updateAudioSliderStartTimeIndicator];
        [self p_replayBarFromRangeLocation];
        [self.cutMusicPanel selecteSuggestView:NO];
        ACCBLOCK_INVOKE(self.suggestSelectedChangeBlock, NO);
    }];
}

- (void)p_updateAudioSliderStartTimeIndicator
{
    [self.cutMusicPanel updateStartTimeIndicator];
}

- (NSInteger)p_barCountForFullWidth
{
    return [ACCCutMusicBarChartView barCountWithFullWidth];
}

- (NSArray<NSNumber *> *)p_defaultVolumesForBarCount:(NSUInteger)barCount
{
    NSMutableArray<NSNumber *> *volumes = [NSMutableArray arrayWithCapacity:barCount];
    CGFloat currentHeight = 0;
    BOOL increasing = YES;
    for (int i = 0; i < barCount; i++) {
        if (currentHeight > 0.75 && increasing) {
            increasing = NO;
            currentHeight = 0.6;
        } else if (currentHeight == 0.6 && !increasing) {
            currentHeight = 0.8;
        } else if (currentHeight == 0.8) {
            currentHeight = 0.4;
        } else if (currentHeight == 0.4 && !increasing) {
            increasing = YES;
            currentHeight = 0.6;
        } else if (currentHeight == 0.6 && increasing) {
            currentHeight = 0.7;
        } else if (currentHeight == 0.7) {
            currentHeight = 0.4;
        } else if (currentHeight == 0.4) {
            currentHeight = 0.25;
        } else if (currentHeight <= 0.75 && increasing) {
            currentHeight += 0.25;
        }
        NSNumber *volumeNumber = [NSNumber numberWithFloat:currentHeight];
        [volumes addObject:volumeNumber];
    }
    return volumes.copy;
}

- (void)p_updateClipInfoWithCutDuration:(CGFloat)cutDuration totalDuration:(CGFloat)totalDuration
{
    [self.cutMusicPanel updateClipInfoWithCutDuration:cutDuration totalDuration:totalDuration];
    NSInteger cliStart = self.music.climax.startPoint.integerValue;
    BOOL showSuggest = cliStart > 0 && totalDuration - cliStart / 1000.f >= cutDuration && ![self shouldShowMusicLoopComponent];
    [self.cutMusicPanel showSuggestView:showSuggest];
    [self.cutMusicPanel selecteSuggestView:self.useSuggestInitial];
    if (self.useSuggestInitial) {
        [self.cutMusicPanel updateStartLocation:self.music.climax.startPoint.integerValue / 1000.f];
        [self p_replayBarFromRangeLocation];
        [self p_updateAudioSliderStartTimeIndicator];
    }
}

- (void)p_updateClipInfoWithVolumns:(NSArray<NSNumber *> *)volumns
                      startLocation:(CGFloat)startLocation
                    enableMusicLoop:(BOOL)enableMusicLoop
{
    NSTimeInterval fetchStartTime = CACurrentMediaTime() * 1000;
    [self.cutMusicPanel updateClipInfoWithVolumns:volumns startLocation:startLocation enableMusicLoop:enableMusicLoop];
    NSTimeInterval duration = CACurrentMediaTime() * 1000 - fetchStartTime;
    [ACCMonitor() trackService:@"acc_clip_panel_render_duration" attributes:@{@"duration" : @(duration)}];
}

- (HTSAudioRange)p_currentSelectedRange
{
    return self.cutMusicPanel.currentRange;
}

- (BOOL)isReachEndOfClipedFragment
{
    NSTimeInterval maxThreshold = self.cutMusicPanel.currentRange.location + self.cutMusicPanel.currentRange.length;
    if (maxThreshold != 0) {
        return (Float64)self.cutMusicPanel.currentTime > maxThreshold;
    }
    return NO;
}

- (void)p_replayBarFromRangeLocation
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && self.cutMusicPanel.superview) {
        [self.internalPlayer seekToTime:CMTimeMakeWithSeconds(CMTimeGetSeconds([self getBarStartLocation]), NSEC_PER_SEC)];
        [self.internalPlayer play];
    }
}

- (void)p_clearState
{
    [self.internalPlayer pause];
    [self.internalPlayer replaceCurrentItemWithPlayerItem:nil];
    self.internalPlayer = nil;
    self.showingAudioClipView = NO;
}

- (double)p_calculateVideoMusicRatio
{
    double ratio = 1;
    CGFloat musicDuration = [self.music.auditionDuration floatValue];
    if (!ACC_FLOAT_EQUAL_ZERO(musicDuration)) {
        ratio = self.videoMaxDuration / musicDuration;
    }
    return ratio;
}

- (double)p_calculateVideoMusicShootRatio
{
    double ratio = 1;
    CGFloat musicShootDuration = [self.music.shootDuration floatValue];
    if (!ACC_FLOAT_EQUAL_ZERO(musicShootDuration)) {
        ratio = self.videoMaxDuration / musicShootDuration;
    }
    return ratio;
}

- (double)p_calculateMusicMusicShootRatio
{
    double ratio = 1;
    CGFloat musicDuration = [self.music.auditionDuration floatValue];
    CGFloat musicShootDuration = [self.music.shootDuration floatValue];
    if (!ACC_FLOAT_EQUAL_ZERO(musicShootDuration)) {
        ratio = musicDuration / musicShootDuration;
    }
    return ratio;
}

- (BOOL)shouldShowMusicLoopComponent
{
    if (!self.music || !self.music.shootDuration || !self.music.videoDuration) {
        return NO;
    }

    if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) == ACCMusicLoopModeOff) {
        return NO;
    }

    if (ACC_FLOAT_LESS_THAN(self.videoMaxDuration, [self.music.shootDuration floatValue] + 1)) {
        return NO;
    }

    if ([self isForbidLoopForLongVideo]) {
        return NO;
    }

    return YES;
}

- (BOOL)isForbidLoopForLongVideo
{
    if (self.videoMaxDuration > 60 && self.music.isPGC && [self.music.videoDuration intValue] <= 60) {
        return YES;
    }
    return NO;
}

#pragma mark - Notifications

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if (self.isShowingAudioClipView) {
        [self.internalPlayer pause];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.isShowingAudioClipView) {
        [self.internalPlayer play];
    }
}

#pragma mark - lazy init

- (UIView *)clearView {
    if (!_clearView) {
        _clearView = [[UIView alloc] init];
        _clearView.backgroundColor = [UIColor clearColor];
        _clearView.hidden = YES;
    }
    return _clearView;
}

#pragma mark - setter/getter
- (void)setMusic:(id<ACCMusicModelProtocol>)music
{
    _music = music;
    [self.cutMusicPanel updateTitle:music.musicName];
}

- (ACCCutMusicPanelView *)cutMusicPanel
{
    if (!_cutMusicPanel) {
        _cutMusicPanel = [[ACCCutMusicPanelView alloc] initWithStyle:self.lightStyle ? ACCCutMusicPanelViewStyleLight : ACCCutMusicPanelViewStyleDark];
    }
    return _cutMusicPanel;
}

@end
