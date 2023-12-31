//
//  ACCFileDownloader.h
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>

@class ACCFileDownloadTask;
typedef void(^ACCFileDownloaderProgress)(CGFloat progress);
typedef void(^ACCFileDownloaderCompletion)(NSError * error, NSString * filePath, NSDictionary *extraInfoDict);

@interface ACCFileDownloader : NSObject

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) id<EffectPlatformRequestDelegate>requestDelegate;

+ (instancetype)sharedInstance;
//Default is 20
- (void)setMaxConcurrentCount:(NSUInteger)count;

- (ACCFileDownloadTask *)downloadFileWithURLs:(NSArray <NSString *>*)urls
                                 downloadPath:(NSString *)path
                             downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                   completion:(ACCFileDownloaderCompletion)completion;

- (ACCFileDownloadTask *)downloadFileWithURLs:(NSArray <NSString *>*)urls
                                 downloadPath:(NSString *)path
                        downloadQueuePriority:(NSOperationQueuePriority)queuePriority
                     downloadQualityOfService:(NSQualityOfService)qualityOfService
                             downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                   completion:(ACCFileDownloaderCompletion)completion;

- (ACCFileDownloadTask *)downloadFileWithRequests:(NSArray <NSURLRequest *>*)requests
                                     downloadPath:(NSString *)path
                                 downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                       completion:(ACCFileDownloaderCompletion)completion;

- (ACCFileDownloadTask *)downloadFileWithRequests:(NSArray <NSURLRequest *>*)requests
                                     downloadPath:(NSString *)path
                            downloadQueuePriority:(NSOperationQueuePriority)queuePriority
                         downloadQualityOfService:(NSQualityOfService)qualityOfService
                                 downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                       completion:(ACCFileDownloaderCompletion)completion;

@end
