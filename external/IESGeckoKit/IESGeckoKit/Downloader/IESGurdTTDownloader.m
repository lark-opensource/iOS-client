//
//  IESGurdTTDownloader.m
//  IESGeckoKit
//
//  Created by liuhaitian on 2020/5/7.
//

#import "IESGeckoKit.h"
#import "IESGurdKit+DownloadProgress.h"
#import "IESGurdTTDownloader.h"
#import "IESGeckoResourceManager.h"
#import "IESGurdEventTraceManager+Message.h"
#import "IESGurdFileBusinessManager.h"
#import "IESGurdKitUtil.h"
#import "IESGurdDownloadInfoModel.h"

#import <TTNetworkDownloader/TTDownloadApi.h>
#import <TTNetworkDownloader/TTDownloadManager.h>

static NSString * const kTTDownloaderErrorDomain = @"IESTTDownloaderErrorDomain";

static void IESGurdTTDownloaderLog (NSString *message, BOOL hasError, BOOL shouldLog) {
    if (message.length > 0) {
        message = [NSString stringWithFormat:@"【TTDownloader】%@", message];
        [IESGurdEventTraceManager traceEventWithMessage:message hasError:hasError shouldLog:shouldLog];
    }
}

typedef void(^IESGurdDownloaderDelegateDownloadCompletion)(NSURL * _Nullable pathURL, BOOL canRetry, NSError * _Nullable error);

@interface IESGurdTTDownloader ()

// 下载参数
@property(nonatomic, strong) DownloadGlobalParameters *downloadParameters;
// 不需要重试的错误码
@property(nonatomic, strong) NSArray *stopRetryErrorCodes;

@end

@implementation IESGurdTTDownloader

+ (IESGurdTTDownloader *)sharedDownloader
{
    static IESGurdTTDownloader *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[self alloc] init];
        
        DownloadGlobalParameters *downloadParameters = [[DownloadGlobalParameters alloc] init];
        downloadParameters.isBackgroundDownloadEnable = NO;
        downloadParameters.isCheckCacheValid = YES;
        downloadParameters.retryTimeoutInterval = 3;
        downloadParameters.isSliced = NO;
        downloadParameters.contentLengthWaitMaxInterval = 1;
        downloadParameters.isHttps2HttpFallback = YES;
        downloadParameters.queuePriority = QUEUE_PRIORITY_HIGH;
        downloadParameters.insertType = QUEUE_HEAD;
        downloadParameters.isSkipGetContentLength = YES;
        downloadParameters.cacheLifeTimeMax = 60 * 60 * 24;
        
        downloader.downloadParameters = downloadParameters;
        
        downloader.stopRetryErrorCodes = @[@(ERROR_FREE_SPACE_NOT_ENOUGH),
                                           @(ERROR_WRITE_DISK_FAILED),
                                           @(ERROR_DOWNLOAD_TASK_COUNT_OVERFLOW),
                                           @(ERROR_FREE_SPACE_NOT_ENOUGH_WHILE_MERGE),
                                           @(ERROR_CANCEL_SUCCESS)];
    });
    return downloader;
}

#pragma mark - Public

+ (void)setEnable:(BOOL)enable
{
    if (enable) {
        IESGurdKit.downloaderDelegate = [self sharedDownloader];
    } else {
        IESGurdKit.downloaderDelegate = nil;
    }
    
    IESGurdTTDownloaderLog([NSString stringWithFormat:@"%@ TTDownloader", enable ? @"Enable" : @"Disable"], NO, YES);
}

+ (void)handleBackgroundURLSessionWithIdentifier:(NSString *)identifier
                               completionHandler:(void (^)(void))completionHandler
{
    if ([[TTDownloadManager shareInstance] findBgIdentifierDicLock:identifier]) {
        IESGurdTTDownloaderLog([NSString stringWithFormat:@"Handle backgroundURLSession(%@)", identifier], NO, YES);
        [TTDownloadManager shareInstance].bgCompletedHandler = completionHandler;
    }
}

#pragma mark - Accessor

static BOOL kBackgroundDownloadEnable = NO;
+ (BOOL)isBackgroundDownloadEnabled
{
    return kBackgroundDownloadEnable;
}

+ (void)setBackgroundDownloadEnabled:(BOOL)backgroundDownloadEnabled
{
    kBackgroundDownloadEnable = backgroundDownloadEnabled;
    
    IESGurdTTDownloaderLog([NSString stringWithFormat:@"%@ TTDownloader background download", backgroundDownloadEnabled ? @"Enable" : @"Disable"], NO, YES);
}

#pragma mark - IESGurdDownloaderDelegate

- (void)downloadPackageWithDownloadInfoModel:(IESGurdDownloadInfoModel *)model
                                  completion:(IESGurdDownloadResourceCompletion)completion
{
    NSString *identity = model.identity;
    NSArray<NSString *> *URLStrings = model.allDownloadURLStrings;
    NSCParameterAssert([URLStrings isKindOfClass:NSArray.class]);
    
    // 查询历史下载
    [[TTDownloadApi shareInstance] queryDownloadInfoWithURL:identity downloadInfoBlock:^(DownloadInfo *downloadInfo) {
        NSMutableArray *updatedURLStrings = [NSMutableArray arrayWithArray:URLStrings];
        IESGurdDownloadContinuationType continuationType = IESGurdDownloadContinuationTypeNormal;
        
        NSString *message = nil;
        BOOL shouldLog = NO;
        if ([self continueDownloadWithInfo:downloadInfo]) {
            // 如果查询有历史下载进度，则将历史下载的 URL 置为 URLStrings 的第一个，并设置续传类型为 IESGurdIsContinuation
            NSString *previousURLString = downloadInfo.secondUrl;
            if (previousURLString) {
                NSInteger index = [updatedURLStrings indexOfObject:previousURLString];
                if (index != NSNotFound) {
                    [updatedURLStrings exchangeObjectAtIndex:index withObjectAtIndex:0];
                } else {
                    [updatedURLStrings insertObject:previousURLString atIndex:0];
                }
            }
            
            continuationType = IESGurdDownloadContinuationTypeContinuation;
            
            message = [NSString stringWithFormat:@"Continue to download : %@; DownloadedSize : %lld; TotalSize : %lld",
                       identity, downloadInfo.downloadedSize, downloadInfo.totalSize];
            shouldLog = YES;
        } else {
            message = [NSString stringWithFormat:@"Start downloading : %@", identity];
        }
        IESGurdTTDownloaderLog(message, NO, shouldLog);
        
        // 开始下载
        [self startDownloadWithIdentity:identity
                             URLStrings:[updatedURLStrings copy]
                           downloadSize:model.packageSize
                       continuationType:continuationType
                             completion:completion];
    }];
}

- (void)cancelDownloadWithIdentity:(nonnull NSString *)identity {
    [[TTDownloadApi shareInstance] deleteDownloadWithURL:identity resultBlock:^(DownloadResultNotification *resultNotification) {
        
    }];
}

#pragma mark - Private

- (BOOL)continueDownloadWithInfo:(DownloadInfo *)downloadInfo
{
    return (downloadInfo && downloadInfo.status == FAILED && downloadInfo.downloadedSize != 0 && [downloadInfo.secondUrl length] != 0);
}

- (void)startDownloadWithIdentity:(NSString *)identity
                       URLStrings:(NSArray <NSString *> *)URLStrings
                     downloadSize:(uint64_t)downloadSize
                 continuationType:(IESGurdDownloadContinuationType)continuationType
                       completion:(IESGurdDownloadResourceCompletion)completion
{
    NSMutableDictionary *downloadInfo = [NSMutableDictionary dictionary];
    downloadInfo[@"download_type"] = self.downloadParameters.isBackgroundDownloadEnable ? @(2) : @(IESGurdDownloadTypeTTDownloader);
    
    __block NSMutableArray *downloadFailedRecords = nil;
    __block NSUInteger index = 0;
    __block NSInteger totalDuration = 0;
    __block dispatch_block_t retryDownloadBlock = ^{
        downloadInfo[@"download_retry_times"] = @(index);
        
        NSString *packageURLString = URLStrings[index++] ? : @"";
        NSCParameterAssert([packageURLString isKindOfClass:NSString.class]);
        
        NSDate *startDownloadDate = [NSDate date];
        [self downloadWithIdentity:identity URLString:packageURLString downloadSize:downloadSize completion:^(NSURL *pathURL, BOOL canRetry, NSError *error) {
            NSInteger downloadDuration = (NSInteger)([[NSDate date] timeIntervalSinceDate:startDownloadDate] * 1000);
            totalDuration += downloadDuration;
            
            if (!pathURL) {
                if (!downloadFailedRecords) {
                    downloadFailedRecords = [NSMutableArray array];
                }
                NSString *reason = [NSString stringWithFormat:@"【%zd】%@", error.code, error.localizedDescription];
                [downloadFailedRecords addObject:@{ @"domain" : packageURLString,
                                                    @"reason" : reason,
                                                    @"duration" : @(downloadDuration) }];
                
                // 如果有剩余可用下载链接且可以重试，则重试下载
                if (index < URLStrings.count && canRetry) {
                    retryDownloadBlock();
                    return;
                }
            } else {
                downloadInfo[IESGurdDownloadInfoDurationKey] = @(downloadDuration);
                downloadInfo[IESGurdDownloadInfoURLKey] = packageURLString;
                
                NSString *packageFilePath = [IESGurdFileBusinessManager downloadTempFilePath];
                NSURL *packageFileURL = [NSURL fileURLWithPath:packageFilePath];
                [[NSFileManager defaultManager] moveItemAtURL:pathURL toURL:packageFileURL error:NULL];
                
                // 删除 TND 上的记录，由 Gecko 内部维护
                NSDate *deleteDownloadDate = [NSDate date];
                [[TTDownloadApi shareInstance] deleteDownloadWithURL:identity resultBlock:^(DownloadResultNotification *resultNotification) {
                    NSInteger deleteDownloadDuration = (NSInteger)([[NSDate date] timeIntervalSinceDate:deleteDownloadDate] * 1000);
                    IESGurdTTDownloaderLog([NSString stringWithFormat:@"Delete record : %@; Cost : %zdms; Code : %zd",
                                            identity, deleteDownloadDuration, resultNotification.code], NO, NO);
                }];
                pathURL = packageFileURL;
            }
            
            if (downloadFailedRecords) {
                downloadInfo[@"download_fail_records"] = [downloadFailedRecords copy];
            }
            downloadInfo[@"total_duration"] = @(totalDuration);
            downloadInfo[@"download_continuation"] = @(continuationType);
            
            !completion ? : completion(pathURL, [downloadInfo copy], error);
            
            retryDownloadBlock = nil;
        }];
    };
    retryDownloadBlock();
}

- (void)downloadWithIdentity:(NSString *)identity
                   URLString:(NSString *)URLString
                downloadSize:(uint64_t)downloadSize
                  completion:(IESGurdDownloaderDelegateDownloadCompletion)completion
{
    NSProgress *downloadProgress = [NSProgress progressWithTotalUnitCount:downloadSize];
    IESGurdDownloadProgressObject *progressObject = [IESGurdKit progressObjectForIdentity:identity];
    [progressObject startObservingWithProgress:downloadProgress];
    
    TTDownloadProgressBlock progressBlock = ^(DownloadProgressInfo *progress) {
        downloadProgress.completedUnitCount = progress.downloadedSize;
    };
    TTDownloadResultBlock resultBlock = ^(DownloadResultNotification *resultNotification) {
        // 如果有地址，则成功返回
        if (resultNotification.downloadedFilePath) {
            IESGurdTTDownloaderLog([NSString stringWithFormat:@"✅ Download successfully : %@", identity], NO, NO);
            
            NSURL *pathURL = [NSURL fileURLWithPath:resultNotification.downloadedFilePath];
            !completion ?: completion(pathURL, NO, nil);
            return;
        }
        // 否则，处理失败逻辑
        StatusCode code = resultNotification.code;
        NSString *errorMessage = resultNotification.downloaderLog ? : @"unknown";
        BOOL canRetry = ![self.stopRetryErrorCodes containsObject:@(code)];
        IESGurdTTDownloaderLog([NSString stringWithFormat:@"❌ Download failed : %@; Code : %zd; Reason : %@; %@ retry",
                                identity, code, errorMessage, canRetry ? @"Can" : @"Can't"], NO, NO);
        
        NSError *error = [[NSError alloc] initWithDomain:kTTDownloaderErrorDomain
                                                    code:code
                                                userInfo:@{ NSLocalizedDescriptionKey : errorMessage }];
        !completion ?: completion(nil, canRetry, error);
    };
    [[TTDownloadApi shareInstance] startDownloadWithKey:identity
                                               fileName:identity
                                               md5Value:nil
                                               urlLists:@[URLString]
                                               progress:progressBlock
                                                 status:resultBlock
                                         userParameters:self.downloadParameters];
}

@end
