//
//  IESEffectDownloadQueue.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/9.
//

#import "IESEffectDownloadQueue.h"
#import <EffectPlatformSDK/IESEffectBaseDownloadTask.h>
#import <EffectPlatformSDK/IESEffectModelDownloadTask.h>
#import <EffectPlatformSDK/IESAlgorithmModelDownloadTask.h>
#import <EffectPlatformSDK/IESManifestManager.h>
#import <EffectPlatformSDK/NSError+IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectPlatformRequestManager.h>

@interface IESEffectDownloadQueue ()

@property (nonatomic, strong, readwrite) IESEffectConfig *config;

@property (nonatomic, strong, readwrite) IESManifestManager *manifestManager;

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESEffectBaseDownloadTask *> *downloadingTasks;

@end

@implementation IESEffectDownloadQueue

- (instancetype)initWithConfig:(IESEffectConfig *)config manifestManager:(IESManifestManager *)manifestManager {
    if (self = [super init]) {
        _config = config;
        _manifestManager = manifestManager;
        _downloadingTasks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Public

- (void)downloadEffectModel:(IESEffectModel *)effectModel
                   progress:(ies_effect_download_progress_block_t)progress
                 completion:(ies_effect_download_completion_block_t)completion {
    [self downloadEffectModel:effectModel downloadQueuePriority:NSOperationQueuePriorityNormal downloadQualityOfService:NSQualityOfServiceDefault progress:progress completion:completion];
}

- (void)downloadEffectModel:(IESEffectModel *)effectModel
      downloadQueuePriority:(NSOperationQueuePriority)queuePriority
   downloadQualityOfService:(NSQualityOfService)qualityOfService
                   progress:(ies_effect_download_progress_block_t __nullable)progress
                 completion:(ies_effect_download_completion_block_t __nullable)completion
{
    if (effectModel.fileDownloadURLs.count == 0 || effectModel.md5.length == 0) {
        if (completion) {
            NSError *error = [NSError ieseffect_errorWithCode:40001 description:@"Invalid Parameters"];
            completion(NO, error, @"the URLs or md5 of effectModel is invalid");
        }
        return;
    }
    
    NSString *destination = [self.config.effectsDirectory stringByAppendingPathComponent:effectModel.md5];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *taskKey = effectModel.md5;
        
        IESEffectBaseDownloadTask *task = self.downloadingTasks[taskKey];
        if (task != nil && ![task isKindOfClass:IESEffectBaseDownloadTask.class]) {
            NSAssert(NO, @"task should be kind of IESEffectModelDownloadTask");
        }
        
        if (task) {
            if (progress) {
                [task.progressBlocks addObject:progress];
            }
            if (completion) {
                [task.completionBlocks addObject:completion];
            }
        } else {
            task = [[IESEffectModelDownloadTask alloc] initWithEffectModel:effectModel destination:destination];
            task.manifestManager = self.manifestManager;
            task.queuePriority = queuePriority;
            task.qualityOfService = qualityOfService;
            if (progress) {
                [task.progressBlocks addObject:progress];
            }
            if (completion) {
                [task.completionBlocks addObject:completion];
            }
            
            self.downloadingTasks[taskKey] = task;
            @weakify(self);
            void (^taskStartCompletion)(void) = ^{
                @strongify(self);
                self.downloadingTasks[taskKey] = nil;
            };
            IESEffectPreFetchProcessIfNeed(completion, taskStartCompletion)
            [task startWithCompletion:taskStartCompletion];
        }
    });
}

- (void)downloadAlgorithmModel:(IESEffectAlgorithmModel *)algorithmModel
                      progress:(ies_effect_download_progress_block_t)progress
                    completion:(ies_effect_download_completion_block_t)completion {
    if (algorithmModel.fileDownloadURLs.count == 0 || algorithmModel.modelMD5.length == 0) {
        if (completion) {
            NSError *error = [NSError ieseffect_errorWithCode:40002 description:@"Invalid Parameters"];
            completion(NO, error, @"the URLs or modelMD5 of algorithmModel is invalid");
        }
        return;
    }
    
    NSString *destination = [self.config.algorithmsDirectory stringByAppendingPathComponent:algorithmModel.modelMD5];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *taskKey = algorithmModel.modelMD5;
        
        IESEffectBaseDownloadTask *task = self.downloadingTasks[taskKey];
        if (task != nil && ![task isKindOfClass:IESAlgorithmModelDownloadTask.class]) {
            NSAssert(NO, @"task should be kind of IESAlgorithmModelDownloadTask");
        }
        
        if (task) {
            if (completion) {
                [task.completionBlocks addObject:completion];
            }
        } else {
            task = [[IESAlgorithmModelDownloadTask alloc] initWithAlgorithmModel:algorithmModel destination:destination];
            task.manifestManager = self.manifestManager;
            if (completion) {
                [task.completionBlocks addObject:completion];
            }
            
            self.downloadingTasks[taskKey] = task;
            @weakify(self);
            void (^taskStartCompletion)(void) = ^{
                @strongify(self);
                self.downloadingTasks[taskKey] = nil;
            };
            IESEffectPreFetchProcessIfNeed(completion, taskStartCompletion)
            [task startWithCompletion:taskStartCompletion];
        }
    });
}

@end
