//
//  ACCAudioPlayerProtocol.h
//  CameraClient
//
//  Created by xiaojuan on 2020/8/7.
//
#import "ACCPropRecommendMusicProtocol.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAudioPlayerProtocol <NSObject>

@property (nonatomic, weak) id<ACCPropRecommendMusicProtocol> delegate;
@property (nonatomic, readonly) BOOL canBackgroundPlay;

- (void)updateServiceWithMusicModel:(id<ACCMusicModelProtocol>)model audioPlayerPlayingBlock:(void (^)(void))stopPlayingToAuditionDuration;

- (void)play;

- (void)continuePlay;

- (void)pause;

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus animated:(BOOL)animated;

@optional
- (id<ACCMusicModelProtocol>)playingMusic;

- (NSURL *)playingURL;

@end

@protocol ACCAudioURLPlayerProtocol <NSObject>

#pragma mark - Common
@property (nonatomic, assign, readonly) ACCAVPlayerPlayStatus playerState;
@property (nonatomic, assign, readonly) NSTimeInterval currentPlaybackTime;
@property (nonatomic, assign, readonly) NSTimeInterval startTime;
/**
 * @brief Default is CGFLOAT_MAX.
 */
@property (nonatomic, assign) NSTimeInterval playableDuration;

#pragma mark - URL Player
/**
 * @note `startTime` and `playableDuration` wil reset to 0 and CGFLOAT_MAX after calling this method.
 */
- (void)playWithURL:(nullable NSString *)URL startTime:(NSTimeInterval)startTime playableDuration:(NSTimeInterval)playableDuration;
@property (nonatomic, readonly, copy) NSString *currentPlayURL;

@end

NS_ASSUME_NONNULL_END
