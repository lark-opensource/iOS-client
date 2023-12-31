//
//  ACCCutSameWorksManagerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/20.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import <CameraClient/AWECutSameMaterialAssetModel.h>
#import "ACCSelectAlbumAssetsProtocol.h"
#import "ACCCutSameWorksAssetModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCCutSameWorksManagerCompletion)(NSArray<AWECutSameMaterialAssetModel *> *result, id _Nullable dataManager, NSError *error);
typedef void(^ACCCutSameWorksManagerProgress)(CGFloat progress);

@class LVExporterConfig;

@protocol ACCCutSameWorksManagerProtocol <NSObject>

/// Current template
@property (nonatomic, strong, nullable) id<ACCMVTemplateModelProtocol> currrentTemplate;


/// Import material from AWEAssetModel array
/// @param assets AWEAssetModel array
/// @param progressHandler callback in progress
/// @param completion callback when completed
- (void)importMaterial:(NSArray<AWEAssetModel *> *)assets
       progressHandler:(ACCCutSameWorksManagerProgress)progressHandler
            completion:(ACCCutSameWorksManagerCompletion)completion;


@optional

/// download template resource callback
@property (nonatomic, copy, nullable) void (^downloadCompletion)(void);

/// Import material from ACCCutSameWorksAssetModel array
/// @param assets ACCCutSameWorksAssetModel array
/// @param progressHandler callback in progress
/// @param completion callback when completed
- (void)importWorksAssetModel:(NSArray<ACCCutSameWorksAssetModel *> *)assets
              progressHandler:(ACCCutSameWorksManagerProgress)progressHandler
                   completion:(ACCCutSameWorksManagerCompletion)completion;

/// Reprocess Template and create new processor
- (void)reprocessTemplate;

/// Cancel current template task
- (void)cancelCurrentTask;

/// Clear all cache files which created by worksmanager expect template zip files
- (void)clearCache;

/// Clear all template zip files
- (void)clearTemplateZip;

- (LVExporterConfig *)defaultConfigForLVExport;

@end

@protocol ACCMVCutSameStyleManagerProtocol <ACCCutSameWorksManagerProtocol>


@end

NS_ASSUME_NONNULL_END
