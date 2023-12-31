//
//  ACCRecorderProtocol.h
//  Pods
//
//  Created by liyingpeng on 2020/6/4.
// 

#ifndef ACCRecorderProtocol_h
#define ACCRecorderProtocol_h

#import "ACCCameraWrapper.h"
#import "ACCCameraSubscription.h"
#import <TTVideoEditor/VERecorder.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCCameraRecorderState) {
    ACCCameraRecorderStateNormal = 0,
    ACCCameraRecorderStatePausing,
    ACCCameraRecorderStateRecording,
};

@class VEPathBuffer;
@protocol ACCRecorderProtocol <ACCCameraWrapper, ACCCameraSubscription>

@property(nonatomic, assign) NSInteger cameraMode;
@property(nonatomic, assign) ACCCameraRecorderState recorderState;
@property (nonatomic, strong, readonly) HTSVideoData *videoData;

/**
 * @brief draft change audio mode clear videodata
 */
- (void)clearVideodata;

- (UIView *)resetPreviewView:(UIView *)view;

- (void)setMusicWithURL:(NSURL *)url repeat:(BOOL)repeat;
- (void)setMusicWithURL:(NSURL *)url repeat:(BOOL)repeat completion:(dispatch_block_t _Nullable)completion;

- (void)captureStillImageWithCompletion:(void (^)(UIImage *processedImage, NSError *error))completion;

- (BOOL)exportWithVideo:(HTSVideoData *)videoData;
- (BOOL)isRecording;

#pragma mark - bg

- (void)setBGVideoWithVideoURL:(NSURL *)url key:(NSString *)key rate:(float)rate completeBlock:(CompleteBlock)completeBlock didPlayToEndBlock:(nullable void (^)(void))didPlayToEndBlock;

- (void)resetBGVideo;

- (void)bgVideoSeekToPercent:(float)percent completeBlock:(nullable void (^)(BOOL finished))completeBlock;

- (BOOL)bgVideoIsPlaying;

- (void)bgVideoMutePlayer:(BOOL)muted;

- (float)bgVideoCurrentPlayPercent;

- (void)bgVideoPlay;

- (void)bgVideoPause;

#pragma mark - mutli

- (AVPlayer *_Nullable)getMultiPlayer;

- (void)multiVideoPause;

- (void)multiVideoIsReady;

- (void)multiVideoSeekToTime:(CMTime)toTime completeBlock:(nullable void (^)(BOOL finished))completeBlock;

- (void)multiVideoChangeRate:(float)rate completeBlock:(CompleteBlock)completeBlock;

- (void)setMultiVideoWithVideoURL:(NSURL *)url rate:(float)rate completeBlock:(CompleteBlock)completeBlock;

- (void)setMultiVideoAutoRepeat:(BOOL)autoRepeat;

- (void)multiVideoPlay;

#pragma mark -

- (void)changeMusicStartTime:(NSTimeInterval)startTime clipDuration:(NSTimeInterval)clipDuration;

- (void)resetRecorderWriter;

- (void)setForceRecordAudio:(BOOL)isForceRecordAudio;

- (void)setForceRecordWithMusicEnd:(BOOL)isForceRecord;


/**
 *  @brief enable/disable loudness equalizer
 *  @param targetLufs default is -16
 */
- (void)setBalanceEnabled:(BOOL)enabled targetLufs:(int)lufs;

/**
 *  @brief enable/disable delay ajustment
 *  @param modelPath which model to use
 */
- (void)setTimeAlignEnabled:(BOOL)enabled modelPath:(NSString *_Nullable)timeAlignPath timeAlignCallback:(nullable void (^)(float ret))callback;

- (void)setAECEnabled:(BOOL)isEnable modelPath:(NSString * _Nullable)path;

- (BOOL)aecStatus;

- (void)setEnableEarBack:(BOOL)enableEarBack;

- (NSUInteger)fragmentCount;

- (void)removePlayer;

- (void)removePlayer:(dispatch_block_t _Nullable)completion;

- (void)resetVideoRecordReady;

- (void)setDropFrame:(BOOL)dropFrame;

- (CGFloat)getTotalDuration;

- (void)pauseVideoRecord;

- (void)setMaxLimitTime:(CMTime)maxDuration;

- (void)releaseCaptureImage:(VEEffectImage *)image;

- (void)applyMusicNodes:(NSString *)path;

- (void)enableAudioEffectSticker:(BOOL)useAudioEffectSticke;

- (void)setUseEffectRecognize:(BOOL)stickerVoiceRecognization;

- (void)removeAllVideoFragments;
- (void)removeAllVideoFragments:(dispatch_block_t)completion;

- (void)removeLastVideoFragment;

- (void)startVideoRecordWithRate:(CGFloat)rate;

- (UIImage *)getFirstRecordFrame;

- (void)setIESCameraDurationBlock:(void(^)(CGFloat duration, CGFloat totalDuration))blokcPapameter;

- (void)bgVideoRestart;

- (void)captureSourcePhotoAsImageByUser:(BOOL)byUser completionHandler:(void (^_Nullable)(UIImage *_Nullable processedImage, NSError *_Nullable error))block afterProcess:(BOOL)isProcessed;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCRecorderProtocol_h */
