//
//  IESGurdDownloadPackageManager.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import "IESGurdDownloadPackageManager.h"

#import "IESGurdFileBusinessManager.h"
#import "IESGurdDownloadOperationsQueue.h"
#import "IESGurdKitUtil.h"
#import "IESGurdLogProxy.h"
#import "IESGeckoKit.h"
#import "IESGurdKit+BackgroundDownload.h"
//operation
#import "IESGurdDownloadPatchPackageOperation.h"
#import "IESGurdDownloadFullPackageOperation.h"
#import "IESGurdKit+Experiment.h"
#import "IESGurdAppLogger.h"
#import "IESGurdEventTraceManager+Message.h"
#import "IESGurdExpiredCacheManager.h"

@interface IESGurdResourceModel (Download)
- (BOOL)canDownloadPatchPackage;
@end

@interface IESGurdDownloadPackageManager ()

@property (nonatomic, strong) dispatch_queue_t downloadSerialQueue;

@property (nonatomic, strong) IESGurdDownloadOperationsQueue *downloadOperationsQueue;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<IESGurdDownloadPackageResultBlock> *> *downloadResultsDictionary;

@property (nonatomic, strong) IESGurdBaseDownloadOperation *downloadingOperation;

@property (atomic, assign) UIBackgroundTaskIdentifier backgroundTempTask;

@property (nonatomic, assign) BOOL downloadedInBackground;

@end

@implementation IESGurdDownloadPackageManager

+ (instancetype)sharedManager
{
    static IESGurdDownloadPackageManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        
        manager.downloadSerialQueue = IESGurdKitCreateSerialQueue("com.IESGurdKit.DownloadPackages");
        manager.downloadOperationsQueue = [IESGurdDownloadOperationsQueue operationsQueue];
        IESGurdDownloadPolicy policy = IESGurdKit.downloadPolicy;
        if (policy == IESGurdDownloadPolicyDefault) {
            manager.downloadOperationsQueue.enableDownload = YES;
        } else {
            manager.downloadOperationsQueue.enableDownload = NO;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(didEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(willEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    });
    return manager;
}

#pragma mark - Public

- (void)downloadPackageWithConfig:(IESGurdResourceModel *)config
                          logInfo:(NSDictionary *)logInfo
                      resultBlock:(IESGurdDownloadPackageResultBlock)resultBlock
{
    __block BOOL shouldDownload = NO;
    NSString *accessKey = config.accessKey;
    NSString *channel = config.channel;
    NSString *key = [NSString stringWithFormat:@"%@-%@", accessKey ? : @"", channel ? : @""];
    @synchronized (self) {
        NSMutableArray *resultsArray = self.downloadResultsDictionary[key];
        if (!resultsArray) {
            resultsArray = [NSMutableArray array];
            self.downloadResultsDictionary[key] = resultsArray;
            
            shouldDownload = YES;
        }
        if (resultBlock) {
            [resultsArray addObject:resultBlock];
        }
    }
    if (!shouldDownload) {
        // 已经在下载队列里
        dispatch_queue_async_safe(self.downloadSerialQueue, ^{
            IESGurdBaseDownloadOperation *currentDownloadOperation = [self.downloadOperationsQueue operationForAccessKey:accessKey
                                                                                                                 channel:channel];
            if (currentDownloadOperation.downloadPriority < config.downloadPriority) {
                // 优先级提高
                [self.downloadOperationsQueue updateDownloadPriority:config.downloadPriority
                                                           operation:currentDownloadOperation];
            }
            if (!currentDownloadOperation.config.forceDownload && config.forceDownload) {
                // 强制下载
                currentDownloadOperation.config.forceDownload = YES;
                [self downloadIfNeeded];
            }
        });
        return;
    }
    
    dispatch_async(self.downloadSerialQueue, ^{
        IESGurdDownloadOperationCompletion downloadCompletion = ^(IESGurdBaseDownloadOperation *operation, BOOL isSuccessful, NSError *error) {
            BOOL isPatch = [operation isPatch];
            @synchronized (self) {
                NSMutableArray *resultsArray = self.downloadResultsDictionary[key];
                [self.downloadResultsDictionary removeObjectForKey:key];
                
                [[resultsArray copy] enumerateObjectsUsingBlock:^(IESGurdDownloadPackageResultBlock block, NSUInteger idx, BOOL *stop) {
                    block(isSuccessful, isPatch, error);
                }];
            }
            
            dispatch_queue_async_safe(self.downloadSerialQueue, ^{
                if (self.downloadingOperation == operation) {
                    self.downloadingOperation = nil;
                    [self.downloadOperationsQueue removeOperationWithAccessKey:accessKey channel:channel];
                    [self downloadIfNeeded];
                }
            });
        };
        
        if ([config canDownloadPatchPackage]) {
            [self enqueueDownloadPatchPackageOperationWithConfig:config
                                                         logInfo:logInfo
                                                      completion:downloadCompletion];
        } else {
            [self enqueueDownloadFullPackageOperationWithConfig:config
                                                        logInfo:logInfo
                                                     completion:downloadCompletion];
        }
        
        [self downloadIfNeeded];
    });
}

- (void)cancelDownloadWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    dispatch_queue_async_safe(self.downloadSerialQueue, ^{
        IESGurdResourceModel *downloadingConfig = self.downloadingOperation.config;
        if ([downloadingConfig.accessKey isEqualToString:accessKey] &&
            [downloadingConfig.channel isEqualToString:channel]) {
            [self.downloadingOperation cancel];
            return;
        }
        [self.downloadOperationsQueue cancelDownloadWithAccessKey:accessKey channel:channel];
    });
}

#pragma mark - Private

- (void)didEnterBackground
{
    IESGurdKit.background = YES;
    if (IESGurdKit.downloadPolicy == IESGurdDownloadPolicyDefault) {
        return;
    }
    IESGurdLogInfo(@"Enter background and start download");
    self.downloadOperationsQueue.enableDownload = YES;
    self.backgroundTempTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        IESGurdLogInfo(@"Background task expired");
        [self endBackgroundUpdateTask];
    }];
    [self downloadIfNeeded];
    self.downloadedInBackground = YES;
}

- (void)willEnterForeground
{
    IESGurdKit.background = NO;
    if (IESGurdKit.downloadPolicy == IESGurdDownloadPolicyDefault) {
        return;
    }
    [self endBackgroundUpdateTask];
    if (![self shouldDownloadInActive]) {
        self.downloadOperationsQueue.enableDownload = NO;
        return;
    }
    IESGurdLogInfo(@"Become active and start download");
    self.downloadOperationsQueue.enableDownload = YES;
    [self downloadIfNeeded];
}

- (BOOL)shouldDownloadInActive
{
    if (![IESGurdKit didSetup]) {
        return NO;
    }
    IESGurdDownloadPolicy downloadPolicy = IESGurdKit.downloadPolicy;
    if (downloadPolicy == IESGurdDownloadPolicyBackgroundOnly) {
        return NO;
    }
    if (downloadPolicy == IESGurdDownloadPolicyImmediatelyInActive && self.downloadedInBackground) {
        return YES;
    }
    return NO;
}

- (void)endBackgroundUpdateTask
{
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTempTask];
    self.backgroundTempTask = UIBackgroundTaskInvalid;
}

- (void)enqueueDownloadPatchPackageOperationWithConfig:(IESGurdResourceModel *)config
                                               logInfo:(NSDictionary *)logInfo
                                            completion:(IESGurdDownloadOperationCompletion)completion
{
    __weak IESGurdDownloadPackageManager *weakSelf = self;
    IESGurdDownloadOperationCompletion patchCompletion = ^(IESGurdBaseDownloadOperation *operation, BOOL isSuccessful, NSError *error) {
        if (isSuccessful || !operation.retryDownload) {
            !completion ? : completion(operation, isSuccessful, error);
            return;
        }
        dispatch_queue_async_safe(self.downloadSerialQueue, ^{
            weakSelf.downloadingOperation = [weakSelf downloadFullPackageOperationWithConfig:config
                                                                                     logInfo:logInfo
                                                                                  completion:completion];
            [weakSelf.downloadingOperation start];
        });
    };
    IESGurdDownloadPatchPackageOperation *operation = [IESGurdDownloadPatchPackageOperation operationWithConfig:config
                                                                                                        logInfo:logInfo
                                                                                             downloadCompletion:patchCompletion];
    [self.downloadOperationsQueue addOperation:operation];
}

- (void)enqueueDownloadFullPackageOperationWithConfig:(IESGurdResourceModel *)config
                                              logInfo:(NSDictionary *)logInfo
                                           completion:(IESGurdDownloadOperationCompletion)completion
{
    IESGurdBaseDownloadOperation *operation = [self downloadFullPackageOperationWithConfig:config
                                                                                   logInfo:logInfo
                                                                                completion:completion];
    [self.downloadOperationsQueue addOperation:operation];
}

- (IESGurdBaseDownloadOperation *)downloadFullPackageOperationWithConfig:(IESGurdResourceModel *)config
                                                                 logInfo:(NSDictionary *)logInfo
                                                              completion:(IESGurdDownloadOperationCompletion)completion
{
    __weak IESGurdDownloadPackageManager *weakSelf = self;
    IESGurdDownloadOperationCompletion fallbackCompletion = ^(IESGurdBaseDownloadOperation *operation, BOOL isSuccessful, NSError * _Nullable error) {
        BOOL cancelDownload = (error.code == IESGurdSyncStatusDownloadVersionIsActive ||
                               error.code == IESGurdSyncStatusDownloadVersionIsInactive);
        !completion ? : completion(operation, isSuccessful, error);
    };
    IESGurdDownloadFullPackageOperation *operation =
    [IESGurdDownloadFullPackageOperation operationWithConfig:config
                                                     logInfo:logInfo
                                          downloadCompletion:fallbackCompletion];
    return operation;
}

- (void)downloadIfNeeded
{
    if (self.downloadingOperation) {
        return;
    }
    
    IESGurdBaseDownloadOperation *operation = [self.downloadOperationsQueue popNextOperation];
    if (!operation) {
        return;
    }
    
    self.downloadingOperation = operation;
    [operation start];
}

#pragma mark - Getter

- (NSMutableDictionary<NSString *, NSMutableArray<IESGurdDownloadPackageResultBlock> *> *)downloadResultsDictionary
{
    if (!_downloadResultsDictionary) {
        _downloadResultsDictionary = [NSMutableDictionary dictionary];
    }
    return _downloadResultsDictionary;
}

@end

@implementation IESGurdResourceModel (Download)

- (BOOL)canDownloadPatchPackage
{
    if (!self.patch || !self.patch.urlList) {
        return NO;
    }
    if (self.isZstd) {
        return YES;
    }
    
    NSString *backupZipPath = [IESGurdFileBusinessManager oldFilePathForAccessKey:self.accessKey
                                                                          channel:self.channel];
    return [IESGurdFilePaths fileSizeAtPath:backupZipPath] > 0;
}

@end
