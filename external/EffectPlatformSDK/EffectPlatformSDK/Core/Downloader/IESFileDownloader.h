//
//  IESFileDownloader.h
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import <Foundation/Foundation.h>
#import "EffectPlatform.h"

@class IESDelegateFileDownloadTask;
typedef void(^IESFileDownloaderProgress)(CGFloat progress);
typedef void(^IESFileDownloaderCompletion)(NSError * error, NSString * filePath, NSDictionary *extraInfoDict);

@interface IESFileDownloader : NSObject

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) id<EffectPlatformRequestDelegate>requestDelegate;

+ (instancetype)sharedInstance;
//Default is 20
- (void)setMaxConcurrentCount:(NSUInteger)count;

- (IESDelegateFileDownloadTask *)downloadFileWithURLs:(NSArray <NSString *>*)urls
                                         downloadPath:(NSString *)path
                                     downloadProgress:(IESFileDownloaderProgress)downloadProgress
                                           completion:(IESFileDownloaderCompletion)completion API_DEPRECATED_WITH_REPLACEMENT("[[IESFileDownloader sharedInstance] delegateDownloadFileWithURLs:]", ios(8.0, 13.7));

- (IESDelegateFileDownloadTask *)delegateDownloadFileWithURLs:(NSArray <NSString *>*)urls
                                                 downloadPath:(NSString *)path
                                             downloadProgress:(IESFileDownloaderProgress)downloadProgress
                                                   completion:(IESFileDownloaderCompletion)completion;

- (IESDelegateFileDownloadTask *)delegateDownloadFileWithURLs:(NSArray <NSString *>*)urls
                                                 downloadPath:(NSString *)path
                                        downloadQueuePriority:(NSOperationQueuePriority)queuePriority
                                     downloadQualityOfService:(NSQualityOfService)qualityOfService
                                             downloadProgress:(IESFileDownloaderProgress)downloadProgress
                                                   completion:(IESFileDownloaderCompletion)completion;

@end
