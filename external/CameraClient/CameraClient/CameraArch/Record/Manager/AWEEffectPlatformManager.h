//
//  AWEEffectPlatformManager.h
//  AWEFoundation
//
// Created by Hao Yipeng on April 25, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectLogger.h>
#import <EffectPlatformSDK/IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectListManager.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>

@class IESEffectModel;
@interface AWEEffectPlatformManager : NSObject <IESEffectListManagerDelegate, IESEffectLoggerProtocol>

@property (nonatomic, strong) NSArray <IESEffectModel *> *localVoiceEffectList;// Built in sound
@property (nonatomic, strong) NSString *localVoiceEffectName_chipmunk;
@property (nonatomic, strong) NSString *localVoiceEffectName_baritone;
@property (nonatomic, strong) IESEffectListManager *effectListManager;
@property (nonatomic, strong, readonly) dispatch_semaphore_t simpleDownloadingEffectsDictLock;

+ (instancetype)sharedManager;

+ (void)configEffectPlatform;

#pragma mark - voice effect
// Built in sound
- (IESEffectModel *)localVoiceEffectWithID:(NSString *)effectID;

// Sound effects distributed in the background
- (IESEffectModel *)cachedVoiceEffectWithID:(NSString *)effectID;

// Whether the sound effect is matched with the built-in sound effect, the tag is preferred
- (BOOL)equalWithCachedEffect:(IESEffectModel *)cached localEffect:(IESEffectModel *)local;

// Read the cache first and download it if you don't have it. You should clear the cache
- (void)loadEffectWithID:(NSString *)effectId completion:(void (^)(IESEffectModel *))completion;

- (AWEEffectDownloadStatus)downloadStatusForEffect:(IESEffectModel *)effect;

- (void)downloadEffect:(IESEffectModel *)effect
              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion;
@end
