//
//  ARTEffectDownloadQueue.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/20.
//

#import <Foundation/Foundation.h>
#import "ARTEffectDefines.h"

@protocol ARTEffectPrototype;

@class ARTEffectModel;
@class ARTEffectConfig;
@class ARTManifestManager;
@class ARTEffectBaseDownloadTask;

NS_ASSUME_NONNULL_BEGIN

@interface ARTEffectDownloadQueue : NSObject
@property (nonatomic, strong, readonly) ARTEffectConfig *config;
@property (nonatomic, strong, readonly) ARTManifestManager *manifestManager;

- (instancetype)initWithConfig:(ARTEffectConfig *)config manifestManager:(ARTManifestManager *)manifestManager;
- (instancetype)init NS_UNAVAILABLE;

- (ARTEffectBaseDownloadTask * __nullable)downloadTaskWithMD5:(NSString *)md5;
- (BOOL)containsDownloadTaskWithMD5:(NSString *)md5;

- (void)downloadEffect:(id<ARTEffectPrototype>)effect
              progress:(art_effect_download_progress_block_t __nullable)progress
            completion:(art_effect_download_completion_block_t __nullable)completion;

- (void)downloadEffectModel:(ARTEffectModel *)effectModel
                   progress:(art_effect_download_progress_block_t __nullable)progress
                 completion:(art_effect_download_completion_block_t __nullable)completion;

@end

NS_ASSUME_NONNULL_END
