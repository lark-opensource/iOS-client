//
//  ACCSmartMovieUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by LeonZou on 2021/8/2.
//

#import <Foundation/Foundation.h>
#import <CameraClient/ACCSmartMovieDefines.h>

FOUNDATION_EXTERN NSString *const kACCSmartMovieBubbleTipsHasShownKey;

@protocol ACCEditVideoDataProtocol;
@class AWEAssetModel;
@class CAKAlbumAssetModel, AWEVideoPublishViewModel;

/// 是否启用智照
/// @param assets 对应的数据
FOUNDATION_EXTERN BOOL acc_isOpenSmartMovieCapabilities(AWEVideoPublishViewModel *_Nonnull publishModel);

@interface ACCSmartMovieUtils : NSObject

+ (BOOL)isAllPhotoAsset:(NSArray *_Nonnull)assets;  // 仅支持判断CAKAlbumAssetModel & AWEAssetModel

+ (NSArray<NSString *> *_Nullable)trimHomeDirForPaths:(NSArray<NSString *> *_Nonnull)assetPaths;

+ (NSArray<NSString *> *_Nullable)thumbImagesForPaths:(NSArray<NSString *> *_Nonnull)assetPaths;

+ (NSArray<NSString *> *_Nullable)absolutePathsForAssets:(NSArray<NSString *> *_Nonnull)assetPaths;

+ (UIImage *_Nullable)compressImage:(UIImage *_Nonnull)originImg toSize:(CGFloat)maxLength;

#pragma mark - Config Methods

/// 获得effectSDK版本号
+ (NSString * _Nullable)effectSDKVersion;

#pragma mark - NLE Methods

/// 合并对应mode下的二次编辑数据到目标
+ (void)mergeModeTracks:(ACCSmartMovieSceneMode)mode to:(AWEVideoPublishViewModel *_Nonnull)to;

/// 从目标对象中移除对应mode下的二次编辑数据
+ (void)removeModeTracks:(ACCSmartMovieSceneMode)mode from:(AWEVideoPublishViewModel *_Nonnull)from;

/// 同步MV二次编辑的轨道到目标并会移除旧数据
+ (void)syncMVTracks:(AWEVideoPublishViewModel *_Nonnull)to;

/// 同步智照二次编辑的轨道到目标并会移除旧数据
+ (void)syncSmartMovieTracks:(AWEVideoPublishViewModel *_Nonnull)to;

/// 标记videoData中的NLEModel的轨道为智照场景中的MV
+ (void)markTracksAsMVForSmartMovie:(id<ACCEditVideoDataProtocol>_Nonnull)videoData;

@end
