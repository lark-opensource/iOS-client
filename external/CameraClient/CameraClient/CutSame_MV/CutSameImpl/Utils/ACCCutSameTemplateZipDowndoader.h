//
//  ACCCutSameTemplateZipDowndoader.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/23.
//

#import <Foundation/Foundation.h>
#import "ACCCutSameTemplateDownloadTask.h"
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>

#import <VideoTemplate/LVTemplateProcessor.h>

@class ACCCutSameTemplateZipDowndoader;

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCCutSameTemplateZipDowndoaderDelegateCompletion)(ACCCutSameTemplateZipDowndoader *downloader, NSString *filePath, NSError * _Nullable error);

@interface ACCCutSameTemplateZipDowndoader : NSObject<LVTemplateZipDowndoader>

@property (nonatomic, weak  ) ACCCutSameTemplateDownloadTask *task;

@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> templateModel;

@property (nonatomic, copy  ) ACCCutSameTemplateZipDowndoaderDelegateCompletion delegateCompletion;

+ (void)clearCache;

@end

NS_ASSUME_NONNULL_END
