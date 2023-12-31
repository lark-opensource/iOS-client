//
//  IESGurdInternalPackagesManager.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/9/16.
//

#import "IESGurdInternalPackagesManager.h"

#import "IESGeckoDefines+Private.h"
#import "IESGurdKitUtil.h"
#import "IESGurdFilePaths+InternalPackage.h"
#import "IESGurdInternalPackageMetaInfo+Private.h"
#import "NSDictionary+IESGurdInternalPackage.h"
#import "IESGurdEventTraceManager+Message.h"
#import "IESGurdEventTraceManager+Business.h"
#import "IESGurdDelegateDispatcherManager.h"
#import "IESGurdProtocolDefines.h"

#import <pthread/pthread.h>

static pthread_mutex_t kMetaInfoLock = PTHREAD_MUTEX_INITIALIZER;

typedef NSDictionary<NSString *, NSDictionary<NSString *, IESGurdInternalPackageMetaInfo *> *> IESGurdInternalPackageMetaInfoDictionaryI;

typedef NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, IESGurdInternalPackageMetaInfo *> *> IESGurdInternalPackageMetaInfoDictionaryM;

@interface IESGurdInternalPackagesManager ()

@property (class, nonatomic, strong) IESGurdInternalPackageMetaInfoDictionaryM *metaInfosDictionary;

@end

@implementation IESGurdInternalPackagesManager

+ (void)load
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        IESGurdInternalPackageAsyncExecuteBlock(^{
            [self clearInternalPackagesIfNeeded];
        });
    });
}

#pragma mark - Public

+ (uint64_t)internalPackageIdForAccessKey:(NSString *)accessKey
                                   channel:(NSString *)channel
{
    [self loadLocalMetaInfosIfNeeded];
    
    GURD_MUTEX_LOCK(kMetaInfoLock);
    IESGurdInternalPackageMetaInfo *metaInfo = self.metaInfosDictionary[accessKey][channel];
    return metaInfo.packageId;
}

+ (IESGurdDataAccessPolicy)dataAccessPolicyForAccessKey:(NSString *)accessKey
                                                channel:(NSString *)channel
{
    GURD_MUTEX_LOCK(kMetaInfoLock);
    IESGurdInternalPackageMetaInfo *metaInfo = self.metaInfosDictionary[accessKey][channel];
    return metaInfo.dataAccessPolicy;
}

+ (void)updateDataAccessPolicy:(IESGurdDataAccessPolicy)policy
                     accessKey:(NSString *)accessKey
                       channel:(NSString *)channel
{
    GURD_MUTEX_LOCK(kMetaInfoLock);
    IESGurdInternalPackageMetaInfo *metaInfo = self.metaInfosDictionary[accessKey][channel];
    metaInfo.dataAccessPolicy = policy;
}

+ (void)saveInternalPackageMetaInfo:(IESGurdInternalPackageMetaInfo *)metaInfo
{
    NSString *accessKey = metaInfo.accessKey;
    NSString *channel = metaInfo.channel;
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    
    [self loadLocalMetaInfosIfNeeded];
    
    pthread_mutex_lock(&kMetaInfoLock);
    
    IESGurdInternalPackageMetaInfoDictionaryM *metaInfosDictionary = self.metaInfosDictionary;
    if (!metaInfosDictionary) {
        metaInfosDictionary = [NSMutableDictionary dictionary];
        self.metaInfosDictionary = metaInfosDictionary;
    }
    
    NSMutableDictionary *subDictionary = metaInfosDictionary[accessKey];
    if (!subDictionary) {
        subDictionary = [NSMutableDictionary dictionary];
        metaInfosDictionary[accessKey] = subDictionary;
    }
    
    subDictionary[channel] = metaInfo;
    
    pthread_mutex_unlock(&kMetaInfoLock);
    
    [self saveInternalPackageMetaInfosToLocal];
}

+ (void)clearInternalPackageForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    
    [self loadLocalMetaInfosIfNeeded];
    
    pthread_mutex_lock(&kMetaInfoLock);
    self.metaInfosDictionary[accessKey][channel] = nil;
    pthread_mutex_unlock(&kMetaInfoLock);
    
    [self saveInternalPackageMetaInfosToLocal];
    
    [self clearInternalCacheForAccessKey:accessKey channel:channel];
}

+ (void)didAccessInternalPackageWithAccessKey:(NSString *)accessKey
                                      channel:(NSString *)channel
                                         path:(NSString *)path
                             dataAccessPolicy:(IESGurdDataAccessPolicy)dataAccessPolicy
{
    NSString *message = nil;
    if (dataAccessPolicy == IESGurdDataAccessPolicyInternalPackageFirst) {
        message = [NSString stringWithFormat:@"Access internal package first, path : %@", path];
    } else if (dataAccessPolicy == IESGurdDataAccessPolicyInternalPackageBackup) {
        message = [NSString stringWithFormat:@"Access internal package backup, path : %@", path];
    }
    if (message) {
        IESGurdInternalPackageBusinessLog(accessKey, channel, message, NO, YES);
    }
    
    [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidAccessInternalPackageWithAccessKey:accessKey
                                                                                 channel:channel
                                                                                    path:path
                                                                        dataAccessPolicy:dataAccessPolicy];
}

#pragma mark - Private

+ (void)loadLocalMetaInfosIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self loadLocalMetaInfos];
    });
}

+ (void)loadLocalMetaInfos
{
    GurdLog(@"Load local meta infos");
    
    NSString *path = [IESGurdFilePaths internalPackageMetaInfosPath];
    NSArray *classes = @[ [NSDictionary class], [IESGurdInternalPackageMetaInfo class] ];
    NSDictionary *localDictionary = IESGurdKitKeyedUnarchiveObject(path, classes);
    
    if (!localDictionary) {
        return;
    }
    
    IESGurdInternalPackageMetaInfoDictionaryM *metaInfosDictionary = [NSMutableDictionary dictionary];
    if ([localDictionary isKindOfClass:[NSDictionary class]]) {
        [localDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary *dictionary, BOOL *stop) {
            if (![dictionary isKindOfClass:[NSDictionary class]]) {
                return;
            }
            metaInfosDictionary[accessKey] = [dictionary mutableCopy];
        }];
    }
    
    GURD_MUTEX_LOCK(kMetaInfoLock);
    self.metaInfosDictionary = metaInfosDictionary;
    
    NSString *message = [NSString stringWithFormat:@"Local internal package meta infos : %@",
                         [localDictionary description]];
    IESGurdInternalPackageMessageLog(message, NO, NO);
}

+ (void)saveInternalPackageMetaInfosToLocal
{
    NSDictionary *dictionary = [self allInternalPackageMetaInfos];
    NSString *path = [IESGurdFilePaths internalPackageMetaInfosPath];
    
    IESGurdKitKeyedArchive(dictionary, path);
    
    NSString *message = [NSString stringWithFormat:@"Save meta infos : %@", [dictionary description]];
    IESGurdInternalPackageMessageLog(message, NO, NO);
}

+ (void)clearInternalPackagesIfNeeded
{
    [self loadLocalMetaInfosIfNeeded];
    
    IESGurdInternalPackageMetaInfoDictionaryI *allInternalPackageMetaInfos = [self allInternalPackageMetaInfos];
    
    __block BOOL didClear = NO;
    [allInternalPackageMetaInfos enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary<NSString *,IESGurdInternalPackageMetaInfo *> *metaInfos, BOOL *stop) {
        [metaInfos enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdInternalPackageMetaInfo *metaInfo, BOOL *stop) {
            if ([self shouldClearInternalPackageWithMetaInfo:metaInfo]) {
                didClear = YES;
                
                pthread_mutex_lock(&kMetaInfoLock);
                self.metaInfosDictionary[accessKey][channel] = nil;
                pthread_mutex_unlock(&kMetaInfoLock);
                
                [self clearInternalCacheForAccessKey:accessKey channel:channel];
            }
        }];
    }];
    
    if (didClear) {
        [self saveInternalPackageMetaInfosToLocal];
    }
}

+ (BOOL)shouldClearInternalPackageWithMetaInfo:(IESGurdInternalPackageMetaInfo *)metaInfo
{
    NSString *bundleName = metaInfo.bundleName;
    NSDictionary *configDictionary = [NSDictionary gurd_configDictionaryWithBundleName:bundleName];
    if (configDictionary.count == 0) {
        return YES;
    }
    __block BOOL shouldClear = YES;
    [configDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *packageName, NSDictionary *info, BOOL *stop) {
        if (![info isKindOfClass:[NSDictionary class]]) {
            return;
        }
        NSString *accessKey = info[kIESGurdInternalPackageConfigKeyAccessKey];
        NSString *channel = info[kIESGurdInternalPackageConfigKeyChannel];
        if (![accessKey isEqualToString:metaInfo.accessKey] ||
            ![channel isEqualToString:metaInfo.channel]) {
            return;
        }
        NSString *packagePath = [[IESGurdFilePaths bundlePathWithName:bundleName] stringByAppendingPathComponent:packageName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:packagePath]) {
            shouldClear = NO;
            *stop = YES;
        }
    }];
    return shouldClear;
}

+ (void)clearInternalCacheForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    IESGurdInternalPackageAsyncExecuteBlock(^{
        IESGurdInternalPackageBusinessLog(accessKey, channel, @"Clear internal package", NO, YES);
        
        NSString *channelDirectory = [IESGurdFilePaths internalRootDirectoryForAccessKey:accessKey channel:channel];
        [[NSFileManager defaultManager] removeItemAtPath:channelDirectory error:NULL];
    });
}

+ (IESGurdInternalPackageMetaInfoDictionaryI *)allInternalPackageMetaInfos
{
    GURD_MUTEX_LOCK(kMetaInfoLock);
    
    NSMutableDictionary *copiedDictionary = [NSMutableDictionary dictionary];
    [self.metaInfosDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableDictionary *obj, BOOL *stop) {
        copiedDictionary[key] = [obj copy];
    }];
    return [copiedDictionary copy];
}

#pragma mark - Accessor

static IESGurdInternalPackageMetaInfoDictionaryM *kMetaInfosDictionary = nil;
+ (IESGurdInternalPackageMetaInfoDictionaryM *)metaInfosDictionary
{
    return kMetaInfosDictionary;
}

+ (void)setMetaInfosDictionary:(IESGurdInternalPackageMetaInfoDictionaryM *)metaInfosDictionary
{
    kMetaInfosDictionary = metaInfosDictionary;
}

@end

void IESGurdInternalPackageBusinessLog (NSString *accessKey,
                                        NSString *channel,
                                        NSString *message,
                                        BOOL hasError,
                                        BOOL shouldLog)
{
    IESGurdTraceMessageInfo *messageInfo = [IESGurdTraceMessageInfo messageInfoWithAccessKey:accessKey
                                                                                     channel:channel
                                                                                     message:message
                                                                                    hasError:hasError];
    messageInfo.shouldLog = shouldLog;
    [IESGurdEventTraceManager traceEventWithMessageInfo:messageInfo];
    
    message = [NSString stringWithFormat:@" [ %@ : %@ ] %@", accessKey, channel, message];
    IESGurdInternalPackageMessageLog(message, hasError, shouldLog);
}

void IESGurdInternalPackageMessageLog (NSString *message, BOOL hasError, BOOL shouldLog)
{
    message = [NSString stringWithFormat:@"【InternalPackage】%@", message];
    [IESGurdEventTraceManager traceEventWithMessage:message hasError:hasError shouldLog:shouldLog];
}

void IESGurdInternalPackageAsyncExecuteBlock (dispatch_block_t block)
{
    if (!block) {
        return;
    }
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = IESGurdKitCreateSerialQueue("com.IESGurdKit.InternalPackagesQueue");
    });
    dispatch_queue_async_safe(queue, block);
}
