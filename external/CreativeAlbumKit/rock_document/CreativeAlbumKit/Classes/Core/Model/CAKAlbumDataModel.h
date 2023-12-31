//
//  CAKAlbumDataModel.h
//  CameraClient
//
//  Created by lixingdong on 2020/6/22.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/RACSubject.h>
#import "CAKPhotoManager.h"
#import "CAKAlbumAssetModel.h"

@interface CAKAlbumAssetModelProvider : NSObject

- (CAKAlbumAssetModel *)assetModelForPhAsset:(PHAsset *)asset;

@end

@interface CAKAlbumAssetModelManager : NSObject

+ (instancetype)createWithPHFetchResult:(PHFetchResult *)result provider:(CAKAlbumAssetModelProvider *)provider;
- (CAKAlbumAssetModel *)objectIndex:(NSInteger)index;
- (CAKAlbumAssetModel *)assetModelForPhAsset:(PHAsset *)asset;
- (BOOL)containsObject:(CAKAlbumAssetModel *)anObject;
- (NSInteger)indexOfObject:(CAKAlbumAssetModel *)model;
- (PHFetchResult *)fetchResult;

@end

@interface CAKAlbumAssetDataModel : NSObject
@property (nonatomic, assign) AWEGetResourceType resourceType;
@property (nonatomic, strong) CAKAlbumAssetModelManager *assetModelManager;

- (CAKAlbumAssetModel *)objectIndex:(NSInteger)index;
- (NSInteger)numberOfObject;
- (NSInteger)indexOfObject:(CAKAlbumAssetModel *)model;
- (BOOL)containsObject:(CAKAlbumAssetModel *)anObject;
- (void)configShowIndexFilterBlock:(BOOL (^)(PHAsset *asset))filterBlock;

#pragma mark - only for preview
- (CAKAlbumAssetModel *)previewObjectIndex:(NSInteger)index;
- (NSInteger)previewNumberOfObject;
- (NSInteger)previewIndexOfObject:(CAKAlbumAssetModel *)model;
- (BOOL)previewContainsObject:(CAKAlbumAssetModel *)anObject;
- (void)configDataWithPreviewFilterBlock:(BOOL (^)(PHAsset *asset))filterBlock;
- (BOOL)removePreviewInvalidAssetForPostion:(NSInteger)position;

@end

typedef RACTwoTuple<CAKAlbumAssetDataModel *, NSNumber *> *CAKAssetsSourceChangedPack;

@interface CAKAlbumDataModel : NSObject

@property (nonatomic, strong) CAKAlbumModel *albumModel;
@property (nonatomic, strong) NSIndexPath *targetIndexPath;

// album list
@property (nonatomic, strong) NSArray<CAKAlbumModel *> *allAlbumModels;

// data source
@property (nonatomic, strong) CAKAlbumAssetDataModel *videoSourceAssetsDataModel;
@property (nonatomic, strong) CAKAlbumAssetDataModel *photoSourceAssetsDataModel;
@property (nonatomic, strong) CAKAlbumAssetDataModel *mixedSourceAssetsDataModel;
@property (nonatomic, readonly) CAKAlbumAssetModelProvider *assetModelProvider;

@property (nonatomic, strong, nonnull) RACSubject<CAKAssetsSourceChangedPack> *resultSourceAssetsSubject;

// selected assets
@property (nonatomic, strong) NSMutableArray<CAKAlbumAssetModel *> *videoSelectAssetsModels;  // selected videos
@property (nonatomic, strong) NSMutableArray<CAKAlbumAssetModel *> *photoSelectAssetsModels;  // selected videos
@property (nonatomic, strong) NSMutableArray<CAKAlbumAssetModel *> *mixedSelectAssetsModels;  // selected videos && photos

// fetch result
@property (nonatomic, strong) PHFetchResult *fetchResult;

@property (nonatomic, assign) NSInteger beforeSelectedPhotoCount;
@property (nonatomic, assign) BOOL addAssetInOrder;
@property (nonatomic, assign) BOOL removeAssetInOrder;

- (void)setupAssetModelProvider;

- (void)addAsset:(CAKAlbumAssetModel *)model forResourceType:(AWEGetResourceType)resourceType;

- (void)removeAsset:(CAKAlbumAssetModel *)model forResourceType:(AWEGetResourceType)resourceType;

- (void)removeAllAssetsForResourceType:(AWEGetResourceType)resourceType;

- (CAKAlbumAssetModel *)findAssetWithResourceType:(AWEGetResourceType)resourceType localIdentifier:(NSString *)localIdentifier;

@end
