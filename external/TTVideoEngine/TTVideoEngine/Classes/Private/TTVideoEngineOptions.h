//
//  TTVideoEngineOptions.h
//

#import <Foundation/Foundation.h>
#import "TTVideoEnginePlayer.h"

@interface TTVideoEngineOptions : NSObject

@property (nonatomic, assign) BOOL vtbFlushKeepSesssion;
@property (nonatomic, assign) BOOL enableDropRASL;
@property (nonatomic, assign) BOOL isCheckVoiceInBufferingStart;
@property (nonatomic, assign) BOOL openVoiceInPrepare;
@property (nonatomic, assign) BOOL allAVViewHoldBackground;
@property (nonatomic, assign) BOOL isEnableNewOutlet;
@property (nonatomic, assign) BOOL enableSubtitleLoadOpt;
@property (nonatomic, assign) BOOL enableDisplayP3;
@property (nonatomic, assign) BOOL enableVideoTimestampMonotonic;
@property (nonatomic, assign) BOOL enableFlushSeek;
@property (nonatomic, assign) BOOL enableGetTimeOptimize;
@property (nonatomic, assign, readonly) NSInteger videoCodecTypeId;
@property (nonatomic, assign, readonly) NSInteger audioCodecTypeId;
@property (nonatomic, copy, readonly) NSString* videoCodecName;
@property (nonatomic, copy, readonly) NSString* audioCodecName;
@property (nonatomic, assign) NSInteger subtitleOpenRetryTimes;
@property (nonatomic, assign) BOOL enableRecreateSubIfNeeded;
@property (nonatomic, copy) NSString *subFormatQuery;
@property (nonatomic, assign) NSInteger positionUpdateInterval;
@property (nonatomic, assign) NSInteger preciseCache;
@property (nonatomic, assign) BOOL enableAVOutsyncCallback;
@property (nonatomic, assign) BOOL isOptBluetoothRenderSync;
@property (nonatomic, assign) NSInteger voiceWroteTimeoutMultiple;
@property (nonatomic, assign) NSInteger audioSkipLimitedTimes;
@property (nonatomic, assign) BOOL forceAsyncPause;
@property (nonatomic, assign) BOOL enableStartUpAutoResolution;
@property (nonatomic, assign) BOOL enableOutletDropLimit;
@property (nonatomic, assign) BOOL enableVideo15SR;
@property (nonatomic, assign) NSInteger threadSafeRefSwitcher;
@property (nonatomic, assign) BOOL enableOptSubSearch;
@property (nonatomic, assign) NSInteger keepDurationBufferSize;
@property (nonatomic, assign) NSInteger maxFps;
@property (nonatomic, assign) BOOL enableClockResumeResetEof;
@property (nonatomic, assign) NSInteger currentAudioInfoId;
@property (nonatomic, assign) BOOL enableUIResponderLogOnPlay;
@property (nonatomic, assign) BOOL enableAudioOutletCpuTest;
@property (nonatomic, assign) BOOL enableBufferingDirectlyRenderStartReport;
@property (nonatomic, assign) BOOL enableDirectlyBufferingEndTimeMilliSeconds;
@property (nonatomic, assign) NSInteger directlyBufferingEndTimeMilliSeconds;
@property (nonatomic, assign) BOOL enableDirectlyBufferingSendVideoPacket;
@property (nonatomic, assign) BOOL enableCacheMetalDevice;
@property (nonatomic, assign) BOOL enableFixVoiceLatency;
@property (nonatomic, assign) BOOL enableNativeMdlSeekReopen;
@property (nonatomic, assign) NSInteger enableMp4Check;
@property (nonatomic, assign) BOOL enableDemuxNonblockRead;
@property (nonatomic, assign) BOOL forbidP2p;
@property (nonatomic, assign) BOOL enableDeinterlace;
@property (nonatomic, assign) BOOL enableGearStrategy;
@property (nonatomic, assign) int64_t precisePausePts;
@property (nonatomic, assign) NSInteger framesDrop;
@property (nonatomic, assign) TTVideoEngineAudioChannelType audioChannelType;
@property (nonatomic, assign) TTVideoEngineImageRotaionType imageRotateType;
@property (nonatomic, assign) BOOL enableNativeMdlCheckTranscode;
@property (nonatomic, assign) TTVideoEngineSeekModeType seekMode;
@property (nonatomic, assign) BOOL enableStrategyRangeControl;
@property (nonatomic, assign) BOOL enableStrategyAutoAddMedia;
@property (nonatomic, assign) BOOL enableHookVoice;
@property (nonatomic, assign) BOOL enablePlaySpeedExtend;

- (instancetype)initWithPlayer:(TTVideoEnginePlayer *) player;

- (void)setDefaultValues;

- (void)applyToPlayer:(TTVideoEnginePlayer *) player;

- (void)setPreIntOptForKey:(NSInteger)key value:(int)value;

- (NSNumber*) getPreIntOptForKey:(NSNumber*)key;

@end
