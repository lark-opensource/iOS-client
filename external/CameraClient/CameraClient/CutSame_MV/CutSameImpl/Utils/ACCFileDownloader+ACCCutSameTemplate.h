//
//  ACCFileDownloader+ACCCutSameTemplate.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/23.
//

#import "ACCFileDownloader.h"
#import "ACCCutSameTemplateDownloadTask.h"
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCFileDownloader (ACCCutSameTemplate)

- (ACCCutSameTemplateDownloadTask *)downloadCutSameTemplate:(id<ACCMVTemplateModelProtocol>)templateModel
                                                        url:(NSURL *)url
                                               downloadPath:(NSString *)path
                                           downloadProgress:(ACCFileDownloaderProgress)downloadProgress
                                                 completion:(ACCFileDownloaderCompletion)completion;

@end

NS_ASSUME_NONNULL_END
