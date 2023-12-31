//
//  ACCCutSameTemplateDownloadTask.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/23.
//

#import "ACCFileDownloadTask.h"
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCutSameTemplateDownloadTask : ACCFileDownloadTask

@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> templateModel;

@end

NS_ASSUME_NONNULL_END
