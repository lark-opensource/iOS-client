//
//  IESGurdDownloadPackageManager+Business.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/9/1.
//

#import "IESGurdDownloadPackageManager+Business.h"

#import "IESGeckoDefines+Private.h"
#import "IESGurdResourceMetadataStorage+Private.h"
#import "IESGurdClearCacheManager.h"
#import "IESGurdApplyPackageManager.h"
#import "IESGurdSyncResourcesGroup.h"
#import "IESGurdLogProxy.h"
#import "IESGurdEventTraceManager+Business.h"

typedef void(^IESGurdDownloadPackageCompletion)(BOOL succeed, BOOL isPatch, IESGurdSyncStatus status);

@implementation IESGurdDownloadPackageManager (Business)

#pragma mark - Public

+ (void)downloadResourcesWithModels:(NSArray<IESGurdResourceModel *> *)models
                          accessKey:(NSString *)accessKey
                        shouldApply:(BOOL)shouldApply
                            logInfo:(NSDictionary *)logInfo
                         completion:(IESGurdSyncStatusDictionaryBlock)completion
{
    IESGurdSyncResourcesGroup *group = [IESGurdSyncResourcesGroup groupWithCompletion:completion];
    
    [models enumerateObjectsUsingBlock:^(IESGurdResourceModel *model, NSUInteger idx, BOOL *stop) {
        NSString *channel = model.channel;
        if (IES_isEmptyString(channel)) {
            return;
        }
        
        [group enter];
        IESGurdDownloadPackageCompletion downloadCompletion = ^(BOOL downloadSuccessfully, BOOL isPatch, IESGurdSyncStatus downloadStatus) {
            void (^updateStatusBlock)(BOOL, IESGurdSyncStatus) = ^(BOOL succeed, IESGurdSyncStatus status) {
                [group leaveWithChannel:channel isSuccessful:succeed status:status];
            };
            
            BOOL cancelDownload = (downloadStatus == IESGurdSyncStatusDownloadVersionIsActive ||
                                   downloadStatus == IESGurdSyncStatusDownloadVersionIsInactive);
            
            if (!shouldApply) {
                updateStatusBlock(downloadSuccessfully ? YES : cancelDownload, downloadStatus);
                return;
            }
            
            if (!downloadSuccessfully && downloadStatus != IESGurdSyncStatusDownloadVersionIsInactive) {
                updateStatusBlock(cancelDownload, downloadStatus);
                return;
            }
            
            IESGurdSyncStatusBlock applyCompletion = ^(BOOL applySucceed, IESGurdSyncStatus applyStatus) {
                if (applySucceed || !model.isZstd) {
                    updateStatusBlock(applySucceed, applyStatus);
                    return;
                }
                [self fallbackWithModel:model
                                logInfo:logInfo
                                isPatch:isPatch
                            applyStatus:applyStatus
                             completion:updateStatusBlock];
            };
            [[IESGurdApplyPackageManager sharedManager] applyInactiveCacheForAccessKey:accessKey
                                                                               channel:channel
                                                                               logInfo:logInfo
                                                                            completion:applyCompletion];
        };
        [self downloadResourceWithModel:model
                                logInfo:logInfo
                             completion:downloadCompletion];
    }];
    
    [group notifyWithBlock:nil];
}

+ (void)downloadResourcesWithModels:(NSArray<IESGurdResourceModel *> *)models
                            logInfo:(NSDictionary * _Nullable)logInfo
{
    [self downloadResourcesWithModels:models
                              logInfo:logInfo
                             callback:nil];
}

+ (void)downloadResourcesWithModels:(NSArray<IESGurdResourceModel *> *)models
                            logInfo:(NSDictionary * _Nullable)logInfo
                           callback:(IESGurdDownloadResourceCallback _Nullable)callback
{
    [models enumerateObjectsUsingBlock:^(IESGurdResourceModel *model, NSUInteger idx, BOOL *stop) {
        NSString *accessKey = model.accessKey;
        NSString *channel = model.channel;
        if (IES_isEmptyString(accessKey) || IES_isEmptyString(channel)) {
            return;
        }
        
        IESGurdDownloadPackageCompletion downloadCompletion = ^(BOOL isSuccessful, BOOL isPatch, IESGurdSyncStatus downloadStatus) {
            if (!isSuccessful && downloadStatus != IESGurdSyncStatusDownloadVersionIsInactive) {
                BOOL cancelDownload = (downloadStatus == IESGurdSyncStatusDownloadVersionIsActive ||
                                       downloadStatus == IESGurdSyncStatusDownloadVersionIsInactive);
                !callback ? : callback(model, cancelDownload, downloadStatus);
                return;
            }
            
            IESGurdSyncStatusBlock applyCompletion = ^(BOOL applySucceed, IESGurdSyncStatus applyStatus) {
                IESGurdDownloadResourceCallback callbackBlock = ^(IESGurdResourceModel *model, BOOL succeed, IESGurdSyncStatus status) {
                    !callback ? : callback(model, succeed, status);
                };
                
                if (applySucceed || !model.isZstd) {
                    callbackBlock(model, applySucceed, applyStatus);
                    return;
                }
                [self fallbackWithModel:model logInfo:logInfo isPatch:isPatch applyStatus:applyStatus completion:^(BOOL succeed, IESGurdSyncStatus status) {
                    callbackBlock(model, succeed, status);
                }];
            };
            [[IESGurdApplyPackageManager sharedManager] applyInactiveCacheForAccessKey:accessKey
                                                                               channel:channel
                                                                               logInfo:logInfo
                                                                            completion:applyCompletion];
        };
        [self downloadResourceWithModel:model
                                logInfo:logInfo
                             completion:downloadCompletion];
    }];
}

#pragma mark - Private

+ (void)fallbackWithModel:(IESGurdResourceModel *)model
                  logInfo:(NSDictionary *)logInfo
                  isPatch:(BOOL)isPatch
              applyStatus:(IESGurdSyncStatus)status
               completion:(IESGurdSyncStatusBlock)completion
{
    if (isPatch) {
        [self fallbackToZstdFullPackageWithModel:model
                                         logInfo:logInfo
                                      completion:completion];
    } else {
        completion(NO, status);
    }
}

+ (void)fallbackToZstdFullPackageWithModel:(IESGurdResourceModel *)model
                                   logInfo:(NSDictionary *)logInfo
                                completion:(IESGurdSyncStatusBlock)completion
{
    [self traceEventWithConfig:model
                       message:@"apply zstd patch failed, fallback to full package"
                      hasError:YES
                     shouldLog:YES];
    
    IESGurdDownloadPackageCompletion downloadCompletion = ^(BOOL succeed, BOOL isPatch, IESGurdSyncStatus status) {
        IESGurdSyncStatusBlock applyCompletion = ^(BOOL succeed, IESGurdSyncStatus status) {
            if (succeed) {
                completion(succeed, status);
                return;
            }
            completion(NO, status);
        };
        [[IESGurdApplyPackageManager sharedManager] applyInactiveCacheForAccessKey:model.accessKey
                                                                           channel:model.channel
                                                                           logInfo:logInfo
                                                                        completion:applyCompletion];
    };
    [self downloadResourceWithModel:[model fullPackageInstance]
                            logInfo:logInfo
                         completion:downloadCompletion];
}

+ (void)downloadResourceWithModel:(IESGurdResourceModel *)model
                          logInfo:(NSDictionary *)logInfo
                       completion:(IESGurdDownloadPackageCompletion)completion
{
    if (model.strategies.deleteBeforeDownload) {
        [IESGurdClearCacheManager clearCacheForAccessKey:model.accessKey channel:model.channel];
    }
    
    IESGurdDownloadPackageResultBlock resultBlock = ^(BOOL isSuccessful, BOOL isPatch, NSError *error) {
        BOOL cancelDownload = (error.code == IESGurdSyncStatusDownloadVersionIsActive ||
                               error.code == IESGurdSyncStatusDownloadVersionIsInactive);
        
        if (!isSuccessful && !cancelDownload && !isPatch && model.strategies.deleteIfDownloadFailed) {
            [IESGurdClearCacheManager clearCacheForAccessKey:model.accessKey channel:model.channel];
        }
        
        IESGurdSyncStatus status = isSuccessful ? IESGurdSyncStatusSuccess : error.code;
        !completion ? : completion(isSuccessful, isPatch, status);
    };
    [[self sharedManager] downloadPackageWithConfig:model
                                            logInfo:logInfo
                                        resultBlock:resultBlock];
}

+ (void)traceEventWithConfig:(IESGurdResourceModel *)config
                     message:(NSString *)message
                    hasError:(BOOL)hasError
                   shouldLog:(BOOL)shouldLog
{
    if (message.length == 0) {
        return;
    }
    IESGurdTraceMessageInfo *messageInfo = [IESGurdTraceMessageInfo messageInfoWithAccessKey:config.accessKey
                                                                                     channel:config.channel
                                                                                     message:message
                                                                                    hasError:hasError];
    messageInfo.shouldLog = shouldLog;
    [IESGurdEventTraceManager traceEventWithMessageInfo:messageInfo];
}

@end
