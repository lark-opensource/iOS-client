//
//  ACCRecorderProtocolD.h
//  CameraClient
//
//  Created by yangying on 2021/7/4.
//

#ifndef ACCRecorderProtocolD_h
#define ACCRecorderProtocolD_h

#import <CreationKitRTProtocol/ACCRecorderProtocol.h>

@protocol ACCRecorderProtocolD <ACCRecorderProtocol>

/**
 *  @brief enable/disable loudness equalizer
 *  @param targetLufs default is -16
 */
- (void)setBalanceEnabled:(BOOL)enabled targetLufs:(NSInteger)lufs;

/**
 *  @brief enable/disable delay ajustment
 *  @param modelPath which model to use
 */
- (void)setTimeAlignEnabled:(BOOL)enabled modelPath:(NSString *_Nullable)timeAlignPath timeAlignCallback:(nullable void (^)(float ret))callback;

- (void)setVideoBufferCallback:(void(^)(CVPixelBufferRef  _Nonnull pixelBuffer, CMTime pts))callback;

- (void)captureImageWithOptions:(IESMMCaptureOptions *_Nonnull)options
                  finishHandler:(IESMMCameraMetadataCaptureHandler _Nullable)finishHandler;

/**
 * 设置 audio graph 道具自带音乐 的播放模式
 */
- (BOOL)setMusicPlayMode:(VERecorderMusicPlayMode)mode;

// flower activity, effect获取bgm播放进度
- (void)enableEffectMusicTime:(BOOL)enable;

@end

#endif /* ACCRecorderProtocolD_h */
