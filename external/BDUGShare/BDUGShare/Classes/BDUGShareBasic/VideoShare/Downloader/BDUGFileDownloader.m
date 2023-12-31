//
//  BDUGFileDownloader.m
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import "BDUGFileDownloader.h"
#import "BDUGFileDownloadTask.h"

@interface BDUGFileDownloader ()

@property (nonatomic) NSOperationQueue *downloadQueue;

@end

@implementation BDUGFileDownloader

+ (instancetype)sharedInstance;
{
    static BDUGFileDownloader *sharedDownloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDownloader = [[BDUGFileDownloader alloc] init];
    });
    return sharedDownloader;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.name = @"com.bytedance.BDUGFileDownloader";
    }
    return self;
}

- (void)setMaxConcurrentCount:(NSUInteger)count
{
    self.downloadQueue.maxConcurrentOperationCount = count;
}

- (BDUGFileDownloadTask *)downloadFileWithURLs:(NSArray <NSString *>*)urls
                                 downloadPath:(NSString *)path
                             downloadProgress:(BDUGFileDownloaderProgress)downloadProgress
                                   completion:(BDUGFileDownloaderCompletion)completion;
{
    NSMutableArray *requests = [[NSMutableArray alloc] initWithCapacity:urls.count];
    for (int i=0; i<urls.count; i++) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urls[i]]];
        [requests addObject:request];
    }
    
    return [self downloadFileWithRequests:requests downloadPath:path downloadProgress:downloadProgress completion:completion];
}

- (BDUGFileDownloadTask *)downloadFileWithRequests:(NSArray <NSURLRequest *>*)requests
                                     downloadPath:(NSString *)path
                                 downloadProgress:(BDUGFileDownloaderProgress)downloadProgress
                                       completion:(BDUGFileDownloaderCompletion)completion;
{
    NSParameterAssert(requests.count > 0);
    BDUGFileDownloadTask *downloadTask = [[BDUGFileDownloadTask alloc] initWithURLRequests:requests filePath:path];
    downloadTask.progressBlock = downloadProgress;
    
    __weak BDUGFileDownloadTask *weakTask = downloadTask;
    downloadTask.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(weakTask.error, weakTask.filePath);
        });
    };
    [self.downloadQueue addOperation:downloadTask];
    return downloadTask;
}

- (void)cancelAllTask
{
    [self.downloadQueue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[BDUGFileDownloadTask class]]) {
            [(BDUGFileDownloadTask *)(obj) cancelDownloadTask];
        }
    }];
    [self.downloadQueue cancelAllOperations];
}

@end
