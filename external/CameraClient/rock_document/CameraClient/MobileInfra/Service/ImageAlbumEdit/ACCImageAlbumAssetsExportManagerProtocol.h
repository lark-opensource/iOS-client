//
//  ACCImageAlbumAssetsExportManagerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/4/13.
//

#ifndef ACCImageAlbumAssetsExportManagerProtocol_h
#define ACCImageAlbumAssetsExportManagerProtocol_h

#import <Foundation/Foundation.h>
#import "ACCImageAlbumEditAssetsExportOutputDataProtocol.h"
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEAssetModel, AWEVideoPublishViewModel;
@protocol ACCMusicModelProtocol;

@protocol ACCImageAlbumAssetsExportManagerProtocol <NSObject>

+ (void)exportWithAssetModels:(NSArray<AWEAssetModel *> *)assetModels
                 publishModel:(AWEVideoPublishViewModel *)publishViewModel
                   completion:(void(^)(BOOL succeed, id<ACCImageAlbumEditAssetsExportOutputDataProtocol> outputData))completion;

/// 标记用户在编辑页主动选择过图集的音乐，下次进入将会主动带上
+ (void)markUserDidSelectMusicWhenEditWithMusic:(id<ACCMusicModelProtocol>)music;

+ (void)clearLastSelectedMusicCache;

+ (void)exportWithImages:(NSArray<UIImage *> *)images
            publishModel:(AWEVideoPublishViewModel *)publishViewModel
              completion:(void(^)(BOOL succeed, id<ACCImageAlbumEditAssetsExportOutputDataProtocol> outputData))completion;

@end

FOUNDATION_STATIC_INLINE Class<ACCImageAlbumAssetsExportManagerProtocol> ACCImageAlbumAssetsExportManager() {
    
    return [[ACCBaseServiceProvider() resolveObject:@protocol(ACCImageAlbumAssetsExportManagerProtocol)] class];
}

NS_ASSUME_NONNULL_END

#endif /* ACCImageAlbumAssetsExportManagerProtocol_h */
