//
//  IESFileDownloader.m
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import "IESFileDownloader.h"
#import "IESDelegateFileDownloadTask.h"
#import "IESEffectPlatformRequestManager.h"

@interface IESFileDownloader ()

@end

@implementation IESFileDownloader

+ (instancetype)sharedInstance;
{
    static IESFileDownloader *sharedDownloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDownloader = [[IESFileDownloader alloc] init];
        sharedDownloader.downloadQueue.maxConcurrentOperationCount = 20;
        sharedDownloader.requestDelegate = [IESEffectPlatformRequestManager requestManager];
    });
    return sharedDownloader;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.name = @"com.bytedance.ies.IESFileDownloader";
    }
    return self;
}

- (void)setMaxConcurrentCount:(NSUInteger)count
{
    self.downloadQueue.maxConcurrentOperationCount = count;
}

- (IESDelegateFileDownloadTask *)downloadFileWithURLs:(NSArray<NSString *> *)urls
                                         downloadPath:(NSString *)path
                                     downloadProgress:(IESFileDownloaderProgress)downloadProgress
                                           completion:(IESFileDownloaderCompletion)completion {
    return [self delegateDownloadFileWithURLs:urls
                                 downloadPath:path
                             downloadProgress:downloadProgress
                                   completion:completion];
}

- (IESDelegateFileDownloadTask *)delegateDownloadFileWithURLs:(NSArray <NSString *>*)urls
                                                 downloadPath:(NSString *)path
                                             downloadProgress:(IESFileDownloaderProgress)downloadProgress
                                                   completion:(IESFileDownloaderCompletion)completion
{
    return [self delegateDownloadFileWithURLs:urls
                                 downloadPath:path
                        downloadQueuePriority:NSOperationQueuePriorityNormal
                     downloadQualityOfService:NSQualityOfServiceDefault
                             downloadProgress:downloadProgress
                                   completion:completion];
}

- (IESDelegateFileDownloadTask *)delegateDownloadFileWithURLs:(NSArray <NSString *>*)urls
                                                 downloadPath:(NSString *)path
                                        downloadQueuePriority:(NSOperationQueuePriority)queuePriority
                                     downloadQualityOfService:(NSQualityOfService)qualityOfService
                                             downloadProgress:(IESFileDownloaderProgress)downloadProgress
                                                   completion:(IESFileDownloaderCompletion)completion
{
    __block IESDelegateFileDownloadTask *downloadTask = [[IESDelegateFileDownloadTask alloc] initWithURL:urls filePath:path];
    downloadTask.queuePriority = queuePriority;
    downloadTask.qualityOfService = qualityOfService;
    downloadTask.progressBlock = downloadProgress;
    downloadTask.requestDelegate = self.requestDelegate;
    void (^completionBlock)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(downloadTask.error, downloadTask.filePath,downloadTask.extraInfoDict);
            downloadTask = nil;
        });
    };
    IESEffectPreFetchProcessIfNeed(completion, completionBlock)
    downloadTask.completionBlock = completionBlock;
    [self.downloadQueue addOperation:downloadTask];
    return downloadTask;
}

@end
