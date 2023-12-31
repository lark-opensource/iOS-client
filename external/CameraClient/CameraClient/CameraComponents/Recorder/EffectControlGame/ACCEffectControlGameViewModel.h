//
//  ACCEffectControlGameViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/3/29.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreativeKit/ACCViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitComponents/AWECameraFilterConfiguration.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEColorFilterDataManager.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCEffectControlMessageType) {
    ACCEffectControlMessageTypeUnknown = 0,
    ACCEffectControlMessageTypeStartGame,
    ACCEffectControlMessageTypeFinishGame,
    ACCEffectControlMessageTypeNoGuide,//new type that means no guide video for the game
};

typedef NS_ENUM(NSUInteger, ACCEffectGameSwitchCameraType) {
    ACCEffectGameSwitchCameraType_UseFront = 0,
    ACCEffectGameSwitchCameraType_UseFrontAndRecord,
    ACCEffectGameSwitchCameraType_Recover,
};

typedef NS_ENUM(NSUInteger, ACCEffectGameMusicOperationType) {
    ACCEffectGameMusicOperationTypeNone = 0,
    ACCEffectGameMusicOperationTypeBackup,
    ACCEffectGameMusicOperationTypeRecover,
};

typedef NS_ENUM(NSInteger, ACCEffectGameRecordType) {
    ACCEffectGameRecordNormal = 0,      // 普通
    ACCEffectGameRecordDuet   = 1       // 合拍
};

typedef NS_ENUM(NSInteger, ACCEffectGameStatus) {
    ACCEffectGameStatusReady        = 0,
    ACCEffectGameStatusDidShow      = 1,
    ACCEffectGameStatusWillStart    = 2,
    ACCEffectGameStatusStart        = 3,
    ACCEffectGameStatusPause        = 4,
    ACCEffectGameStatusResume       = 5,
    ACCEffectGameStatusReset        = 6,
    ACCEffectGameStatusEnd          = 7
};

@protocol ACCRecordEffectGameProvideProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *gameStatusSignal;
@property (nonatomic, strong, readonly) RACSignal *didbackToRecordSignal;
@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *switchCameraPositionSignal;
@property (nonatomic, strong, readonly) RACSignal *showGameSignal;
@property (nonatomic, assign, readonly) ACCEffectGameStatus gameStatus;

#pragma mark - signal
- (void)showGameWithCompletion:(void (^)(void))completion;

- (void)sendGameStatusSignal:(ACCEffectGameStatus)status;

- (void)sendDidbackToRecordSignal;

- (void)sendSwitchCameraPositionSignal:(ACCEffectGameSwitchCameraType)type;

#pragma mark - music
- (void)operateMusicWithType:(ACCEffectGameMusicOperationType)type;

@end


@interface ACCEffectControlGameViewModel : ACCRecorderViewModel <ACCRecordEffectGameProvideProtocol>
@property (nonatomic, copy) IESEffectModel *(^getCurrentStickerBlock)(void);
@property (nonatomic, copy) void(^handleEffectControlMessageBlock)(ACCEffectControlMessageType);

//start receive message from effect (start/stop record etc.)
- (void)startReceiveMessageFromCamera;

@end

NS_ASSUME_NONNULL_END
