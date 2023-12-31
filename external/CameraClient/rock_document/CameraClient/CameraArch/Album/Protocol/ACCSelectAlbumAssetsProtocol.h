//
//  ACCSelectAlbumAssetsProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/9.
//  打开相册选择页面

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCCommonDefine.h>
#import "ACCPhotoAlbumDefine.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCAlbumInputData.h"
#import <CreativeAlbumKit/CAKAlbumViewController.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEAssetModel, ACCAlbumInputData;

@protocol ACCSelectAlbumAssetsDelegate <NSObject>

@optional

- (void)albumViewControllerDidRequestPhotoAuthorization;
- (BOOL)albumViewControllerShouldSelectAsset:(AWEAssetModel *)asset;
- (void)albumViewControllerDidSelectAssets:(NSArray<AWEAssetModel *> *)selectedAssets;
- (void)albumViewController:(CAKAlbumViewController *)controller didFinishFetch:(NSArray *)result;
- (BOOL)albumViewControllerShouldStartClipProcedure:(CAKAlbumViewController *)controller;

// TC21 每次点击选中照片/视频回调
- (void)albumViewControllerDidSelectOneAsset:(AWEAssetModel * _Nullable)asset;

@end

@protocol ACCSelectAlbumAssetsProtocol <NSObject>

@property (nonatomic, weak) id<ACCSelectAlbumAssetsDelegate> delegate;

- (nonnull CAKAlbumViewController *)albumViewControllerWithInputData:(ACCAlbumInputData *)inputData;

@end

NS_ASSUME_NONNULL_END
