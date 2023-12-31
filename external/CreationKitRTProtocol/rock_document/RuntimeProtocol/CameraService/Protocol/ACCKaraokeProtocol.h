//
//  ACCKaraokeProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/3/24.
//

#import <Foundation/Foundation.h>

#import <TTVideoEditor/IESMMBaseDefine.h>
#import "ACCCameraWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCKaraokeProtocol <ACCCameraWrapper>
/**
 * @brief set record mode.
 * @note Calling this method is not time consuming.
 */
- (void)setRecorderAudioMode:(VERecorderAudioMode)mode;
/**
 * @brief play karaoke materials (original sound and accompany sound). When the user taps record button, we start play karaoke music with this method.
 */
- (void)karaokePlay;
/**
 * @brief pause karaoke materials (original sound and accompany sound). When the user pauses/stops recording, we pause playing karaoke music with this method.
 */
- (void)karaokePause;
/**
 * @brief seek accompany to the specified time (relative to the start of the file).
 */
- (void)accompanySeekToTime:(NSTimeInterval)time;
/**
 * @brief seek original sound to the specified time (relative to the start of the file).
 */
- (void)originalSingSeekToTime:(NSTimeInterval)time;

/**
 * @brief seek accompany and original sound simultaneously.
 */
- (void)seekToAccompanyTime:(NSTimeInterval)accompanyTime
           accompanyStartWritingTime:(NSTimeInterval)accompanyStartWritingTime
                    originalSingTime:(NSTimeInterval)origianlSingTime
        originalSingStartWritingTime:(NSTimeInterval)originalSingStartWritingTime;

/**
 * @brief set karaoke materials.
 * @param musicURL accompany file path
 * @param startTime accompany start playing time (relative to the start of the file)
 * @param singURL original sound file path
 * @param startTime original sound start playing time (relative to the start of the file)
 */
- (void)setAccompanyMusicFile:(NSURL *_Nonnull)musicURL fromTime:(NSTimeInterval)startTime OriginalSingMusicFile:(NSURL *_Nullable)singURL startTime:(NSTimeInterval)singStartTime;
/**
 * @brief get current accompany playing time.
 * @discussion If current play time is t and you seek it to time T but did not call play, the return value would be t instead of T.
 */
- (NSTimeInterval)getAccompanyCurrentTime;
/**
 * @brief get current original sound playing time.
 * @discussion Same as `getAccompanyCurrentTime`.
 */
- (NSTimeInterval)getOriginalSingCurrentTime;
/**
 * @brief mute original sound if `muted` is `YES`, unmute if `NO`.
 */
- (void)mutedOrignalSing:(BOOL)muted;
/**
 * @brief mute accompany if `muted` is `YES`, unmute if `NO`.
 */
- (void)mutedAccompany:(BOOL)muted;
/**
 * @brief set original sound volume
 * @param recordVolume a float number in the range of  [0-1].
 */
- (void)setOriginalSingVolume:(CGFloat)recordVolume;
/**
 * @brief get original sound volume.
 */
- (CGFloat)originalSingVolume;
/**
 * @brief set accompany volume
 * @param musicVolume a float number in the range of  [0-1].
 */
- (void)setAccompanyVolume:(CGFloat)musicVolume;
/**
 * @brief get accompany volume.
 */
- (CGFloat)accompanyVolume;

/**
 * @brief notify VE the change of audio route.
 */
- (void)routeChanged;

@end

NS_ASSUME_NONNULL_END
