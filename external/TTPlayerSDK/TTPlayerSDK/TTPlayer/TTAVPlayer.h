//
// Don't edit this file directly.
// This file is generated from TTAVPlayer.h.in
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#define TTAVPLAYER_MACOS 0
#if TTAVPLAYER_MACOS
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif
#import "TTPlayerDef.h"
#import "TTAVPlayerProtocol.h"
#import "TTAVPlayerItemProtocol.h"

#import "TTAVPlayerLoadControlInterface.h"
#import "TTAVPlayerMaskInfoInterface.h"
#import "TTAVPlayerSubInfoInterface.h"

#define TTAVPLAYER_WRITER 0
#if TTAVPLAYER_WRITER
#import "TTMediaWriterProtocol.h"
#endif

@interface TTAVPlayer : NSObject<TTAVPlayerProtocol>

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
@property (nonatomic, assign) CGRect normalizeCropArea;
//videoprocessoer instance
@property (nonatomic, assign) void* videoProcessor;
@property (nonatomic, strong) NSMutableArray* effectParamArray;
@property (nonatomic, assign) BOOL isUseEffect;

+ (void)setLogFileEnabled:(BOOL)enabled;

+ (NSString *)playerVersion;

+ (NSString *)versionInfo;

/// version of iPlayer interface.
+ (NSInteger)iPlayerVersion;

+ (BOOL)supportsSSL;

+ (BOOL)isMetalCapable;

+ (void)setStackSizeOptimized:(BOOL)optimized;

+ (void)configThreadWaitMilliSeconds:(int)timeout;

+ (void)setGlobalValue:(id)value forKey:(int)key;

- (instancetype)initWithURL:(NSURL *)url;

- (instancetype)initWithURL:(NSURL *)url options:(NSDictionary *)header;

/**
 * params field:
 * @"business_identity" : TTAVPlayerBusinessIdentity type
 */
- (instancetype)initWithURL:(NSURL *)url
                    options:(NSDictionary *)header
                     params:(NSDictionary *)params;

+ (instancetype)playerWithURL:(NSURL *)url;
    
+ (instancetype)playerWithURL:(NSURL *)url options:(NSDictionary *)header;

/**
 * params field:
 * @"business_identity" : TTAVPlayerBusinessIdentity type
 */
+ (instancetype)playerWithURL:(NSURL *)url
                      options:(NSDictionary *)header
                       params:(NSDictionary *)params;

- (instancetype)initWithPlayerItem:(NSObject<TTAVPlayerItemProtocol>*)item;
    
- (instancetype)initWithPlayerItem:(NSObject<TTAVPlayerItemProtocol>*)item options:(NSDictionary *)header;

/**
 * params field:
 * @"business_identity" : TTAVPlayerBusinessIdentity type
 */
- (instancetype)initWithPlayerItem:(NSObject<TTAVPlayerItemProtocol>*)item
                           options:(NSDictionary *)header
                            params:(NSDictionary *)params;
                            
+ (instancetype)playerWithItem:(NSObject<TTAVPlayerItemProtocol>*)item;
    
+ (instancetype)playerWithItem:(NSObject<TTAVPlayerItemProtocol>*)item options:(NSDictionary *)header;

/**
 * params field:
 * @"business_identity" : TTAVPlayerBusinessIdentity type
 */
+ (instancetype)playerWithItem:(NSObject<TTAVPlayerItemProtocol>*)item
                       options:(NSDictionary *)header
                        params:(NSDictionary *)params;

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

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler renderCompleteHandler:(void (^)(BOOL isSeekInCached))renderCompleteHandler;

- (void)switchStreamBitrate:(NSUInteger)bitrate type:(TTMediaStreamType)type completionHandler:(void (^)(BOOL finished))completionHandler;

- (NSString *)getIPAddress;

- (float)getFloatValueForKey:(int)key;
- (float)getFloatValueForKeyType:(int)key forType:(int)type;
- (NSString*)getStringValueForKey:(int)key;
- (NSString*)getStringValueForKeyType:(int)key forType:(int)type;
- (int64_t)getInt64Value:(int64_t)dValue forKey:(int)key;
- (int)getIntValue:(int)dValue forKey:(int)key;
- (int)getIntValueForKeyType:(int)key forType:(int)type;

- (void)setFloatValue:(float)value forKey:(int)key;
- (void)setValueVoidPTR: (void*)value forKey:(int)key;
- (void)setValueString: (NSString*)value forKey:(int)key;
- (void)setValue:(int)value forKey:(int)key;
- (void)setIntValue:(int)value forKey:(int)key;

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
#endif

/**
 play next url

 @param url the url to play
 @param options
 */
- (void)playNextWithURL:(NSURL *)url options:(NSDictionary *)options completionHandler:(void (^)(BOOL finished))completionHandler;

//- (void)setResourceLoaderDelegate:(id <TTAVAssetResourceloaderDelegate>)delegate;

- (void)setDrmCreater:(DrmCreater)creater;

- (CVPixelBufferRef)copyPixelBuffer;

- (void)setLoadControlInterface:(id<TTAVPlayerLoadControlInterface>)loadControl;

- (void)setMaskInfoInterface:(id<TTAVPlayerMaskInfoInterface>)maskInfo;

- (void)setSubInfoInterface:(id<TTAVPlayerSubInfoInterface>)subInfo;

- (void)setVideoProcessor:(void *)videoProcessor;

@end
