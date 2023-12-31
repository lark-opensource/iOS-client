//
//  ACCFileDownloader+ACCCutSameTemplate.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/23.
//

#import "ACCFileDownloader+ACCCutSameTemplate.h"

@implementation ACCFileDownloader (ACCCutSameTemplate)

- (ACCCutSameTemplateDownloadTask *)downloadCutSameTemplate:(id<ACCMVTemplateModelProtocol>)templateModel
                                                        url:(NSURL *)url
                                               downloadPath:(NSString *)path
                                           downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                                 completion:(ACCFileDownloaderCompletion)completion
{
    NSParameterAssert(url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSParameterAssert(request);
    
    __block ACCCutSameTemplateDownloadTask *downloadTask = [[ACCCutSameTemplateDownloadTask alloc] initWithURLRequests:@[request] filePath:path];
    downloadTask.queuePriority = NSOperationQueuePriorityNormal;
    downloadTask.qualityOfService = NSQualityOfServiceDefault;
    downloadTask.progressBlock = downloadProgress;
    downloadTask.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(downloadTask.error, downloadTask.filePath,downloadTask.extraInfoDict);
            downloadTask = nil;
        });
    };
    downloadTask.templateModel = templateModel;
    [self.downloadQueue addOperation:downloadTask];
    
    return downloadTask;
}

@end
