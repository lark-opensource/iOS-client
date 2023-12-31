//
//  IESGurdBaseDownloadOperation.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import "IESGurdBaseDownloadOperation.h"

#import "IESGurdProtocolDefines.h"
#import "IESGeckoDefines+Private.h"
//meta
#import "IESGurdResourceMetadataStorage+Private.h"
//manager
#import "IESGurdApplyPackageManager.h"
#import "IESGurdDelegateDispatcherManager.h"
#import "IESGurdEventTraceManager+Business.h"
//util
#import "IESGurdDownloader.h"
#import "IESGurdAppLogger.h"
#import "IESGeckoFileMD5Hash.h"
#import "IESGurdFilePaths.h"
//model
#import "IESGurdDownloadPackageInfo.h"
//category
#import "NSError+IESGurdKit.h"
#import "IESGurdKit+Experiment.h"
#import "IESGurdExpiredCacheManager.h"

#import "UIApplication+IESGurdKit.h"

@interface IESGurdBaseDownloadOperation ()

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, strong) IESGurdResourceModel *config;

@property (nonatomic, copy) NSDictionary *logInfo;

@property (nonatomic, copy) IESGurdDownloadOperationCompletion downloadCompletion;

@property (atomic, assign) IESGurdDownloadPriority downloadPriority;

@property (nonatomic, assign) BOOL shouldRetry;

@property (nonatomic, strong) IESGurdDownloadPackageInfo *downloadPackageInfo;

@property (assign, nonatomic, getter = isExecuting) BOOL executing;

@property (assign, nonatomic, getter = isFinished) BOOL finished;

@property (nonatomic, strong) IESGurdDownloadInfoModel *downloadInfoModel;

@property (nonatomic, assign) BOOL skipAppLog;

- (BOOL)checkLowStorage;

@end

@implementation IESGurdBaseDownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

+ (instancetype)operationWithConfig:(IESGurdResourceModel *)config
                            logInfo:(NSDictionary *)logInfo
                 downloadCompletion:(IESGurdDownloadOperationCompletion)downloadCompletion
{
    IESGurdBaseDownloadOperation *operation = [[self alloc] init];
    operation.accessKey = config.accessKey;
    operation.config = config;
    operation.logInfo = logInfo;
    operation.downloadPriority = config.downloadPriority;
    operation.downloadCompletion = [downloadCompletion copy];
    operation.retryDownload = config.retryDownload;
    
    IESGurdDownloadInfoModel *downloadInfoModel = [[IESGurdDownloadInfoModel alloc] init];
    downloadInfoModel.identity = [NSString stringWithFormat:@"%@_%@_%llu_%@",
                                  config.accessKey, config.channel, config.version, [operation isPatch] ? @"patch" : @"full"];
    downloadInfoModel.packageSize = [operation isPatch] ? config.patch.packageSize : config.package.packageSize;
    operation.downloadInfoModel = downloadInfoModel;

    return operation;
}

- (void)updateDownloadPriority:(IESGurdDownloadPriority)downloadPriority
{
    self.downloadPriority = downloadPriority;
    self.config.downloadPriority = downloadPriority;
    self.downloadPackageInfo.downloadPriority = downloadPriority;
}

#pragma mark - NSOperation Override

- (void)start
{
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            return;
        }
        
        NSString *accessKey = self.accessKey;
        NSString *channel = self.config.channel;
        
        uint64_t targetVersion = self.config.version;
        
        IESGurdActivePackageMeta *activeMeta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
        BOOL isResourceActive = [self isResourceActiveWithMeta:activeMeta];
        
        BOOL isResourceInactive = [self isResourceInactiveWithAccessKey:accessKey channel:channel];
        
        if (isResourceActive || isResourceInactive) {
            IESGurdSyncStatus status = isResourceActive ? IESGurdSyncStatusDownloadVersionIsActive : IESGurdSyncStatusDownloadVersionIsInactive;
            NSString *extraInfo = [NSString stringWithFormat:@"status:%zd", status];
            NSString *message = [NSString stringWithFormat:@"Version exists，no need to download %@（%@）",
                                 [self isPatch] ? @"P-package" : @"F-package", extraInfo];
            [self traceEventWithMessage:message hasError:NO shouldLog:YES];
            
            // 埋点上报
            [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeDownload
                                          subtype:IESGurdAppLogEventSubtypeNoNeedToDownload
                                           params:nil
                                        extraInfo:extraInfo
                                     errorMessage:nil];
            
            NSError *error = [NSError ies_errorWithCode:status description:message];
            !self.downloadCompletion ? : self.downloadCompletion(self, NO, error);
            
            self.finished = YES;
            return;
        }
        
        if ([IESGurdKit isChannelLocked:self.config.accessKey channel:self.config.channel]) {
            NSError *error = [NSError ies_errorWithCode:IESGurdSyncStatusLocked description:@"channel is locked"];
            !self.downloadCompletion ? : self.downloadCompletion(self, NO, error);
            return;
        }
        
        self.executing = YES;
        
        if ([self checkLowStorage]) {
            [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdWillDownloadPackageForAccessKey:self.accessKey
                                                                                   channel:self.config.channel
                                                                                   isPatch:[self isPatch]];
            NSString *errMsg = @"cancel download, not available storage";
            NSError *error = [NSError ies_errorWithCode:IESGurdSyncStatusNoAvailableStorage description:errMsg];
            NSDictionary *downloadInfo = @{
                @"download_type": @(IESGurdDownloadTypeOriginal),
                @"err_msg": errMsg
            };
            IESGurdUpdateStageModel *stageModel = [self getUpdateStageMode:YES];
            stageModel.startTime = [NSDate date];
            [self handleDownloadResultWithDownloadInfo:downloadInfo succeed:NO error:error];
//            [[IESGurdExpiredCacheManager sharedManager] clearCacheWhenLowStorage];
        } else {
            [self operationDidStart];
            
            NSString *message = [NSString stringWithFormat:@"Start downloading %@ (local:%llu)（version:%llu）",
                                 [self isPatch] ? @"P-package" : @"F-package", activeMeta.version, targetVersion];
            [self traceEventWithMessage:message hasError:NO shouldLog:YES];
        }
    }
}

- (void)cancel
{
    @synchronized (self) {
        if (self.isFinished) {
            return;
        }
        [super cancel];
        
        self.shouldRetry = NO;
        
        if (self.isExecuting) {
            self.executing = NO;
            
            [IESGurdDownloader cancelDownloadWithIdentity:self.downloadInfoModel.identity];
        }
        self.finished = YES;
    }
    
    [self handleOperationCancel];
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)checkLowStorage
{
    int availableStorage = [self isPatch] ? IESGurdKit.availableStoragePatch : IESGurdKit.availableStorageFull;
    if (availableStorage <= 0 || availableStorage < [UIApplication iesgurdkit_freeDiskSpace].doubleValue / 1024 / 1024) {
        return false;
    }
    if ([IESGurdKit isInLowStorageWhiteList:self.accessKey group:self.config.groupName channel:self.config.channel]) {
        return false;
    }
    return true;
}

#pragma mark - Subclass Call

- (void)handleDownloadResultWithDownloadInfo:(NSDictionary *)downloadInfo
                                     succeed:(BOOL)succeed
                                       error:(NSError * _Nullable)error
{
    self.downloadPackageInfo.downloadDuration = [downloadInfo[IESGurdDownloadInfoDurationKey] integerValue];
    self.downloadPackageInfo.error = error;
    
    IESGurdUpdateStageModel *stageModel = [self getUpdateStageMode:NO];
    stageModel.url = downloadInfo[IESGurdDownloadInfoURLKey];
    stageModel.failedTimes = [downloadInfo[@"download_failed_times"] intValue];
    IESGurdUpdateStatisticModel *model = self.config.updateStatisticModel;
    model.downloadType = [downloadInfo[@"download_type"] intValue];
    
    if (succeed) {
        model.durationDownloadLastTime = [downloadInfo[IESGurdDownloadInfoDurationKey] integerValue];
        model.durationDownload = [downloadInfo[@"total_duration"] integerValue];
        return;
    }
    
    stageModel.result = NO;
    stageModel.errCode = IESGurdSyncStatusDownloadFailed;
    stageModel.downloadErrCode = (int)error.code;
    stageModel.errMsg = downloadInfo[@"err_msg"];
    if (![self isPatch]) {
        [self sendUpdateStats];
    }
    
    [self innerFinishDownload:NO error:error];
}

- (void)handleBusinessSuccessWithPackagePath:(NSString *)packagePath
                                downloadSize:(uint64_t)downloadSize
                                downloadInfo:(NSDictionary *)downloadInfo
{
    self.downloadPackageInfo.successful = YES;
    self.downloadPackageInfo.downloadSize = downloadSize;
    
    NSString *message = [NSString stringWithFormat:@"✅ Download %@ successfully (Version : %llu; PackagePath : %@; PackageSize :%@)",
                         [self isPatch] ? @"P-package" : @"F-package",
                         self.config.version,
                         [IESGurdFilePaths briefFilePathWithFullPath:packagePath],
                         [IESGurdFilePaths fileSizeStringAtPath:packagePath]];
    [self traceEventWithMessage:message hasError:NO shouldLog:NO];
    [self innerFinishDownload:YES error:nil];
}

- (void)handleBusinessFailedWithType:(NSError *)error
{
    self.downloadPackageInfo.error = error;
    
    IESGurdUpdateStageModel *stageModel = [self getUpdateStageMode:NO];
    stageModel.result = NO;
    stageModel.errCode = (int)error.code;
    stageModel.errMsg = error.localizedDescription;
    if (![self isPatch]) {
        [self sendUpdateStats];
    }
    [self innerFinishDownload:NO error:error];
}

- (BOOL)checkFileMd5WithPackagePath:(NSString *)packagePath
                                md5:(NSString *)md5
                  packageTypeString:(NSString *)packageTypeString
                  downloadURLString:(NSString *)downloadURLString
                       errorMessage:(NSString *_Nonnull *_Nonnull)errorMessage
{
    NSError *fileHashError = nil;
    NSString *fileHashString = [IESGurdFileMD5Hash md5HashOfFileAtPath:packagePath error:&fileHashError];
    if ([fileHashString isEqualToString:md5]) {
        NSString *message = [NSString stringWithFormat:@"✅ Check %@ md5 successfully (Version : %llu)", packageTypeString, self.config.version];
        [self traceEventWithMessage:message hasError:NO shouldLog:NO];
        return YES;
    }
    
    NSString *message = [NSString stringWithFormat:@"❌ Check %@ md5 failed (Version : %llu; Reason : %@; Expected : %@; Actual : %@; FileSize : %@; DownloadURL : %@)",
                         packageTypeString,
                         self.config.version,
                         fileHashError.localizedDescription ? : @"unknown",
                         md5 ? : @"",
                         fileHashString ? : @"",
                         [IESGurdFilePaths fileSizeStringAtPath:packagePath],
                         downloadURLString ? : @"unknown"];
    [self traceEventWithMessage:message hasError:YES shouldLog:YES];
    
    [[NSFileManager defaultManager] removeItemAtPath:packagePath error:NULL];
    
    *errorMessage = message;
    return NO;
}

- (void)traceEventWithMessage:(NSString *)message hasError:(BOOL)hasError shouldLog:(BOOL)shouldLog
{
    if (message.length == 0) {
        return;
    }
    message = [NSString stringWithFormat:@"<%@> %@", self.config.logId ? : @"unknown", message];
    
    IESGurdTraceMessageInfo *messageInfo = [IESGurdTraceMessageInfo messageInfoWithAccessKey:self.accessKey
                                                                                     channel:self.config.channel
                                                                                     message:message
                                                                                    hasError:hasError];
    messageInfo.shouldLog = shouldLog;
    [IESGurdEventTraceManager traceEventWithMessageInfo:messageInfo];
}

#pragma mark - Private

- (void)handleOperationCancel
{
    NSString *message = [NSString stringWithFormat:@"❌ Download %@ failed (Version : %llu; ErrorCode : -999; Reason : Download operation is cancelled)",
                         [self isPatch] ? @"P-package" : @"F-package",
                         self.config.version];
    [self traceEventWithMessage:message hasError:YES shouldLog:YES];
    
    NSError *error = [NSError ies_errorWithCode:IESGurdSyncStatusDownloadCancelled
                                    description:message];
    self.downloadPackageInfo.error = error;
    self.downloadPackageInfo.cancelled = YES;
    
    // 埋点上报
    [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeDownload
                                  subtype:IESGurdAppLogEventSubtypeCancelDownload
                                   params:@{ @"download_identity" : self.downloadInfoModel.identity ? : @"" }
                                extraInfo:nil
                             errorMessage:nil];
    
    [self callDownloadCompletion:NO error:error];
}

- (void)innerFinishDownload:(BOOL)isSuccessful error:(NSError *)error;
{
    if (isSuccessful) {
        [self saveInactivePackageMetaData];
    }
    
    @synchronized (self) {
        self.executing = NO;
        self.finished = YES;
    }
    
    [self callDownloadCompletion:isSuccessful error:error];
}

- (void)callDownloadCompletion:(BOOL)isSuccessful error:(NSError *)error
{
    dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
        [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidFinishDownloadingPackageForAccessKey:self.accessKey
                                                                                       channel:self.config.channel
                                                                                   packageInfo:self.downloadPackageInfo];
        !self.downloadCompletion ? : self.downloadCompletion(self, isSuccessful, error);
    });
}

- (void)sendUpdateStats
{
    IESGurdUpdateStatisticModel *model = self.config.updateStatisticModel;
    [model resetDuration];
    model.updateResult = NO;
    model.durationTotal = GURD_TOK_WITH_START(model.startTime);
    
    NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    [extra addEntriesFromDictionary:self.logInfo];
    [model putDataToDict:extra];
    [self.config putDataToDict:extra];
    
    [IESGurdAppLogger recordUpdateStats:[extra copy]];
}

- (void)saveInactivePackageMetaData
{
    IESGurdResourceModel *config = self.config;
    
    IESGurdInactiveCacheMeta *meta = [[IESGurdInactiveCacheMeta alloc] init];
    meta.accessKey = self.accessKey;
    meta.channel = config.channel;
    meta.md5 = config.package.md5;
    meta.decompressMD5 = [self isPatch] ? config.patch.decompressMD5 : config.package.decompressMD5;
    meta.version = config.version;
    meta.packageID = config.package.ID;
    meta.patchID = config.patch.ID;
    meta.localVersion = config.localVersion;
    meta.packageType = (int)config.packageType;
    meta.fromPatch = [self isPatch];
    meta.isZstd = config.isZstd;
    meta.fileName = config.package.urlList[0].lastPathComponent;
    meta.groupName = config.groupName;
    meta.groups = config.groups;
    meta.logId = config.logId;
    meta.packageSize = config.package.packageSize;
    meta.patchPackageSize = config.patch.packageSize;
    meta.updateStatisticModel = config.updateStatisticModel;
    
    [IESGurdResourceMetadataStorage saveInactiveMeta:meta];
}

- (BOOL)isResourceActiveWithMeta:(IESGurdActivePackageMeta *)meta
{
    if (!meta) {
        // 本地没有已激活资源
        return NO;
    }
    if (meta.version != self.config.version) {
        // 本地资源版本和目标版本不匹配
        return NO;
    }
    // 检查本地资源是否真实存在
    NSString *resourceDirectory = [IESGurdFilePaths directoryPathForAccessKey:meta.accessKey channel:meta.channel];
    if ([[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourceDirectory error:NULL].count == 0) {
        [IESGurdResourceMetadataStorage deleteActiveMetaForAccessKey:meta.accessKey channel:meta.channel];
        return NO;
    }
    return YES;
}

- (BOOL)isResourceInactiveWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    IESGurdInactiveCacheMeta *inactiveMeta = [IESGurdResourceMetadataStorage inactiveMetaForAccessKey:accessKey channel:channel];
    if (!inactiveMeta) {
        // 本地没有要激活的资源
        return NO;
    }
    int64_t targetVersion = self.config.version;
    NSString *targetMd5 = self.config.package.md5;
    if (inactiveMeta.version == targetVersion && [inactiveMeta.md5 isEqualToString:targetMd5]) {
        NSString *zipFilePath = [IESGurdFilePaths inactivePackagePathForAccessKey:accessKey
                                                                          channel:channel
                                                                          version:targetVersion
                                                                           isZstd:self.config.isZstd
                                                                              md5:targetMd5];
        if ([[NSFileManager defaultManager] fileExistsAtPath:zipFilePath]) {
            return YES;
        }
    }
    // 本地记录未激活信息跟目标信息不匹配，或zip包不存在，删除本地记录
    [IESGurdResourceMetadataStorage deleteInactiveMetaForAccessKey:accessKey channel:channel];
    return NO;
}

#pragma mark - Subclass Override

- (void)operationDidStart
{
    IESGurdUpdateStageModel *stageModel = [self getUpdateStageMode:YES];
    stageModel.startTime = [NSDate date];
}

- (BOOL)isPatch
{
    return NO;
}

- (IESGurdUpdateStageModel *)getUpdateStageMode: (BOOL)needCreate
{
    return [self.config.updateStatisticModel getStageModel:needCreate
                                                   isPatch:[self isPatch]];
}

#pragma mark - Setter

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - Getter

- (IESGurdDownloadPackageInfo *)downloadPackageInfo
{
    if (!_downloadPackageInfo) {
        _downloadPackageInfo = [[IESGurdDownloadPackageInfo alloc] init];
        BOOL isPatch = [self isPatch];
        _downloadPackageInfo.patch = isPatch;
        _downloadPackageInfo.packageId = self.config.package.ID;
        _downloadPackageInfo.downloadPriority = self.config.downloadPriority;
    }
    return _downloadPackageInfo;
}

@end
