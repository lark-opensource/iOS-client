//
//  ACCEffectControlGameViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/3/29.
//

#import "ACCEffectControlGameViewModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

static NSInteger const kACCEffectControlGameMsgTypeGameResourceReady = 0x0000002D;   // Effect -> Client: game resource ready
static NSInteger const kACCEffectControlGameMsgTypeStartGame         = 0x00000030;   // Effect -> Client:Notify Client start record
static NSInteger const kACCEffectControlGameMsgTypeFinishGame        = 0x00000031;   // effect -> Client:Notify Client stop record (game over)
static NSInteger const kACCEffectControlGameMsgTypeStickerLoadCNT    = 0x0000002E;   // Client -> Effect:Notify Effect Sticker load count
static NSString * const kACCEffectControlGameTimesKey = @"kACCEffectControlGameTimesKey";    // resource load count key
static NSString * const kEffectControlGameSelectedMusicBackupPath = @"AWEGameRecordMusicBackupPath";

@interface ACCEffectControlGameViewModel () <ACCEffectEvent>
@property (nonatomic, assign) BOOL hasAddCameraMessageBlock;
@property (nonatomic, assign) AVCaptureDevicePosition oldCaptureDevicePosition;
@property (nonatomic, strong) id<ACCMusicModelProtocol> oldSelectedMusic;
@property (nonatomic, strong, readwrite) id<ACCCameraService> cameraService;

@property (nonatomic, strong, readwrite) RACSignal *gameStatusSignal;
@property (nonatomic, strong, readwrite) RACSignal *didbackToRecordSignal;
@property (nonatomic, strong, readwrite) RACSignal<NSNumber *> *switchCameraPositionSignal;

@property (nonatomic, strong, readwrite) RACSubject *gameStatusSubject;
@property (nonatomic, strong, readwrite) RACSubject *didbackToRecordSubject;
@property (nonatomic, strong, readwrite) RACSubject *switchCameraPositionSubject;

@property (nonatomic, strong, readwrite) RACSignal *showGameSignal;
@property (nonatomic, strong, readwrite) RACSubject *showGameSubject;

@property (nonatomic, assign, readwrite) ACCEffectGameStatus gameStatus;
@end

@implementation ACCEffectControlGameViewModel

#pragma mark - ViewModel Lifecycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [_showGameSubject sendCompleted];
    [_gameStatusSubject sendCompleted];
    [_didbackToRecordSubject sendCompleted];
    [_switchCameraPositionSubject sendCompleted];
}

#pragma mark - ACCEffectEvent

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message {
    ACCEffectControlMessageType type = ACCEffectControlMessageTypeUnknown;
    switch (message.msgId) {
        case kACCEffectControlGameMsgTypeStartGame: {
            type = ACCEffectControlMessageTypeStartGame;
            AWELogToolInfo(AWELogToolTagRecord, @"receive camera start game message");
        }
            break;
        case kACCEffectControlGameMsgTypeFinishGame: {
            type = ACCEffectControlMessageTypeFinishGame;
            AWELogToolInfo(AWELogToolTagRecord, @"receive camera finish game message");
        }
            break;
        case kACCEffectControlGameMsgTypeGameResourceReady:
        {
            if (message.arg1 == 2 && [self shouldHandleMessage:message]) {
                [self sendLoadTimesMessageToEffectWithArg:message.arg3];
                if (message.arg2 == 0) {
                    type = ACCEffectControlMessageTypeNoGuide;
                }
            }
        }
            break;
        default:
            break;
    }
    if (type != ACCEffectControlMessageTypeUnknown && [self shouldHandleMessage:message]) {
        ACCBLOCK_INVOKE(self.handleEffectControlMessageBlock, type);
    }
}

- (void)startReceiveMessageFromCamera
{
    if (self.hasAddCameraMessageBlock) {
        return;
    }
    self.hasAddCameraMessageBlock = YES;
    [self.cameraService.message addSubscriber:self];
}

- (BOOL)shouldHandleMessage:(IESMMEffectMessage *)message
{
    if (self.currentSticker.filePath == nil) {
        return NO;
    }
    NSDictionary *dic = [self dictionaryWithJsonString:message.arg3];
    NSString *tag = dic[@"effectPath"];
    return [tag containsString:self.currentSticker.filePath];
}

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }

    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        return nil;
    }
    NSError *err;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    
    if (err || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return dict;
}

#pragma mark - message counts
- (void)sendLoadTimesMessageToEffectWithArg:(NSString *)arg
{
    IESMMEffectMessage *message = [[IESMMEffectMessage alloc] init];
    message.type = kACCEffectControlGameMsgTypeStickerLoadCNT;
    message.arg1 = 1;
    message.arg2 = [self updateEffectLoadTimes];
    message.arg3 = arg;
    
    [self.cameraService.message sendMessageToEffect:message];
}

- (NSInteger)updateEffectLoadTimes
{
    NSString *key = [NSString stringWithFormat:@"%@_%@", kACCEffectControlGameTimesKey, self.currentSticker.effectIdentifier];
    NSInteger times = [ACCCache() integerForKey:key];
    times +=1;
    [ACCCache() setInteger:times forKey:key];
    return times;
}

#pragma mark - getter

- (IESEffectModel *)currentSticker
{
    return self.getCurrentStickerBlock ? self.getCurrentStickerBlock() : nil;
}

- (id<ACCCameraService>)cameraService {
    return IESAutoInline(self.serviceProvider, ACCCameraService);
}

#pragma mark - signal

- (RACSignal *)gameStatusSignal
{
    return self.gameStatusSubject;
}

- (RACSubject *)gameStatusSubject
{
    if (!_gameStatusSubject) {
        _gameStatusSubject = [RACSubject subject];
    }
    return _gameStatusSubject;
}

- (RACSignal *)didbackToRecordSignal
{
    return self.didbackToRecordSubject;
}

- (RACSubject *)didbackToRecordSubject
{
    if (!_didbackToRecordSubject) {
        _didbackToRecordSubject = [RACSubject subject];
    }
    return _didbackToRecordSubject;
}

- (RACSignal *)switchCameraPositionSignal
{
    return self.switchCameraPositionSubject;
}

- (RACSubject *)switchCameraPositionSubject
{
    if (!_switchCameraPositionSubject) {
        _switchCameraPositionSubject = [RACSubject subject];
    }
    return _switchCameraPositionSubject;
}

#pragma mark - public methods

- (void)sendGameStatusSignal:(ACCEffectGameStatus)status
{
    self.gameStatus = status;
    [self.gameStatusSubject sendNext:@(status)];
}

- (void)sendDidbackToRecordSignal
{
    [self.didbackToRecordSubject sendNext:nil];
}

- (void)sendSwitchCameraPositionSignal:(ACCEffectGameSwitchCameraType)type
{
    if (type == ACCEffectGameSwitchCameraType_Recover) {
        if ([self.cameraService.cameraControl currentCameraPosition] != self.oldCaptureDevicePosition) {
            [self.switchCameraPositionSubject sendNext:@(self.oldCaptureDevicePosition)];
        }
    } else {
        if (type == ACCEffectGameSwitchCameraType_UseFrontAndRecord) {
            self.oldCaptureDevicePosition = [self.cameraService.cameraControl currentCameraPosition];
        }
        if ([self.cameraService.cameraControl currentCameraPosition] != AVCaptureDevicePositionFront) {
            [self.switchCameraPositionSubject sendNext:@(AVCaptureDevicePositionFront)];
        }
    }
}

- (RACSignal *)showGameSignal
{
    return self.showGameSubject;
}

- (RACSubject *)showGameSubject
{
    if (!_showGameSubject) {
        _showGameSubject = [RACSubject subject];
    }
    return _showGameSubject;
}

- (void)showGameWithCompletion:(void (^)(void))completion
{
    [self.showGameSubject sendNext:completion];
}

#pragma mark - music

- (void)operateMusicWithType:(ACCEffectGameMusicOperationType)type
{
    if (type == ACCEffectGameMusicOperationTypeBackup) {
        self.oldSelectedMusic = [self p_exchangeSelectedMusicForBackup:YES];
        self.inputData.publishModel.repoMusic.music = nil;
    } else if (type == ACCEffectGameMusicOperationTypeRecover) {
        self.inputData.publishModel.repoMusic.music = [self p_exchangeSelectedMusicForBackup:NO];
        self.oldSelectedMusic = nil;
    }
}

- (id<ACCMusicModelProtocol>)p_exchangeSelectedMusicForBackup:(BOOL)isBackup
{
    id<ACCMusicModelProtocol> music = nil;
    NSString *folderName = nil;
    if (isBackup) {
        music = self.inputData.publishModel.repoMusic.music;
        folderName = kEffectControlGameSelectedMusicBackupPath;
    } else {
        music = self.oldSelectedMusic;
        folderName = self.inputData.publishModel.repoDraft.taskID;
    }
    
    if (!(music && music.loaclAssetUrl)) {
        return music;
    }
    
    NSString *lastPathComponent = [music.loaclAssetUrl lastPathComponent];
    NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:folderName];
    NSString *draftMusicPath = [draftFolder stringByAppendingPathComponent:lastPathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:draftFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:draftFolder withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    NSURL *musicURL = [NSURL fileURLWithPath:draftMusicPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:draftMusicPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtURL:music.loaclAssetUrl toURL:musicURL error:&error];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftMusicPath] && !error) {
            if (!isBackup) {
                [[NSFileManager defaultManager] removeItemAtPath:music.loaclAssetUrl.absoluteString error:nil];
            }
            music.loaclAssetUrl = musicURL;
        } else {
            music = nil;
        }
    } else {
        music.loaclAssetUrl = musicURL;
    }
    
    return music;
}

@end
