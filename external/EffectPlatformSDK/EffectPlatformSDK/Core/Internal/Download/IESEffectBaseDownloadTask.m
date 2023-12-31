//
//  IESEffectBaseDownloadTask.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/9.
//

#import "IESEffectBaseDownloadTask.h"
#import <EffectPlatformSDK/IESEffectUtil.h>
#import <EffectPlatformSDK/IESEffectDownloadQueue.h>

@interface IESEffectBaseDownloadTask ()

@property (nonatomic, copy, readwrite) NSString *fileMD5;

@property (nonatomic, copy, readwrite) NSString *destination;

@property (nonatomic, strong, readwrite) NSMutableArray *progressBlocks;

@property (nonatomic, strong, readwrite) NSMutableArray *completionBlocks;

@end

@implementation IESEffectBaseDownloadTask

- (instancetype)initWithFileMD5:(NSString *)fileMD5 destination:(nonnull NSString *)destination {
    if (self = [super init]) {
        _fileMD5 = [fileMD5 copy];
        _destination = [destination copy];
        _progressBlocks = [[NSMutableArray alloc] init];
        _completionBlocks = [[NSMutableArray alloc] init];
        _queuePriority = NSOperationQueuePriorityNormal;
        _qualityOfService = NSQualityOfServiceDefault;
    }
    return self;
}

- (void)startWithCompletion:(void (^)(void))completion {
    
}

- (void)callProgressBlocks:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (ies_effect_download_progress_block_t progressBlock in self.progressBlocks) {
            progressBlock(progress);
        }
    });
}

- (void)callCompletionBlocks:(BOOL)success error:(NSError *)error traceLog:(NSString *)traceLog{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (ies_effect_download_completion_block_t completionBlock in self.completionBlocks) {
            completionBlock(success, error, traceLog);
        }
    });
}

- (void)downloadFileWithURLs:(NSArray<NSString *> *)urls
                downloadPath:(NSString *)path
            downloadProgress:(IESFileDownloaderProgress)downloadProgress
                  completion:(IESFileDownloaderCompletion)completion {
    [[IESFileDownloader sharedInstance] delegateDownloadFileWithURLs:urls
                                                        downloadPath:path
                                               downloadQueuePriority:self.queuePriority
                                            downloadQualityOfService:self.qualityOfService
                                                    downloadProgress:downloadProgress
                                                          completion:completion];
}

@end
