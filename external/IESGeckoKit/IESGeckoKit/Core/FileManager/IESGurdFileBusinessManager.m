//
//  IESGurdFileBusinessManager.m
//  Pods
//
//  Created by 陈煜钏 on 2019/9/29.
//

#import "IESGurdFileBusinessManager.h"

#import <objc/runtime.h>
#import "IESGeckoDefines.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdProtocolDefines.h"
#import "IESGurdKit+InternalPackages.h"
#import "IESGurdKit+Experiment.h"
#import "IESGurdResourceMetadataStorage+Private.h"
#import "IESGurdDelegateDispatcherManager.h"
#import "IESGurdInternalPackagesManager.h"
#import "IESGurdKitUtil.h"
#import "IESGurdLogProxy.h"
#import "NSError+IESGurdKit.h"

#define FILE_MANAGER        [NSFileManager defaultManager]

static NSString * const kIESGurdApplyTempFilePrefix = @"gurd-apply";
static NSString * const kIESGurdDownloadTempFilePrefix = @"gurd-download";

static NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *kIESGurdCacheWhitelist;

static dispatch_queue_t IESGurdBusinessFileQueue (NSString *accessKey, NSString *channel);

@implementation IESGurdFileBusinessManager

+ (void)setup
{
    [self _createDirectoryIfNeeded:IESGurdFilePaths.cacheRootDirectoryPath];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_clearTempFilesIfNeeded)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * 60 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:IESGurdFilePaths.backupDirectoryPath error:NULL];
        [[NSFileManager defaultManager] removeItemAtPath:IESGurdFilePaths.modifyTimeDirectoryPath error:NULL];
    });
}

#pragma mark - Data

+ (BOOL)hasCacheForAccessKey:(NSString *)accessKey channel:(NSString *)channel path:(NSString *)path
{
    NSString *cachePath = [self _cachePathForAccessKey:accessKey channel:channel path:path];
    if ([FILE_MANAGER fileExistsAtPath:cachePath]) {
        return YES;
    }
    IESGurdDataAccessPolicy dataAccessPolicy = [IESGurdInternalPackagesManager dataAccessPolicyForAccessKey:accessKey channel:channel];
    if (dataAccessPolicy == IESGurdDataAccessPolicyNormal) {
        return NO;
    }
    // internal package
    NSString *internalPackageCachePath = [self _internalPackageCachePathForAccessKey:accessKey channel:channel path:path];
    return [FILE_MANAGER fileExistsAtPath:internalPackageCachePath];
}

+ (NSData * _Nullable)dataForAccessKey:(NSString *)accessKey
                               channel:(NSString *)channel
                                  path:(NSString *)path
                               options:(NSDataReadingOptions)options
{
    NSData *data = nil;
    IESGurdDataAccessPolicy dataAccessPolicy = [IESGurdInternalPackagesManager dataAccessPolicyForAccessKey:accessKey channel:channel];
    if (dataAccessPolicy == IESGurdDataAccessPolicyInternalPackageFirst) {
        // internal package first
        data = [self _internalPackageDataForAccessKey:accessKey
                                              channel:channel
                                                 path:path
                                              options:options
                                     dataAccessPolicy:dataAccessPolicy];
        if (data.length > 0) {
            return data;
        }
    }
    
    NSString *cachePath = [self _cachePathForAccessKey:accessKey channel:channel path:path];
    data = [self _dataWithCachePath:cachePath options:options];
    IESGurdLogInfo(@"dataForPath - ak: %@, channel: %@, path: %@, cachePath: %@, data.length: %lu", accessKey, channel, path, cachePath, (unsigned long)data.length);

    if (data.length > 0) {
        [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidAccessCachePackageWithAccessKey:accessKey
                                                                                  channel:channel
                                                                                     path:path];
        return data;
    }
    
    if (dataAccessPolicy == IESGurdDataAccessPolicyInternalPackageBackup) {
        // internal package backup
        data = [self _internalPackageDataForAccessKey:accessKey
                                              channel:channel
                                                 path:path
                                              options:options
                                     dataAccessPolicy:dataAccessPolicy];
    }
    
    return data;
}

+ (NSData * _Nullable)offlineDataForAccessKey:(NSString *)accessKey
                                      channel:(NSString *)channel
                                         path:(NSString *)path
{
    NSString *cachePath = [self _cachePathForAccessKey:accessKey channel:channel path:path];
    NSData *data = [self _dataWithCachePath:cachePath options:NSDataReadingMappedIfSafe];
    IESGurdLogInfo(@"offlineDataForAccessKey - ak: %@, channel: %@, path: %@, cachePath: %@, data.length: %lu", accessKey, channel, path, cachePath, (unsigned long)data.length);

    if (data.length > 0) {
        [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidAccessCachePackageWithAccessKey:accessKey
                                                                                  channel:channel
                                                                                     path:path];
    }
    
    return data;
}

#pragma mark - Create Directory

+ (NSString * _Nullable)createDirectoryForAccessKey:(NSString *)accessKey
                                            channel:(NSString *)channel
                                              error:(NSError **)error
{
    __block NSString *channelDirectory = nil;
    __block NSError *createError = nil;
    dispatch_queue_sync_safe(IESGurdBusinessFileQueue(accessKey, channel), ^{
        NSString *directory = [IESGurdFilePaths directoryPathForAccessKey:accessKey channel:channel];
        if ([self _createDirectoryIfNeeded:directory error:&createError]) {
            channelDirectory = directory;
            
            [[FILE_MANAGER contentsOfDirectoryAtPath:directory error:NULL] enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
                [FILE_MANAGER removeItemAtPath:[directory stringByAppendingPathComponent:name] error:NULL];
            }];
        }
    });
    if (createError) {
        *error = createError;
    }
    return channelDirectory;
}

+ (NSString * _Nullable)createInactivePackagePathForAccessKey:(NSString *)accessKey
                                                      channel:(NSString *)channel
                                                      version:(uint64_t)version
                                                          md5:(NSString *)md5
                                                       isZstd:(BOOL)isZstd
                                                        error:(NSError **)error
{
    __block NSString *inactiveZipPath = nil;
    __block NSError *createError = nil;
    dispatch_queue_sync_safe(IESGurdBusinessFileQueue(accessKey, channel), (^{
        //创建inactive根目录
        if (![objc_getAssociatedObject(self, _cmd) boolValue]) {
            if ([self _createDirectoryIfNeeded:IESGurdFilePaths.inactiveDirectoryPath]) {
                objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
        
        NSString *inactiveCacheDirectory = [IESGurdFilePaths inactivePathForAccessKey:accessKey channel:channel];
        [FILE_MANAGER removeItemAtPath:inactiveCacheDirectory error:nil];
        
        NSString *versionPath = [inactiveCacheDirectory stringByAppendingPathComponent:@(version).stringValue];
        if ([self _createDirectoryIfNeeded:versionPath error:&createError]) {
            NSString *ext = isZstd ? @"zst" : @"zip";
            inactiveZipPath = [versionPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", md5, ext]];
        }
    }));
    if (createError) {
        *error = createError;
    }
    return inactiveZipPath;
}

+ (void)createBackupDirectoryIfNeeded
{
    if ([objc_getAssociatedObject(self, _cmd) boolValue]) {
        return;
    }
    if ([self _createDirectoryIfNeeded:IESGurdFilePaths.backupDirectoryPath]) {
        objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

+ (void)createBackupSingleFilePathIfNeeded
{
    if ([objc_getAssociatedObject(self, _cmd) boolValue]) {
        return;
    }
    if ([self _createDirectoryIfNeeded:IESGurdFilePaths.backupSingleFileChannelPath]) {
        objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - Paths

+ (NSString *)applyTempFilePath
{
    NSString *tempFileName = [NSString stringWithFormat:@"%@-%@-%f",
                              kIESGurdApplyTempFilePrefix,
                              [self tempFilePathUniqueString],
                              [NSDate date].timeIntervalSince1970];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
}

+ (NSString *)downloadTempFilePath
{
    NSString *tempFileName = [NSString stringWithFormat:@"%@-%@-%f",
                              kIESGurdDownloadTempFilePrefix,
                              [self tempFilePathUniqueString],
                              [NSDate date].timeIntervalSince1970];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
}

+ (NSString * _Nullable)backupPathForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    IESGurdActivePackageMeta *meta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
    if (!meta.md5) {
        return nil;
    }
    return [IESGurdFilePaths backupPathForMd5:meta.md5];
}

+ (NSString * _Nullable)oldFilePathForAccessKey:(NSString *)accessKey
                                        channel:(NSString *)channel
{
    IESGurdActivePackageMeta *meta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
    if (!meta.md5) {
        return nil;
    }
    if (meta.packageType == 0) {
        return [IESGurdFilePaths backupPathForMd5:meta.md5];
    } else {
        return [IESGurdFilePaths backupSingleFilePathForMd5:meta.md5];
    }
}

#pragma mark - Business

+ (void)asyncExecuteBlock:(dispatch_block_t)block
                accessKey:(NSString *)accessKey
                  channel:(NSString *)channel
{
    if (!block) {
        return;
    }
    dispatch_queue_async_safe(IESGurdBusinessFileQueue(accessKey, channel), ^{
        block();
    });
}

+ (void)syncExecuteBlock:(dispatch_block_t)block
               accessKey:(NSString *)accessKey
                 channel:(NSString *)channel
{
    if (!block) {
        return;
    }
    dispatch_queue_sync_safe(IESGurdBusinessFileQueue(accessKey, channel), ^{
        block();
    });
}

#pragma mark - Clean

+ (void)addCacheWhitelistWithAccessKey:(NSString *)accessKey
                              channels:(NSArray<NSString *> *)channels
{
    if (accessKey.length == 0 || channels.count == 0) {
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kIESGurdCacheWhitelist = [NSMutableDictionary dictionary];
    });
    @synchronized (kIESGurdCacheWhitelist) {
        NSMutableSet<NSString *> *whitelistChannels = kIESGurdCacheWhitelist[accessKey];
        if (!whitelistChannels) {
            whitelistChannels = [NSMutableSet set];
            kIESGurdCacheWhitelist[accessKey] = whitelistChannels;
        }
        [whitelistChannels addObjectsFromArray:channels];
    }
}

+ (void)clearCache
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self _cleanCache:NO];
    });
}

+ (void)clearCacheExceptWhitelist
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self _cleanCache:YES];
    });
}

+ (void)cleanCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
                    completion:(IESGurdFileOperationCompletion)completion
{
    [self cleanCacheForAccessKey:accessKey channel:channel isSync:NO completion:completion];
}

+ (void)cleanCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
                        isSync:(BOOL)isSync
                    completion:(IESGurdFileOperationCompletion)completion
{
    GurdLog(@"Clean cache : %@ %@", accessKey, channel);
    if (IES_isEmptyString(accessKey) || IES_isEmptyString(channel)) {
        return;
    }
    
    void (^cleaner)(void) = ^{
        GURD_TIK;
        
        NSString *cleanActiveErrorMessage = nil;
        [self _cleanActiveCacheForAccessKey:accessKey channel:channel errorMessage:&cleanActiveErrorMessage];
        NSString *cleanInactiveErrorMessage = nil;
        [self _cleanInactiveCacheForAccessKey:accessKey channel:channel errorMessage:&cleanInactiveErrorMessage];
        
        if (completion) {
            NSString *errorMessage = cleanActiveErrorMessage;
            if (cleanInactiveErrorMessage) {
                errorMessage = errorMessage ? [errorMessage stringByAppendingFormat:@"、%@", cleanInactiveErrorMessage] : cleanInactiveErrorMessage;
            }
            
            BOOL succeed = errorMessage ? NO : YES;
            
            NSInteger duration = GURD_TOK;
            NSDictionary *info = @{ @"clean_duration" : @(duration) };
            
            NSError *error = [NSError ies_errorWithCode:succeed ? IESGurdSyncStatusCleanCacheSuccess : IESGurdSyncStatusCleanCacheFailed
                                            description:errorMessage];
            completion(succeed, info, error);
        }
    };
    
    if (isSync) {
        dispatch_queue_sync_safe(IESGurdBusinessFileQueue(accessKey, channel), cleaner);
    } else {
        dispatch_queue_async_safe(IESGurdBusinessFileQueue(accessKey, channel), cleaner);
    }
}

+ (void)cleanInactiveCacheForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    if (IES_isEmptyString(accessKey) || IES_isEmptyString(channel)) {
        return;
    }
    dispatch_queue_async_safe(IESGurdBusinessFileQueue(accessKey, channel), (^{
        NSString *inactiveCacheDirectory = [IESGurdFilePaths inactivePathForAccessKey:accessKey channel:channel];
        [FILE_MANAGER removeItemAtPath:inactiveCacheDirectory error:NULL];
    }));
}

#pragma mark - Private

+ (BOOL)_createDirectoryIfNeeded:(NSString *)directoryPath
{
    return [FILE_MANAGER createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:NULL];
}

+ (BOOL)_createDirectoryIfNeeded:(NSString *)directoryPath error:(NSError **)error;
{
    NSError *createError = nil;
    if ([FILE_MANAGER createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&createError]) {
        return YES;
    }
    *error = createError;
    return NO;
}

+ (void)_cleanCache:(BOOL)exceptWhitelist
{
    NSDictionary<NSString *, NSSet<NSString *> *> *whitelistChannelsDictionary = nil;
    if (exceptWhitelist) {
        @synchronized (kIESGurdCacheWhitelist) {
            whitelistChannelsDictionary = [[NSDictionary alloc] initWithDictionary:kIESGurdCacheWhitelist copyItems:YES];
        }
    }
    
    [[IESGurdResourceMetadataStorage copyActiveMetadataDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary<NSString *,IESGurdActivePackageMeta *> *obj, BOOL *stop) {
        NSSet<NSString *> *whitelistChannels = whitelistChannelsDictionary[accessKey];
        [obj enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdActivePackageMeta *meta, BOOL *stop) {
            if ([whitelistChannels containsObject:channel]) {
                return;
            }
            dispatch_queue_sync_safe(IESGurdBusinessFileQueue(accessKey, channel), (^{
                [self _cleanActiveCacheForAccessKey:accessKey channel:channel errorMessage:nil];
            }));
        }];
    }];
    
    [[IESGurdResourceMetadataStorage copyInactiveMetadataDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary<NSString *,IESGurdInactiveCacheMeta *> *obj, BOOL *stop) {
        NSSet<NSString *> *whitelistChannels = whitelistChannelsDictionary[accessKey];
        [obj enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdInactiveCacheMeta *meta, BOOL *stop) {
            if ([whitelistChannels containsObject:channel]) {
                return;
            }
            dispatch_queue_sync_safe(IESGurdBusinessFileQueue(accessKey, channel), (^{
                [self _cleanInactiveCacheForAccessKey:accessKey channel:channel errorMessage:nil];
            }));
        }];
    }];
}

+ (void)_cleanActiveCacheForAccessKey:(NSString *)accessKey
                              channel:(NSString *)channel
                         errorMessage:(NSString **)errorMessage
{
    // 这里顺序不能动，backupPath 依赖 meta 信息，后续待优化
    NSString *backupPath = [IESGurdFileBusinessManager oldFilePathForAccessKey:accessKey channel:channel];
    [IESGurdResourceMetadataStorage deleteActiveMetaForAccessKey:accessKey channel:channel];
    
    NSError *removeError = nil;
    NSString *removeErrorMessage = nil;
    
    NSString *cacheDirectory = [IESGurdFilePaths directoryPathForAccessKey:accessKey channel:channel];
    [FILE_MANAGER removeItemAtPath:cacheDirectory error:&removeError];
    if (removeError) {
        removeErrorMessage = [self removeErrorMessageWithPath:cacheDirectory error:removeError];
        removeError = nil;
    }
    
    [FILE_MANAGER removeItemAtPath:backupPath error:&removeError];
    if (removeError) {
        NSString *message = [self removeErrorMessageWithPath:backupPath error:removeError];
        removeErrorMessage = removeErrorMessage ? [removeErrorMessage stringByAppendingFormat:@"、%@", message] : message;
        removeError = nil;
    }
    
    if (errorMessage) {
        *errorMessage = removeErrorMessage;
    }
    
    [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidCleanCachePackageForAccessKey:accessKey channel:channel];
}

+ (void)_cleanInactiveCacheForAccessKey:(NSString *)accessKey
                                channel:(NSString *)channel
                           errorMessage:(NSString **)errorMessage
{
    [IESGurdResourceMetadataStorage deleteInactiveMetaForAccessKey:accessKey channel:channel];
    
    NSError *removeError = nil;
    NSString *inactiveCacheDirectory = [IESGurdFilePaths inactivePathForAccessKey:accessKey channel:channel];
    [FILE_MANAGER removeItemAtPath:inactiveCacheDirectory error:&removeError];
    if (removeError && errorMessage) {
        *errorMessage = [self removeErrorMessageWithPath:inactiveCacheDirectory error:removeError];
    }
}

+ (NSData *)_dataWithCachePath:(NSString *)cachePath options:(NSDataReadingOptions)options
{
    BOOL isDirectory = NO;
    BOOL fileExist = [FILE_MANAGER fileExistsAtPath:cachePath isDirectory:&isDirectory];
    if (fileExist && !isDirectory) {
        return [NSData dataWithContentsOfFile:cachePath options:options error:NULL];
    }
    return nil;
}

+ (NSString * _Nullable)removeErrorMessageWithPath:(NSString *)path error:(NSError *)error
{
    if (error.code == NSFileNoSuchFileError) {
        return nil;
    }
    return [NSString stringWithFormat:@"Delete file failed (Path : %@, Code : %zd; Msg : %@)",
            [IESGurdFilePaths briefFilePathWithFullPath:path],
            error.code,
            error.localizedDescription];
}

+ (NSString *)_cachePathForAccessKey:(NSString *)accessKey channel:(NSString *)channel path:(NSString *)path
{
    return [IESGurdFilePaths directoryPathForAccessKey:accessKey channel:channel path:path];
}

+ (NSString *)_internalPackageCachePathForAccessKey:(NSString *)accessKey channel:(NSString *)channel path:(NSString *)path
{
    return [[IESGurdKit internalRootDirectoryForAccessKey:accessKey channel:channel] stringByAppendingPathComponent:path];
}

+ (NSData * _Nullable)_internalPackageDataForAccessKey:(NSString *)accessKey
                                               channel:(NSString *)channel
                                                  path:(NSString *)path
                                               options:(NSDataReadingOptions)options
                                      dataAccessPolicy:(IESGurdDataAccessPolicy)dataAccessPolicy
{
    NSString *cachePath = [self _internalPackageCachePathForAccessKey:accessKey channel:channel path:path];
    NSData *data = [self _dataWithCachePath:cachePath options:options];
    if (data.length > 0) {
        [IESGurdInternalPackagesManager didAccessInternalPackageWithAccessKey:accessKey
                                                                      channel:channel
                                                                         path:path
                                                             dataAccessPolicy:dataAccessPolicy];
    }
    return data;
}

static BOOL kIsGurdClearingTempFiles = NO;
+ (void)_clearTempFilesIfNeeded
{
    if (kIsGurdClearingTempFiles) {
        return;
    }
    kIsGurdClearingTempFiles = YES;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *uniqueString = [self tempFilePathUniqueString];
        NSString *applyPrefix = [NSString stringWithFormat:@"%@-%@", kIESGurdApplyTempFilePrefix, uniqueString];
        NSString *downloadPrefix = [NSString stringWithFormat:@"%@-%@", kIESGurdDownloadTempFilePrefix, uniqueString];
        
        NSString *temporaryDirectory = NSTemporaryDirectory();
        [[FILE_MANAGER contentsOfDirectoryAtPath:temporaryDirectory error:NULL] enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
            if (![fileName hasPrefix:kIESGurdApplyTempFilePrefix] &&
                ![fileName hasPrefix:kIESGurdDownloadTempFilePrefix]) {
                // 非 gecko 文件
                return;
            }
            if ([fileName hasPrefix:applyPrefix] || [fileName hasPrefix:downloadPrefix]) {
                // 当前生命周期内文件，由激活/下载流程负责清理
                return;
            }
            // 清理非正常关闭应用遗留的资源
            NSString *filePath = [temporaryDirectory stringByAppendingPathComponent:fileName];
            [FILE_MANAGER removeItemAtPath:filePath error:NULL];
        }];
        
        kIsGurdClearingTempFiles = NO;
    });
}

+ (NSString *)tempFilePathUniqueString
{
    static NSString *prefix = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        prefix = [[NSUUID UUID] UUIDString];
    });
    return prefix;
}

@end

dispatch_queue_t IESGurdBusinessFileQueue (NSString *accessKey, NSString *channel)
{
    NSCParameterAssert(accessKey.length > 0 && channel.length > 0);
    
    static NSMutableDictionary<NSString *, dispatch_queue_t> *queueDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queueDictionary = [NSMutableDictionary dictionary];
    });
    __block dispatch_queue_t queue = nil;
    @synchronized (queueDictionary) {
        NSString *identifier = [NSString stringWithFormat:@"%@-%@", accessKey, channel];
        queue = queueDictionary[identifier];
        if (!queue) {
            NSString *label = [NSString stringWithFormat:@"com.IESGurdKit.BusinessFileQueue-%@", identifier];
            queue = IESGurdKitCreateSerialQueue([label UTF8String]);
            queueDictionary[identifier] = queue;
        }
    }
    return queue;
}

#undef FILE_MANAGER
