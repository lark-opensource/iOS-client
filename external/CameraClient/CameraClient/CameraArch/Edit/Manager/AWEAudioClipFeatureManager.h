//
//  AWEAudioClipFeatureManager.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/10.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import "AWEVideoEditDefine.h"
#import "ACCSelectMusicProtocol.h"

@class UIViewController;
@class AVAsset;
@protocol ACCMusicModelProtocol;

typedef void(^AWEAudioClipDoneBlock)(HTSAudioRange range, AWEAudioClipRangeChangeType changeType, BOOL enableMusicLoop, NSInteger repeatCount);
typedef void(^AWEAudioCLipCancelBlock)(HTSAudioRange range, AWEAudioClipRangeChangeType changeType);
typedef void(^AWEAudioClipRangeChangeBlock)(HTSAudioRange range, AWEAudioClipRangeChangeType changeType, NSInteger repeatCount);
typedef void(^AWEAudioClipSuggestSelectedChangeBlock)(BOOL selected);

@interface AWEAudioClipFeatureManager : NSObject

@property (nonatomic, copy) AWEAudioClipDoneBlock audioClipDoneBlock;
@property (nonatomic, copy) AWEAudioCLipCancelBlock audioClipCancelBlock;
@property (nonatomic, copy) AWEAudioClipRangeChangeBlock audioRangeChangeBlock;
@property (nonatomic, copy) AWEAudioClipSuggestSelectedChangeBlock suggestSelectedChangeBlock;
@property (nonatomic, copy) NSDictionary *audioClipCommonTrackDic; // for track

@property (nonatomic, assign, getter=isShowingAudioClipView) BOOL showingAudioClipView;
@property (nonatomic, assign) BOOL allowUsingVideoDurationAsMaxMusicDuration; // 是否允许使用视频时长作为最大音频时长
@property (nonatomic, assign) BOOL lightStyle;
@property (nonatomic, assign) BOOL userInnerPlayer;
@property (nonatomic, assign) ACCMusicEnterScenceType sceneType;
@property (nonatomic, assign) BOOL useSuggestInitial;
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> music;

@property (nonatomic, assign) BOOL isFixDurationMode; // the total length is fixed, such as using multi seg prop
@property (nonatomic, assign) CGFloat fixDuration;

@property (nonatomic, assign) BOOL usedForMusicSearch;

@property (nonatomic, assign) BOOL shouldAccommodateVideoDurationToMusicDuration; // 视频时长是否需要根据音乐时长来自适应
@property (nonatomic, assign) NSTimeInterval maximumMusicDurationToAccommodate; // 根据音乐来自适应的最大视频时长

- (void)addAudioCLipViewForViewController:(UIViewController *)controller;

- (void)showMusicClipView;

- (void)showMusicClipViewWithCompletion:(void(^)(void))completion;

- (void)updateAudioClipViewWithTime:(Float64)time;

- (CMTime)getBarStartLocation;

- (void)updateAudioBarWithURL:(NSURL *)assetURL
                totalDuration:(CGFloat)totalDuration
                startLocation:(CGFloat)startLocation
   exsitingVideoTotalDuration:(CGFloat)exsitingVideoTotalDuration
              enableMusicLoop:(BOOL)enableMusicLoop;

- (void)configPlayerWithMusic:(id<ACCMusicModelProtocol>)music;

// 当前音乐是否支持循环
- (BOOL)shouldShowMusicLoopComponent;

// 当前音乐循环是否开启
- (BOOL)isMusicLoopOpen;

@end
