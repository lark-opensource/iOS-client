//
//  IESEffectDownloadQueue.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <EffectPlatformSDK/IESEffectAlgorithmModel.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectConfig;
@class IESManifestManager;

// Download progress callback block definition.
typedef void(^ies_effect_download_progress_block_t)(CGFloat progress);

// Download completion callback block definition.
typedef void(^ies_effect_download_completion_block_t)(BOOL success, NSError * _Nullable error, NSString *traceLog);

@interface IESEffectDownloadQueue : NSObject

@property (nonatomic, strong, readonly) IESEffectConfig *config;

@property (nonatomic, strong, readonly) IESManifestManager *manifestManager;

- (instancetype)initWithConfig:(IESEffectConfig *)config manifestManager:(IESManifestManager *)manifestManager;

- (instancetype)init NS_UNAVAILABLE;

- (void)downloadEffectModel:(IESEffectModel *)effectModel
                   progress:(ies_effect_download_progress_block_t __nullable)progress
                 completion:(ies_effect_download_completion_block_t __nullable)completion;

- (void)downloadEffectModel:(IESEffectModel *)effectModel
      downloadQueuePriority:(NSOperationQueuePriority)queuePriority
   downloadQualityOfService:(NSQualityOfService)qualityOfService
                   progress:(ies_effect_download_progress_block_t __nullable)progress
                 completion:(ies_effect_download_completion_block_t __nullable)completion;

- (void)downloadAlgorithmModel:(IESEffectAlgorithmModel *)algorithmModel
                      progress:(ies_effect_download_progress_block_t __nullable)progress
                    completion:(ies_effect_download_completion_block_t __nullable)completion;

@end

NS_ASSUME_NONNULL_END
