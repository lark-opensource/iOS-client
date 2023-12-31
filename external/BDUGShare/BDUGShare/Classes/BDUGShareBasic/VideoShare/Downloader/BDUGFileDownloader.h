//
//  BDUGFileDownloader.h
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import <Foundation/Foundation.h>

@class BDUGFileDownloadTask;
typedef void(^BDUGFileDownloaderProgress)(CGFloat progress);
typedef void(^BDUGFileDownloaderCompletion)(NSError * error, NSString * filePath);

@interface BDUGFileDownloader : NSObject

+ (instancetype)sharedInstance;

- (void)setMaxConcurrentCount:(NSUInteger)count;

- (BDUGFileDownloadTask *)downloadFileWithURLs:(NSArray <NSString *>*)urls
                                 downloadPath:(NSString *)path
                             downloadProgress:(BDUGFileDownloaderProgress)downloadProgress
                                   completion:(BDUGFileDownloaderCompletion)completion;

- (BDUGFileDownloadTask *)downloadFileWithRequests:(NSArray <NSURLRequest *>*)requests
                                     downloadPath:(NSString *)path
                                 downloadProgress:(BDUGFileDownloaderProgress)downloadProgress
                                       completion:(BDUGFileDownloaderCompletion)completion;

- (void)cancelAllTask;

@end
