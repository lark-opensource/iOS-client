//
//  BDXAudioService.h
//  BDXElement-Pods-BDXme
//
//  Created by DylanYang on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import "BDXAudioQueueModel.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, BDXAudioServicePauseType) {
    BDXAudioServicePauseTypeManual,
    BDXAudioServicePauseTypeInterrupt
};

typedef NS_ENUM(NSInteger, BDXAudioServicePlayStatus) {
    BDXAudioServicePlayStatusPlaying,
    BDXAudioServicePlayStatusPaused,
    BDXAudioServicePlayStatusStopped,
    BDXAudioServicePlayStatusLoading,
    BDXAudioServicePlayStatusError
};

@class BDXAudioService;

@protocol BDXAudioServiceDelegate <NSObject>
- (void)audioService:(BDXAudioService *)service didFinishedWithError:(nullable NSError *)error;
- (void)audioService:(BDXAudioService *)service playStatusChanged:(BDXAudioServicePlayStatus)playStatus;
- (void)audioServiceReadyToPlay:(BDXAudioService *)service;
- (void)audioServiceDidPlay:(BDXAudioService *)service;
- (void)audioServiceDidPause:(BDXAudioService *)service pauseType:(BDXAudioServicePauseType)type;
- (void)audioServiceDidStop:(BDXAudioService *)service;
- (void)audioServiceDidSeek:(BDXAudioService *)service;
- (void)audioServiceInPlaying:(BDXAudioService *)service;
- (void)audioServiceAudioChanged:(BDXAudioService *)service;
- (void)audioServicePeriodicTimeObserverForInterval:(BDXAudioService *)service;
@end

@class BDXAudioService;
@protocol BDXAudioEventServiceDelegate<BDXAudioServiceDelegate>
- (void)setPlayService: (BDXAudioService *)service;
@end


@protocol AudioService

- (void)prepareToPlay;
- (void)play;
- (void)pause;
- (void)stop;
- (void)clear;
- (void)seekToTime:(NSTimeInterval)time;
- (BOOL)isPlaying;
- (NSInteger)playBitrate;
- (NSTimeInterval)duration;
- (NSTimeInterval)playbackTime;
- (NSTimeInterval)playableTime;
- (BDXAudioServicePlayStatus)playStatus;
- (nullable BDXAudioQueueModel *)queue;
- (void)setQueue:(BDXAudioQueueModel *)queue;
- (BDXAudioModel *)currentPlayModel;
- (void)setIsLooping:(BOOL)isLooping;
- (BOOL)updateCurrentModel:(BDXAudioModel *)current;
- (void)setAudioModels:(NSArray<BDXAudioModel *> *)models current:(BDXAudioModel *)current queueId:(NSString *)queueId;
- (void)appendAudioModels:(NSArray<BDXAudioModel *> *)models;

- (void)goPrev;
- (void)goNext;

- (BOOL)canGoPrev;
- (BOOL)canGoNext;

- (void)addObserver:(id<BDXAudioServiceDelegate>)observer;
- (void)removeObserver:(id<BDXAudioServiceDelegate>)observer;

@end

@interface BDXAudioService : NSObject<AudioService>

@property (nonatomic, strong) NSMutableDictionary * nowPlayingInfo;
@property (nonatomic, weak) id<BDXAudioServiceDelegate> delegate;
@property (nonatomic, strong, nullable) id<BDXAudioEventServiceDelegate> eventService;
@property (nonatomic, assign) BOOL inAudioChanging;
@property (nonatomic, assign) BOOL enableEvent;
- (instancetype)init;
- (void)clear;
- (void)setupCommand;
- (void)clearCommand;
@end

NS_ASSUME_NONNULL_END
