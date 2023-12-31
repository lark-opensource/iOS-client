//
//  ACCVideoPublishAsImageAlbumProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/9/22.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

@class AWEAssetModel, AWEVideoPublishViewModel;

/// 视频类的素材发布为图集，目前仅支持画布单图

@protocol ACCVideoPublishAsImageAlbumProtocol <NSObject>

/// 单图是否是能够发布为图集
+ (BOOL)isCanvansPhotoAndEnablePublishAsImageAlbum:(AWEVideoPublishViewModel *_Nonnull)publishModel;

/// 单图是否是能够发布为图集的简单判断，会忽略商业化等在发布页可以重新设置的元素的判断
+ (BOOL)isCanvansPhotoAndEnablePublishAsImageAlbumWithoutDynamicCheck:(AWEVideoPublishViewModel *_Nonnull)publishModel;

/// 单图存本地是否能存成图片，存本地不受 类似 一闪而过, 存本地，商业化元素 等影响，而一闪而过之类的不能发布为图片
/// 另外存本地不会检查贴纸，需要在component里自行加判断
+ (BOOL)isCanvansPhotoAndEnableSaveAlbumAsImageAlbum:(AWEVideoPublishViewModel *_Nonnull)publishModel;

/// 单图导入时存入的原始图
+ (NSString *)existOriginalImageFilePathFrom:(AWEVideoPublishViewModel *_Nonnull)publishModel;

/// 存入单图原图，发布时用作图集发布导出图片
+ (void)saveOriginalImageWithAsset:(AWEAssetModel *_Nonnull)assetModel
                                to:(AWEVideoPublishViewModel *_Nonnull)publishModel
                        completion:(void (^)(BOOL))completion;

+ (void)saveOriginalImageWithImage:(UIImage *_Nonnull)image
                                to:(AWEVideoPublishViewModel *_Nonnull)publishModel
                        completion:(void (^)(BOOL))completion;

@end


FOUNDATION_STATIC_INLINE Class<ACCVideoPublishAsImageAlbumProtocol> ACCVideoPublishAsImageAlbumHelper() {
    
    return [[ACCBaseServiceProvider() resolveObject:@protocol(ACCVideoPublishAsImageAlbumProtocol)] class];
}
