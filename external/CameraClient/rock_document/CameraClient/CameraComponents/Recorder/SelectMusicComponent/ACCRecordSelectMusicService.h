//
//  ACCRecordSelectMusicService.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2021/1/10.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;

@protocol ACCRecordSelectMusicService <NSObject>

@property (nonatomic, strong, readonly) RACSignal *cancelMusicSignal;
@property (nonatomic, strong, readonly) RACSignal *pickMusicSignal;

- (void)updateAudioRangeWithStartLocation:(double)startLocation;

- (void)refreshMusicCover;
- (void)handlePickMusic:(id<ACCMusicModelProtocol>)music error:(NSError *)error completion:(void (^)(void))completion;
- (void)pickMusic:(nullable id<ACCMusicModelProtocol>)music complete:(nullable void (^)(void))completeBlock;
- (void)handleCancelMusic:(id<ACCMusicModelProtocol>)music;
- (void)handleCancelMusic:(id<ACCMusicModelProtocol>)music muteBGM:(BOOL)muteBGM trackInfo:(nullable NSDictionary *)trackInfo;

- (void)cancelForceBindMusic:(id<ACCMusicModelProtocol>)musicModel;

//资源后置加载应用
- (void)handleRearApplyMusic:(id<ACCMusicModelProtocol>)music completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
