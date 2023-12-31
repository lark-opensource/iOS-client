//
//  ACCFileDownloader.m
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import "ACCFileDownloadTask.h"

@interface ACCFileDownloader ()

@end

@implementation ACCFileDownloader

+ (instancetype)sharedInstance;
{
    static ACCFileDownloader *sharedDownloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDownloader = [[ACCFileDownloader alloc] init];
        sharedDownloader.downloadQueue.maxConcurrentOperationCount = 20;
    });
    return sharedDownloader;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.name = @"com.bytedance.ACC.ACCFileDownloader";
    }
    return self;
}

- (void)setMaxConcurrentCount:(NSUInteger)count
{
    self.downloadQueue.maxConcurrentOperationCount = count;
}

- (ACCFileDownloadTask *)downloadFileWithURLs:(NSArray <NSString *>*)urls
                                 downloadPath:(NSString *)path
                             downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                   completion:(ACCFileDownloaderCompletion)completion;
{
    return [self downloadFileWithURLs:urls
                         downloadPath:path
                downloadQueuePriority:NSOperationQueuePriorityNormal
             downloadQualityOfService:NSQualityOfServiceDefault
                     downloadProgress:downloadProgress
                           completion:completion];
}

- (ACCFileDownloadTask *)downloadFileWithURLs:(NSArray <NSString *>*)urls
                                 downloadPath:(NSString *)path
                        downloadQueuePriority:(NSOperationQueuePriority)queuePriority
                     downloadQualityOfService:(NSQualityOfService)qualityOfService
                             downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                   completion:(ACCFileDownloaderCompletion)completion
{
    NSMutableArray *requests = [[NSMutableArray alloc] initWithCapacity:urls.count];
    for (int i=0; i<urls.count; i++) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urls[i]]];
        [requests addObject:request];
    }
    
    return [self downloadFileWithRequests:[requests copy]
                             downloadPath:path
                    downloadQueuePriority:queuePriority
                 downloadQualityOfService:qualityOfService
                         downloadProgress:downloadProgress
                               completion:completion];
}

- (ACCFileDownloadTask *)downloadFileWithRequests:(NSArray <NSURLRequest *>*)requests
                                     downloadPath:(NSString *)path
                                 downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                       completion:(ACCFileDownloaderCompletion)completion;
{
    return [self downloadFileWithRequests:requests
                             downloadPath:path
                    downloadQueuePriority:NSOperationQueuePriorityNormal
                 downloadQualityOfService:NSQualityOfServiceDefault
                         downloadProgress:downloadProgress
                               completion:completion];
}

- (ACCFileDownloadTask *)downloadFileWithRequests:(NSArray <NSURLRequest *>*)requests
                                     downloadPath:(NSString *)path
                            downloadQueuePriority:(NSOperationQueuePriority)queuePriority
                         downloadQualityOfService:(NSQualityOfService)qualityOfService
                                 downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                       completion:(ACCFileDownloaderCompletion)completion
{
    NSParameterAssert(requests.count > 0);
    __block ACCFileDownloadTask *downloadTask = [[ACCFileDownloadTask alloc] initWithURLRequests:requests filePath:path];
    downloadTask.queuePriority = queuePriority;
    downloadTask.qualityOfService = qualityOfService;
    downloadTask.progressBlock = downloadProgress;
    downloadTask.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(downloadTask.error, downloadTask.filePath,downloadTask.extraInfoDict);
            downloadTask = nil;
        });
    };
    [self.downloadQueue addOperation:downloadTask];
    return downloadTask;
}

@end
