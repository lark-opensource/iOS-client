//
//  ACCKaraokeService.h
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/3/19.
//

#import <Foundation/Foundation.h>

#import "ACCRepoKaraokeModelProtocol.h"
#import "ACCKaraokeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCKaraokeService, ACCMusicModelProtocol;

@protocol ACCKaraokeServiceSubscriber <NSObject>

@optional

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode;
- (void)karaokeService:(id<ACCKaraokeService>)service musicDidChangeFrom:(id<ACCMusicModelProtocol>)prevMusic to:(id<ACCMusicModelProtocol>)music musicSourceDidChangeFrom:(ACCKaraokeMusicSource)prevSource to:(ACCKaraokeMusicSource)source;
- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state;
- (void)karaokeService:(id<ACCKaraokeService>)service isCountingDownDidChangeFrom:(BOOL)prevState to:(BOOL)state;

@end

@class RACSignal, IESEffectModel;

@protocol ACCKaraokeService <NSObject>

/**
 * @note If holds KaraokeService as a propery of your object, remember to use the `weak` specifier.
 */
- (void)addSubscriber:(id<ACCKaraokeServiceSubscriber>)subscriber;
- (void)removeSubscriber:(id<ACCKaraokeServiceSubscriber>)subscriber;

/**
 * @discussion Methods to activate/deactivate karaoke components. This is where every-karaoke-thing begins and ends. Required parameter include: kAWEKaraokeWorkflowMusic, kAWEKaraokeWorkflowMusicSource.
 */
@property (nonatomic, copy, readonly) NSDictionary<ACCKaraokeWorkflowParam, id> *workflowParams;
- (void)startKaraokeWorkflowWithParams:(NSDictionary *)params;
- (void)exitKaraokeWorkflow;

/**
 * @discussion Whether an prop is allowed when creating karaoke videos.
 */
- (BOOL)propIsNotAllowedInKaraoke:(IESEffectModel *)prop;

/**
 * @discussion These properties are related to karaoke runtime state. While the they're shared among all feature components, the associated `update` methods SHOULD be called by karaoke components only.
 */
@property (nonatomic, strong, readonly) id<ACCMusicModelProtocol> karaokeMusic;
@property (nonatomic, assign, readonly) ACCKaraokeMusicSource musicSource;
- (void)updateMusic:(id<ACCMusicModelProtocol>)music musicSource:(ACCKaraokeMusicSource)source;

@property (nonatomic, strong, readonly) RACSignal *updateAcousticAlgoSignal;
- (void)sendUpdateAcousticAlgoSignal;

@property (nonatomic, assign, readonly) ACCKaraokeRecordMode recordMode;
- (void)updateRecordMode:(ACCKaraokeRecordMode)recordMode;

@property (nonatomic, assign, readonly) BOOL inKaraokeRecordPage;
- (void)updateInKaraokeRecordPage:(BOOL)inKaraokeRecordPage;

@property (nonatomic, assign, readonly) BOOL isCountingDown;
- (void)updateIsCountingdown:(BOOL)isCountingDown;

@end

NS_ASSUME_NONNULL_END
