//
// TTAVPlayerProtocol.h
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#ifndef TTAVPLAYER_MACOS
#define TTAVPLAYER_MACOS 0
#endif

#if TTAVPLAYER_MACOS
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

#import "TTAVPlayerLoadControlInterface.h"
#import "TTAVPlayerMaskInfoInterface.h"
#import "TTAVPlayerSubInfoInterface.h"
#import "TTAVPlayerItemProtocol.h"
#import "TTPlayerDef.h"

#ifndef TTM_DUAL_CORE_TTPLAYER_PROTOCOL
#define TTM_DUAL_CORE_TTPLAYER_PROTOCOL

#ifndef TTAVPLAYER_WRITER
#define TTAVPLAYER_WRITER 0
#endif

#if TTAVPLAYER_WRITER
#import "TTMediaWriterProtocol.h"
#endif

typedef NS_ENUM(NSInteger, AVPlayerPlaybackState) {
    AVPlayerPlaybackStateUnknown,
    AVPlayerPlaybackStateStopped,   //播放停止
    AVPlayerPlaybackStatePlaying,   //正在播放
    AVPlayerPlaybackStatePaused,    //播放暂停
    AVPlayerPlaybackStateError,     //播放出错
};

typedef NS_ENUM(NSInteger, AVPlayerLoadState) {
    AVPlayerLoadStateUnknown,
    AVPlayerLoadStateStalled,   //缓冲开始
    AVPlayerLoadStatePlayable,  //缓冲结束
    AVPlayerLoadStateError,
};

typedef NS_ENUM(NSInteger, AVPlayerViewRotation) {
    AVPlayerViewRotationNone    = 0,
    AVPlayerViewRotationLeft    = 1,
    AVPlayerViewRotationRight   = 2,
    AVPlayerViewRotation90      = 90,//clockwise
    AVPlayerViewRotation180     = 180,//clockwise
    AVPlayerViewRotation270     = 270,//clockwise
};

typedef NS_ENUM(NSUInteger, AVPlayerStallReason) {
    AVPlayerStallNone,
    AVPlayerStallNetwork,
    AVPlayerStallDecoder,
};

typedef NS_ENUM(NSInteger, AVPlayerSRType) {
    AVPlayerSRTypeNONE    = 0,
    AVPlayerSRTypeRAISE   = 1,
    AVPlayerSRTypeNNSR    = 2,
};

typedef NS_ENUM(int, TTAVPlayerBusinessIdentity) {
    TTAVPlayerBusinessIdentityLive = 0,
    TTAVPlayerBusinessIdentityVOD,
    TTAVPlayerBusinessIdentityRTC,
};

#if TTAVPLAYER_MACOS
typedef void (^TTScreenshotCompleionBlock)(NSImage *image);
#else
typedef void (^TTScreenshotCompleionBlock)(UIImage *image);
#endif
typedef void (^TTAVBufferCallback)(uint8_t *data[3], int linesize[3], int width, int height);
typedef void (^TTPacketDidReceiveCallback)(int stream, int64_t dts, int64_t pts) DEPRECATED_MSG_ATTRIBUTE("Will be deprecated, use 'TTPacketDidReceiveWithPacketInfoCallback' instead.");
typedef void (^TTPacketDidReceiveWithPacketInfoCallback)(int stream, int64_t dts, int64_t pts, NSDictionary *packetInfo);
typedef void (^TTFrameWillRenderCallback)(int stream, int64_t dts, int64_t pts, NSDictionary *frameData);
typedef void (^TTFrameDidReceiveBinarySeiCallback)(const uint8_t* binarySei, int size);
typedef void (^TTVideoFrameWillProcessCallback)(BOOL *outShouldSkip);
typedef void (^TTAbrDecisionInfoCallback)(int64_t offsetTime, const char* content);
typedef const char* (^TTAVStrategyParamsCallback)(const char* key);
typedef void (^TTSeiImmediatlyCallback)(int size, const char* content);
typedef void* (*DrmCreater)(int drmType);



@protocol TTAVPlayerProtocol <NSObject>

@property (nonatomic, strong) NSObject<TTAVPlayerItemProtocol> *currentItem;
@property (nonatomic, getter=isMuted) BOOL muted;
@property (nonatomic, assign, getter=isHardwareDecode) BOOL hardwareDecode; // iOS 8 以上版本支持硬解
@property (nonatomic) float volume;
@property (nonatomic, assign) float speed;
@property (nonatomic, assign) AVPlayerPlaybackState playbackState;  //播放状态
@property (nonatomic, assign) AVPlayerLoadState loadState;  //缓冲加载状态
@property (nonatomic, assign) AVPlayerStallReason stallReason; // 缓冲原因
#if TTAVPLAYER_MACOS
@property (nonatomic, strong, readonly) NSImage *attachedPic;
#else
@property (nonatomic, strong, readonly) UIImage *attachedPic;
#endif
@property (nonatomic, assign) CGRect normalizeCropArea;//the inputing area of Pseudo horizontal screen
//videoprocessoer instance
@property (nonatomic, assign) void* videoProcessor;

- (instancetype)initWithURL:(NSURL *)url;

- (instancetype)initWithURL:(NSURL *)url options:(NSDictionary *)header;

- (instancetype)initWithPlayerItem:(NSObject<TTAVPlayerItemProtocol>*)item;
    
- (instancetype)initWithPlayerItem:(NSObject<TTAVPlayerItemProtocol>*)item options:(NSDictionary *)header;

- (void)replaceCurrentItemWithPlayerItem:(NSObject<TTAVPlayerItemProtocol>*)item;
    
- (void)replaceCurrentItemWithPlayerItem:(NSObject<TTAVPlayerItemProtocol>*)item options:(NSDictionary *)header;

- (void)prepare;

- (void)play;

- (void)pause;

- (void)pause:(BOOL)async;

- (void)stop;

- (void)close;

- (void)closeWithoutRelease;

- (void)close:(BOOL)async;

- (void)setLoop:(BOOL)loop;

- (CMTime)currentTime;

- (void)seekToTime:(CMTime)time;

- (void)seekToTime:(CMTime)time flag:(AVSeekType)flag;

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler flag:(AVSeekType)flag;

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler renderCompleteHandler:(void (^)(BOOL isSeekInCached))renderCompleteHandler;

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler renderCompleteHandler:(void (^)(BOOL isSeekInCached))renderCompleteHandler flag:(AVSeekType)flag;

- (void)switchStreamBitrate:(NSUInteger)bitrate type:(TTMediaStreamType)type completionHandler:(void (^)(BOOL finished))completionHandler;

- (NSString *)getIPAddress;

- (float)getFloatValueForKey:(int)key;

- (NSString*)getStringValueForKey:(int)key;

- (int64_t)getInt64Value:(int64_t)dValue forKey:(int)key;

- (int)getIntValue:(int)dValue forKey:(int)key;
- (void)setFloatValue:(float)value forKey:(int)key;
- (void)setValueVoidPTR:(void*)value forKey:(int)key;
- (void)setValueString: (NSString*)value forKey:(int)key;
- (void)setValue:(int)value forKey:(int)key;
- (void)setIntValue:(int)value forKey:(int)key;
- (void)setValue:(NSDictionary*)param;
/* set filepath and open mode when used nhttp
 */
- (void)setCacheFile:(NSString *)path mode:(int)mode;

/* 
 * set notify callback queue, if not set, callback will be call at main queue.
 */
- (void)setNotifyQueue:(dispatch_queue_t)notifyQueue;

/* set the view rotation from the phone
 * the valid values are AVPlayerViewRotation
 */
- (void)setViewRotation:(AVPlayerViewRotation)rotation;

/**
 to enable or disable rotation

 @param enabled YES to enable rotation
 */
- (void)setAutoRotation:(bool)enabled;

- (CGRect)cropAreaFrame;

- (void)setCropAreaFrame:(CGRect)cropAreaFrame;

/* angle is in degree measure,
   angle.x is the angle in horizontal direction(0~360),
   angle.y is the angle in vertical direction(0~360)
 */
- (void)rotateCamera:(CGPoint)angle;

#if TTAVPLAYER_WRITER
/**
 set mediaWriter

 @param mediaWriter
 */
- (void)setMediaWriter:(id<TTMediaWriter>)mediaWriter;

/**
 start to record

 @return if failed return NO
 */
- (BOOL)startToRecord;

/**
 end recording
 */
- (void)endRecording:(TTMediaCompleionBlock)completionBlock;

- (void)takeScreenshot:(TTScreenshotCompleionBlock)completionBlock;

- (void)startToCaptureBuffer:(TTAVBufferCallback)callback;

- (void)endCaptureBuffer:(void(^)(void))completion;

#endif // TTAVPLAYER_WRITER

/**
 play next url

 @param url the url to play
 @param options
 */
- (void)playNextWithURL:(NSURL *)url options:(NSDictionary *)options completionHandler:(void (^)(BOOL finished))completionHandler;

- (void)setDrmCreater:(DrmCreater)creater;

- (CVPixelBufferRef)copyPixelBuffer;

- (void)setLoadControlInterface:(id<TTAVPlayerLoadControlInterface>)loadControl;

- (void)setMaskInfoInterface:(id<TTAVPlayerMaskInfoInterface>)maskInfo;

- (void)setAIBarrageInfoInterface:(id<TTAVPlayerMaskInfoInterface>)barrageInfo;

- (void)setSubInfoInterface:(id<TTAVPlayerSubInfoInterface>)subInfo;

- (void)setVideoProcessor:(void *)videoProcessor;

- (NSString *)getSubtitleContent:(NSInteger)queryTime Params:(id)params;

@end

#endif // TTM_DUAL_CORE_TTPLAYER_PROTOCOL
