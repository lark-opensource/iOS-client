//
//  BDXAudioPlayer.h
//  BDXElement-Pods-BDXme
//
//  Created by DylanYang on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import "BDXAudioModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDXAudioPlayerLoadState) {
    BDXAudioPlayerLoadStateUnknown,
    BDXAudioPlayerLoadStatePlayable,
    BDXAudioPlayerLoadStateStalled,
    BDXAudioPlayerLoadStateError,
};

typedef NS_ENUM(NSInteger, BDXAudioPlayerPlaybackState) {
    BDXAudioPlayerPlaybackStateStopped,
    BDXAudioPlayerPlaybackStatePlaying,
    BDXAudioPlayerPlaybackStatePaused,
    BDXAudioPlayerPlaybackStateError,
};

@class BDXAudioPlayer;
@protocol BDXAudioPlayerDelegate <NSObject>
- (void)audioEngine:(BDXAudioPlayer *)engine didFinishedWithError:(nullable NSError *)error;
- (void)audioEngine:(BDXAudioPlayer *)engine loadStateChanged:(BDXAudioPlayerLoadState)loadState;
- (void)audioEngine:(BDXAudioPlayer *)engine playbackStateChanged:(BDXAudioPlayerPlaybackState)playbackState;
- (void)audioEngineStartPlay:(BDXAudioPlayer *)engine;
- (void)audioEngineReadyToPlay:(BDXAudioPlayer *)engine;
- (void)audioEnginePeriodicTimeObserverForInterval:(BDXAudioPlayer *)engine;
@end


@interface BDXAudioPlayer : NSObject
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval playbackTime;
@property (nonatomic, readonly) NSTimeInterval playableTime;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, assign) BOOL looping;
@property (nonatomic, weak) id<BDXAudioPlayerDelegate> delegate;
- (void)prepareToPlay;
- (void)play;
- (void)pause;
- (void)stop;
- (NSInteger)playBitrate;
- (void)seekPlaybackTime:(NSTimeInterval)time completion:(nullable void (^)(BOOL success))completion;
- (void)setPlayUrl:(NSString *)url;
- (void)setLocalUrl:(NSString *)url;
- (void)setPlayModel:(BDXAudioVideoModel *)videoModel;
@end

NS_ASSUME_NONNULL_END
