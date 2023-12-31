//
//  IESGurdApplyPackageManager.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/27.
//

#import "IESGurdApplyPackageManager.h"

//header
#import "IESGeckoDefines+Private.h"
#import "IESGurdProtocolDefines.h"
#import "IESGeckoFileMD5Hash.h"
#import "IESGurdKitUtil.h"
#import "IESGeckoKit.h"
//meta
#import "IESGurdResourceMetadataStorage+Private.h"
//logger
#import "IESGurdAppLogger.h"
//manager
#import "IESGurdFileBusinessManager.h"
#import "IESGurdEventTraceManager+Business.h"
#import "IESGurdDelegateDispatcherManager.h"
//category
#import "NSError+IESGurdKit.h"
//model
#import "IESGurdUnzipPackageInfo.h"
//util
#import "IESGurdKitUtil.h"
#import "IESGurdPatch.h"
#import "IESGurdKit+Experiment.h"
//third
#import <SSZipArchive/ZipArchive.h>
//cache
#import "IESGurdExpiredCacheManager.h"
// block list
#import "IESGurdCachePackageModelsManager.h"
#import "IESGurdChannelBlocklistManager.h"

#define FILE_MANAGER  [NSFileManager defaultManager]

typedef void(^IESGurdApplyPackageCompletion)(BOOL succeed, NSError *error);

static dispatch_queue_t IESGurdUnzipQueue (void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = IESGurdKitCreateConcurrentQueue("com.ies.gurd.unzip");
    });
    return queue;
};

@interface IESGurdApplyPackageManager ()

@property (nonatomic, strong) NSMutableDictionary *applyCompletionDictionary;

@end

@implementation IESGurdApplyPackageManager

+ (instancetype)sharedManager
{
    static IESGurdApplyPackageManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

#pragma mark - Public

- (void)applyAllInactiveCacheWithCompletion:(IESGurdSyncStatusBlock)completion
{
    NSDictionary<NSString *, NSDictionary<NSString *, IESGurdInactiveCacheMeta *> *> *metadataDictionary =
    [IESGurdResourceMetadataStorage copyInactiveMetadataDictionary];
    if (metadataDictionary.count == 0) {
        !completion ? : completion(NO, IESGurdSyncStatusActiveInactiveNoCaches);
        return;
    }
    __block IESGurdSyncStatus callbackStatus = IESGurdApplyInactivePackagesStatusSuccess;
    
    dispatch_group_t group = dispatch_group_create();
    [metadataDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary<NSString *,IESGurdInactiveCacheMeta *> *dictionary, BOOL *stop) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdInactiveCacheMeta *meta, BOOL *stop) {
            dispatch_group_enter(group);
            [self applyInactiveCacheWithMeta:meta logInfo:nil completion:^(BOOL succeed, IESGurdSyncStatus status) {
                if (status != IESGurdSyncStatusSuccess) {
                    callbackStatus = IESGurdApplyInactivePackagesStatusFailed;
                }
                dispatch_group_leave(group);
            }];
        }];
    }];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        BOOL success = (callbackStatus == IESGurdApplyInactivePackagesStatusSuccess);
        !completion ? : completion(success, callbackStatus);
    });
}

- (void)applyInactiveCacheForAccessKey:(NSString *)accessKey
                               channel:(NSString *)channel
                            completion:(IESGurdSyncStatusBlock)completion
{
    [self applyInactiveCacheForAccessKey:accessKey
                                 channel:channel
                                 logInfo:nil
                              completion:completion];
}

- (void)applyInactiveCacheForAccessKey:(NSString *)accessKey
                               channel:(NSString *)channel
                               logInfo:(NSDictionary * _Nullable)logInfo
                            completion:(IESGurdSyncStatusBlock)completion
{
    IESGurdInactiveCacheMeta *meta = [IESGurdResourceMetadataStorage inactiveMetaForAccessKey:accessKey channel:channel];
    [self applyInactiveCacheWithMeta:meta
                             logInfo:logInfo
                          completion:completion];
}

#pragma mark - Private

- (void)applyInactiveCacheWithMeta:(IESGurdInactiveCacheMeta *)meta
                           logInfo:(NSDictionary * _Nullable)logInfo
                        completion:(IESGurdSyncStatusBlock)completion
{
    if ([IESGurdKit isChannelLocked:meta.accessKey channel:meta.channel]) {
        !completion ? : completion(NO, IESGurdSyncStatusLocked);
        return;
    }
    
    if (!meta) {
        !completion ? : completion(NO, IESGurdSyncStatusActiveInactiveNoCaches);
        return;
    }
    
    NSString *accessKey = meta.accessKey;
    NSString *channel = meta.channel;
    
    __block BOOL shouldApply = NO;
    NSString *key = [NSString stringWithFormat:@"%@-%@", accessKey, channel];
    @synchronized (self) {
        NSMutableArray *completionArray = self.applyCompletionDictionary[key];
        if (!completionArray) {
            completionArray = [NSMutableArray array];
            self.applyCompletionDictionary[key] = completionArray;
            
            shouldApply = YES;
        }
        if (completion) {
            [completionArray addObject:completion];
        }
    }
    if (!shouldApply) {
        return;
    }
    
    [IESGurdFileBusinessManager asyncExecuteBlock:^{
        IESGurdApplyPackageCompletion innerCompletion = ^(BOOL succeed, NSError *error) {
            // save active meta
            if (succeed) {
                [self gurdDidApplyPackageWithInactiveMeta:meta];
            }
            // delegate
            [self notifyApplyResult:succeed
                              error:error
                       inactiveMeta:meta];
            // applog
            [self reportApplyResult:succeed
                              error:error
                       inactiveMeta:meta
                            logInfo:logInfo];
            
            @synchronized (self) {
                NSMutableArray *completionArray = self.applyCompletionDictionary[key];
                [self.applyCompletionDictionary removeObjectForKey:key];
                
                IESGurdSyncStatus status = succeed ? IESGurdSyncStatusSuccess : error.code;
                [[completionArray copy] enumerateObjectsUsingBlock:^(IESGurdSyncStatusBlock block, NSUInteger idx, BOOL *stop) {
                    dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
                        block(succeed, status);
                    });
                }];
            }
        };
        if (meta.isZstd) {
            [self applyZstdPackage:meta completion:innerCompletion];
        } else if (meta.packageType == IESGurdChannelFileTypeCompressed) {
            [self unzipInactiveCacheWithMeta:meta completion:innerCompletion];
        } else if (meta.packageType == IESGurdChannelFileTypeUncompressed) {
            [self copyInactiveCacheWithMeta:meta completion:innerCompletion];
        }
    } accessKey:accessKey channel:channel];
}

- (void)copyInactiveCacheWithMeta:(IESGurdInactiveCacheMeta *)meta
                       completion:(IESGurdApplyPackageCompletion)completion
{
    NSString *accessKey = meta.accessKey;
    NSString *channel = meta.channel;
    NSString *md5 = meta.md5;
    
    NSError *error = nil;
    NSString *channelDirectory = [IESGurdFileBusinessManager createDirectoryForAccessKey:accessKey
                                                                                 channel:channel
                                                                                   error:&error];
    if (!channelDirectory) {
        NSString *message = [NSString stringWithFormat:@"❌ Channel directory doesn't exist（Reason : %@）",
                             error.localizedDescription];
        NSError *channelDirectoryError = [NSError ies_errorWithCode:IESGurdSyncStatusBusinesspBundlePathNotExist
                                                        description:message];
        !completion ? : completion(NO, channelDirectoryError);
        return;
    }
    
    [self traceEventWithInactiveMeta:meta message:@"Start copying file" hasError:NO shouldLog:NO];
    
    NSString *backupPath = [IESGurdFilePaths backupSingleFilePathForMd5:md5];
    NSString *targetPackagePath = [channelDirectory stringByAppendingPathComponent:meta.fileName];
    if ([FILE_MANAGER copyItemAtPath:backupPath toPath:targetPackagePath error:&error]) {
        !completion ? : completion(YES, nil);
        return;
    }
    
    // 清除过期缓存（一期试验先不开启）
//    [[IESGurdExpiredCacheManager sharedManager] clearCache:nil];
    
    NSString *message = [NSString stringWithFormat:@"❌ Copy file failed (Version : %llu; Reason : %@; SrcPath : %@; DesPath : %@)",
                         meta.version,
                         error.localizedDescription,
                         [IESGurdFilePaths briefFilePathWithFullPath:backupPath],
                         [IESGurdFilePaths briefFilePathWithFullPath:targetPackagePath]];
    NSError *copyItemError = [NSError ies_errorWithCode:IESGurdSyncStatusCopyPackageFailed
                                            description:message];
    !completion ? : completion(NO, copyItemError);
}

- (NSString *)getInactivePackagePath:(IESGurdInactiveCacheMeta *)meta
                               error:(NSError **)error
{
    NSString *accessKey = meta.accessKey;
    NSString *channel = meta.channel;
    NSString *filePath = [IESGurdFilePaths inactivePackagePathForAccessKey:accessKey
                                                                   channel:channel
                                                                   version:meta.version
                                                                    isZstd:meta.isZstd
                                                                       md5:meta.md5];
    if (![FILE_MANAGER fileExistsAtPath:filePath]) {
        [IESGurdResourceMetadataStorage deleteInactiveMetaForAccessKey:accessKey channel:channel];
        
        NSString *inactiveDirectory = [IESGurdFilePaths inactivePathForAccessKey:accessKey channel:channel];
        NSString *localVersion = [FILE_MANAGER contentsOfDirectoryAtPath:inactiveDirectory error:NULL].firstObject;
        NSString *localVersionPath = [inactiveDirectory stringByAppendingPathComponent:localVersion];
        NSString *localMd5 = [FILE_MANAGER contentsOfDirectoryAtPath:localVersionPath error:NULL].firstObject;
        
        NSString *message = [NSString stringWithFormat:@"❌ Zip package doesn't exist (Local version : %@; Expected version : %llu; Local md5 : %@; Expected md5 : %@)",
                             localVersion ? : @"unknown",
                             meta.version,
                             localMd5 ? : @"unknown",
                             meta.md5 ? : @"unknown"];
        *error = [NSError ies_errorWithCode:IESGurdSyncStatusActiveInactiveNoCaches
                                description:message];
        return nil;
    }
    return filePath;
}

- (void)applyZstdPackage:(IESGurdInactiveCacheMeta *)meta
              completion:(IESGurdApplyPackageCompletion)completion
{
//    NSLog(@"IESGurd start apply zstd, %@", meta);
    NSError *error = nil;
    NSString *filePath = [self getInactivePackagePath:meta error:&error];
    if (!filePath) {
//        NSLog(@"IESGurd get package file error, %@", meta);
        !completion ? : completion(NO, error);
        return;
    };
    
    GURD_TIK;
    NSString *dest = [filePath stringByAppendingFormat:@".zstd.tmp.%llu", meta.version];
    NSString *errorMsg = nil;
    if (!decompressFile(filePath, dest, &errorMsg)) {
        [FILE_MANAGER removeItemAtPath:filePath error:NULL];
        [FILE_MANAGER removeItemAtPath:dest error:NULL];
        NSError *error = [NSError ies_errorWithCode:IESGurdSyncStatusDecompressZstdFailed
                                        description:errorMsg];
        !completion ? : completion(NO, error);
        return;
    }
    
//    NSLog(@"IESGurd decompress zstd success, %@", meta);
    [FILE_MANAGER removeItemAtPath:filePath error:NULL];
    NSString *realMD5 = [IESGurdFileMD5Hash md5HashOfFileAtPath:dest error:nil];
    if (![realMD5 isEqualToString:meta.decompressMD5]) {
        NSString *msg = [NSString stringWithFormat:@"decompress zstd check md5 failed: %@, realMD5:%@, expectMD5:%@",
                         [IESGurdFilePaths briefFilePathWithFullPath:filePath], realMD5 ? : @"", meta.decompressMD5];
        NSError *error = [NSError ies_errorWithCode:IESGurdSyncStatusDecompressZstdCheckMd5Failed
                                        description:msg];
        !completion ? : completion(NO, error);
        return;
    }
    meta.updateStatisticModel.durationDecompressZstd = GURD_TOK;
    
//    NSLog(@"IESGurd decompress zstd check md5 success, %@", meta);
    if (meta.fromPatch) {
        [self patchZstd:meta patch:dest completion:completion];
    } else {
        // 使用zip解包
        [self unpackZstd:meta zipPath:dest completion:completion];
    }
}

- (void)patchZstd:(IESGurdInactiveCacheMeta *)meta
            patch:(NSString *)patch
       completion:(IESGurdApplyPackageCompletion)completion
{
    NSString *accessKey = meta.accessKey;
    NSString *channel = meta.channel;
    NSString *channelDirectory = [IESGurdFilePaths directoryPathForAccessKey:accessKey channel:channel];
    if (![FILE_MANAGER fileExistsAtPath:channelDirectory] ||
        [[FILE_MANAGER contentsOfDirectoryAtPath:channelDirectory error:NULL] count] == 0) {
        [FILE_MANAGER removeItemAtPath:patch error:NULL];
        NSString *message = [NSString stringWithFormat:@"patchZstd failed, channel directory doesn't exist or empty: %@-%@",
                             accessKey, channel];
        NSError *error = [NSError ies_errorWithCode:IESGurdSyncStatusBusinesspBundlePathNotExist description:message];
        completion(NO, error);
        return;
    }
    
    GURD_TIK;
    NSString *inactivePath = [IESGurdFilePaths inactivePathForAccessKeyAndVersion:accessKey channel:channel version:meta.version];
    NSString *dest = [inactivePath stringByAppendingPathComponent:@".bytepatch.tmp"];
    IESGurdPatch *bytepatch = [[IESGurdPatch alloc] init];
    NSError *patchError = nil;
    if (![bytepatch patch:channelDirectory dest:dest patch:patch error:&patchError]) {
        [FILE_MANAGER removeItemAtPath:patch error:NULL];
        completion(NO, patchError);
        return;
    }
    meta.updateStatisticModel.durationBytepatch = GURD_TOK;
    
    if ([IESGurdKit isChannelLocked:accessKey channel:channel]) {
        NSError *error = [NSError ies_errorWithCode:IESGurdSyncStatusLocked
                                        description:@"channel is locked"];
        !completion ? : completion(NO, error);
        return;
    }
    
//    NSLog(@"IESGurd patch zstd success, %@", meta);
    [FILE_MANAGER removeItemAtPath:patch error:NULL];
    NSError *fileError = nil;
    if (![FILE_MANAGER removeItemAtPath:channelDirectory error:&fileError] ||
        ![FILE_MANAGER moveItemAtPath:dest toPath:channelDirectory error:&fileError]) {
        [FILE_MANAGER removeItemAtPath:dest error:nil];
        NSString *message = [NSString stringWithFormat:@"patchZstd failed, rename error: %@", fileError.localizedDescription];
        NSError *error = [NSError ies_errorWithCode:IESGurdSyncStatusRenameZstdFailed description:message];
        completion(NO, error);
        return;
    }
    
//    NSLog(@"IESGurd rename zstd success, %@", meta);
    // 删除旧的zip
    NSString *backupPath = [IESGurdFileBusinessManager backupPathForAccessKey:accessKey channel:channel];
    [FILE_MANAGER removeItemAtPath:backupPath error:NULL];
    // 删除inactive目录
    [IESGurdFileBusinessManager cleanInactiveCacheForAccessKey:accessKey channel:channel];
    
    completion(YES, nil);
}

- (void)unpackZstd:(IESGurdInactiveCacheMeta *)meta
           zipPath:(NSString *)zipFilePath
        completion:(IESGurdApplyPackageCompletion)completion
{
    NSString *accessKey = meta.accessKey;
    NSString *channel = meta.channel;
    [self unzipWebCacheWithMeta:meta zipFilePath:zipFilePath completion:^(BOOL unzipSucceed, NSError *unzipError) {
        [IESGurdFileBusinessManager asyncExecuteBlock:^{
            [FILE_MANAGER removeItemAtPath:zipFilePath error:NULL];
            if (!unzipSucceed) {
                completion(NO, unzipError);
                return;
            }
            
            // NSLog(@"IESGurd unpack zstd success, %@", meta);
            // 删除旧的zip
            NSString *backupPath = [IESGurdFileBusinessManager backupPathForAccessKey:accessKey channel:channel];
            [FILE_MANAGER removeItemAtPath:backupPath error:NULL];
            // 删除inactive目录
            [IESGurdFileBusinessManager cleanInactiveCacheForAccessKey:accessKey channel:channel];
            
            completion(YES, nil);
        } accessKey:accessKey channel:channel];
    }];
}


- (void)unzipInactiveCacheWithMeta:(IESGurdInactiveCacheMeta *)meta
                        completion:(IESGurdApplyPackageCompletion)completion
{
    NSString *accessKey = meta.accessKey;
    NSString *channel = meta.channel;
    
    NSError *error;
    NSString *zipFilePath = [self getInactivePackagePath:meta error:&error];
    if (!zipFilePath) {
        completion(NO, error);
        return;
    };
    
    __weak IESGurdApplyPackageManager *weakSelf = self;
    [self unzipWebCacheWithMeta:meta zipFilePath:zipFilePath completion:^(BOOL unzipSucceed, NSError *unzipError) {
        [IESGurdFileBusinessManager asyncExecuteBlock:^{
            if (!unzipSucceed) {
                [FILE_MANAGER removeItemAtPath:zipFilePath error:NULL];
                completion(NO, unzipError);
                return;
            }
            
            // 删除旧的zip
            NSString *backupPath = [IESGurdFileBusinessManager backupPathForAccessKey:accessKey channel:channel];
            [FILE_MANAGER removeItemAtPath:backupPath error:NULL];
            
            // 对于使用zstd的用户，不需要保存zip了
            [FILE_MANAGER removeItemAtPath:zipFilePath error:NULL];
            
            // 删除inactive目录
            [IESGurdFileBusinessManager cleanInactiveCacheForAccessKey:accessKey channel:channel];
            
            completion(YES, nil);
        } accessKey:accessKey channel:channel];
    }];
}

- (void)unzipWebCacheWithMeta:(IESGurdInactiveCacheMeta *)meta
                  zipFilePath:(NSString *)zipFilePath
                   completion:(IESGurdApplyPackageCompletion)completion
{
    NSString *tempDirectory = [IESGurdFileBusinessManager applyTempFilePath];
    NSError *error = nil;
    BOOL createDirectorySucceed = [FILE_MANAGER createDirectoryAtPath:tempDirectory
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:&error];
    if (!createDirectorySucceed) {
        NSString *message = [NSString stringWithFormat:@"❌ Create temp directory for unzip failed (Reason : %@)", error.localizedDescription];
        NSError *createDirectoryError = [NSError ies_errorWithCode:IESGurdSyncStatusCreateTmpPathForUnzipFailed
                                                       description:message];
        !completion ? : completion(NO, createDirectoryError);
        return;
    }
    
    [self innerUnzipWebCacheWithMeta:meta
                         zipFilePath:zipFilePath
                       tempDirectory:tempDirectory
                          completion:completion];
}

- (void)innerUnzipWebCacheWithMeta:(IESGurdInactiveCacheMeta *)meta
                       zipFilePath:(NSString *)zipFilePath
                     tempDirectory:(NSString *)tempDirectory
                        completion:(IESGurdApplyPackageCompletion)completion
{
    dispatch_async(IESGurdUnzipQueue(), ^{
        [self traceEventWithInactiveMeta:meta message:@"Start unzipping package" hasError:NO shouldLog:NO];
        
        IESGurdUnzipPackageInfo *unzipPackageInfo = [[IESGurdUnzipPackageInfo alloc] init];
        GURD_TIK;
        __weak IESGurdApplyPackageManager *weakSelf = self;
        [SSZipArchive unzipFileAtPath:zipFilePath toDestination:tempDirectory progressHandler:nil completionHandler:^(NSString *path, BOOL unzipSucceed, NSError *unzipError) {
            unzipPackageInfo.successful = unzipSucceed;
            unzipPackageInfo.error = unzipError;
            unzipPackageInfo.unzipDuration = GURD_TOK;
            if (unzipSucceed) {
                meta.updateStatisticModel.durationUnzip = GURD_TOK;
            }
            
            [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidFinishUnzippingPackageForAccessKey:meta.accessKey
                                                                                         channel:meta.channel
                                                                                     packageInfo:unzipPackageInfo];
            
            IESGurdApplyPackageCompletion unzipCompletion = ^(BOOL succeed, NSError *error) {
                [FILE_MANAGER removeItemAtPath:tempDirectory error:NULL];
                !completion ? : completion(succeed, error);
            };
            
            if (!unzipSucceed) {
                // 清理过期缓存（一期试验先不开启）
//                if (unzipError.code == SSZipArchiveErrorCodeFailedToWriteFile) {
//                    [[IESGurdExpiredCacheManager sharedManager] clearCache:nil];
//                }
                NSString *message = [NSString stringWithFormat:@"❌ Unzip failed (Version : %llu; Reason : %@; PackagePath : %@; PackageSize : %@)",
                                     meta.version,
                                     unzipError.localizedDescription,
                                     [IESGurdFilePaths briefFilePathWithFullPath:zipFilePath],
                                     [IESGurdFilePaths fileSizeStringAtPath:zipFilePath]];
                NSError *gurdUnzipError = [NSError ies_errorWithCode:IESGurdSyncStatusUnzipPackageFailed
                                                         description:message];
                unzipCompletion(NO, gurdUnzipError);
                return;
            }
            
            [weakSelf updateResourcesWithMetaData:meta tempDirectory:tempDirectory completion:^(BOOL succeed, NSError *error) {
                unzipCompletion(succeed, error);
            }];
        }];
    });
}

- (void)updateResourcesWithMetaData:(IESGurdInactiveCacheMeta *)meta
                      tempDirectory:(NSString *)tempDirectory
                         completion:(void (^)(BOOL succeed, NSError *error))completion
{
    NSString *accessKey = meta.accessKey;
    NSString *channel = meta.channel;
    
    [IESGurdFileBusinessManager asyncExecuteBlock:^{
        __block NSError *error = nil;
        NSString *channelDirectory = [IESGurdFileBusinessManager createDirectoryForAccessKey:accessKey
                                                                                     channel:channel
                                                                                       error:&error];
        if (!channelDirectory) {
            NSString *message = [NSString stringWithFormat:@"❌ Channel directory doesn't exist（Reason : %@）",
                                 error.localizedDescription];
            NSError *channelDirectoryError = [NSError ies_errorWithCode:IESGurdSyncStatusBusinesspBundlePathNotExist
                                                            description:message];
            !completion ? : completion(NO, channelDirectoryError);
            return;
        }
        
        if ([IESGurdKit isChannelLocked:accessKey channel:channel]) {
            NSError *error = [NSError ies_errorWithCode:IESGurdSyncStatusLocked
                                            description:@"channel is locked"];
            !completion ? : completion(NO, error);
            return;
        }
        
        NSString *resourcesDirectory = [tempDirectory stringByAppendingPathComponent:channel];
        __block BOOL succeed = YES;
        [[FILE_MANAGER contentsOfDirectoryAtPath:resourcesDirectory error:NULL] enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            NSString *sourcePath = [resourcesDirectory stringByAppendingPathComponent:name];
            NSString *destinationPath = [channelDirectory stringByAppendingPathComponent:name];
            NSError *moveItemError = nil;
            
            if (![FILE_MANAGER moveItemAtPath:sourcePath toPath:destinationPath error:&moveItemError]) {
                BOOL sourceFileExists = [FILE_MANAGER fileExistsAtPath:sourcePath];
                NSString *message = [NSString stringWithFormat:@"❌ Move file failed (Version : %llu; Reason : %@; SrcPath : %@ %@; DesPath : %@)",
                                     meta.version,
                                     moveItemError.localizedDescription,
                                     sourcePath,
                                     sourceFileExists ? @"exists" : @"does not exist",
                                     [IESGurdFilePaths briefFilePathWithFullPath:destinationPath]];
                error = [NSError ies_errorWithCode:IESGurdSyncStatusRenameFailed
                                       description:message];
                succeed = NO;
                
                *stop = YES;
            }
        }];

        completion(succeed, error);
    } accessKey:accessKey channel:channel];
}

- (void)reportApplyResult:(BOOL)succeed
                    error:(NSError *)error
             inactiveMeta:(IESGurdInactiveCacheMeta *)meta
                  logInfo:(NSDictionary *)logInfo
{
    NSString *message = [NSString stringWithFormat:@"%@ Apply %@",
                         succeed ? @"✅" : @"❌",
                         succeed ? @"successfully" : [NSString stringWithFormat:@"failed, %@", error.localizedDescription ? : @""]];
    [self traceEventWithInactiveMeta:meta message:message hasError:!succeed shouldLog:YES];
    
    IESGurdUpdateStatisticModel *model = meta.updateStatisticModel;
    IESGurdUpdateStageModel *stageMode = [model getStageModel:NO isPatch:meta.fromPatch];
    if (!succeed) {
        [model resetDuration];
        stageMode.result = NO;
        stageMode.errCode = (int)error.code;
        stageMode.errMsg = error.localizedDescription;
        if (meta.fromPatch) {
            return;
        }
    }
    
    model.updateResult = succeed;
    model.durationTotal = GURD_TOK_WITH_START(model.startTime);
    stageMode.result = succeed;
    if (succeed) {
        model.durationLastStage = GURD_TOK_WITH_START(stageMode.startTime);
        model.durationActive = model.durationLastStage - model.durationDownload;
    }
    
    NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    [extra addEntriesFromDictionary:logInfo];
    [model putDataToDict:extra];
    [meta putDataToDict:extra];
    extra[@"package_size"] = meta.fromPatch ? @(meta.patchPackageSize) : @(meta.packageSize);
    extra[@"dur_from_cold_start"] = @(([[NSDate date] timeIntervalSince1970] - [IESGurdKit setupTimestamp]) * 1000);
    if ([[IESGurdChannelBlocklistManager sharedManager] isBlocklistChannel:meta.channel accessKey:meta.accessKey]) {
        extra[@"is_block"] = @(1);
    }
    
    [IESGurdAppLogger recordUpdateStats:[extra copy]];
}

- (void)notifyApplyResult:(BOOL)succeed
                    error:(NSError *)error
             inactiveMeta:(IESGurdInactiveCacheMeta *)inactiveMeta
{
    [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidFinishApplyingPackageForAccessKey:inactiveMeta.accessKey
                                                                                channel:inactiveMeta.channel
                                                                                succeed:succeed
                                                                                  error:error];
}

- (void)traceEventWithInactiveMeta:(IESGurdInactiveCacheMeta *)inactiveMeta
                           message:(NSString *)message
                          hasError:(BOOL)hasError
                         shouldLog:(BOOL)shouldLog
{
    if (message.length == 0) {
        return;
    }
    message = [NSString stringWithFormat:@"<%@> %@", inactiveMeta.logId ? : @"unknown", message];
    IESGurdTraceMessageInfo *messageInfo = [IESGurdTraceMessageInfo messageInfoWithAccessKey:inactiveMeta.accessKey
                                                                                     channel:inactiveMeta.channel
                                                                                     message:message
                                                                                    hasError:hasError];
    messageInfo.shouldLog = shouldLog;
    [IESGurdEventTraceManager traceEventWithMessageInfo:messageInfo];
}

- (void)gurdDidApplyPackageWithInactiveMeta:(IESGurdInactiveCacheMeta *)inactiveMeta
{
    NSString *accessKey = inactiveMeta.accessKey;
    NSString *channel = inactiveMeta.channel;
    
    IESGurdActivePackageMeta *activeMeta = [[IESGurdActivePackageMeta alloc] init];
    activeMeta.accessKey = accessKey;
    activeMeta.channel = channel;
    activeMeta.version = inactiveMeta.version;
    activeMeta.md5 = inactiveMeta.md5;
    activeMeta.packageID = inactiveMeta.packageID;
    activeMeta.packageType = inactiveMeta.packageType;
    int64_t lastUpdateTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    activeMeta.lastUpdateTimestamp = lastUpdateTimestamp;
    activeMeta.packageSize = inactiveMeta.packageSize;
    activeMeta.groups = inactiveMeta.groups;
    
    // 把旧的 lastReadTimestamp 迁移到新建的 meta 上
    IESGurdActivePackageMeta *preActiveMeta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
    activeMeta.lastReadTimestamp = (preActiveMeta.lastReadTimestamp > 0) ? preActiveMeta.lastReadTimestamp : lastUpdateTimestamp;
    activeMeta.isUsed = preActiveMeta.isUsed;
    
    IESGurdUpdateStatisticModel *model = inactiveMeta.updateStatisticModel;
    IESGurdUpdateStageModel *stageMode = [model getStageModel:NO isPatch:YES];
    // 全量（非增量转全量）更新时，如果lastReadTimestamp>0
    if ((preActiveMeta.lastReadTimestamp > 0 && !inactiveMeta.fromPatch && !stageMode)) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        dictionary[@"localVersion"] = @(inactiveMeta.localVersion);
        dictionary[@"version"] = @(preActiveMeta.version);
        dictionary[@"packageID"] = @(preActiveMeta.packageID);
        dictionary[@"lastUpdateTimestamp"] = @(preActiveMeta.lastUpdateTimestamp);
        dictionary[@"lastReadTimestamp"] = @(preActiveMeta.lastReadTimestamp);
        dictionary[@"groupName"] = [preActiveMeta.groups componentsJoinedByString:@","];
        NSString *msg = [NSString stringWithFormat:@"%@", dictionary];
        [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeClearCache
                                      subtype:IESGurdAppLogEventSubtypeLastReadTimestampError
                                       params:nil
                                    extraInfo:preActiveMeta.metadataIdentity
                                 errorMessage:msg];
    }

    [IESGurdResourceMetadataStorage saveActiveMeta:activeMeta];
    
    [IESGurdResourceMetadataStorage deleteInactiveMetaForAccessKey:accessKey channel:channel];
    
    if ([self.delegate respondsToSelector:@selector(applyPackageManager:didApplyPackageForAccessKey:channel:)]) {
        [self.delegate applyPackageManager:self
               didApplyPackageForAccessKey:accessKey
                                   channel:channel];
    }
}

#pragma mark - Getter

- (NSMutableDictionary *)applyCompletionDictionary
{
    if (!_applyCompletionDictionary) {
        _applyCompletionDictionary = [NSMutableDictionary dictionary];
    }
    return _applyCompletionDictionary;
}

@end

#undef FILE_MANAGER
