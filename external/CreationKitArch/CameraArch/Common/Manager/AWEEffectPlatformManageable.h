//
//  AWEEffectPlatformManageable.h
//  AWEFoundation
//
// Created by Peng on April 25, 2018
//  Copyright  ©  2021 byedance. All rights reserved
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import "AWEEffectPlatformTrackModel.h"

@class IESEffectModel;

@protocol AWEEffectPlatformManageable <NSObject>

@property (nonatomic, strong, readonly) dispatch_semaphore_t simpleDownloadingEffectsDictLock;

+ (instancetype)sharedManager;

/// Download props resource pack
///@ param effectmodel prop model
///@ param trackmodel buried point information
///@ param progressblock progress bar
///@ param completion callback
- (void)downloadEffect:(IESEffectModel *)effectModel
         trackModel:(AWEEffectPlatformTrackModel *)trackModel
              progress:(nullable EffectPlatformDownloadProgressBlock)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock)completion;

/// Download props resource pack
///@ param effectmodel prop model
///@ param trackmodel buried point information
///@ param queuepriority queue priority
/// @param qualityOfService QoS
///@ param progressblock progress bar
///@ param completion callback
- (void)downloadEffect:(IESEffectModel *)effectModel
         trackModel:(AWEEffectPlatformTrackModel *)trackModel
 downloadQueuePriority:(NSOperationQueuePriority)queuePriority
downloadQualityOfService:(NSQualityOfService)qualityOfService
              progress:(nullable EffectPlatformDownloadProgressBlock)progressBlock
            completion:(nullable EffectPlatformDownloadCompletionBlock)completion;
@end
