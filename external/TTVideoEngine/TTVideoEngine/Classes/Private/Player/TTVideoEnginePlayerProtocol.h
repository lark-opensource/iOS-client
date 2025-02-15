//
//  TTAVPlayer.h
//  Article
//
//  Created by panxiang on 16/10/24.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TTVideoEnginePlayerDefinePrivate.h"
#import "TTVideoEngineAVPlayerItemAccessLog.h"
#import "TTVideoEngine+SubTitle.h"
#import <TTPlayerSDK/TTAVPlayerLoadControlInterface.h>
#import <TTPlayerSDK/TTAVPlayerMaskInfoInterface.h>
#import <TTPlayerSDK/TTAVPlayerSubInfoInterface.h>
#import "TTVideoEnginePlayerViewWrapper.h"

typedef void* (*DrmCreater)(int drmType);

@protocol TTVideoPlayerEngineInfoProtocol <NSObject>

@optional
- (dispatch_queue_t)usingSerialTaskQueue;
- (id<TTVideoEngineFFmpegProtocol>) getFFmpegProtocolObject;
- (TTVideoEngineSeekModeType)playerSeekMode;
@end

@protocol TTVideoPlayerStateProtocol <NSObject>

- (void)playbackStateDidChange:(TTVideoEnginePlaybackState)state;
- (void)loadStateDidChange:(TTVideoEngineLoadState)state stallReason:(TTVideoEngineStallReason)reason;
- (void)playableDurationUpdate:(NSTimeInterval)playableDuration;
- (void)playbackDidFinish:(NSDictionary *)reason;
- (void)playerIsPrepared;
- (void)playerIsReadyToPlay;
- (void)playerVideoBitrateChanged:(NSInteger)bitrate;
- (void)playerReadyToDisplay;
- (void)playerAudioRenderStart;
- (void)playerDeviceOpened:(TTVideoEngineStreamType)streamType;
- (void)playerViewWillRemove;
- (void)playerPreBuffering:(NSInteger)type;
- (void)playerOutleterPaused:(TTVideoEngineStreamType)streamType;
- (void)playerBarrageMaskInfoCompleted:(NSInteger)code;
- (void)playerAVOutsyncStateChange:(NSInteger)type pts:(NSInteger)pts;
- (void)playerNOVARenderStateChange:(TTVideoEngineNOVARenderStateType)stateType noRenderType:(int)noRenderType;
- (void)playerDidCreateKernelPlayer;
- (void)playerStartTimeNoVideoFrame:(int)streamDuration;
- (void)playerMediaInfoDidChanged:(NSInteger)infoId;

@optional
- (void)playerVideoSizeChange;
- (void)playerVideoSizeChange:(NSInteger)width height:(NSInteger)height;
@end

@protocol TTVideoEnginePlayer <NSObject>

@property (nonatomic, weak) id <TTVideoPlayerStateProtocol> delegate;

@property (nonatomic, weak) id <TTVideoPlayerEngineInfoProtocol> engine;

@property (nonatomic, weak) id <TTAVPlayerSubInfoInterface> subInfo;

// 视频view
@property (nonatomic, strong, readonly) UIView *view;

// 视频URL
@property (nonatomic, copy) NSURL *contentURL;

@property (nonatomic, assign, readwrite) int cacheFileMode;

@property (nonatomic, assign, readwrite) int testSpeedMode;

// 当前播放时间
@property(nonatomic) NSTimeInterval currentPlaybackTime;

// 总时长
@property(nonatomic, readonly) NSTimeInterval duration;

// 可播放时长
@property(nonatomic, readonly) NSTimeInterval playableDuration;

/// 从metadata获取的size，仅自研播放器实现
@property (nonatomic, assign, readonly) long long mediaSize;

// 当前播放段的缓冲进度
@property(nonatomic, readonly) NSInteger bufferingProgress;

// 播放状态
@property(nonatomic, readonly) TTVideoEnginePlaybackState playbackState;

// 加载状态
@property(nonatomic, readonly) TTVideoEngineLoadState loadState;

//scale模式
@property(nonatomic) TTVideoEngineScalingMode scalingMode;

//align模式
@property(nonatomic, assign, readwrite) TTVideoEngineAlignMode alignMode;

//align比例
@property(nonatomic, assign, readwrite) CGFloat alignRatio;

//规范化裁剪区域，width ,height在0,1 之间
@property (nonatomic, assign) CGRect normalizeCropArea;

// 播放器静音
@property (nonatomic) BOOL muted;

// 播放速率
@property (nonatomic, assign) CGFloat playbackSpeed;

// 播放器提供的accessLog
@property (nonatomic, readonly) TTVideoEngineAVPlayerItemAccessLog *accessLog;

@property (nonatomic, assign, readwrite) TTVideoEngineImageScaleType imageScaleType;

@property (nonatomic, assign, readwrite) TTVideoEngineEnhancementType enhancementType;

@property (nonatomic, assign, readwrite) TTVideoEngineImageLayoutType imageLayoutType;

@property (nonatomic, assign, readwrite) TTVideoEngineRenderType renderType;

@property (nonatomic, assign, readwrite) TTVideoEngineRenderEngine renderEngine;

@property (nonatomic, assign, readwrite) TTVideoEngineRenderEngine finalRenderEngine;

@property (nonatomic, assign, readwrite) TTVideoEngineRotateType rotateType;

@property (nonatomic, assign, readwrite) TTVideoEngineMirrorType mirrorType;

@property (nonatomic, assign, readwrite) BOOL optimizeMemoryUsage;

@property (nonatomic, assign, readwrite) BOOL looping;

@property (nonatomic, assign, readwrite) NSInteger loopWay;

@property (nonatomic, assign, readwrite) BOOL asyncInit;

@property (nonatomic, assign, readwrite) BOOL asyncPrepare;

@property (nonatomic, assign, readwrite) BOOL hardwareDecode;

@property (nonatomic, assign, readwrite) BOOL ksyByteVC1Decode;

@property (nonatomic, assign, readwrite) BOOL barrageMaskEnable;

@property (nonatomic, assign, readwrite) BOOL aiBarrageEnable;

@property (nonatomic, assign, readwrite) NSInteger openTimeOut;

@property (nonatomic, assign, readwrite) NSInteger smoothDelayedSeconds;

@property (nonatomic, readwrite) NSTimeInterval startTime;

@property (nonatomic, copy, readonly) NSDictionary *metadata;
// 用于外部提供数据的代理
@property (nonatomic, weak) id<AVAssetResourceLoaderDelegate> resourceLoaderDelegate;

//还没有prepare就已经暂停了,这个时候存在bug,进入下一个页面,视频仍然会播放,因为有loadNextUrl逻辑存在,
@property (nonatomic) BOOL isPauseWhenNotReady;

@property (nonatomic, assign) CGFloat volume;

@property (nonatomic, strong, readonly) UIImage *attachedPic;

@property (nonatomic, assign) NSInteger enableReportAllBufferUpdate;

@property (nonatomic, assign, readwrite) BOOL subEnable;

@property (nonatomic, strong, readwrite) NSString *subTitleUrlInfo;

@property (nonatomic, assign, readwrite) NSInteger subLanguageId;

@property (nonatomic, assign) BOOL enableRemoveTaskQueue;

- (NSString *)getVersion;

- (void)prepareToPlay;

- (void)play;

- (void)pause;
- (void)pause:(BOOL)async;

- (void)stop;
- (void)close;
- (void)closeAsync;

- (BOOL)isPlaying;

- (float)currentRate;

- (BOOL)isPrerolling;

- (BOOL)isCustomPlayer;//自研播放器

- (void)setIgnoreAudioInterruption:(BOOL)ignore;

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime complete:(void(^)(BOOL success))complete;

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime complete:(void(^)(BOOL success))finished renderComplete:(void(^)(BOOL isSeekInCached))renderComplete;

- (void)playNextWithURL:(NSURL *)url complete:(void(^)(BOOL success))finished;

- (void)switchStreamBitrate:(NSInteger)bitrate ofType:(NSInteger)type completion:(void(^)(BOOL success))finished;

- (long long)numberOfBytesPlayed;

- (long long)numberOfBytesTransferred;

- (long long)downloadSpeed;

- (long long)videoBufferLength;

- (long long)audioBufferLength;

- (void)setPrepareFlag:(BOOL)flag;

- (void)setIntValue:(int)value forKey:(int)key;

- (void)setValueVoidPTR:(void *)value forKey:(int)key;

- (void)setFloatValue:(float)value forKey:(int)key;

- (void)setEffect:(NSDictionary *)effectParam;

- (void)setCustomHeader:(NSDictionary *)header;

- (int64_t)getInt64ValueForKey:(int)key;

- (int64_t)getInt64Value:(int64_t)dValue forKey:(int)key;

- (int)getIntValueForKey:(int)key;

- (int)getIntValue:(int)dValue forKey:(int)key;

- (CGFloat)getFloatValueForKey:(int)key;

- (NSString *)getStringValueForKey:(int)key;

- (CVPixelBufferRef)copyPixelBuffer;

- (void)setDrmCreater:(DrmCreater)drmCreater;

- (void)setAVPlayerItem:(AVPlayerItem *)playerItem;

- (void)setLoadControl:(id<TTAVPlayerLoadControlInterface>)loadControl;

- (void)setMaskInfo:(id<TTAVPlayerMaskInfoInterface>)maskInfo;

- (void)setAIBarrageInfo:(id<TTAVPlayerMaskInfoInterface>)barrageInfo;

- (void)setEnableReportAllBufferUpdate:(NSInteger)enableReportAllBufferUpdate;

- (void)setUpPlayerViewWrapper:(TTVideoEnginePlayerViewWrapper *)viewWrapper;

- (void)refreshPara;

- (NSString *_Nullable)getSubtitleContent:(NSInteger)queryTime Params:(NSMutableDictionary *_Nullable)params;

@end

